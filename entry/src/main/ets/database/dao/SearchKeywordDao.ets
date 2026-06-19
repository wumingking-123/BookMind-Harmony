import DbUtil from '../../common/utils/DbUtil';
import AppDatabaseUtil from '../AppDatabaseUtil';
import { ColumnInfo } from '../types/ColumnInfo';

export class SearchKeyword {
  word: string = ''
  usage: number = 0
  lastUseTime: number = 0
}

class SearchKeywordDao {
  TABLE_NAME: string = 'search_keywords'

  async initSearchKeywordTable() {
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

  async getAll(): Promise<SearchKeyword[]> {
    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      const sql = `SELECT * FROM ${this.TABLE_NAME} ORDER BY lastUseTime DESC`;
      return await DbUtil.querySqlForList<SearchKeyword>(sql, column);
    } catch (err) {
      console.log('SearchKeywordDao getAll error: ' + JSON.stringify(err))
      return []
    }
  }

  async insertOrUpdate(word: string) {
    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('word', word)
      const count = await DbUtil.queryForCount(predicates, column)
      if (count > 0) {
        const existing = await DbUtil.querySqlForList<SearchKeyword>(
          `SELECT * FROM ${this.TABLE_NAME} WHERE word = '${word.replace(/'/g, "''")}'`, column
        );
        const item = new SearchKeyword();
        item.word = word;
        item.usage = existing.length > 0 ? existing[0].usage + 1 : 1;
        item.lastUseTime = Date.now();
        await DbUtil.update(predicates, item, column)
      } else {
        const item = new SearchKeyword();
        item.word = word;
        item.usage = 1;
        item.lastUseTime = Date.now();
        await DbUtil.insert(this.TABLE_NAME, item, column)
      }
      return true
    } catch (err) {
      console.log('SearchKeywordDao insertOrUpdate error: ' + JSON.stringify(err))
      return false
    }
  }

  async delete(word: string) {
    try {
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('word', word)
      await DbUtil.delete(predicates)
      return true
    } catch (err) {
      console.log('SearchKeywordDao delete error: ' + JSON.stringify(err))
      return false
    }
  }

  async deleteAll() {
    try {
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      await DbUtil.delete(predicates)
      return true
    } catch (err) {
      console.log('SearchKeywordDao deleteAll error: ' + JSON.stringify(err))
      return false
    }
  }
}

const searchKeywordDao = new SearchKeywordDao()
export default searchKeywordDao as SearchKeywordDao
