import Header from '../../../../componets/common/Header';
import { router } from '@kit.ArkUI';
import { ExploreItem } from '../../../../database/types/BookSourceType';
import { ExploreRule } from '../../../../database/entities/rule';
import RefreshComponent from '../../../../componets/common/RefreshComponent';
import { isNetworkUrl } from '../../../../common/utils/utils';
import noFind from '../../../../componets/common/noFind';
import { CardItem } from '../components/CardItem';
import { ThemeItem } from '../../../../common/model/Theme';
import { ThemeStorageKey } from '../../../../common/constants/Theme';
import requestUtils from '../../../../common/utils/requestUtils';
import { RuleAnalyzer, RuleAnalyzerData } from '../../../../common/model/analyzeRule/RuleAnalyzer';
import { BookSource } from '../../../../database/entities/BookSource';

interface RouteParams {
  bookSourceUrl: string,
  exploreItem: ExploreItem,
  exploreRule: ExploreRule,
  currentIndex: number,
  charset?: string
}

@Entry
@Component
struct CateGoryListPage {
  @State bookSourceUrl: string = ''
  @State exploreItem: ExploreItem = {
    title: '',
    url: ''
  }
  @State exploreRule: ExploreRule = {}
  @State pageNum: number = 1
  @State pageSize: number = 10
  @State bookList: ExploreRule[] = []
  @State startLoading: boolean = false
  @State loading: boolean = false
  @State isRefreshing: boolean = false
  @State RefreshingTitle: string = '松开刷新'
  @State currentIndex: number = 0
  @State charset: string = ''

  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem
  async aboutToAppear() {
    this.startLoading = true
    const params = router.getParams() as RouteParams;
    this.currentIndex = params.currentIndex
    this.bookSourceUrl = params.bookSourceUrl
    this.exploreItem = params.exploreItem
    this.exploreRule = params.exploreRule
    this.charset = params.charset || ''
    await this.getList()
    this.startLoading = false
  }

  async getList() {
    let url = this.exploreItem.url.replace('{{page}}', this.pageNum.toString())
    if (!isNetworkUrl(url)) {
      url = this.bookSourceUrl + url
    }

    if (this.pageNum * this.pageSize - this.bookList.length >= this.pageSize * 2 && !this.startLoading) {
      return
    }
    this.loading = true

    try {
      // 本地请求+本地解析（不依赖后端API）
      const html = await requestUtils.requestUrlHtml(url, this.charset)
      const bookList = this.parseExploreHtml(html)

      if (this.pageNum === 1) {
        this.bookList = bookList
      } else {
        this.bookList = this.bookList.concat(bookList)
      }
      this.loading = false
    } catch (err) {
      console.log('CategoryList 请求失败：' + (err as Error).message);
      this.loading = false
    }
  }

  /**
   * 本地解析探索页面HTML
   */
  private parseExploreHtml(html: string): ExploreRule[] {
    const results: ExploreRule[] = []
    if (!this.exploreRule.bookList) return results

    const dummySource = new BookSource()
    dummySource.bookSourceUrl = this.bookSourceUrl

    const analyzer = new RuleAnalyzer()
    analyzer.init(new RuleAnalyzerData({
      body: html,
      bookSource: dummySource
    }))

    const bookElements = analyzer.getElements(this.exploreRule.bookList)
    if (bookElements.length === 0) return results

    for (const element of bookElements) {
      const item: ExploreRule = {}

      item.name = analyzer.extractText(element, this.exploreRule.name)
      item.author = analyzer.extractText(element, this.exploreRule.author)
      item.intro = analyzer.extractText(element, this.exploreRule.intro)
      item.kind = analyzer.extractText(element, this.exploreRule.kind)
      item.lastChapter = analyzer.extractText(element, this.exploreRule.lastChapter)
      item.wordCount = analyzer.extractText(element, this.exploreRule.wordCount)
      item.bookUrl = analyzer.extractText(element, this.exploreRule.bookUrl)
      item.coverUrl = analyzer.extractText(element, this.exploreRule.coverUrl)

      if (item.bookUrl && !isNetworkUrl(item.bookUrl)) {
        item.bookUrl = this.bookSourceUrl + item.bookUrl
      }
      if (item.coverUrl && !isNetworkUrl(item.coverUrl)) {
        item.coverUrl = this.bookSourceUrl + item.coverUrl
      }

      if (item.name) {
        results.push(item)
      }
    }

    return results
  }

  build() {
    Column() {
      Header({
        title: this.exploreItem.title
      })

      Column() {
        Refresh({ refreshing: $$this.isRefreshing, builder: this.refreshComponent }) {
          Scroll() {
            Column() {
              if (this.startLoading) {
                Row() {
                  LoadingProgress()
                    .color(this.theme.mainColor)
                    .width(35)
                  Text('内容加载中...')
                }
                .height('100%')
                .alignItems(VerticalAlign.Center)
                .justifyContent(FlexAlign.Center)
              } else if (this.bookList.length === 0) {
                noFind({
                  hintIndex: 0
                })
              } else {
                ForEach(this.bookList, (item: ExploreRule, index) => {
                  CardItem({ item: item, currentIndex: this.currentIndex })
                })
              }
            }
            .padding({ left: 16, right: 16 })
          }
          .padding({ bottom: 16 })
          .scrollBar(BarState.Off)
          .onReachEnd(() => {
            this.pageNum += 1
            this.getList()
          })
        }
        .onStateChange((refreshStatus: RefreshStatus) => {
          if (refreshStatus === 1 || refreshStatus === 2) {
            this.RefreshingTitle = '松开刷新'
          } else {
            this.RefreshingTitle = '刷新中...'
          }
        })
        .height('100%')
        .onRefreshing(() => {
          setTimeout(async () => {
            this.pageNum = 1
            this.startLoading = true
            await this.getList()
            this.startLoading = false
            this.isRefreshing = false
          }, 1000)
        })
      }
      .layoutWeight(1)

    }
    .height('100%')
    .width('100%')
  }

  @Builder
  refreshComponent() {
    RefreshComponent({
      RefreshingTitle: this.RefreshingTitle,
    })
  }
}
