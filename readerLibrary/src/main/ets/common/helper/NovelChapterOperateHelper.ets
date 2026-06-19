import { ReaderChapterItem } from '../entity/ReaderChaptersItem';

export class NovelChapterOperateHelper {
  static nextPageIndex(chapterList: ReaderChapterItem[], chapterIndex: number, pageIndex: number): number[] | null {
    if (!chapterList || chapterList.length === 0 || chapterIndex < 0 || chapterIndex >= chapterList.length) {
      return null;
    }
    let curChapter = chapterList[chapterIndex];
    if (!curChapter || !curChapter.chapterPageList || curChapter.chapterPageList.length === 0) {
      return null;
    }
    if (pageIndex >= curChapter.chapterPageList.length - 1) {
      // 当前章节最后一页 → 跳下一章首页
      if (chapterIndex >= chapterList.length - 1) {
        return null; // 全书最后
      }
      let nextChapter = chapterList[chapterIndex + 1];
      if (!nextChapter || !nextChapter.chapterPageList || nextChapter.chapterPageList.length === 0) {
        return null; // 下一章还没加载
      }
      return [chapterIndex + 1, 0];
    }
    return [chapterIndex, pageIndex + 1];
  }

  static prePageIndex(chapterList: ReaderChapterItem[], chapterIndex: number, pageIndex: number): number[] | null {
    if (!chapterList || chapterList.length === 0 || chapterIndex < 0 || chapterIndex >= chapterList.length) {
      return null;
    }
    let curChapter = chapterList[chapterIndex];
    if (!curChapter || !curChapter.chapterPageList || curChapter.chapterPageList.length === 0) {
      return null;
    }
    if (pageIndex <= 0) {
      // 当前章节第一页 → 跳上一章尾页
      if (chapterIndex <= 0) {
        return null; // 全书开头
      }
      let preChapter = chapterList[chapterIndex - 1];
      if (!preChapter || !preChapter.chapterPageList || preChapter.chapterPageList.length === 0) {
        return null; // 上一章还没加载
      }
      return [chapterIndex - 1, preChapter.chapterPageList.length - 1];
    }
    return [chapterIndex, pageIndex - 1];
  }
}