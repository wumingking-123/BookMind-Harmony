import DbUtil from '../../common/utils/DbUtil';
import AppDatabaseUtil from '../AppDatabaseUtil';
import { ReadRecord } from '../entities/ReadRecord';
import { ColumnInfo } from '../types/ColumnInfo';

class ReadRecordDao {
  TABLE_NAME: string = 'readRecord'

  // 创建数据表及新增缺失字段
  async initReadRecordTable() {
    try {
      const createSql = AppDatabaseUtil.getCreateSql(this.TABLE_NAME);
      if (!createSql) {
        return
      }
      await DbUtil.createTable(createSql)
      await AppDatabaseUtil.existsTable(this.TABLE_NAME)
      return
    } catch (err) {
      console.info('TagInfo', JSON.stringify(err))
    }
  }

  // 获取今日日期字符串 YYYYMMDD
  private getTodayDateString(): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}${month}${day}`;
  }

  // 根据 bookName 查询记录
  async getRecordByBookName(bookName: string): Promise<ReadRecord | null> {
    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('deviceId', 'local');
      predicates.equalTo('bookName', bookName);
      
      const records = await DbUtil.queryForList<ReadRecord>(predicates, column);
      if (records && records.length > 0) {
        return records[0];
      }
      return null;
    } catch (err) {
      console.log("TagInfo", JSON.stringify(err))
      return null;
    }
  }

  // 获取所有阅读记录
  async getAllRecords(): Promise<ReadRecord[]> {
    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      let sql = `SELECT * FROM ${this.TABLE_NAME} WHERE deviceId = 'local' ORDER BY lastRead DESC`;
      const records = await DbUtil.querySqlForList<ReadRecord>(sql, column);
      return records || [];
    } catch (err) {
      console.log("TagInfo", JSON.stringify(err))
      return [];
    }
  }

  // 更新阅读记录
  // timeSpentSeconds: 增加的秒数
  // isFinished: 是否阅读完结增加一次 N 刷
  async updateReadRecord(bookName: string, bookUrl: string, timeSpentSeconds: number, isFinished: boolean = false) {
    if (!bookName || timeSpentSeconds <= 0 && !isFinished) return;

    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('deviceId', 'local');
      predicates.equalTo('bookName', bookName);

      const count = await DbUtil.queryForCount(predicates, column);
      const todayStr = this.getTodayDateString();

      if (count > 0) {
        // 更新现有记录
        let records = await DbUtil.queryForList<ReadRecord>(predicates, column);
        if (records && records.length > 0) {
          let record = records[0];
          record.readTime += timeSpentSeconds;
          record.lastRead = Date.now();
          if (record.bookUrl !== bookUrl && bookUrl) {
            record.bookUrl = bookUrl;
          }
          // 判断是否跨天
          if (record.lastReadDate !== todayStr) {
            record.readDays += 1;
            record.lastReadDate = todayStr;
          }
          if (isFinished) {
            record.readCount += 1;
          }
          await DbUtil.update(predicates, record, column);
        }
      } else {
        // 插入新记录
        let newRecord = new ReadRecord();
        newRecord.deviceId = 'local';
        newRecord.bookName = bookName;
        newRecord.bookUrl = bookUrl;
        newRecord.readTime = timeSpentSeconds;
        newRecord.lastRead = Date.now();
        newRecord.readDays = 1;
        newRecord.readCount = isFinished ? 2 : 1; // 初次读完算1，但因为初始就是1，所以 +1
        newRecord.lastReadDate = todayStr;
        await DbUtil.insert(this.TABLE_NAME, newRecord, column);
      }
    } catch (err) {
      console.log('TagInfo, Error updating read record: ', JSON.stringify(err));
    }
  }
}

const readRecordDao = new ReadRecordDao();
export default readRecordDao as ReadRecordDao;
