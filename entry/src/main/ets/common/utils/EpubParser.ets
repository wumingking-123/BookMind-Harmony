/**
 * EPUB 解析器 v3
 * 策略: 先用 zlib 解压整个 EPUB 到目录, 失败则手动解析 ZIP 字节流
 */
import fs from '@ohos.file.fs';
import zlib from '@ohos.zlib';
import { chaptersItem } from '../../componets/dataList/ReaderChaptersItem';
import { util } from '@kit.ArkTS';

interface ManifestItem {
  id: string
  href: string
  mediaType: string
  title: string
}

interface ParseResult {
  manifest: ManifestItem[]
  spine: string[]
  title: string
}

export class EpubParser {

  /**
   * 解析 EPUB 文件，返回章节数组
   */
  static async parse(epubPath: string): Promise<chaptersItem[]> {
    const chapters: chaptersItem[] = [];

    try {
      // 检查文件是否存在
      if (!fs.accessSync(epubPath)) {
        chapters.push(new chaptersItem(1, '文件不存在', '1', 'EPUB 文件路径无效: ' + epubPath));
        return chapters;
      }

      // 获取文件大小
      const stat: fs.Stat = fs.statSync(epubPath);
      console.info('EPUB 文件大小: ' + stat.size + ' bytes');

      if (stat.size === 0) {
        chapters.push(new chaptersItem(1, '文件为空', '1', 'EPUB 文件大小为 0。'));
        return chapters;
      }

      // 策略1: 尝试用 zlib 解压整个 EPUB 到临时目录
      const extractDir: string = epubPath + '_extracted';
      let extractedOk: boolean = false;

      try {
        // 清理旧的解压目录
        try { fs.rmdirSync(extractDir); } catch (e) {}
        fs.mkdirSync(extractDir);

        // 尝试解压
        await zlib.decompressFile(epubPath, extractDir);
        extractedOk = true;
        console.info('EPUB zlib 解压成功');
      } catch (zlibErr) {
        console.warn('EPUB zlib 解压失败，尝试手动解析: ' + JSON.stringify(zlibErr));
        try { fs.rmdirSync(extractDir); } catch (e) {}
      }

      if (extractedOk) {
        // zlib 解压成功，从目录读取文件
        const result: chaptersItem[] = EpubParser.parseFromDirectory(extractDir, chapters, epubPath);
        // 清理临时目录
        try { fs.rmdirSync(extractDir); } catch (e) {}
        return result.length > 0 ? result : chapters;
      }

      // 策略2: 手动解析 ZIP 字节流
      const file: fs.File = fs.openSync(epubPath, fs.OpenMode.READ_ONLY);
      const fileData: ArrayBuffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, fileData);
      fs.closeSync(file);

      const bytes: Uint8Array = new Uint8Array(fileData);
      const files: Map<string, Uint8Array> = EpubParser.extractZipEntries(bytes);

      if (files.size === 0) {
        chapters.push(new chaptersItem(1, 'EPUB 解析失败', '1', '无法从 EPUB 文件中提取任何内容。文件可能使用了不支持的压缩格式。'));
        return chapters;
      }

      // 解析 container.xml
      const containerData: Uint8Array | undefined = files.get('META-INF/container.xml');
      if (!containerData) {
        // 尝试不区分大小写查找
        let found: boolean = false;
        const keys: string[] = Array.from(files.keys());
        for (let i = 0; i < keys.length; i++) {
          if (keys[i].toLowerCase() === 'meta-inf/container.xml') {
            const data: Uint8Array | undefined = files.get(keys[i]);
            if (data) {
              const xml: string = EpubParser.bytesToString(data);
              const rootfilePath: string = EpubParser.parseContainer(xml);
              if (rootfilePath.length > 0) {
                const result: chaptersItem[] = EpubParser.parseFromOpf(files, rootfilePath, epubPath);
                return result.length > 0 ? result : chapters;
              }
            }
            found = true;
            break;
          }
        }
        if (!found) {
          chapters.push(new chaptersItem(1, 'EPUB 解析失败', '1', '缺少 container.xml 文件。'));
        }
        return chapters;
      }

      const containerXml: string = EpubParser.bytesToString(containerData);
      const rootfilePath: string = EpubParser.parseContainer(containerXml);
      if (rootfilePath.length === 0) {
        chapters.push(new chaptersItem(1, 'EPUB 解析失败', '1', '无法找到 rootfile 路径。'));
        return chapters;
      }

      const result: chaptersItem[] = EpubParser.parseFromOpf(files, rootfilePath, epubPath);
      return result.length > 0 ? result : chapters;

    } catch (err) {
      console.error('EPUB 解析异常: ' + JSON.stringify(err));
      if (chapters.length === 0) {
        chapters.push(new chaptersItem(1, 'EPUB 解析失败', '1', '解析过程中发生错误: ' + String(err)));
      }
    }

    return chapters;
  }

  /**
   * 从解压后的目录解析 EPUB
   */
  static parseFromDirectory(extractDir: string, chapters: chaptersItem[], epubPath: string): chaptersItem[] {
    try {
      // 查找 container.xml
      const containerPath: string = extractDir + '/META-INF/container.xml';
      if (!fs.accessSync(containerPath)) {
        chapters.push(new chaptersItem(1, 'EPUB 解析失败', '1', '缺少 container.xml'));
        return chapters;
      }

      const containerXml: string = EpubParser.readFileAsText(containerPath);
      const rootfilePath: string = EpubParser.parseContainer(containerXml);
      if (rootfilePath.length === 0) {
        chapters.push(new chaptersItem(1, 'EPUB 解析失败', '1', '无法找到 rootfile'));
        return chapters;
      }

      const opfPath: string = extractDir + '/' + rootfilePath;
      if (!fs.accessSync(opfPath)) {
        chapters.push(new chaptersItem(1, 'EPUB 解析失败', '1', '无法找到 content.opf'));
        return chapters;
      }

      const opfXml: string = EpubParser.readFileAsText(opfPath);
      const result: ParseResult = EpubParser.parseContentOpf(opfXml);

      // 解析 toc.ncx
      const rootfileDir: string = rootfilePath.substring(0, rootfilePath.lastIndexOf('/'));
      EpubParser.parseTocNcxFromDir(extractDir, rootfileDir, result);

      // 确定 bookKey 并创建持久性资源目录
      const bookKey = epubPath.substring(epubPath.lastIndexOf('/') + 1).replace(/\.[^.]+$/, '');
      const appDir = getAppFilesDir();
      const resourcesDir = appDir + '/epub_resources/' + bookKey;

      // 提取/复制所有图片到 epub_resources
      for (let i = 0; i < result.manifest.length; i++) {
        const item = result.manifest[i];
        if (item.mediaType.startsWith('image/')) {
          let srcImageKey = item.href;
          let srcPath = extractDir + '/' + (rootfileDir.length > 0 ? (rootfileDir + '/' + srcImageKey) : srcImageKey);
          if (fs.accessSync(srcPath)) {
            let destPath = resourcesDir + '/' + (rootfileDir.length > 0 ? (rootfileDir + '/' + srcImageKey) : srcImageKey);
            const parentDir = destPath.substring(0, destPath.lastIndexOf('/'));
            EpubParser.ensureDirExists(parentDir);
            try {
              if (fs.accessSync(destPath)) {
                fs.unlinkSync(destPath);
              }
              fs.copyFileSync(srcPath, destPath);
            } catch (copyErr) {
              console.warn('Failed to copy image ' + srcImageKey + ': ' + JSON.stringify(copyErr));
            }
          }
        }
      }

      // 按 spine 顺序读取章节
      let chapterNumber: number = 0;
      for (let si = 0; si < result.spine.length; si++) {
        const itemRef: string = result.spine[si];
        const item: ManifestItem | undefined = EpubParser.findManifestItem(result.manifest, itemRef);
        if (!item || item.href.length === 0) continue;

        let xhtmlPath: string = extractDir;
        if (rootfileDir.length > 0) {
          xhtmlPath += '/' + rootfileDir;
        }
        xhtmlPath += '/' + item.href;

        if (!fs.accessSync(xhtmlPath)) continue;

        const xhtmlContent: string = EpubParser.readFileAsText(xhtmlPath);
        
        let xhtmlKey = item.href;
        if (rootfileDir.length > 0) {
          xhtmlKey = rootfileDir + '/' + item.href;
        }
        const processedXhtml = EpubParser.processImagesInXhtml(xhtmlContent, xhtmlKey, resourcesDir);
        const textContent: string = EpubParser.extractTextFromXhtml(processedXhtml);

        if (textContent.trim().length > 0) {
          chapterNumber++;
          const chapterTitle: string = item.title.length > 0 ? item.title : '第' + chapterNumber + '章';
          chapters.push(new chaptersItem(chapterNumber, chapterTitle, chapterNumber.toString(), textContent));
        }
      }

      if (chapters.length === 0) {
        chapters.push(new chaptersItem(1, result.title.length > 0 ? result.title : 'EPUB 电子书', '1', '未能提取到文本内容。'));
      }

    } catch (err) {
      console.error('目录解析失败: ' + JSON.stringify(err));
      if (chapters.length === 0) {
        chapters.push(new chaptersItem(1, 'EPUB 解析失败', '1', '目录解析出错。'));
      }
    }

    return chapters;
  }

  /**
   * 从 ZIP 字节流解析 EPUB
   */
  static parseFromOpf(files: Map<string, Uint8Array>, rootfilePath: string, epubPath: string): chaptersItem[] {
    const chapters: chaptersItem[] = [];

    const opfData: Uint8Array | undefined = files.get(rootfilePath);
    if (!opfData) {
      chapters.push(new chaptersItem(1, 'EPUB 解析失败', '1', '无法找到 content.opf'));
      return chapters;
    }

    const opfXml: string = EpubParser.bytesToString(opfData);
    const result: ParseResult = EpubParser.parseContentOpf(opfXml);

    // 解析 toc.ncx
    EpubParser.parseTocNcx(files, result);

    const rootfileDir: string = rootfilePath.substring(0, rootfilePath.lastIndexOf('/'));

    // 确定 bookKey 并创建持久性资源目录
    const bookKey = epubPath.substring(epubPath.lastIndexOf('/') + 1).replace(/\.[^.]+$/, '');
    const appDir = getAppFilesDir();
    const resourcesDir = appDir + '/epub_resources/' + bookKey;

    // 提取所有图片文件并写入沙箱
    for (let i = 0; i < result.manifest.length; i++) {
      const item = result.manifest[i];
      if (item.mediaType.startsWith('image/')) {
        let imageKey = item.href;
        if (rootfileDir.length > 0) {
          imageKey = rootfileDir + '/' + item.href;
        }
        const imgData = files.get(imageKey);
        if (imgData && imgData.length > 0) {
          let destPath = resourcesDir + '/' + imageKey;
          const parentDir = destPath.substring(0, destPath.lastIndexOf('/'));
          EpubParser.ensureDirExists(parentDir);
          try {
            if (fs.accessSync(destPath)) {
              fs.unlinkSync(destPath);
            }
            const destFile = fs.openSync(destPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
            fs.writeSync(destFile.fd, imgData.buffer);
            fs.closeSync(destFile);
          } catch (writeErr) {
            console.warn('Failed to write image ' + imageKey + ': ' + JSON.stringify(writeErr));
          }
        }
      }
    }

    // 按 spine 读取章节
    let chapterNumber: number = 0;

    for (let si = 0; si < result.spine.length; si++) {
      const itemRef: string = result.spine[si];
      const item: ManifestItem | undefined = EpubParser.findManifestItem(result.manifest, itemRef);
      if (!item || item.href.length === 0) continue;

      let xhtmlKey: string = item.href;
      if (rootfileDir.length > 0) {
        xhtmlKey = rootfileDir + '/' + item.href;
      }

      const xhtmlData: Uint8Array | undefined = files.get(xhtmlKey);
      if (!xhtmlData || xhtmlData.length === 0) continue;

      const xhtmlContent: string = EpubParser.bytesToString(xhtmlData);
      const processedXhtml = EpubParser.processImagesInXhtml(xhtmlContent, xhtmlKey, resourcesDir);
      const textContent: string = EpubParser.extractTextFromXhtml(processedXhtml);

      if (textContent.trim().length > 0) {
        chapterNumber++;
        const chapterTitle: string = item.title.length > 0 ? item.title : '第' + chapterNumber + '章';
        chapters.push(new chaptersItem(chapterNumber, chapterTitle, chapterNumber.toString(), textContent));
      }
    }

    if (chapters.length === 0) {
      chapters.push(new chaptersItem(1, result.title.length > 0 ? result.title : 'EPUB 电子书', '1',
        '未能提取到文本内容。文件可能使用了压缩格式，当前版本暂不支持。'));
    }

    return chapters;
  }

  // ==================== ZIP 解析 ====================

  static extractZipEntries(bytes: Uint8Array): Map<string, Uint8Array> {
    const files: Map<string, Uint8Array> = new Map();

    try {
      // 先查找中央目录结束记录 (EOCD) 签名 0x06054b50
      let eocdOffset: number = bytes.length - 22;
      while (eocdOffset >= 0) {
        if (bytes[eocdOffset] === 0x50 && bytes[eocdOffset + 1] === 0x4B &&
            bytes[eocdOffset + 2] === 0x05 && bytes[eocdOffset + 3] === 0x06) {
          break;
        }
        eocdOffset--;
      }

      if (eocdOffset < 0) {
        // 没找到 EOCD，回退到顺序扫描
        return EpubParser.extractZipEntriesSequential(bytes);
      }

      // 从 EOCD 读取中央目录信息
      const centralDirEntries: number = bytes[eocdOffset + 10] | (bytes[eocdOffset + 11] << 8);
      const centralDirOffset: number = EpubParser.readUint32(bytes, eocdOffset + 16);

      // 遍历中央目录
      let offset: number = centralDirOffset;
      for (let i = 0; i < centralDirEntries && offset < bytes.length - 4; i++) {
        // 中央目录头签名 0x02014b50
        if (!(bytes[offset] === 0x50 && bytes[offset + 1] === 0x4B &&
              bytes[offset + 2] === 0x01 && bytes[offset + 3] === 0x02)) {
          break;
        }

        const compressionMethod: number = bytes[offset + 10] | (bytes[offset + 11] << 8);
        const compressedSize: number = EpubParser.readUint32(bytes, offset + 20);
        const uncompressedSize: number = EpubParser.readUint32(bytes, offset + 24);
        const fileNameLength: number = bytes[offset + 28] | (bytes[offset + 29] << 8);
        const extraFieldLength: number = bytes[offset + 30] | (bytes[offset + 31] << 8);
        const commentLength: number = bytes[offset + 32] | (bytes[offset + 33] << 8);
        const localHeaderOffset: number = EpubParser.readUint32(bytes, offset + 42);

        const fileNameStart: number = offset + 46;
        const fileName: string = EpubParser.bytesToString(
          bytes.slice(fileNameStart, fileNameStart + fileNameLength)
        );

        // 从本地文件头读取数据
        if (localHeaderOffset + 30 < bytes.length) {
          const localFileNameLength: number = bytes[localHeaderOffset + 26] | (bytes[localHeaderOffset + 27] << 8);
          const localExtraLength: number = bytes[localHeaderOffset + 28] | (bytes[localHeaderOffset + 29] << 8);
          const dataStart: number = localHeaderOffset + 30 + localFileNameLength + localExtraLength;

          if (compressionMethod === 0 && dataStart + uncompressedSize <= bytes.length) {
            // 未压缩
            const fileData: Uint8Array = bytes.slice(dataStart, dataStart + uncompressedSize);
            files.set(fileName, fileData);
          } else if (compressionMethod === 8 && dataStart + compressedSize <= bytes.length) {
            // Deflate 压缩 — 保存压缩数据，标记为需要解压
            const compressedData: Uint8Array = bytes.slice(dataStart, dataStart + compressedSize);
            files.set(fileName, compressedData);
          }
        }

        offset = fileNameStart + fileNameLength + extraFieldLength + commentLength;
      }

    } catch (err) {
      console.error('ZIP 中央目录解析错误: ' + JSON.stringify(err));
      // 回退到顺序扫描
      return EpubParser.extractZipEntriesSequential(bytes);
    }

    return files;
  }

  /**
   * 顺序扫描 ZIP 文件头 (回退方案)
   */
  static extractZipEntriesSequential(bytes: Uint8Array): Map<string, Uint8Array> {
    const files: Map<string, Uint8Array> = new Map();

    try {
      let offset: number = 0;
      while (offset < bytes.length - 30) {
        if (bytes[offset] === 0x50 && bytes[offset + 1] === 0x4B &&
            bytes[offset + 2] === 0x03 && bytes[offset + 3] === 0x04) {

          const compressionMethod: number = bytes[offset + 8] | (bytes[offset + 9] << 8);
          const compressedSize: number = EpubParser.readUint32(bytes, offset + 18);
          const uncompressedSize: number = EpubParser.readUint32(bytes, offset + 22);
          const fileNameLength: number = bytes[offset + 26] | (bytes[offset + 27] << 8);
          const extraFieldLength: number = bytes[offset + 28] | (bytes[offset + 29] << 8);

          const fileNameStart: number = offset + 30;
          const fileName: string = EpubParser.bytesToString(
            bytes.slice(fileNameStart, fileNameStart + fileNameLength)
          );

          const dataStart: number = fileNameStart + fileNameLength + extraFieldLength;

          if (compressionMethod === 0 && dataStart + uncompressedSize <= bytes.length) {
            files.set(fileName, bytes.slice(dataStart, dataStart + uncompressedSize));
          } else if (compressionMethod === 8 && dataStart + compressedSize <= bytes.length) {
            files.set(fileName, bytes.slice(dataStart, dataStart + compressedSize));
          }

          offset = dataStart + Math.max(compressedSize, uncompressedSize);
        } else {
          offset++;
        }
      }
    } catch (err) {
      console.error('ZIP 顺序扫描错误: ' + JSON.stringify(err));
    }

    return files;
  }

  // ==================== XML 解析 ====================

  static parseContainer(containerXml: string): string {
    const match: RegExpMatchArray | null = containerXml.match(/full-path\s*=\s*"([^"]+)"/);
    if (match !== null && match.length > 1) {
      return match[1];
    }
    return '';
  }

  static parseContentOpf(opfXml: string): ParseResult {
    const result: ParseResult = { manifest: [], spine: [], title: '' };

    const titleMatch: RegExpMatchArray | null = opfXml.match(/<dc:title[^>]*>([^<]+)<\/dc:title>/);
    if (titleMatch !== null && titleMatch.length > 1) {
      result.title = titleMatch[1].trim();
    }

    const manifestRegex: RegExp = /<item\s+[^>]*?(?:id\s*=\s*"([^"]+)"[^>]*?href\s*=\s*"([^"]+)"[^>]*?media-type\s*=\s*"([^"]+)"|href\s*=\s*"([^"]+)"[^>]*?id\s*=\s*"([^"]+)"[^>]*?media-type\s*=\s*"([^"]+)"|id\s*=\s*"([^"]+)"[^>]*?media-type\s*=\s*"([^"]+)"[^>]*?href\s*=\s*"([^"]+)")[^>]*\/?>/g;
    let match: RegExpExecArray | null;
    while ((match = manifestRegex.exec(opfXml)) !== null) {
      let id: string = '';
      let href: string = '';
      let mediaType: string = '';
      if (match[1] && match[2] && match[3]) { id = match[1]; href = match[2]; mediaType = match[3]; }
      else if (match[4] && match[5] && match[6]) { href = match[4]; id = match[5]; mediaType = match[6]; }
      else if (match[7] && match[8] && match[9]) { id = match[7]; mediaType = match[8]; href = match[9]; }
      if (id.length > 0 && href.length > 0) {
        result.manifest.push({ id, href, mediaType, title: '' });
      }
    }

    const spineRegex: RegExp = /<itemref\s+[^>]*?idref\s*=\s*"([^"]+)"[^>]*\/?>/g;
    let spineMatch: RegExpExecArray | null;
    while ((spineMatch = spineRegex.exec(opfXml)) !== null) {
      result.spine.push(spineMatch[1]);
    }

    return result;
  }

  static parseTocNcx(files: Map<string, Uint8Array>, result: ParseResult): void {
    let tocKey: string = '';
    for (let i = 0; i < result.manifest.length; i++) {
      if (result.manifest[i].mediaType === 'application/x-dtbncx+xml') {
        tocKey = result.manifest[i].href;
        break;
      }
    }
    if (tocKey.length === 0) return;

    const tocData: Uint8Array | undefined = files.get(tocKey);
    if (!tocData || tocData.length === 0) return;

    EpubParser.parseTocContent(EpubParser.bytesToString(tocData), result);
  }

  static parseTocNcxFromDir(extractDir: string, rootfileDir: string, result: ParseResult): void {
    let tocKey: string = '';
    for (let i = 0; i < result.manifest.length; i++) {
      if (result.manifest[i].mediaType === 'application/x-dtbncx+xml') {
        tocKey = result.manifest[i].href;
        break;
      }
    }
    if (tocKey.length === 0) return;

    let tocPath: string = extractDir;
    if (rootfileDir.length > 0) tocPath += '/' + rootfileDir;
    tocPath += '/' + tocKey;

    if (!fs.accessSync(tocPath)) return;

    const content: string = EpubParser.readFileAsText(tocPath);
    EpubParser.parseTocContent(content, result);
  }

  static parseTocContent(content: string, result: ParseResult): void {
    const navPointRegex: RegExp = /<navPoint[^>]*>[\s\S]*?<text>([^<]+)<\/text>[\s\S]*?<content\s+src\s*=\s*"([^"]+)"[^>]*\/?>/g;
    let match: RegExpExecArray | null;
    while ((match = navPointRegex.exec(content)) !== null) {
      const title: string = match[1].trim();
      const src: string = match[2].split('#')[0];
      for (let i = 0; i < result.manifest.length; i++) {
        if (result.manifest[i].href === src || result.manifest[i].href.endsWith(src)) {
          result.manifest[i].title = title;
          break;
        }
      }
    }
  }

  // ==================== 工具方法 ====================

  static findManifestItem(manifest: ManifestItem[], id: string): ManifestItem | undefined {
    for (let i = 0; i < manifest.length; i++) {
      if (manifest[i].id === id) return manifest[i];
    }
    return undefined;
  }

  static extractTextFromXhtml(content: string): string {
    let text: string = content;
    text = text.replace(/<\?xml[^?]*\?>/g, '');
    text = text.replace(/<!DOCTYPE[^>]*>/gi, '');
    text = text.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '');
    text = text.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '');
    text = text.replace(/<br\s*\/?>/gi, '\n');
    text = text.replace(/<\/p>/gi, '\n');
    text = text.replace(/<\/div>/gi, '\n');
    text = text.replace(/<\/h[1-6]>/gi, '\n');
    text = text.replace(/<[^>]+>/g, '');
    text = text.replace(/&nbsp;/g, ' ');
    text = text.replace(/&lt;/g, '<');
    text = text.replace(/&gt;/g, '>');
    text = text.replace(/&amp;/g, '&');
    text = text.replace(/&quot;/g, '"');
    text = text.replace(/&#39;/g, "'");
    text = text.replace(/&\w+;/g, '');
    text = text.replace(/\n\s*\n\s*\n/g, '\n\n');
    text = text.replace(/[ \t]+/g, ' ');
    return text.trim();
  }

  static readUint32(bytes: Uint8Array, offset: number): number {
    return (bytes[offset] | (bytes[offset + 1] << 8) |
            (bytes[offset + 2] << 16) | (bytes[offset + 3] << 24)) >>> 0;
  }

  static bytesToString(bytes: Uint8Array): string {
    try {
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      return decoder.decodeWithStream(bytes, { stream: false });
    } catch (err) {
      return '';
    }
  }

  static readFileAsText(filePath: string): string {
    try {
      const file: fs.File = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const stat: fs.Stat = fs.statSync(filePath);
      const buf: ArrayBuffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buf);
      fs.closeSync(file);
      return EpubParser.bytesToString(new Uint8Array(buf));
    } catch (err) {
      return '';
    }
  }

  /**
   * 从 EPUB 提取封面图片
   */
  static async extractCover(epubPath: string): Promise<string> {
    try {
      // 1. 尝试用 zlib 解压整个 EPUB 到临时目录
      const extractDir: string = epubPath + '_cover_tmp';
      let extractedOk: boolean = false;
      try {
        try { fs.rmdirSync(extractDir); } catch (e) {}
        fs.mkdirSync(extractDir);
        await zlib.decompressFile(epubPath, extractDir);
        extractedOk = true;
      } catch (zlibErr) {
        console.warn('Cover extraction: zlib decompress failed, falling back to manual zip: ' + JSON.stringify(zlibErr));
        try { fs.rmdirSync(extractDir); } catch (e) {}
      }

      if (extractedOk) {
        const containerPath: string = extractDir + '/META-INF/container.xml';
        if (fs.accessSync(containerPath)) {
          const containerXml: string = EpubParser.readFileAsText(containerPath);
          const rootfilePath: string = EpubParser.parseContainer(containerXml);
          if (rootfilePath.length > 0) {
            const opfPath: string = extractDir + '/' + rootfilePath;
            if (fs.accessSync(opfPath)) {
              const opfXml: string = EpubParser.readFileAsText(opfPath);
              const result: ParseResult = EpubParser.parseContentOpf(opfXml);
              const rootfileDir: string = rootfilePath.substring(0, rootfilePath.lastIndexOf('/'));
              
              let coverHref: string = EpubParser.findCoverHref(result);
              if (coverHref.length > 0) {
                let coverPath: string = extractDir;
                if (rootfileDir.length > 0) coverPath += '/' + rootfileDir;
                coverPath += '/' + coverHref;
                
                if (fs.accessSync(coverPath)) {
                  const appDir: string = getAppFilesDir();
                  const ext: string = coverHref.substring(coverHref.lastIndexOf('.'));
                  const destPath: string = appDir + '/epub_cover_' + Date.now() + ext;
                  fs.copyFileSync(coverPath, destPath);
                  try { fs.rmdirSync(extractDir); } catch (e) {}
                  return destPath;
                }
              }
            }
          }
        }
        try { fs.rmdirSync(extractDir); } catch (e) {}
      }

      // 2. 手动解析 ZIP 字节流提取封面
      const stat: fs.Stat = fs.statSync(epubPath);
      const file: fs.File = fs.openSync(epubPath, fs.OpenMode.READ_ONLY);
      const fileData: ArrayBuffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, fileData);
      fs.closeSync(file);

      const bytes: Uint8Array = new Uint8Array(fileData);
      const files: Map<string, Uint8Array> = EpubParser.extractZipEntries(bytes);
      
      const containerData: Uint8Array | undefined = files.get('META-INF/container.xml') || 
                                                    files.get('meta-inf/container.xml');
      if (containerData) {
        const containerXml: string = EpubParser.bytesToString(containerData);
        const rootfilePath: string = EpubParser.parseContainer(containerXml);
        if (rootfilePath.length > 0) {
          const opfData: Uint8Array | undefined = files.get(rootfilePath);
          if (opfData) {
            const opfXml: string = EpubParser.bytesToString(opfData);
            const result: ParseResult = EpubParser.parseContentOpf(opfXml);
            const rootfileDir: string = rootfilePath.substring(0, rootfilePath.lastIndexOf('/'));
            
            let coverHref: string = EpubParser.findCoverHref(result);
            if (coverHref.length > 0) {
              let coverKey: string = coverHref;
              if (rootfileDir.length > 0) {
                coverKey = rootfileDir + '/' + coverHref;
              }
              const coverData: Uint8Array | undefined = files.get(coverKey);
              if (coverData && coverData.length > 0) {
                const appDir: string = getAppFilesDir();
                const ext: string = coverHref.substring(coverHref.lastIndexOf('.'));
                const destPath: string = appDir + '/epub_cover_' + Date.now() + ext;
                
                const destFile = fs.openSync(destPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
                fs.writeSync(destFile.fd, coverData.buffer);
                fs.closeSync(destFile);
                return destPath;
              }
            }
          }
        }
      }
    } catch (err) {
      console.warn('EPUB 封面提取失败: ' + JSON.stringify(err));
    }
    return '';
  }

  static findCoverHref(result: ParseResult): string {
    for (let i = 0; i < result.manifest.length; i++) {
      const item: ManifestItem = result.manifest[i];
      if (item.href.toLowerCase().includes('cover') && item.mediaType.startsWith('image/')) {
        return item.href;
      }
    }
    for (let i = 0; i < result.manifest.length; i++) {
      const item: ManifestItem = result.manifest[i];
      if (item.id.toLowerCase().includes('cover') && item.mediaType.startsWith('image/')) {
        return item.href;
      }
    }
    for (let i = 0; i < result.manifest.length; i++) {
      if (result.manifest[i].mediaType.startsWith('image/')) {
        return result.manifest[i].href;
      }
    }
    return '';
  }

  static resolveRelativePath(basePath: string, relativePath: string): string {
    const baseParts = basePath.split('/');
    baseParts.pop(); // 移除文件名，保留目录
    const relParts = relativePath.split('/');
    for (const part of relParts) {
      if (part === '.' || part === '') {
        continue;
      } else if (part === '..') {
        baseParts.pop();
      } else {
        baseParts.push(part);
      }
    }
    return baseParts.join('/');
  }

  static ensureDirExists(dirPath: string): void {
    if (fs.accessSync(dirPath)) {
      return;
    }
    const lastSlash = dirPath.lastIndexOf('/');
    if (lastSlash > 0) {
      const parentDir = dirPath.substring(0, lastSlash);
      EpubParser.ensureDirExists(parentDir);
    }
    try {
      fs.mkdirSync(dirPath);
    } catch (e) {
      // 忽略
    }
  }

  static processImagesInXhtml(xhtmlContent: string, xhtmlKey: string, resourcesDir: string): string {
    let content = xhtmlContent;
    
    // 替换 <img> 标签
    const imgRegex = /<img[^>]+src\s*=\s*["']([^"']+)["'][^>]*>/gi;
    content = content.replace(imgRegex, (match: string, src: string): string => {
      if (src.startsWith('http://') || src.startsWith('https://') || src.startsWith('data:')) {
        return `\n[img:${src}]\n`;
      }
      const resolvedKey = EpubParser.resolveRelativePath(xhtmlKey, src);
      const localPath = resourcesDir + '/' + resolvedKey;
      return `\n[img:${localPath}]\n`;
    });
    
    // 替换 SVG <image> 标签
    const svgImgRegex = /<image[^>]+(?:href|xlink:href)\s*=\s*["']([^"']+)["'][^>]*>/gi;
    content = content.replace(svgImgRegex, (match: string, href: string): string => {
      if (href.startsWith('http://') || href.startsWith('https://') || href.startsWith('data:')) {
        return `\n[img:${href}]\n`;
      }
      const resolvedKey = EpubParser.resolveRelativePath(xhtmlKey, href);
      const localPath = resourcesDir + '/' + resolvedKey;
      return `\n[img:${localPath}]\n`;
    });
    
    return content;
  }
}

// 延迟获取应用目录
function getAppFilesDir(): string {
  try {
    const ctx = getContext();
    return ctx.filesDir;
  } catch (e) {
    return '';
  }
}
