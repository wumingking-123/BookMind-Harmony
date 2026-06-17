import { router } from '@kit.ArkUI'
import BookBodyContent from './components/BookBodyContent'
import { FileHandler } from '../../../common/utils/FileHandler'
import Dialog from '../../../componets/common/Dialog'
import { showMessage } from '../../../componets/common/promptShow'
import { bookShelfImport } from '../../../database/entities/Books'
import { getPasteDataSync, isNetworkUrl, sleep } from '../../../common/utils/utils'
import booksUtil from '../../../common/utils/booksUtils'
import axios, { AxiosResponse } from '@ohos/axios'
import { ThemeItem } from '../../../common/model/Theme'
import { ThemeStorageKey } from '../../../common/constants/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkMotion, InkLayout
} from '../../../common/constants/DesignTokens'

@Component
export default struct IndexShelf {
  @State currentIndex: number = 0
  titleArray: string[] = ['小说', '漫画', '有声书']
  @State bookTypeNumber: number = 2
  @State EXHIBIT: string = '列表'
  @State @Watch('changeGroup') GROUP: string = '标签'
  @State isShowSheet: boolean = false
  @State sheetType: string = ''
  @State sheetHeight: number | SheetSize = 240
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @StorageProp('APP_INDEX_SCROLLABLE') APP_INDEX_SCROLLABLE: boolean = false
  @StorageLink('BOOK_IS_BOOK_REFRESHING') isBookRefreshing: number = 0
  @State bookImport: bookShelfImport[] = []
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  dialogController: CustomDialogController = new CustomDialogController({
    builder: Dialog({
      title: '网址导入',
      child: () => {
        this.DialogInput('请输入书籍目录或详情页')
      }
    }),
    cornerRadius: InkRadius.CARD,
    offset: { dx: 0, dy: 0 }
  })

  tabsController: TabsController = new TabsController()

  changeGroup() {
    this.bookTypeNumber = this.GROUP === '文件夹' ? 1 : 2
  }

  @Builder
  ImportClickBox(index: number, iconName: string, text: string) {
    Column({ space: InkSpacing.SM }) {
      Row() {
        Image($r(`${iconName}`))
          .width(22)
          .height(22)
          .fillColor(InkPalette.INK_FAINT)
      }
      .width(48)
      .height(48)
      .borderRadius(InkRadius.FULL)
      .backgroundColor(InkPalette.PAPER_WARM)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Text(text)
        .fontSize(InkTypography.CAPTION)
        .fontColor(InkPalette.INK_LIGHT)
    }
    .padding({ top: InkSpacing.LG, bottom: InkSpacing.MD })
    .alignItems(HorizontalAlign.Center)
    .onClick(async () => {
      switch (index) {
        case 0:
          let FileResult = await FileHandler.documentPickerFile(1, [
            '.txt', '.epub', '.pdf', '.mobi', '.azw', '.azw3', '.chm',
            '.cbz', '.cbr', '.cb7',
            '.m4b', '.mp3', '.wav', '.flac', '.m4a', '.ogg', '.opus'
          ])
          if (FileResult && FileResult.length > 0) {
            FileHandler.CopyFile(FileResult[0], this.currentIndex)
          }
          this.closeSheet()
          setTimeout(() => { this.isBookRefreshing++ }, 500)
          break
        case 1:
          this.openSheet('cloud', 240)
          break
        case 2:
          this.dialogController.open()
          break
        case 3:
          this.pasteBookImport()
          break
        case 4:
          let res = await FileHandler.documentPickerFile(1, ['.json'])
          FileHandler.ReadJSONFile(res[0]).then(async result => {
            if (result.length > 0) {
              this.bookImport = JSON.parse(result) as bookShelfImport[]
              this.bookImport.length > 0 ? await booksUtil.batchAdd(this.bookImport, this.currentIndex) : ''
              showMessage(this.bookImport.length > 0 ? `导入 ${this.bookImport.length} 本书籍` : '未找到书籍内容')
            }
          })
          setTimeout(() => { this.isBookRefreshing++ }, 500)
          break
      }
    })
  }

  @Builder
  ImportDialog() {
    Column() {
      Row()
        .width(32)
        .height(4)
        .borderRadius(2)
        .backgroundColor(InkPalette.INK_MIST)
        .margin({ top: InkSpacing.MD, bottom: InkSpacing.LG })

      GridRow({ columns: 3, gutter: 0 }) {
        GridCol() { this.ImportClickBox(0, 'app.media.my_center_file_icon', '本地导入') }
        GridCol() { this.ImportClickBox(2, 'app.media.official_website', '网址导入') }
        GridCol() { this.ImportClickBox(3, 'app.media.Paste', '粘贴导入') }
      }

      Divider()
        .color(InkPalette.PAPER_DEEP)
        .margin({ top: InkSpacing.MD })

      Text('取消')
        .fontSize(InkTypography.BODY)
        .fontColor(InkPalette.INK_GHOST)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: InkSpacing.LG, bottom: InkSpacing.LG })
        .onClick(() => { this.closeSheet() })
    }
    .backgroundColor(InkPalette.PAPER)
    .borderRadius({ topLeft: InkRadius.SHEET, topRight: InkRadius.SHEET })
  }

  @Builder
  DialogInput(placeholder: string, maxlength?: number) {
    Row() {
      TextInput({ placeholder: placeholder })
        .cancelButton({ icon: { src: $r('app.media.close') } })
        .backgroundColor(InkPalette.PAPER_WARM)
        .borderRadius(InkRadius.MD)
    }
    .margin({ top: InkSpacing.LG, bottom: InkSpacing.LG })
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Row({ space: InkSpacing.XS }) {
          ForEach(this.titleArray, (title: string, index: number) => {
            Column({ space: 4 }) {
              Text(title)
                .fontSize(InkTypography.BODY)
                .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.currentIndex === index ? InkPalette.INK : InkPalette.INK_MIST)
                .animation({ duration: InkMotion.FAST, curve: Curve.EaseOut })

              Row()
                .width(this.currentIndex === index ? 16 : 0)
                .height(2)
                .borderRadius(1)
                .backgroundColor(this.theme.mainColor)
                .animation({ duration: InkMotion.NORMAL, curve: Curve.EaseOut })
            }
            .padding({ left: InkSpacing.MD, right: InkSpacing.MD, top: InkSpacing.SM, bottom: InkSpacing.SM })
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.currentIndex = index
              this.tabsController.changeIndex(index)
            })
          })
        }

        Blank()

        Row({ space: InkSpacing.SM }) {
          Row() {
            Image($r('app.media.search'))
              .width(20)
              .height(20)
              .fillColor(InkPalette.INK_FAINT)
          }
          .width(36)
          .height(36)
          .borderRadius(InkRadius.FULL)
          .backgroundColor(InkPalette.OVERLAY_LIGHT)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            router.pushUrl({ url: 'pages/view/search/SearchBook' })
          })

          Row() {
            Image($r('app.media.down_svg'))
              .width(20)
              .height(20)
              .fillColor(InkPalette.INK_FAINT)
          }
          .width(36)
          .height(36)
          .borderRadius(InkRadius.FULL)
          .backgroundColor(InkPalette.OVERLAY_LIGHT)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            router.pushUrl({ url: 'pages/view/bookShelf/DownloadManagementPage' })
          })

          Row() {
            Image($r('app.media.import_svg'))
              .width(20)
              .height(20)
              .fillColor(InkPalette.INK_FAINT)
          }
          .width(36)
          .height(36)
          .borderRadius(InkRadius.FULL)
          .backgroundColor(InkPalette.OVERLAY_LIGHT)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.openSheet('import', SheetSize.MEDIUM)
          })
        }
      }
      .width('100%')
      .padding({
        top: this.topRectHeight === 0 ? 30 : this.topRectHeight,
        left: InkSpacing.PAGE_HORIZONTAL,
        right: InkSpacing.PAGE_HORIZONTAL,
        bottom: InkSpacing.SM
      })

      // 内容区
      Tabs({
        barPosition: BarPosition.Start,
        controller: this.tabsController,
        index: this.currentIndex
      }) {
        ForEach(this.titleArray, () => {
          TabContent() {
            Column() {
              BookBodyContent({
                currentIndex: this.currentIndex,
                EXHIBIT: this.EXHIBIT,
                GROUP: this.GROUP,
                bookTypeNumber: this.bookTypeNumber
              })
            }
          }
        })
      }
      .layoutWeight(1)
      .barWidth(0)
      .barHeight(0)
      .onChange((index) => {
        this.tabsController.changeIndex(index)
        this.currentIndex = index
      })
      .scrollable(this.APP_INDEX_SCROLLABLE)
    }
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[this.theme.mainColor, 0], [this.theme.secondColor, 0.15]]
    })
    .bindSheet($$this.isShowSheet, this.unifiedSheetBuilder(), {
      height: this.sheetHeight,
      showClose: false,
      dragBar: false,
      backgroundColor: InkPalette.PAPER,
      preferType: SheetType.BOTTOM
    })
  }

  private openSheet(type: string, height: number | SheetSize): void {
    this.sheetType = type
    this.sheetHeight = height
    this.isShowSheet = true
  }

  private closeSheet(): void {
    this.isShowSheet = false
  }

  @Builder
  unifiedSheetBuilder() {
    if (this.sheetType === 'import') {
      this.ImportDialog()
    }
  }

  async pasteBookImport() {
    try {
      let url = getPasteDataSync()
      if (!url) {
        showMessage('未获取到粘贴信息，请求默认数据')
        await sleep()
        return
      }
      if (!isNetworkUrl(url ?? '')) {
        showMessage('复制的链接不正确')
        await sleep()
        url = undefined
        return
      }
      const res: AxiosResponse = await axios.get(url)
      this.bookImport = res.data as bookShelfImport[]
      showMessage(this.bookImport.length > 0 ? `导入 ${this.bookImport.length} 本书籍` : '未找到书籍内容')
      this.bookImport.length > 0 ? booksUtil.batchAdd(this.bookImport, this.currentIndex) : ''
    } catch (err) {
      console.error('错误 ' + err)
    }
  }
}
