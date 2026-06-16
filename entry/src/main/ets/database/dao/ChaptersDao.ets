/**
 * 章节数据访问对象
 */
import DbUtil from '../../common/utils/DbUtil';
import AppDatabaseUtil from '../AppDatabaseUtil';
import { BookChapter } from '../../common/model/BookChapter';
import { ColumnInfo } from '../types/ColumnInfo';

class ChaptersDao {
  TABLE_NAME: string = 'chapters'

  /**
   * 初始化章节表
   */
  async initChaptersTable(): Promise<void> {
    try {
      const createSql = AppDatabaseUtil.getCreateSql(this.TABLE_NAME);
      if (!createSql) {
        return
      }
      await DbUtil.createTable(createSql)
      AppDatabaseUtil.existsTable(this.TABLE_NAME)
      console.log('ChaptersDao: 章节表初始化成功');
    } catch (e) {
      console.error('ChaptersDao: 章节表初始化失败', e);
    }
  }

  /**
   * 根据bookUrl获取所有章节
   */
  async getChaptersByBookUrl(bookUrl: string): Promise<BookChapter[]> {
    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('bookUrl', bookUrl);

      const chapters = await DbUtil.queryForList<BookChapter>(predicates, column);
      // 按index排序
      chapters.sort((a, b) => a.index - b.index);
      return chapters;
    } catch (e) {
      console.error('ChaptersDao: 查询章节失败', e);
      return [];
    }
  }

  /**
   * 批量插入章节
   */
  async insertChapters(chapters: BookChapter[]): Promise<void> {
    if (chapters.length === 0) return;

    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      for (const chapter of chapters) {
        await DbUtil.insert(this.TABLE_NAME, chapter, column);
      }
      console.log(`ChaptersDao: 成功插入 ${chapters.length} 个章节`);
    } catch (e) {
      console.error('ChaptersDao: 插入章节失败', e);
    }
  }

  /**
   * 删除指定书籍的所有章节
   */
  async deleteChaptersByBookUrl(bookUrl: string): Promise<void> {
    try {
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('bookUrl', bookUrl);
      await DbUtil.delete(predicates);
      console.log(`ChaptersDao: 删除书籍 ${bookUrl} 的所有章节`);
    } catch (e) {
      console.error('ChaptersDao: 删除章节失败', e);
    }
  }

  /**
   * 根据URL获取单个章节
   */
  async getChapterByUrl(bookUrl: string, url: string): Promise<BookChapter | undefined> {
    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('bookUrl', bookUrl);
      predicates.equalTo('url', url);

      const chapters = await DbUtil.queryForList<BookChapter>(predicates, column);
      return chapters.length > 0 ? chapters[0] : undefined;
    } catch (e) {
      console.error('ChaptersDao: 查询章节失败', e);
      return undefined;
    }
  }

  /**
   * 获取章节总数
   */
  async getChapterCount(bookUrl: string): Promise<number> {
    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('bookUrl', bookUrl);
      const count = await DbUtil.queryForCount(predicates, column);
      return count;
    } catch (e) {
      console.error('ChaptersDao: 查询章节总数失败', e);
      return 0;
    }
  }

  /**
   * 更新章节信息
   */
  async updateChapter(chapter: BookChapter): Promise<void> {
    try {
      const column: ColumnInfo[] = AppDatabaseUtil.getColumn(this.TABLE_NAME);
      const predicates = DbUtil.getPredicates(this.TABLE_NAME);
      predicates.equalTo('bookUrl', chapter.bookUrl);
      predicates.equalTo('url', chapter.url);
      await DbUtil.update(predicates, chapter, column);
    } catch (e) {
      console.error('ChaptersDao: 更新章节失败', e);
    }
  }
}

const chaptersDao = new ChaptersDao();
export default chaptersDao as ChaptersDao;
