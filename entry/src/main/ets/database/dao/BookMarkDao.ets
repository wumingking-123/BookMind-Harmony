import DbUtil from '../../common/utils/DbUtil';
import AppDatabaseUtil from '../AppDatabaseUtil';
import { BookMark } from '../entities/BookMark';
import { ColumnInfo } from '../types/ColumnInfo';

class BookMarkDao {
  TABLE_NAME: string = 'bookmarks'

  async initBookMarkTable() {
    try {
      const createSql = AppDatabaseUtil.getCreateSql(this.TABLE_NAME);
      if (!createSql) {
        return
      }
      await DbUtil.createTable(createSql)
      AppDatabaseUtil.existsTable(this.TABLE_NAME)
      return
    } catch (err) {
      console.info('TagInfo', JSON.stringify(err))
    }
  }

  async insert(bookMark: BookMark): Promise<boolean> {
    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      bookMark.time = Date.now()
      await DbUtil.insert(this.TABLE_NAME, bookMark, column)
      console.log('TagInfo', '书签添加成功')
      return true
    } catch (err) {
      console.log('TagInfo, Error, ', JSON.stringify(err))
      return false
    }
  }

  async queryByBook(bookName: string, bookAuthor: string): Promise<BookMark[]> {
    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('bookName', bookName)
      predicates.equalTo('bookAuthor', bookAuthor)
      const list = await DbUtil.queryForList<BookMark>(predicates, column)
      return list.sort((a, b) => b.time - a.time)
    } catch (err) {
      console.log('TagInfo, Error, ', JSON.stringify(err))
      return []
    }
  }

  async queryByChapter(bookName: string, bookAuthor: string, chapterIndex: number): Promise<BookMark[]> {
    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('bookName', bookName)
      predicates.equalTo('bookAuthor', bookAuthor)
      predicates.equalTo('chapterIndex', chapterIndex)
      return await DbUtil.queryForList<BookMark>(predicates, column)
    } catch (err) {
      console.log('TagInfo, Error, ', JSON.stringify(err))
      return []
    }
  }

  async delete(time: number): Promise<boolean> {
    try {
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('time', time)
      await DbUtil.delete(predicates)
      return true
    } catch (err) {
      console.log('TagInfo, Error, ', JSON.stringify(err))
      return false
    }
  }

  async deleteByBook(bookName: string, bookAuthor: string): Promise<boolean> {
    try {
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('bookName', bookName)
      predicates.equalTo('bookAuthor', bookAuthor)
      await DbUtil.delete(predicates)
      return true
    } catch (err) {
      console.log('TagInfo, Error, ', JSON.stringify(err))
      return false
    }
  }
}

const bookMarkDao = new BookMarkDao()
export default bookMarkDao as BookMarkDao
