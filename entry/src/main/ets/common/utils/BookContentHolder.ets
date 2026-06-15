import { chaptersItem } from 'ets/componets/dataList/ReaderChaptersItem';

export class BookContentHolder {
  private static chapters: chaptersItem[] = [];

  public static setChapters(chapters: chaptersItem[]) {
    BookContentHolder.chapters = chapters;
  }

  public static getChapters(): chaptersItem[] {
    return BookContentHolder.chapters;
  }

  public static clear() {
    BookContentHolder.chapters = [];
  }
}
