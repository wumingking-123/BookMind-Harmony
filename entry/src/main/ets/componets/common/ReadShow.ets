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
import { FileHandler } from '../../common/utils/FileHandler'
import { BookContentHolder } from '../../common/utils/BookContentHolder'
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
      } else {
        this.book = JSON.parse(JSON.stringify(this.bookHistory[0])) as Books
        this.book.isJoin = false
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
            clickUtil.preventClick(async () => {
              if (!this.book || !this.book.bookUrl) {
                console.error('Book URL is empty, cannot continue reading');
                return
              }
              let savedIndex = this.book.durChapterIndex ?? this.bookHistory[0].durChapterIndex ?? 0
              if (this.book.bookType === 2) {
                // 有声书直接跳转播放器
                router.pushUrl({
                  url: 'pages/view/Reader/ReaderPage2',
                  params: {
                    bookData: this.book,
                    clickBookChapter: savedIndex
                  }
                })
              } else {
                // 小说/漫画跳转阅读器
                let temp = await FileHandler.readFile(this.book.bookUrl || '')
                BookContentHolder.setChapters(temp)
                router.pushUrl({
                  url: canIUse("SystemCapability.Reader.ReaderService.ReaderCore")
                    ? 'pages/view/Reader/ReaderPageKit'
                    : 'pages/view/Reader/ReaderPage2',
                  params: {
                    bookData: this.book,
                    clickBookChapter: savedIndex
                  }
                })
              }
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
