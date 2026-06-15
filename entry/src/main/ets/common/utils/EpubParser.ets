/**
 * EPUB 解析器 (ArkTS 兼容版)
 * 解压 EPUB (ZIP格式) → 解析 container.xml → content.opf → XHTML 章节
 */
import fs from '@ohos.file.fs';
import zlib from '@ohos.zlib';
import { chaptersItem } from '../../componets/dataList/ReaderChaptersItem';
import { util } from '@kit.ArkTS';

// Manifest 条目
interface ManifestItem {
  id: string
  href: string
  mediaType: string
  title: string
}

// 解析结果
interface ParseResult {
  manifest: ManifestItem[]
  spine: string[]
  title: string
}

export class EpubParser {
  /**
   * 从 EPUB 中提取封面图片路径 (如果有的话)
   * 返回提取到的封面图片保存路径，如果没有封面返回空字符串
   */
  static async extractCover(epubPath: string, destDir: string): Promise<string> {
    try {
      const extractDir: string = epubPath + '_cover_extract';
      await EpubParser.extractEpub(epubPath, extractDir);

      const rootfilePath: string = EpubParser.parseContainer(extractDir);
      if (rootfilePath.length === 0) {
        try { fs.rmdirSync(extractDir); } catch (e) {}
        return '';
      }

      const result: ParseResult = EpubParser.parseContentOpf(extractDir, rootfilePath);
      const rootfileDir: string = rootfilePath.substring(0, rootfilePath.lastIndexOf('/'));

      // 查找封面图片: 优先找 cover-image 属性，其次找 media-type 为 image/*
      let coverHref: string = '';

      // 方法1: 查找 properties 包含 cover-image 的 item
      for (let i = 0; i < result.manifest.length; i++) {
        const item: ManifestItem = result.manifest[i];
        if (item.href.includes('cover') && item.mediaType.startsWith('image/')) {
          coverHref = item.href;
          break;
        }
      }

      // 方法2: 查找任何 image/* 类型的 item
      if (coverHref.length === 0) {
        for (let i = 0; i < result.manifest.length; i++) {
          const item: ManifestItem = result.manifest[i];
          if (item.mediaType.startsWith('image/')) {
            coverHref = item.href;
            break;
          }
        }
      }

      if (coverHref.length === 0) {
        try { fs.rmdirSync(extractDir); } catch (e) {}
        return '';
      }

      // 复制封面图片到目标目录
      const srcPath: string = extractDir + '/' + rootfileDir + '/' + coverHref;
      const ext: string = coverHref.substring(coverHref.lastIndexOf('.'));
      const destPath: string = destDir + '/cover_' + Date.now() + ext;

      if (fs.accessSync(srcPath)) {
        await fs.copyFile(srcPath, destPath);
        try { fs.rmdirSync(extractDir); } catch (e) {}
        return destPath;
      }

      try { fs.rmdirSync(extractDir); } catch (e) {}
      return '';
    } catch (err) {
      console.error('EPUB 封面提取失败: ' + JSON.stringify(err));
      return '';
    }
  }

  /**
   * 解析 EPUB 文件，返回章节数组
   */
  static async parse(epubPath: string): Promise<chaptersItem[]> {
    const chapters: chaptersItem[] = [];

    try {
      // 1. 解压 EPUB 到临时目录
      const extractDir: string = epubPath + '_extracted';
      await EpubParser.extractEpub(epubPath, extractDir);

      // 2. 解析 META-INF/container.xml 获取 rootfile 路径
      const rootfilePath: string = EpubParser.parseContainer(extractDir);
      if (rootfilePath.length === 0) {
        console.error('EPUB: container.xml 中未找到 rootfile');
        chapters.push(new chaptersItem(1, 'EPUB 解析失败', '1', '无法找到书籍内容定义文件。'));
        return chapters;
      }

      // 3. 解析 content.opf 获取 manifest 和 spine
      const result: ParseResult = EpubParser.parseContentOpf(extractDir, rootfilePath);

      // 4. 按 spine 顺序读取每个 XHTML 章节
      const rootfileDir: string = rootfilePath.substring(0, rootfilePath.lastIndexOf('/'));
      let chapterNumber: number = 0;

      for (let si = 0; si < result.spine.length; si++) {
        const itemRef: string = result.spine[si];
        const item: ManifestItem | undefined = EpubParser.findManifestItem(result.manifest, itemRef);
        if (!item || item.href.length === 0) {
          continue;
        }

        const xhtmlPath: string = extractDir + '/' + rootfileDir + '/' + item.href;
        const textContent: string = EpubParser.extractTextFromXhtml(xhtmlPath);

        if (textContent.trim().length > 0) {
          chapterNumber++;
          const chapterTitle: string = item.title.length > 0 ? item.title : '第' + chapterNumber + '章';
          chapters.push(new chaptersItem(
            chapterNumber,
            chapterTitle,
            chapterNumber.toString(),
            textContent
          ));
        }
      }

      // 5. 清理临时目录
      try {
        fs.rmdirSync(extractDir);
      } catch (e) {
        // 忽略清理错误
      }

      // 如果没有解析到章节，返回占位
      if (chapters.length === 0) {
        chapters.push(new chaptersItem(1, result.title.length > 0 ? result.title : 'EPUB 电子书', '1', '未能解析到章节内容。'));
      }

    } catch (err) {
      console.error('EPUB 解析失败: ' + JSON.stringify(err));
      if (chapters.length === 0) {
        chapters.push(new chaptersItem(1, 'EPUB 解析失败', '1', '文件可能已损坏或格式不受支持。'));
      }
    }

    return chapters;
  }

  /**
   * 在 manifest 中查找指定 id 的条目
   */
  static findManifestItem(manifest: ManifestItem[], id: string): ManifestItem | undefined {
    for (let i = 0; i < manifest.length; i++) {
      if (manifest[i].id === id) {
        return manifest[i];
      }
    }
    return undefined;
  }

  /**
   * 在 manifest 中查找指定 href 的条目
   */
  static findManifestItemByHref(manifest: ManifestItem[], href: string): ManifestItem | undefined {
    for (let i = 0; i < manifest.length; i++) {
      if (manifest[i].href === href || manifest[i].href.endsWith(href)) {
        return manifest[i];
      }
    }
    return undefined;
  }

  /**
   * 解压 EPUB 文件 (ZIP格式)
   */
  static async extractEpub(srcPath: string, destDir: string): Promise<void> {
    // 创建目标目录
    try {
      fs.mkdirSync(destDir);
    } catch (e) {
      // 目录已存在
    }

    // 使用 zlib 解压
    try {
      const options: zlib.Options = {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION
      };
      await zlib.decompressFile(srcPath, destDir, options);
    } catch (err) {
      console.error('EPUB 解压失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 解析 META-INF/container.xml 获取 rootfile 路径
   */
  static parseContainer(extractDir: string): string {
    try {
      const containerPath: string = extractDir + '/META-INF/container.xml';
      const content: string = EpubParser.readFileAsText(containerPath);

      // 查找 rootfile full-path
      const match: RegExpMatchArray | null = content.match(/full-path\s*=\s*"([^"]+)"/);
      if (match !== null && match.length > 1) {
        return match[1];
      }

      return '';
    } catch (err) {
      console.error('解析 container.xml 失败: ' + JSON.stringify(err));
      return '';
    }
  }

  /**
   * 解析 content.opf 获取 manifest 和 spine
   */
  static parseContentOpf(extractDir: string, rootfilePath: string): ParseResult {
    const result: ParseResult = {
      manifest: [],
      spine: [],
      title: ''
    };

    try {
      const opfPath: string = extractDir + '/' + rootfilePath;
      const content: string = EpubParser.readFileAsText(opfPath);

      // 解析书名
      const titleMatch: RegExpMatchArray | null = content.match(/<dc:title[^>]*>([^<]+)<\/dc:title>/);
      if (titleMatch !== null && titleMatch.length > 1) {
        result.title = titleMatch[1].trim();
      }

      // 解析 manifest items — 使用全局正则逐个匹配
      const manifestRegex: RegExp = /<item\s+[^>]*?(?:id\s*=\s*"([^"]+)"[^>]*?href\s*=\s*"([^"]+)"[^>]*?media-type\s*=\s*"([^"]+)"|href\s*=\s*"([^"]+)"[^>]*?id\s*=\s*"([^"]+)"[^>]*?media-type\s*=\s*"([^"]+)"|id\s*=\s*"([^"]+)"[^>]*?media-type\s*=\s*"([^"]+)"[^>]*?href\s*=\s*"([^"]+)")[^>]*\/?>/g;
      let match: RegExpExecArray | null;
      while ((match = manifestRegex.exec(content)) !== null) {
        let id: string = '';
        let href: string = '';
        let mediaType: string = '';

        if (match[1] && match[2] && match[3]) {
          id = match[1];
          href = match[2];
          mediaType = match[3];
        } else if (match[4] && match[5] && match[6]) {
          href = match[4];
          id = match[5];
          mediaType = match[6];
        } else if (match[7] && match[8] && match[9]) {
          id = match[7];
          mediaType = match[8];
          href = match[9];
        }

        if (id.length > 0 && href.length > 0) {
          const item: ManifestItem = {
            id: id,
            href: href,
            mediaType: mediaType,
            title: ''
          };
          result.manifest.push(item);
        }
      }

      // 解析 spine itemrefs
      const spineRegex: RegExp = /<itemref\s+[^>]*?idref\s*=\s*"([^"]+)"[^>]*\/?>/g;
      let spineMatch: RegExpExecArray | null;
      while ((spineMatch = spineRegex.exec(content)) !== null) {
        result.spine.push(spineMatch[1]);
      }

      // 尝试从 toc.ncx 获取章节标题
      EpubParser.parseTocNcx(extractDir, rootfilePath, result.manifest);

    } catch (err) {
      console.error('解析 content.opf 失败: ' + JSON.stringify(err));
    }

    return result;
  }

  /**
   * 解析 toc.ncx 获取章节标题
   */
  static parseTocNcx(extractDir: string, rootfilePath: string, manifest: ManifestItem[]): void {
    try {
      // 查找 toc.ncx 在 manifest 中的位置
      let tocHref: string = '';
      for (let i = 0; i < manifest.length; i++) {
        if (manifest[i].mediaType === 'application/x-dtbncx+xml') {
          tocHref = manifest[i].href;
          break;
        }
      }

      if (tocHref.length === 0) {
        return;
      }

      const rootfileDir: string = rootfilePath.substring(0, rootfilePath.lastIndexOf('/'));
      const tocPath: string = extractDir + '/' + rootfileDir + '/' + tocHref;
      const content: string = EpubParser.readFileAsText(tocPath);

      // 解析 navPoint 标签获取章节标题和对应的 src
      const navPointRegex: RegExp = /<navPoint[^>]*>[\s\S]*?<text>([^<]+)<\/text>[\s\S]*?<content\s+src\s*=\s*"([^"]+)"[^>]*\/?>/g;
      let match: RegExpExecArray | null;
      while ((match = navPointRegex.exec(content)) !== null) {
        const title: string = match[1].trim();
        const src: string = match[2].split('#')[0]; // 去掉锚点

        // 找到对应的 manifest item 并设置标题
        const item: ManifestItem | undefined = EpubParser.findManifestItemByHref(manifest, src);
        if (item !== undefined) {
          item.title = title;
        }
      }
    } catch (err) {
      // toc.ncx 解析失败不影响主流程
      console.warn('解析 toc.ncx 失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 从 XHTML 文件中提取纯文本
   */
  static extractTextFromXhtml(xhtmlPath: string): string {
    try {
      const content: string = EpubParser.readFileAsText(xhtmlPath);

      // 移除 XML 声明
      let text: string = content.replace(/<\?xml[^?]*\?>/g, '');

      // 移除 DOCTYPE
      text = text.replace(/<!DOCTYPE[^>]*>/gi, '');

      // 移除 style 和 script 标签及其内容
      text = text.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '');
      text = text.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '');

      // 将 <br>, <p>, <div>, <h1>-<h6> 转换为换行
      text = text.replace(/<br\s*\/?>/gi, '\n');
      text = text.replace(/<\/p>/gi, '\n');
      text = text.replace(/<\/div>/gi, '\n');
      text = text.replace(/<\/h[1-6]>/gi, '\n');

      // 移除所有 HTML 标签
      text = text.replace(/<[^>]+>/g, '');

      // 解码 HTML 实体
      text = text.replace(/&nbsp;/g, ' ');
      text = text.replace(/&lt;/g, '<');
      text = text.replace(/&gt;/g, '>');
      text = text.replace(/&amp;/g, '&');
      text = text.replace(/&quot;/g, '"');
      text = text.replace(/&#39;/g, "'");
      text = text.replace(/&\w+;/g, '');

      // 清理多余空白
      text = text.replace(/\n\s*\n\s*\n/g, '\n\n'); // 最多保留两个换行
      text = text.replace(/[ \t]+/g, ' '); // 合并空格
      text = text.trim();

      return text;
    } catch (err) {
      console.error('提取 XHTML 文本失败: ' + xhtmlPath + ', ' + JSON.stringify(err));
      return '';
    }
  }

  /**
   * 读取文件为 UTF-8 文本
   */
  static readFileAsText(filePath: string): string {
    try {
      const file: fs.File = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const stat: fs.Stat = fs.statSync(filePath);
      const arrayBuffer: ArrayBuffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, arrayBuffer);
      fs.closeSync(file);

      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      return decoder.decodeWithStream(new Uint8Array(arrayBuffer), { stream: false });
    } catch (err) {
      console.error('读取文件失败: ' + filePath + ', ' + JSON.stringify(err));
      return '';
    }
  }
}
