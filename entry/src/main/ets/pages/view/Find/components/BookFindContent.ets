/**
 * @author 2008
 * @datetime 2024/7/14 21:54
 * @className: BookFind
 * 发现公用书籍展示组件（本地解析版本，不依赖后端API）
 */
import { isNetworkUrl } from '../../../../common/utils/utils'
import noFind from '../../../../componets/common/noFind'
import { ExploreRule } from '../../../../database/entities/rule'
import { ExploreItem } from '../../../../database/types/BookSourceType'
import mayAlsoLike from '../mayAlsoLike'
import { CardItem } from './CardItem'
import { router } from '@kit.ArkUI'
import { ThemeItem } from '../../../../common/model/Theme'
import { ThemeStorageKey } from '../../../../common/constants/Theme'
import requestUtils from '../../../../common/utils/requestUtils'
import { RuleAnalyzer, RuleAnalyzerData } from '../../../../common/model/analyzeRule/RuleAnalyzer'
import { BookSource } from '../../../../database/entities/BookSource'

@Component
export default struct BookFindContent {
  @Prop currentIndex: number
  @Prop bookSourceUrl: string
  @Prop exploreItem: ExploreItem
  @Prop @Watch('getList') counter: number = 0
  @State loading: boolean = true
  @State errorExplore: boolean = false
  @State bookList: ExploreRule[] = []
  @Prop exploreRule: ExploreRule = {}
  @Prop charset: string = ''
  handleClick: () => void = () => {
  }
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  aboutToAppear() {
    this.getList()
  }

  async getList() {
    this.loading = true
    this.errorExplore = false
    this.bookList = []

    let url = this.exploreItem.url.replace('{{page}}', '1')
    if (!isNetworkUrl(url)) {
      url = this.bookSourceUrl + url
    }

    try {
      // 1. 直接请求页面HTML（不依赖后端API）
      const html = await requestUtils.requestUrlHtml(url, this.charset)
      if (!html || html.length < 100) {
        this.loading = false
        return
      }

      // 2. 本地解析HTML
      const results = this.parseExploreHtml(html)
      this.bookList = results
      this.loading = false
      this.errorExplore = false
    } catch (e) {
      console.log('BookFindContent 请求失败: ' + (e as Error).message)
      this.loading = false
      this.errorExplore = true
    }
  }

  /**
   * 本地解析探索页面HTML
   */
  private parseExploreHtml(html: string): ExploreRule[] {
    const results: ExploreRule[] = []
    if (!this.exploreRule.bookList) return results

    // 构造一个最小的BookSource用于RuleAnalyzer
    const dummySource = new BookSource()
    dummySource.bookSourceUrl = this.bookSourceUrl

    const analyzer = new RuleAnalyzer()
    analyzer.init(new RuleAnalyzerData({
      body: html,
      bookSource: dummySource
    }))

    // 获取书籍列表元素
    const bookElements = analyzer.getElements(this.exploreRule.bookList)
    if (bookElements.length === 0) return results

    for (const element of bookElements) {
      const item: ExploreRule = {}

      // 提取各字段
      item.name = analyzer.extractText(element, this.exploreRule.name)
      item.author = analyzer.extractText(element, this.exploreRule.author)
      item.intro = analyzer.extractText(element, this.exploreRule.intro)
      item.kind = analyzer.extractText(element, this.exploreRule.kind)
      item.lastChapter = analyzer.extractText(element, this.exploreRule.lastChapter)
      item.wordCount = analyzer.extractText(element, this.exploreRule.wordCount)
      item.bookUrl = analyzer.extractAttribute(element, this.exploreRule.bookUrl)
      item.coverUrl = analyzer.extractAttribute(element, this.exploreRule.coverUrl)

      // 解析相对URL
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
    Column({
      space: 16
    }) {
      Column() {
        mayAlsoLike({
          mayAlsoLike: this.exploreItem.title,
          handleClick: this.handleClick
        })
        if (this.loading) {
          Column() {
            LoadingProgress()
              .color(this.theme.mainColor)
              .width('50%')
            Text('内容加载中...')
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
        } else if (this.errorExplore) {
          noFind({
            onclick: () => {
              this.getList()
            }
          })
        } else if (this.bookList.length === 0) {
          noFind({
            hintIndex: 0
          })
        } else {
          Column() {
            ForEach(this.bookList, (item: ExploreRule, index) => {
              CardItem({ item: item, currentIndex: this.currentIndex })
            })
            if (this.bookList.length === 3) {
              Column() {
                Text('查看更多')
                  .lineHeight(20)
                  .fontColor('#73000000')
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
              .margin({ top: 20 })
              .backgroundColor('#0F000000')
              .borderRadius(4)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/view/Find/CategoryList/Index',
                  params: {
                    bookSourceUrl: this.bookSourceUrl,
                    exploreItem: this.exploreItem,
                    exploreRule: this.exploreRule,
                    currentIndex: this.currentIndex,
                    charset: this.charset
                  }
                })
              })
            }
          }
          .height('100%')
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Start)
        }
      }
      .padding({
        left: 16,
        right: 16,
        top: 20,
        bottom: 20
      })
      .borderRadius(12)
      .backgroundColor(Color.White)
      .height(436)
    }
    .margin({ top: 12 })
  }
}
