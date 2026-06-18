import BookGroupsDao from './dao/BookGroupsDao'
import bookHistoryDao from './dao/BookHistoryDao'
import BooksDao from './dao/BooksDao'
import BookSourceDao from './dao/BookSourceDao'
import BookMarkDao from './dao/BookMarkDao'
import chaptersDao from './dao/ChaptersDao'
import rssSourceGroupDao from './dao/rssSourceGroupDao'
import rssSourcesHistoryDao from './dao/RssSourcesHistoryDao'
import SubscriptionDao from './dao/SubscriptionDao'
import worksListsDao from './dao/WorksListsDao'
import searchKeywordDao from './dao/SearchKeywordDao'

class DataBase {
  async initAllTable() {
    await BookSourceDao.initBookSourceTable()
    await rssSourcesHistoryDao.initRssSourcesHistoryTable()
    await SubscriptionDao.initSubscriptionTable()
    await BooksDao.initBooksTable()
    await BookGroupsDao.initGroupTable()
    await worksListsDao.initWorksListsTable()
    await bookHistoryDao.initBookHistoryTable()
    await rssSourceGroupDao.initBookSourceGroupTable()
    await BookMarkDao.initBookMarkTable()
    await chaptersDao.initChaptersTable()
    await searchKeywordDao.initSearchKeywordTable()
  }
}

const dataBase = new DataBase()

export default dataBase as DataBase