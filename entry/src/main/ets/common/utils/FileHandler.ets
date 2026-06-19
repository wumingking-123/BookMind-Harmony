import { BusinessError } from '@ohos.base';
import fs, { Options } from '@ohos.file.fs';
import { common, Context } from '@kit.AbilityKit';
import { chaptersItem } from 'ets/componets/dataList/ReaderChaptersItem';
import { showMessage } from '../../componets/common/promptShow';
import { picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { buffer } from '@kit.ArkTS'
import { Books } from '../../database/entities/Books';
import booksUtil from './booksUtils';
import { EpubParser } from './EpubParser';

// 延迟获取沙箱路径，避免模块顶层 getContext 不可用
function getAppFilesDir(): string {
  try {
    const ctx = getContext() as common.UIAbilityContext;
    return ctx.filesDir;
  } catch (e) {
    console.error('获取 filesDir 失败: ' + JSON.stringify(e));
    return '';
  }
}

let options: Options = {
  encoding: 'utf-8'
};

export interface FileClassification {
  typeName: string
  bookType: number
}

export class FileHandler {
  // 核心分类引擎
  static classifyFile(fileName: string, currentTabIndex: number): FileClassification {
    const ext = fileName.substring(fileName.lastIndexOf('.')).toLowerCase();
    
    // 有声书格式 (MP3, WAV, FLAC, M4A, M4B, OGG, OPUS) — 归入小说
    const audioExts = ['.m4b', '.mp3', '.wav', '.flac', '.m4a', '.ogg', '.opus'];
    if (audioExts.includes(ext)) {
      return { typeName: ext.substring(1).toUpperCase(), bookType: 0 } as FileClassification;
    }
    
    // 漫画格式 (CBZ, CBR, CB7)
    const mangaExts = ['.cbz', '.cbr', '.cb7'];
    if (mangaExts.includes(ext)) {
      return { typeName: ext.substring(1).toUpperCase(), bookType: 1 } as FileClassification;
    }
    
    // 小说格式 (TXT, EPUB, PDF, MOBI, AZW, AZW3, CHM)
    const novelExts = ['.txt', '.epub', '.pdf', '.mobi', '.azw', '.azw3', '.chm'];
    
    // PDF / EPUB 的特殊双重性质处理 (如果是从漫画页面导入，则归为漫画)
    if (ext === '.pdf') {
      if (currentTabIndex === 1) {
        return { typeName: 'PDF', bookType: 1 } as FileClassification;
      }
      return { typeName: 'PDF', bookType: 0 } as FileClassification;
    }
    
    if (ext === '.epub') {
      if (currentTabIndex === 1) {
        return { typeName: 'EPUB', bookType: 1 } as FileClassification;
      }
      return { typeName: 'EPUB', bookType: 0 } as FileClassification;
    }
    
    if (novelExts.includes(ext)) {
      return { typeName: ext.substring(1).toUpperCase(), bookType: 0 } as FileClassification;
    }

    // 默认回退为小说
    return { typeName: ext.substring(1).toUpperCase() || 'TXT', bookType: 0 } as FileClassification;
  }

  static async CopyFile(srcUrl: string, currentIndex: number) {
    try {
      const filesDir: string = getAppFilesDir();
      if (filesDir.length === 0) {
        showMessage('应用存储不可用');
        return;
      }

      // picker 返回的 URI 只允许 READ 访问
      let file = fs.openSync(srcUrl, fs.OpenMode.READ_ONLY);
      let fileName: string = file.name || 'unknown.txt';
      let dstPath = filesDir + '/' + fileName;
      
      // 处理同名文件冲突 — 添加时间戳后缀
      if (fs.accessSync(dstPath)) {
        const dotIndex: number = fileName.lastIndexOf('.');
        const baseName: string = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
        const ext: string = dotIndex > 0 ? fileName.substring(dotIndex) : '';
        const timestamp: number = Date.now();
        dstPath = filesDir + '/' + baseName + '_' + timestamp + ext;
      }
      
      const classification: FileClassification = FileHandler.classifyFile(fileName, currentIndex);
      
      // 先复制文件到沙箱，确保文件就位后再入库
      try {
        await fs.copyFile(file.fd, dstPath, 0);
        console.info("copy file success");
      } catch (err) {
        showMessage('导入失败');
        console.error("copy file failed with error message: " + (err as BusinessError).message);
        fs.closeSync(file);
        return;
      }
      fs.closeSync(file);
      
      let coverUrl: string = '';
      
      // 如果是 EPUB 文件，尝试提取封面图片
      if (classification.typeName === 'EPUB') {
        try {
          const epubCover: string = await EpubParser.extractCover(dstPath, filesDir);
          if (epubCover.length > 0) {
            coverUrl = epubCover;
          }
        } catch (e) {
          console.warn('EPUB 封面提取失败，使用默认封面');
        }
      }
      
      let book = new Books();
      book.bookName = fileName.replace(/\.[^.]+$/, '');
      book.bookUrl = dstPath;
      book.author = '本地导入';
      book.bookGroup = 4;
      book.latestChapterTime = 0;
      book.totalChapterNum = 0;
      book.durChapterIndex = 0;
      book.durChapterPos = 0;
      book.durChapterTime = 0;
      book.canUpdate = false;
      book.sort = 0;
      book.originOrder = 0;
      book.bookType = classification.bookType;
      book.isTop = false;
      book.isJoin = true;
      book.isLocalBook = true;
      if (coverUrl.length > 0) {
        book.coverUrl = coverUrl;
      }
      
      await booksUtil.addBooks(book);
      showMessage('导入书架成功');
    } catch (e) {
      console.error("CopyFile error: " + JSON.stringify(e));
      showMessage('打开文件失败');
    }
  }

  static async importLocalFile(srcUrl: string, currentTabIndex: number): Promise<boolean> {
    try {
      const filesDir: string = getAppFilesDir();
      if (filesDir.length === 0) {
        showMessage('应用存储不可用');
        return false;
      }

      // picker 返回的 URI 只允许 READ 访问
      let file = fs.openSync(srcUrl, fs.OpenMode.READ_ONLY);
      let fileName: string = file.name || 'unknown.txt';
      let dstPath = filesDir + '/' + fileName;
      
      // 检查书架中是否已存在同名同路径的书籍
      let exist = await booksUtil.isExistBooks(dstPath, fileName);
      if (exist) {
        console.info(`书籍 ${fileName} 已存在`);
        fs.closeSync(file);
        return false;
      }
      
      const classification: FileClassification = FileHandler.classifyFile(fileName, currentTabIndex);
      
      // 先复制文件到沙箱，确保文件就位后再入库
      try {
        await fs.copyFile(file.fd, dstPath, 0);
        console.info("importLocalFile copy success");
      } catch (err) {
        showMessage('导入失败');
        console.error("importLocalFile copy failed: " + (err as BusinessError).message);
        fs.closeSync(file);
        return false;
      }
      fs.closeSync(file);
      
      let coverUrl: string = '';
      
      // 如果是 EPUB 文件，尝试提取封面图片
      if (classification.typeName === 'EPUB') {
        try {
          const epubCover: string = await EpubParser.extractCover(dstPath, filesDir);
          if (epubCover.length > 0) {
            coverUrl = epubCover;
          }
        } catch (e) {
          console.warn('EPUB 封面提取失败，使用默认封面');
        }
      }
      
      let book = new Books();
      book.bookName = fileName.replace(/\.[^.]+$/, '');
      book.bookUrl = dstPath;
      book.author = '本地导入';
      book.bookGroup = 4;
      book.latestChapterTime = 0;
      book.totalChapterNum = 0;
      book.durChapterIndex = 0;
      book.durChapterPos = 0;
      book.durChapterTime = 0;
      book.canUpdate = false;
      book.sort = 0;
      book.originOrder = 0;
      book.bookType = classification.bookType;
      book.isTop = false;
      book.isJoin = true;
      book.isLocalBook = true;
      if (coverUrl.length > 0) {
        book.coverUrl = coverUrl;
      }
      
      await booksUtil.addBooks(book);
      return true;
    } catch (err) {
      console.error("import file failed: " + (err as BusinessError).message);
      return false;
    }
  }

  //动态获取文件大小
  static async ReadJSONFile(srcUrl: string) {
    try {
      let file = fs.openSync(srcUrl, fs.OpenMode.READ_ONLY);
      let stat = fs.statSync(file.path)
      let arrayBuffer = new ArrayBuffer(stat.size);
      let readLen: number = fs.readSync(file.fd, arrayBuffer)
      fs.closeSync(file)
      let JSONString = buffer.from(arrayBuffer, 0, readLen).toString();
      return JSONString
    } catch (e){
      console.error(`读取失败：${e}`);
      return ''
    }
  }

  static async readFile(readFileUrl: string): Promise<chaptersItem[]> {
    let chapterNumber = 0;
    const chapters: chaptersItem[] = [];
    console.info('readFileUrl:' + readFileUrl);
    if (!readFileUrl) {
      return chapters;
    }

    const ext = readFileUrl.substring(readFileUrl.lastIndexOf('.')).toLowerCase();
    
    // 1. 快速判定并跳过非纯文本文件的行解析，直接秒级返回默认空章节（防止解析二进制乱码导致巨量耗时卡死）
    const audioExts = ['.m4b', '.mp3', '.wav', '.flac', '.m4a', '.ogg', '.opus'];
    if (audioExts.includes(ext)) {
      chapters.push(new chaptersItem(1, '音频文件', '1', '当前不支持该音频格式的文本提取。'));
      return chapters;
    }
    
    const mangaExts = ['.cbz', '.cbr', '.cb7'];
    if (mangaExts.includes(ext)) {
      chapters.push(new chaptersItem(1, '漫画分卷', '1', '漫画画册已载入。'));
      return chapters;
    }
    
    if (ext === '.pdf') {
      chapters.push(new chaptersItem(1, 'PDF 电子书目录', '1', '本地 PDF 文件暂不支持提取文本，请查阅固定排版视图。'));
      return chapters;
    }
    
    if (ext === '.epub') {
      try {
        return await EpubParser.parse(readFileUrl, getAppFilesDir());
      } catch (err) {
        console.error('EPUB 解析失败: ' + JSON.stringify(err));
        chapters.push(new chaptersItem(1, 'EPUB 解析失败', '1', '文件可能已损坏或格式不受支持。'));
        return chapters;
      }
    }
    
    if (['.mobi', '.azw', '.azw3', '.chm'].includes(ext)) {
      chapters.push(new chaptersItem(1, '专有格式电子书目录', '1', '书籍已载入。'));
      return chapters;
    }

    // 2. 对于 TXT 纯文本，做高效率的行缓存合并优化 (解决 += 大字符串频繁分配引起的内存垃圾回收和极度卡顿)
    // 支持中文章节 (第X章/第X回/序章/楔子/番外) 和英文章节 (Chapter X/CHAPTER X)
    const regex =
      /^[=|<]{0,4}((?:序章|楔子|番外|第\s{0,4})([\d〇零一二两三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟]+?\s{0,4})(?:章|回(?!合)|话(?!说)|节(?!课)|卷|篇(?!张)))(.{0,30})/;
    const regexEn = /^[=|<]{0,4}(chapter\s+(\d+)[\s:.\-]*(.*))/i;
    
    let currentChapterLines: string[] = [];
    
    try {
      await fs.readLines(readFileUrl, options).then((readerIterator: fs.ReaderIterator) => {
        for (let it = readerIterator.next(); !it.done; it = readerIterator.next()) {
          let match = regex.exec(it.value);
          if (!match) {
            match = regexEn.exec(it.value);
          }
          if (match) {
            // 在进入下一章时，把前一章累积的所有行使用 join('\n') 一次性合并
            if (chapters.length > 0) {
              chapters[chapters.length - 1].content = currentChapterLines.join('\n');
              currentChapterLines = [];
            }
            let chapterTitleNumber: string;
            let chapterTitle: string;
            if (match.length >= 4 && match[2] && /^\d+$/.test(match[2])) {
              // 英文章节: match[1]=full, match[2]=number, match[3]=title
              chapterTitleNumber = 'Chapter ' + match[2];
              chapterTitle = match[3]?.trim() || chapterTitleNumber;
            } else {
              // 中文章节: match[1]=标题号, match[3]=标题名
              chapterTitleNumber = match[1];
              chapterTitle = match[3] || match[1];
            }
            chapterNumber++;
            chapters.push(new chaptersItem(chapterNumber, chapterTitle, chapterTitleNumber, ''));
          } else {
            currentChapterLines.push(it.value);
          }
        }
      });
      
      // 合并写入最后一章
      if (chapters.length > 0) {
        chapters[chapters.length - 1].content = currentChapterLines.join('\n');
      } else {
        // 如果整本书没有检测到任何符合第几章的段落标题，直接视整本书为第一章，装载全部内容
        const allContent = currentChapterLines.join('\n');
        chapters.push(new chaptersItem(1, '开始阅读', '1', allContent));
      }
    } catch (err) {
      console.error("readLines failed with error message: " + err.message + ", error code: " + err.code);
    }

    // 过滤掉超短的无用空行数据项
    for (let i = 0; i < chapters.length; i++) {
      if (chapters[i].content.length < 5 && chapters.length > 1) {
        chapters.splice(i, 1);
        i--;
      }
    }
    return chapters;
  }

  static async documentPickerFile(maxSelectNumber: number, fileSuffixFilters: Array<string>) {
    // 尝试写一个通用的picker
    try {
      const ctx = getContext() as common.UIAbilityContext;
      const documentSelectOptions = new picker.DocumentSelectOptions();
      // 选择文档的最大数目（可选）
      documentSelectOptions.maxSelectNumber = maxSelectNumber;
      // 选择文件的后缀类型，若选择项存在多个后缀名，则每一个后缀名之间用英文逗号进行分隔（可选），后缀类型名不能超过100
      documentSelectOptions.fileSuffixFilters = fileSuffixFilters;
      let documentViewPicker = new picker.DocumentViewPicker(ctx);
      const documentSelectResult: Array<string> = await documentViewPicker.select(documentSelectOptions)
      return documentSelectResult
    } catch (err) {
      console.error(`读取失败：${err}`);
      return Promise.reject(err)
    }
  }

  static async pickerFile(context: Context) {
    try {
      const documentSelectOptions = new picker.DocumentSelectOptions();
      // 选择文档的最大数目（可选）
      documentSelectOptions.maxSelectNumber = 1;
      // 选择文件的后缀类型，若选择项存在多个后缀名，则每一个后缀名之间用英文逗号进行分隔（可选），后缀类型名不能超过100
      documentSelectOptions.fileSuffixFilters = ['.json'];
      let documentViewPicker = new picker.DocumentViewPicker(context);
      const documentSelectResult: Array<string> = await documentViewPicker.select(documentSelectOptions)
      const pathUrl = documentSelectResult[0];
      console.info('文件目录：' + pathUrl);
      let file = fs.openSync(pathUrl, fs.OpenMode.READ_WRITE);
      let buf = new ArrayBuffer(40960000);
      fs.readSync(file.fd, buf);
      fs.closeSync(file);
      let uint8View = new Uint8Array(buf);
      // 设置编码格式为"utf-8"
      let textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      // 解码输后获取对应文本
      let readString = textDecoder.decodeWithStream(uint8View, { stream: false });
      console.log('读取的数据内容：' + readString);
      return JSON.parse(readString)
    } catch (err) {
      console.error(`读取失败：${err}`);
      return Promise.reject(err)
    }
  }

  static async readJsonFile<T>(pathUrl: string): Promise<T | undefined> {
    console.info('TagInfo', '文件路径：' + pathUrl);
    try {
      const readString = await fs.readText(pathUrl);
      console.info('TagInfo', '读取的数据内容：' + readString);
      const data: T = JSON.parse(readString)
      return data
    } catch (err) {
      console.error('TagInfo', `未读取到：${err}`);
      return undefined
    }
  }

  static writeJsonFile(pathUrl: string, context: ArrayBuffer | string) {
    console.info('TagInfo', '文件地址：' + pathUrl);
    try {
      // 创建文件，并且写入内容，若是存在则重写内容
      let res = fs.accessSync(pathUrl);
      let file: fs.File
      if (res) {
        file = fs.openSync(pathUrl, fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      } else {
        file = fs.openSync(pathUrl, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      }
      fs.writeSync(file.fd, context)
      fs.close(file);
      return '写入成功'
    } catch (e) {
      console.error('TagInfo', '写入失败' + JSON.stringify(e))
      return '写入失败' + JSON.stringify(e)
    }
  }

  static deleteJsonFile(pathUrl: string) {
    try {
      fs.unlinkSync(pathUrl);
      return '删除成功'
    } catch (e) {
      console.error('TagError', '删除失败' + JSON.stringify(e))
      return '删除失败'
    }
  }
}