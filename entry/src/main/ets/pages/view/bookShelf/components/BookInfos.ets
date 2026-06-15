import { Books } from '../../../../database/entities/Books'
import { router } from '@kit.ArkUI'
import BookInfoDialogs from './dialog/BookInfoDialogs'
import clickUtil from '../../../../common/utils/ClickUtils'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow
} from '../../../../common/constants/DesignTokens'
import { ThemeStorageKey } from '../../../../common/constants/Theme'
import { ThemeItem } from '../../../../common/model/Theme'

@Component
/**
 * 书签 — 列表模式 墨韵风格
 */
export default struct BookInfos {
  @Prop currentIndex: number
  @Prop book: Books
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  @State delCache: boolean = false

  build() {
    Row({ space: InkSpacing.LG }) {
      // 封面
      Stack() {
        // 本地标签
        if (this.book.isLocalBook) {
          Text('本地')
            .fontColor(InkPalette.PAPER)
            .fontSize(InkTypography.MICRO)
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .backgroundColor(this.theme.mainColor)
            .zIndex(2)
            .borderRadius({ topRight: InkRadius.SM, bottomLeft: InkRadius.SM })
            .position({ right: 0, top: 0 })
        }

        Stack() {
          if (this.book.isTop) {
            Text('置顶')
              .fontColor(Color.White)
              .fontSize(InkTypography.MICRO)
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .borderRadius(InkRadius.XS)
              .backgroundColor(InkPalette.OVERLAY_INTENSE)
              .zIndex(1)
              .position({ left: 4, bottom: 4 })
          }

          Image(this.book.coverUrl)
            .draggable(false)
            .alt($r('app.media.icon_book_default_cover_one'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }
        .width('100%')
        .height('100%')
        .borderRadius(InkRadius.BOOK_COVER)
        .clip(true)
      }
      .width(60)
      .height(80)

      // 信息区
      Column({ space: InkSpacing.SM }) {
        Text(this.book.bookName)
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)

        if (this.book.intro) {
          Text(this.book.intro)
            .fontSize(InkTypography.CAPTION)
            .fontColor(InkPalette.INK_MIST)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(2)
            .lineHeight(InkTypography.LINE_HEIGHT_NORMAL * InkTypography.CAPTION)
        }

        if (this.book.durChapterTitle) {
          Text(this.book.durChapterTitle)
            .fontSize(InkTypography.CAPTION)
            .fontColor(InkPalette.INK_GHOST)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(1)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(InkSpacing.MD)
    .borderRadius(InkRadius.MD)
    .onClick(() => {
      clickUtil.preventClick(() => {
        router.pushUrl({ url: 'pages/view/BookDetailPage', params: this.book })
      })
    })
    .gesture(
      LongPressGesture({ repeat: true, duration: 500 })
        .onAction((event: GestureEvent) => {
          if (event.repeat) {
            this.bookInfoDialog?.open()
          }
        })
    )
  }

  bookInfoDialog: CustomDialogController | null = new CustomDialogController({
    builder: BookInfoDialogs({
      bookData: this.book,
      cancel: () => { this.exitDialog() }
    }),
    cancel: this.exitDialog,
    autoCancel: true,
    width: '100%',
    alignment: DialogAlignment.Bottom,
    customStyle: true
  })

  exitDialog() { this.bookInfoDialog?.close() }
}
