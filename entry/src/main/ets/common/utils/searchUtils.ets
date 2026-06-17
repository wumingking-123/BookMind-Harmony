import { showMessage } from '../../componets/common/promptShow';
import bookSourceDao from '../../database/dao/BookSourceDao';
import { BookSource } from '../../database/entities/BookSource';
import { SearchBook } from '../../database/entities/SearchBook';
import { XmlAnalysis, XmlAnalysisData } from '../model/XmlAnalysis';
import networkUtil from './NetworkUtils';
import { IParseURL, ParseURL, ParseURLUtils } from './ParseURLUtils';
import requestUtil from './requestUtils';


class searchUtils{
  searchBooks: SearchBook[] = []
  private bookSourceParts:BookSource[] = []
  private searchKey: string = ''
  private searchPage:number = 1
  private mSearchId:number = 0

  async search(searchKey: string) {
    if (!searchKey) {
      return;
    }
    this.searchKey = searchKey;
    this.bookSourceParts = await bookSourceDao.getEnabledPartByGroup();
    if (!this.bookSourceParts || this.bookSourceParts.length === 0) {
      showMessage('启用书源为空');
      return;
    }
    this.searchBooks = [];
    for (const bookSource of this.bookSourceParts) {
      this.searchData(this.searchKey,Date.now(), bookSource);
    }
  }

  async searchData(searchKey: string,searchId:number, bookSource:BookSource) {
    this.searchKey = searchKey;
    if (searchId != this.mSearchId) {
      this.mSearchId = searchId
      this.searchPage = 1
    } else {
      this.searchPage++
    }
    try {
      let book = await this.searchBook(bookSource)
      return book
    } catch (e) {
      console.log('searchData error: ' + (e as Error).message)
      return []
    }
  }

  private extractSearchId(html: string): string {
    // 匹配 meta refresh: <meta http-equiv="refresh" content="0;url=...searchid=12345">
    let match = html.match(/searchid=(\d+)/)
    if (match) {
      return match[1]
    }
    // 匹配JS跳转: window.location="...searchid=12345"
    match = html.match(/location[^"]*"[^"]*searchid=(\d+)/)
    if (match) {
      return match[1]
    }
    return ''
  }

  async searchBook(bookSource:BookSource): Promise<SearchBook[]>{
    if (!bookSource.searchUrl || bookSource.searchUrl === undefined) {
      console.log('搜索url为空: ' + bookSource.bookSourceName)
      throw new Error('搜索url为空');
    }
    let books:SearchBook[] = []
    let urls = ''
    let body = ''

    // 解析搜索url
    const parseURLUtil = new ParseURLUtils();
    let xmlAnalysis = new XmlAnalysis();
    const parseURLData: IParseURL = {
      page: this.searchPage,
      keyword: this.searchKey,
      baseUrl: bookSource.bookSourceUrl,
      searchUrl: bookSource.searchUrl,
      bookSource:bookSource
    };
    parseURLUtil.setParseURL(new ParseURL(parseURLData));
    let parse = parseURLUtil.processRuleUrl();
    console.log('[Search] processRuleUrl类型: ' + (typeof parse) + ', 书源: ' + bookSource.bookSourceName)
    if (typeof parse !== 'string') {
      urls = parse.url
      console.log('[Search] URL(POST): ' + urls)
      console.log('[Search] POST body: ' + parse.body)
      console.log('[Search] POST charset: ' + parse.charset)
      console.log('[Search] POST headers: ' + JSON.stringify(parse.headers))
      try {
        body = await requestUtil.requestHtml(parse)
      } catch (reqErr) {
        console.log('[Search] POST请求异常: ' + (reqErr as Error).message)
        throw new Error((reqErr as Error).message)
      }
    } else {
      urls = parse
      console.log('[Search] URL(GET): ' + urls)
      try {
        let res = await requestUtil.requestUrlHtml(parse, bookSource.charset)
        body = res
      } catch (reqErr) {
        console.log('[Search] GET请求异常: ' + (reqErr as Error).message + ', URL: ' + urls)
        throw new Error((reqErr as Error).message)
      }
    }
    console.log('[Search] 响应长度: ' + body.length + ', 书源: ' + bookSource.bookSourceName)
    if (body.length > 0) {
      console.log('[Search] 完整响应内容: ' + body)
    }

    // 处理帝国CMS等两步搜索：POST返回中间页，需要提取searchid后再次请求
    // 只有当响应不是搜索结果页面时才尝试提取searchid
    if (body.length > 0 && !body.includes('article-list')) {
      let searchid = this.extractSearchId(body)
      console.log('[Search] extractSearchId结果: "' + searchid + '", 响应长度: ' + body.length)
      if (searchid && bookSource.searchResultUrl) {
        // 使用配置的 searchResultUrl 模板构造结果页URL
        let resultUrl = bookSource.searchResultUrl
          .replace('{{searchid}}', searchid)
          .replace('{{page}}', this.searchPage.toString())
        // 如果是相对路径，补全域名
        if (!resultUrl.startsWith('http')) {
          resultUrl = bookSource.bookSourceUrl.replace(/\/+$/, '') + (resultUrl.startsWith('/') ? '' : '/') + resultUrl
        }
        console.log('[Search] 检测到searchid: ' + searchid + ', 请求结果页: ' + resultUrl)
        try {
          body = await requestUtil.requestUrlHtml(resultUrl, bookSource.charset)
          console.log('[Search] 结果页响应长度: ' + body.length)
          if (body.length > 0) {
            console.log('[Search] 结果页前200字符: ' + body.substring(0, 200))
          }
          urls = resultUrl
        } catch (e) {
          console.log('[Search] 结果页请求失败: ' + (e as Error).message)
        }
      }
    }
    if (bookSource.ruleSearch) {
      xmlAnalysis.init(new XmlAnalysisData({
        baseUrl: parseURLData.baseUrl,
        body: body,
        bookSource:bookSource,
        searchUrl: urls
      }))
      let searchBooks = await xmlAnalysis.analysisXml()
      console.log('[Search] 解析到 ' + searchBooks.length + ' 本书, 书源: ' + bookSource.bookSourceName)
      books.push(...searchBooks)
    } else {
      console.log('[Search] 书源缺少ruleSearch: ' + bookSource.bookSourceName)
    }
    return books
  }

  /**
   * 调试方法：测试单个书源的搜索
   * 返回详细的调试信息
   */
  async debugSearch(bookSource: BookSource, keyword: string): Promise<string[]> {
    const logs: string[] = []

    logs.push('=== 书源调试: ' + bookSource.bookSourceName + ' ===')
    logs.push('书源URL: ' + bookSource.bookSourceUrl)
    logs.push('搜索URL: ' + (bookSource.searchUrl || '(空)'))
    logs.push('搜索关键词: ' + keyword)

    if (!bookSource.searchUrl) {
      logs.push('[错误] 搜索URL为空!')
      return logs
    }

    // 检查规则
    logs.push('ruleSearch: ' + (bookSource.ruleSearch ? '已设置' : '(空)'))
    if (bookSource.ruleSearch) {
      logs.push('  bookList: ' + (bookSource.ruleSearch.bookList || '(空)'))
      logs.push('  bookUrl: ' + (bookSource.ruleSearch.bookUrl || '(空)'))
      logs.push('  name: ' + (bookSource.ruleSearch.name || '(空)'))
    }
    logs.push('ruleToc: ' + (bookSource.ruleToc ? '已设置' : '(空)'))
    logs.push('ruleContent: ' + (bookSource.ruleContent ? '已设置' : '(空)'))

    try {
      // 构造URL
      const parseURLUtil = new ParseURLUtils();
      const parseURLData: IParseURL = {
        page: 1,
        keyword: keyword,
        baseUrl: bookSource.bookSourceUrl,
        searchUrl: bookSource.searchUrl,
        bookSource: bookSource
      };
      parseURLUtil.setParseURL(new ParseURL(parseURLData));
      let parse = parseURLUtil.processRuleUrl();
      logs.push('[解析] processRuleUrl类型: ' + (typeof parse))

      let urls = ''
      let body = ''
      if (typeof parse !== 'string') {
        urls = parse.url
        logs.push('[URL] POST: ' + urls)
        try {
          body = await requestUtil.requestHtml(parse)
        } catch (reqErr) {
          logs.push('[错误] POST请求失败: ' + (reqErr as Error).message)
          return logs
        }
      } else {
        urls = parse
        logs.push('[URL] GET: ' + urls)
        try {
          body = await requestUtil.requestUrlHtml(parse, bookSource.charset)
        } catch (reqErr) {
          logs.push('[错误] GET请求失败: ' + (reqErr as Error).message)
          logs.push('[错误] URL: ' + urls)
          return logs
        }
      }

      logs.push('[响应] 长度: ' + body.length)
      if (body.length > 0) {
        logs.push('[响应] 前300字符:')
        logs.push(body.substring(0, 300))
      } else {
        logs.push('[错误] 响应内容为空!')
        return logs
      }

      // 处理两步搜索
      if (body.length > 0) {
        let searchid = this.extractSearchId(body)
        if (searchid) {
          logs.push('[两步搜索] 检测到searchid: ' + searchid)
          if (bookSource.searchResultUrl) {
            let resultUrl = bookSource.searchResultUrl
              .replace('{{searchid}}', searchid)
              .replace('{{page}}', '1')
            if (!resultUrl.startsWith('http')) {
              resultUrl = bookSource.bookSourceUrl.replace(/\/+$/, '') + (resultUrl.startsWith('/') ? '' : '/') + resultUrl
            }
            logs.push('[两步搜索] 结果页URL: ' + resultUrl)
            try {
              body = await requestUtil.requestUrlHtml(resultUrl, bookSource.charset)
              logs.push('[两步搜索] 结果页响应长度: ' + body.length)
              if (body.length > 0) {
                logs.push('[两步搜索] 结果页前300字符:')
                logs.push(body.substring(0, 300))
              }
            } catch (e) {
              logs.push('[两步搜索] 结果页请求失败: ' + (e as Error).message)
            }
          } else {
            logs.push('[两步搜索] 未配置searchResultUrl，跳过')
          }
        }
      }

      // 解析
      if (bookSource.ruleSearch) {
        const xmlAnalysis = new XmlAnalysis()
        xmlAnalysis.init(new XmlAnalysisData({
          baseUrl: bookSource.bookSourceUrl,
          body: body,
          bookSource: bookSource,
          searchUrl: urls
        }))
        let searchBooks = await xmlAnalysis.analysisXml()
        logs.push('[解析] 找到 ' + searchBooks.length + ' 本书')

        for (let i = 0; i < Math.min(searchBooks.length, 3); i++) {
          logs.push('  书名: ' + searchBooks[i].name)
          logs.push('  作者: ' + searchBooks[i].author)
          logs.push('  URL: ' + searchBooks[i].bookUrl)
        }
      } else {
        logs.push('[错误] ruleSearch为空!')
      }
    } catch (e) {
      logs.push('[异常] ' + (e as Error).message)
    }

    return logs
  }
}

const searchUtil = new searchUtils();
export default searchUtil as searchUtils;
