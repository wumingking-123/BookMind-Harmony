import { ReaderChapterItem } from '../entity/ReaderChaptersItem';

export class NovelChapterOperateHelper {
  static nextPageIndex(chapterList: ReaderChapterItem[], chapterIndex: number, pageIndex: number): number[] | null {
    if (!chapterList || chapterList.length === 0 || chapterIndex < 0 || chapterIndex >= chapterList.length) {
      return null;
    }
    let curChapter = chapterList[chapterIndex];
    if (!curChapter || !curChapter.chapterPageList) {
      return null;
    }
    if (chapterIndex >= chapterList.length - 1) {
      if (pageIndex >= curChapter.chapterPageList.length - 1) {
        return null;
      } else {
        return [chapterIndex, pageIndex + 1];
      }
    } else {
      if (pageIndex >= curChapter.chapterPageList.length - 1) {
        let nextChapter = chapterList[chapterIndex + 1];
        if (!nextChapter || !nextChapter.chapterPageList || nextChapter.chapterPageList.length === 0) {
          return null;
        }
        return [chapterIndex + 1, 0];
      } else {
        return [chapterIndex, pageIndex + 1];
      }
    }
  }

  static prePageIndex(chapterList: ReaderChapterItem[], chapterIndex: number, pageIndex: number): number[] | null {
    if (!chapterList || chapterList.length === 0 || chapterIndex < 0 || chapterIndex >= chapterList.length) {
      return null;
    }
    let curChapter = chapterList[chapterIndex];
    if (!curChapter || !curChapter.chapterPageList) {
      return null;
    }
    if (chapterIndex <= 0) {
      if (pageIndex <= 0) {
        return null;
      } else {
        return [chapterIndex, pageIndex - 1];
      }
    } else {
      if (pageIndex <= 0) {
        let preChapter = chapterList[chapterIndex - 1];
        if (!preChapter || !preChapter.chapterPageList || preChapter.chapterPageList.length === 0) {
          return null;
        }
        return [chapterIndex - 1, preChapter.chapterPageList.length - 1];
      } else {
        return [chapterIndex, pageIndex - 1];
      }
    }
  }
}