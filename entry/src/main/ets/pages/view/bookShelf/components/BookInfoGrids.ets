import confirmDialogExample from '../../../../componets/common/confirmDialog'
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
 * 书签_宫格 — 墨韵风格
 */
export default struct BookInfoGrids {
  @Prop book: Books
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  onDelete: () => void = () => {}
  @State delCache: boolean = false

  bookInfoDel: CustomDialogController | null = new CustomDialogController({
    builder: confirmDialogExample({
      cancel: () => { this.onCancel() },
      confirm: () => { this.onAccept() },
      delCache: this.delCache,
      isShowCache: true
    }),
    cancel: this.exitApp,
    autoCancel: true,
    alignment: DialogAlignment.Center,
    gridCount: 4,
    customStyle: false,
    cornerRadius: 25,
  })

  onCancel() { console.info('取消') }
  onAccept() { this.onDelete() }
  exitApp() { console.info('点外围取消') }

  build() {
    Column({ space: InkSpacing.SM }) {
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

        // 封面图
        Stack() {
          // 置顶标签
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
        .aspectRatio(0.75) // 3:4 封面比例
        .borderRadius(InkRadius.BOOK_COVER)
        .clip(true)
      }
      .width('100%')

      // 书名
      Text(this.book.bookName)
        .fontSize(InkTypography.BODY_SMALL)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(2)
        .lineHeight(InkTypography.LINE_HEIGHT_TIGHT * InkTypography.BODY_SMALL)

      // 章节信息
      if (this.book.durChapterTitle) {
        Text(this.book.durChapterTitle)
          .fontSize(InkTypography.MICRO)
          .fontColor(InkPalette.INK_MIST)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: InkSpacing.XS, right: InkSpacing.XS, top: InkSpacing.XS, bottom: InkSpacing.SM })
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
