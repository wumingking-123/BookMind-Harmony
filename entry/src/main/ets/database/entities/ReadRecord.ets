/**
 * @author 2008
 * @className: ReadRecord
 * 书籍阅读记录
 */
@Observed
export class ReadRecord {
  deviceId: string = 'local';
  bookName: string = '';
  bookUrl?: string = '';
  // 累计阅读时间（秒）
  readTime: number = 0;
  // 最后阅读时间戳
  lastRead: number = 0;
  // 累计阅读天数
  readDays: number = 1;
  // 阅读次数（N刷）
  readCount: number = 1;
  // 最后阅读日期 YYYYMMDD
  lastReadDate?: string = '';

  constructor(record?: ReadRecord) {
    if (record) {
      this.deviceId = record.deviceId;
      this.bookName = record.bookName;
      this.bookUrl = record.bookUrl;
      this.readTime = record.readTime;
      this.lastRead = record.lastRead;
      this.readDays = record.readDays;
      this.readCount = record.readCount;
      this.lastReadDate = record.lastReadDate;
    }
  }
}
