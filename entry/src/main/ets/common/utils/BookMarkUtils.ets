import bookMarkDao from '../../database/dao/BookMarkDao';
import { BookMark } from '../../database/entities/BookMark';

class BookMarkUtils {
  async addBookMark(bookMark: BookMark): Promise<boolean> {
    return await bookMarkDao.insert(bookMark)
  }

  async getBookMarks(bookName: string, bookAuthor: string): Promise<BookMark[]> {
    return await bookMarkDao.queryByBook(bookName, bookAuthor)
  }

  async isBookMarked(bookName: string, bookAuthor: string, chapterIndex: number, chapterPos: number): Promise<boolean> {
    let list = await bookMarkDao.queryByChapter(bookName, bookAuthor, chapterIndex)
    return list.some(item => item.chapterPos === chapterPos)
  }

  async deleteBookMarkByPosition(bookName: string, bookAuthor: string, chapterIndex: number, chapterPos: number): Promise<boolean> {
    return await bookMarkDao.deleteByPosition(bookName, bookAuthor, chapterIndex, chapterPos)
  }

  async deleteBookMark(time: number): Promise<boolean> {
    return await bookMarkDao.delete(time)
  }

  async deleteAllBookMarks(bookName: string, bookAuthor: string): Promise<boolean> {
    return await bookMarkDao.deleteByBook(bookName, bookAuthor)
  }

  async getAllBookMarks(): Promise<BookMark[]> {
    return await bookMarkDao.queryAll()
  }

  async getTotalBookmarkCount(): Promise<number> {
    return await bookMarkDao.countAll()
  }

  async getBookmarkCountByBook(bookName: string, bookAuthor: string): Promise<number> {
    return await bookMarkDao.countByBook(bookName, bookAuthor)
  }
}

const bookMarkUtils = new BookMarkUtils()
export default bookMarkUtils as BookMarkUtils
