/**
 * 漫画解析器
 * 支持 CBZ (Comic Book ZIP) 格式：解压 ZIP → 扫描图片 → 生成章节
 * CBR/CB7/PDF 格式无原生解压支持，由 FileHandler 返回明确提示
 */
import fs from '@ohos.file.fs';
import zlib from '@ohos.zlib';
import { chaptersItem } from '../../componets/dataList/ReaderChaptersItem';

const IMAGE_EXTS: string[] = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.avif']

export class ComicParser {

  /**
   * 解析 CBZ 文件，返回章节数组（每张图片一个章节）
   */
  static async parse(cbzPath: string, filesDir?: string): Promise<chaptersItem[]> {
    const chapters: chaptersItem[] = new Array()

    try {
      if (!fs.accessSync(cbzPath)) {
        chapters.push(new chaptersItem(1, '文件不存在', '1', 'CBZ 文件路径无效: ' + cbzPath))
        return chapters
      }

      const stat: fs.Stat = fs.statSync(cbzPath)
      if (stat.size === 0) {
        chapters.push(new chaptersItem(1, '文件为空', '1', 'CBZ 文件大小为 0。'))
        return chapters
      }

      const appDir: string = filesDir && filesDir.length > 0 ? filesDir : ComicParser.getAppFilesDir()
      const bookKey: string = cbzPath.substring(cbzPath.lastIndexOf('/') + 1).replace(/\.[^.]+$/, '')
      const extractDir: string = appDir + '/comic_tmp/' + bookKey
      const resourcesDir: string = appDir + '/comic_resources/' + bookKey

      // 清理旧的临时目录
      try { fs.rmdirSync(extractDir); } catch (e) {}
      try { fs.rmdirSync(resourcesDir); } catch (e) {}
      ComicParser.ensureDirExists(extractDir)
      ComicParser.ensureDirExists(resourcesDir)

      // 解压 CBZ (ZIP 格式)
      let extractedOk: boolean = false
      try {
        await zlib.decompressFile(cbzPath, extractDir)
        extractedOk = true
      } catch (zlibErr) {
        console.warn('CBZ zlib 解压失败: ' + JSON.stringify(zlibErr))
      }

      if (!extractedOk) {
        chapters.push(new chaptersItem(1, '解压失败', '1', 'CBZ 文件可能已损坏或压缩格式不受支持。'))
        try { fs.rmdirSync(extractDir); } catch (e) {}
        return chapters
      }

      // 递归扫描所有图片文件
      const imageFiles: string[] = new Array()
      ComicParser.scanImages(extractDir, '', imageFiles)

      if (imageFiles.length === 0) {
        chapters.push(new chaptersItem(1, '无图片', '1', 'CBZ 文件中未找到任何图片。'))
        try { fs.rmdirSync(extractDir); } catch (e) {}
        return chapters
      }

      // 自然排序（1, 2, 10 而非 1, 10, 2）
      imageFiles.sort((a: string, b: string) => {
        return ComicParser.naturalCompare(a, b)
      })

      // 复制图片到持久化目录
      for (let i = 0; i < imageFiles.length; i++) {
        const srcPath: string = extractDir + '/' + imageFiles[i]
        const destPath: string = resourcesDir + '/' + imageFiles[i]
        const parentDir: string = destPath.substring(0, destPath.lastIndexOf('/'))
        ComicParser.ensureDirExists(parentDir)
        try {
          fs.copyFileSync(srcPath, destPath)
        } catch (copyErr) {
          console.warn('Failed to copy comic image: ' + JSON.stringify(copyErr))
        }
      }

      // 生成章节：每张图片一个章节
      for (let i = 0; i < imageFiles.length; i++) {
        const imgPath: string = 'file://' + resourcesDir + '/' + imageFiles[i]
        const chapterNum: number = i + 1
        const title: string = '第' + chapterNum + '页'
        const content: string = '\n[img:' + imgPath + ']\n'
        chapters.push(new chaptersItem(chapterNum, title, chapterNum.toString(), content))
      }

      // 清理临时解压目录
      try { fs.rmdirSync(extractDir); } catch (e) {}

    } catch (err) {
      console.error('CBZ 解析异常: ' + JSON.stringify(err))
      if (chapters.length === 0) {
        chapters.push(new chaptersItem(1, '解析失败', '1', 'CBZ 解析过程中发生错误: ' + String(err)))
      }
    }

    return chapters
  }

  /**
   * 从 CBZ 提取封面图片（第一张图片）
   */
  static async extractCover(cbzPath: string, filesDir?: string): Promise<string> {
    try {
      if (!fs.accessSync(cbzPath)) return ''

      const appDir: string = filesDir && filesDir.length > 0 ? filesDir : ComicParser.getAppFilesDir()
      const bookKey: string = cbzPath.substring(cbzPath.lastIndexOf('/') + 1).replace(/\.[^.]+$/, '')
      const extractDir: string = appDir + '/comic_cover_tmp/' + bookKey

      try { fs.rmdirSync(extractDir); } catch (e) {}
      ComicParser.ensureDirExists(extractDir)

      let extractedOk: boolean = false
      try {
        await zlib.decompressFile(cbzPath, extractDir)
        extractedOk = true
      } catch (e) {
        try { fs.rmdirSync(extractDir); } catch (e2) {}
      }

      if (!extractedOk) return ''

      // 扫描所有图片
      const imageFiles: string[] = new Array()
      ComicParser.scanImages(extractDir, '', imageFiles)

      if (imageFiles.length === 0) {
        try { fs.rmdirSync(extractDir); } catch (e) {}
        return ''
      }

      // 自然排序取第一张
      imageFiles.sort((a: string, b: string) => ComicParser.naturalCompare(a, b))

      const coverSrc: string = extractDir + '/' + imageFiles[0]
      const ext: string = imageFiles[0].substring(imageFiles[0].lastIndexOf('.'))
      const destPath: string = appDir + '/comic_cover_' + Date.now() + ext
      fs.copyFileSync(coverSrc, destPath)

      try { fs.rmdirSync(extractDir); } catch (e) {}

      return 'file://' + destPath
    } catch (err) {
      console.warn('CBZ 封面提取失败: ' + JSON.stringify(err))
      return ''
    }
  }

  /**
   * 递归扫描目录中的图片文件
   */
  private static scanImages(dir: string, relativePath: string, result: string[]): void {
    try {
      if (!fs.accessSync(dir)) return

      const stat: fs.Stat = fs.statSync(dir)
      if (!stat.isDirectory()) return

      const files: string[] = fs.listFileSync(dir)
      for (let i = 0; i < files.length; i++) {
        const fileName: string = files[i]
        const fullPath: string = dir + '/' + fileName
        const relPath: string = relativePath.length > 0 ? relativePath + '/' + fileName : fileName

        const fileStat: fs.Stat = fs.statSync(fullPath)
        if (fileStat.isDirectory()) {
          ComicParser.scanImages(fullPath, relPath, result)
        } else {
          const ext: string = fileName.substring(fileName.lastIndexOf('.')).toLowerCase()
          if (IMAGE_EXTS.includes(ext)) {
            result.push(relPath)
          }
        }
      }
    } catch (e) {
      console.warn('scanImages error: ' + JSON.stringify(e))
    }
  }

  /**
   * 自然排序比较（数字按数值排序，非按字符排序）
   */
  private static naturalCompare(a: string, b: string): number {
    const ax: string[] = new Array()
    const bx: string[] = new Array()
    a.replace(/(\d+)|(\D+)/g, (_: string, m1: string, m2: string) => { ax.push(m1 || ''); ax.push(m2 || ''); return '' })
    b.replace(/(\d+)|(\D+)/g, (_: string, m1: string, m2: string) => { bx.push(m1 || ''); bx.push(m2 || ''); return '' })

    const len: number = Math.min(ax.length, bx.length)
    for (let i = 0; i < len; i++) {
      if (ax[i] !== bx[i]) {
        const an: number = parseInt(ax[i])
        const bn: number = parseInt(bx[i])
        if (!isNaN(an) && !isNaN(bn)) {
          return an - bn
        }
        return ax[i] < bx[i] ? -1 : 1
      }
    }
    return ax.length - bx.length
  }

  private static getAppFilesDir(): string {
    try {
      return getContext().filesDir
    } catch (e) {
      return ''
    }
  }

  private static ensureDirExists(dirPath: string): void {
    if (fs.accessSync(dirPath)) return
    const lastSlash: number = dirPath.lastIndexOf('/')
    if (lastSlash > 0) {
      const parentDir: string = dirPath.substring(0, lastSlash)
      ComicParser.ensureDirExists(parentDir)
    }
    try {
      fs.mkdirSync(dirPath)
    } catch (e) {
      // ignore
    }
  }
}
