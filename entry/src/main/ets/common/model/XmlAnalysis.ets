import { SearchRule } from '../../database/entities/rule';
import { SearchBook } from '../../database/entities/SearchBook';
import { BookSource } from '../../database/entities/BookSource';
import { ExploreQuery } from '../../database/types/BookSourceType';
import { isNetworkUrl } from '../utils/utils';
import { RuleAnalyzer, RuleAnalyzerData } from './analyzeRule/RuleAnalyzer';


export interface IXmlAnalysis {
  baseUrl: string  //搜索地址
  body: string  //请求内容
  bookSource: BookSource//书源
  variable?: string
  searchUrl: string
}

export class XmlAnalysisData {
  baseUrl: string = ''  //搜索地址
  body: string = ''//请求内容
  bookSource?: BookSource//书源
  variable?: string
  searchUrl: string = ''

  constructor(data?: IXmlAnalysis) {
    this.baseUrl = data?.baseUrl || ''
    this.body = data?.body || ''
    this.bookSource = data?.bookSource
    this.variable = data?.variable
    this.searchUrl = data?.searchUrl || ''
  }
}

export class XmlAnalysis {
  xmlDate: XmlAnalysisData = new XmlAnalysisData()
  url: string = ''
  source?: SearchRule
  searchUrl: string = ''

  init(xmlDate: XmlAnalysisData) {
    this.xmlDate = xmlDate
    this.url = xmlDate.searchUrl
    this.source = this.xmlDate.bookSource?.ruleSearch
    this.searchUrl = xmlDate.searchUrl
  }

  /**
   * 本地解析获取书籍列表（替代后端API）
   */
  async getBookList(): Promise<SearchBook[]> {
    const bookList: SearchBook[] = []
    if (!this.source || !this.xmlDate.body) return bookList

    const analyzer = new RuleAnalyzer()
    analyzer.init(new RuleAnalyzerData({
      body: this.xmlDate.body,
      bookSource: this.xmlDate.bookSource!
    }))

    // 1. 获取书籍列表元素
    const bookListRule = this.source.bookList
    if (!bookListRule) {
      console.log('书源规则缺少bookList: ' + this.xmlDate.bookSource?.bookSourceName)
      return bookList
    }

    console.log('解析规则bookList: ' + bookListRule + ', 书源: ' + this.xmlDate.bookSource?.bookSourceName)
    const bookElements = analyzer.getElements(bookListRule)
    console.log('匹配到 ' + bookElements.length + ' 个元素, 书源: ' + this.xmlDate.bookSource?.bookSourceName)
    if (bookElements.length === 0) return bookList

    // 2. 从每个书籍元素中提取信息
    for (const element of bookElements) {
      const book = new SearchBook()

      // 提取书名
      book.name = analyzer.extractText(element, this.source.name)

      // 提取作者
      book.author = analyzer.extractText(element, this.source.author)

      // 提取简介
      book.intro = analyzer.extractText(element, this.source.intro)

      // 提取分类
      book.kind = analyzer.extractText(element, this.source.kind)

      // 提取最新章节
      book.latestChapterTitle = analyzer.extractText(element, this.source.lastChapter)

      // 提取字数
      book.wordCount = analyzer.extractText(element, this.source.wordCount)

      // 提取书籍URL
      book.bookUrl = analyzer.extractAttribute(element, this.source.bookUrl)

      // 提取封面URL
      book.coverUrl = analyzer.extractAttribute(element, this.source.coverUrl)

      // 解析相对URL
      if (book.bookUrl && !isNetworkUrl(book.bookUrl)) {
        book.bookUrl = this.xmlDate.bookSource?.bookSourceUrl + book.bookUrl
      }
      if (book.bookUrl) {
        book.tocUrl = book.bookUrl
      }
      if (book.coverUrl && !isNetworkUrl(book.coverUrl)) {
        book.coverUrl = this.xmlDate.bookSource?.bookSourceUrl + book.coverUrl
      }

      // 设置书源信息
      book.bookType = this.xmlDate.bookSource?.bookSourceType ?? 0
      book.source = this.xmlDate.bookSource

      bookList.push(book)
    }

    return bookList
  }

  //解析xml
  async analysisXml(): Promise<SearchBook[]> {
    return await this.getBookList();
  }
}
