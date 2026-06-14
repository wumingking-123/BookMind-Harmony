/**
 * 上次阅读弹窗 — 檀木风格浮层
 * 使用暖棕色系，营造书香氛围
 */
import booksUtil from '../../common/utils/booksUtils'
import bookHistoryDao from '../../database/dao/BookHistoryDao'
import { BookHistory } from '../../database/entities/BookHistory'
import { Books } from '../../database/entities/Books'
import { router } from '@kit.ArkUI'
import clickUtil from '../../common/utils/ClickUtils'
import { ThemeStorageKey } from '../../common/constants/Theme'
import { ThemeItem } from '../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow
} from '../../common/constants/DesignTokens'

@Component
export default struct ReadShow {
  @Link showReadShow: boolean
  @State bookHistory: BookHistory[] = []
  @State book: Books = new Books()

  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  aboutToAppear(): void {
    this.getBookHistoryList()
  }

  async getBookHistoryList() {
    this.bookHistory = await bookHistoryDao.searchLimit()
    if (this.bookHistory.length >= 1 && this.bookHistory[0].id) {
      let bookInfo = await booksUtil.getBookByIds(this.bookHistory[0].id)
      if (bookInfo && bookInfo[0]) {
        this.book = bookInfo[0]
      }
    }
  }

  build() {
    if (this.bookHistory[0] && this.book) {
      Row({ space: InkSpacing.MD }) {
        // 封面 — 带微阴影
        Image(this.bookHistory[0].coverUrl ?? '')
          .alt($r('app.media.icon_book_default_cover_one'))
          .width(40)
          .height(53)
          .borderRadius(InkRadius.SM)
          .shadow(InkShadow.SUBTLE)
          .draggable(false)

        // 信息 — 书名 + 章节
        Column({ space: 3 }) {
          Text(this.bookHistory[0].bookName)
            .fontSize(InkTypography.BODY_SMALL)
            .fontColor(InkPalette.PAPER)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.bookHistory[0].durChapterTitle)
            .fontSize(InkTypography.MICRO)
            .fontColor(InkPalette.PAPER_SAND)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 继续阅读按钮 — 圆角胶囊
        Text('继续阅读')
          .fontSize(InkTypography.CAPTION)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.mainColor)
          .padding({ left: InkSpacing.LG, right: InkSpacing.LG, top: InkSpacing.SM, bottom: InkSpacing.SM })
          .borderRadius(InkRadius.BUTTON_LARGE)
          .backgroundColor(InkPalette.PAPER)
          .onClick(() => {
            clickUtil.preventClick(() => {
              router.pushUrl({
                url: 'pages/view/BookDetailPage',
                params: this.book
              })
            })
          })

        // 关闭按钮
        Image($r('app.media.close'))
          .width(16)
          .height(16)
          .fillColor(InkPalette.PAPER_SAND)
          .onClick(() => {
            this.showReadShow = !this.showReadShow
            console.log(this.showReadShow + '')
          })
      }
      .width('92%')
      .height(68)
      .padding({ left: InkSpacing.MD, right: InkSpacing.LG })
      .borderRadius(InkRadius.LG)
      .backgroundColor(InkPalette.SANDALWOOD)
      .shadow(InkShadow.DEEP)
      .alignItems(VerticalAlign.Center)
    }
  }
}
