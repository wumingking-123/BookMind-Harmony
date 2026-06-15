import bookMarkDao from '../../database/dao/BookMarkDao';
import { BookMark } from '../../database/entities/BookMark';

class BookMarkUtils {
  async addBookMark(bookMark: BookMark): Promise<boolean> {
    return await bookMarkDao.insert(bookMark)
  }

  async getBookMarks(bookName: string, bookAuthor: string): Promise<BookMark[]> {
    return await bookMarkDao.queryByBook(bookName, bookAuthor)
  }

  async isBookMarked(bookName: string, bookAuthor: string, chapterIndex: number): Promise<boolean> {
    let list = await bookMarkDao.queryByChapter(bookName, bookAuthor, chapterIndex)
    return list.length > 0
  }

  async deleteBookMark(time: number): Promise<boolean> {
    return await bookMarkDao.delete(time)
  }

  async deleteAllBookMarks(bookName: string, bookAuthor: string): Promise<boolean> {
    return await bookMarkDao.deleteByBook(bookName, bookAuthor)
  }
}

const bookMarkUtils = new BookMarkUtils()
export default bookMarkUtils as BookMarkUtils
