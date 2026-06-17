import { router } from '@kit.ArkUI';
import bookSourceDao from '../../../database/dao/BookSourceDao';
import { BookSource } from '../../../database/entities/BookSource';
import requestUtils from '../../../common/utils/requestUtils';
import { RuleAnalyzer, RuleAnalyzerData } from '../../../common/model/analyzeRule/RuleAnalyzer';
import { ParseURLUtils, ParseURL, IParseURL } from '../../../common/utils/ParseURLUtils';

@Entry
@Component
struct WebViewSearch {
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @State logs: string[] = []
  @State testing: boolean = false
  @State testKeyword: string = '都市'

  addLog(msg: string) {
    this.logs.push(msg)
    console.log('[DebugSearch] ' + msg)
  }

  async testSearch() {
    this.testing = true
    this.logs = []

    // 1. 获取所有启用的书源
    const sources = await bookSourceDao.getEnabledPartByGroup()
    this.addLog('启用书源数量: ' + sources.length)

    if (sources.length === 0) {
      this.addLog('没有启用的书源!')
      this.testing = false
      return
    }

    // 2. 测试第一个书源
    const source = sources[0]
    this.addLog('测试书源: ' + source.bookSourceName)
    this.addLog('书源URL: ' + source.bookSourceUrl)
    this.addLog('搜索URL: ' + (source.searchUrl || '(空)'))

    if (!source.searchUrl) {
      this.addLog('[错误] 搜索URL为空!')
      this.testing = false
      return
    }

    // 3. 构造搜索URL
    try {
      const parseURLUtil = new ParseURLUtils()
      const parseURLData: IParseURL = {
        page: 1,
        keyword: this.testKeyword,
        baseUrl: source.bookSourceUrl,
        searchUrl: source.searchUrl,
        bookSource: source
      }
      parseURLUtil.setParseURL(new ParseURL(parseURLData))
      const parse = parseURLUtil.processRuleUrl()
      this.addLog('URL类型: ' + (typeof parse))

      let url = ''
      let body = ''

      if (typeof parse !== 'string') {
        url = parse.url
        this.addLog('POST URL: ' + url)
        try {
          body = await requestUtils.requestHtml(parse)
        } catch (e) {
          this.addLog('[错误] POST请求失败: ' + (e as Error).message)
          this.testing = false
          return
        }
      } else {
        url = parse
        this.addLog('GET URL: ' + url)
        try {
          body = await requestUtils.requestUrlHtml(parse, source.charset)
        } catch (e) {
          this.addLog('[错误] GET请求失败: ' + (e as Error).message)
          this.testing = false
          return
        }
      }

      this.addLog('响应长度: ' + body.length)
      if (body.length > 0) {
        this.addLog('响应前300字: ' + body.substring(0, 300))
      } else {
        this.addLog('[错误] 响应为空!')
        this.testing = false
        return
      }

      // 4. 尝试解析
      if (source.ruleSearch) {
        this.addLog('开始解析...')
        this.addLog('bookList规则: ' + (source.ruleSearch.bookList || '(空)'))

        const analyzer = new RuleAnalyzer()
        analyzer.init(new RuleAnalyzerData({
          body: body,
          bookSource: source
        }))

        const elements = analyzer.getElements(source.ruleSearch.bookList || '')
        this.addLog('匹配到元素数: ' + elements.length)

        if (elements.length > 0) {
          this.addLog('第一个元素前200字: ' + elements[0].substring(0, 200))

          // 提取第一本书的信息
          const name = analyzer.extractText(elements[0], source.ruleSearch.name)
          const author = analyzer.extractText(elements[0], source.ruleSearch.author)
          const bookUrl = analyzer.extractText(elements[0], source.ruleSearch.bookUrl)
          this.addLog('书名: ' + name)
          this.addLog('作者: ' + author)
          this.addLog('URL: ' + bookUrl)
        }
      } else {
        this.addLog('[错误] ruleSearch为空!')
      }
    } catch (e) {
      this.addLog('[异常] ' + (e as Error).message)
    }

    this.testing = false
  }

  async testExplore() {
    this.testing = true
    this.logs = []

    const sources = await bookSourceDao.getEnabledPartByGroup()
    this.addLog('启用书源数量: ' + sources.length)

    // 找到猎文网
    let source: BookSource | null = null
    for (const s of sources) {
      if (s.bookSourceName === '猎文网') {
        source = s
        break
      }
    }

    if (!source) {
      this.addLog('未找到猎文网书源!')
      this.testing = false
      return
    }

    this.addLog('测试书源: ' + source.bookSourceName)
    this.addLog('书源URL: ' + source.bookSourceUrl)

    // 测试探索页
    const testUrl = source.bookSourceUrl + '/liebiao1/'
    this.addLog('测试URL: ' + testUrl)

    try {
      const html = await requestUtils.requestUrlHtml(testUrl, source.charset)
      this.addLog('响应长度: ' + html.length)
      if (html.length > 0) {
        this.addLog('响应前500字:')
        this.addLog(html.substring(0, 500))
      } else {
        this.addLog('[错误] 响应为空!')
      }
    } catch (e) {
      this.addLog('[错误] 请求失败: ' + (e as Error).message)
    }

    this.testing = false
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.return_left'))
          .width(24).height(24)
          .onClick(() => { router.back() })
        Text('书源调试')
          .fontSize(16).padding({ left: 8 })
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: this.topRectHeight + 8, bottom: 8 })

      Row({ space: 8 }) {
        Button('测试搜索')
          .fontSize(12).height(30)
          .onClick(() => { this.testSearch() })
        Button('测试发现')
          .fontSize(12).height(30)
          .onClick(() => { this.testExplore() })
        Button('清空日志')
          .fontSize(12).height(30)
          .onClick(() => { this.logs = [] })
      }
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.testing) {
        Row() {
          LoadingProgress().width(24).height(24)
          Text('测试中...').fontSize(14).padding({ left: 8 })
        }
        .padding({ left: 16, bottom: 8 })
      }

      // 日志显示
      List() {
        ForEach(this.logs, (log: string, index: number) => {
          ListItem() {
            Text(log)
              .fontSize(11)
              .fontFamily('monospace')
              .fontColor(log.startsWith('[错误]') ? '#FF0000' : log.startsWith('[异常]') ? '#FF6600' : '#333333')
              .padding({ left: 16, right: 16, top: 2, bottom: 2 })
          }
        })
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: this.bottomRectHeight })
  }
}
