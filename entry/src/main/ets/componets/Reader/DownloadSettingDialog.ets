import { ThemeStorageKey } from '../../common/constants/Theme';
import { ThemeItem } from '../../common/model/Theme';
import { promptAction } from '@kit.ArkUI';
import downloadManager from '../../common/utils/DownloadManager';
import { DownloadTask } from '../../common/model/DownloadTask';
import { BookSource } from '../../database/entities/BookSource';
import { Books } from '../../database/entities/Books';

@CustomDialog
export struct DownloadSettingDialog {
  controller?: CustomDialogController
  @State selectedOption: number = -1
  @State StartText: string = "1"
  @State EndText: string = "50"
  inputController: TextInputController = new TextInputController()
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  // 外部传入参数
  bookData?: Books
  bookSource?: BookSource
  chapterCount: number = 0
  onDownloadStart?: (task: DownloadTask) => void
  // Reader页面兼容参数
  isShowDownload: boolean = false
  isShowSetting: boolean = true

  private downloadOptions: string[] = [
    '缓存后50章',
    '缓存后面全部章节',
    '缓存全部章节',
    '自定义缓存范围'
  ]

  build() {
    Column({ space: 20 }) {
      // 标题
      Row() {
        Text('缓存设置')
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#1F2329')
      }
      .width('100%')
      .padding({ top: 20 })

      // 章节数提示
      Text('共 ' + this.chapterCount + ' 章')
        .fontSize(13)
        .fontColor('#8F959E')
        .width('100%')

      // 选项列表
      Column({ space: 12 }) {
        ForEach(this.downloadOptions, (option: string, index: number) => {
          this.OptionItem(option, index)
        })
      }
      .width('100%')

      // 自定义范围输入
      if (this.selectedOption === 3) {
        Column({ space: 12 }) {
          Text('请输入缓存章节范围')
            .fontSize(14)
            .fontColor('#646A73')
            .width('100%')

          Row({ space: 12 }) {
            Column({ space: 4 }) {
              Text('起始章节')
                .fontSize(12)
                .fontColor('#8F959E')
              TextInput({ text: this.StartText, controller: this.inputController })
                .type(InputType.Number)
                .height(44)
                .borderRadius(8)
                .fontSize(15)
                .fontWeight(400)
                .textAlign(TextAlign.Center)
                .backgroundColor('#F7F8FA')
                .onChange((value: string) => {
                  this.StartText = value
                })
            }
            .layoutWeight(1)

            Text('至')
              .fontSize(14)
              .fontColor('#646A73')
              .margin({ top: 20 })

            Column({ space: 4 }) {
              Text('结束章节')
                .fontSize(12)
                .fontColor('#8F959E')
              TextInput({ text: this.EndText, controller: this.inputController })
                .type(InputType.Number)
                .height(44)
                .borderRadius(8)
                .fontSize(15)
                .fontWeight(400)
                .textAlign(TextAlign.Center)
                .backgroundColor('#F7F8FA')
                .onChange((value: string) => {
                  this.EndText = value
                })
            }
            .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .padding({ top: 8 })
        .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
      }

      // 底部按钮
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(15)
          .fontColor('#646A73')
          .backgroundColor('#F7F8FA')
          .borderRadius(10)
          .height(44)
          .layoutWeight(1)
          .onClick(() => {
            this.controller?.close()
          })

        Button('开始缓存')
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor(this.theme.mainColor || '#A89B7E')
          .borderRadius(10)
          .height(44)
          .layoutWeight(1)
          .onClick(() => {
            this.startDownload()
          })
      }
      .width('100%')
      .padding({ top: 12 })
    }
    .padding({ left: 20, right: 20, bottom: 24 })
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder
  OptionItem(text: string, index: number) {
    Row({ space: 12 }) {
      Column() {
        if (this.selectedOption === index) {
          Column()
            .width(12)
            .height(12)
            .backgroundColor(this.theme.mainColor || '#A89B7E')
            .borderRadius(6)
        }
      }
      .width(20)
      .height(20)
      .border({
        width: 2,
        color: this.selectedOption === index ? (this.theme.mainColor || '#A89B7E') : '#E5E6EB',
        radius: 10
      })
      .justifyContent(FlexAlign.Center)

      Text(text)
        .fontSize(15)
        .fontColor(this.selectedOption === index ? '#1F2329' : '#646A73')
        .fontWeight(this.selectedOption === index ? 500 : 400)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(this.selectedOption === index ? '#F7F4F0' : '#FFFFFF')
    .borderRadius(10)
    .border({
      width: this.selectedOption === index ? 1.5 : 1,
      color: this.selectedOption === index ? (this.theme.mainColor || '#A89B7E') : '#E5E6EB'
    })
    .onClick(() => {
      this.selectedOption = index
    })
  }

  startDownload() {
    if (this.selectedOption === -1) {
      promptAction.showToast({ message: '请选择缓存选项', duration: 1500 })
      return
    }

    if (!this.bookData || !this.bookSource) {
      promptAction.showToast({ message: '书源信息不完整', duration: 1500 })
      return
    }

    const count = this.chapterCount
    if (count <= 0) {
      promptAction.showToast({ message: '暂无章节可下载', duration: 1500 })
      return
    }

    let startChapter = 0
    let endChapter = count - 1

    switch (this.selectedOption) {
      case 0: // 后50章
        startChapter = Math.max(0, count - 50)
        break
      case 1: // 后面全部
        startChapter = 0
        break
      case 2: // 全部
        startChapter = 0
        break
      case 3: // 自定义
        const s = parseInt(this.StartText)
        const e = parseInt(this.EndText)
        if (isNaN(s) || isNaN(e) || s < 1 || e < s) {
          promptAction.showToast({ message: '请输入有效的章节范围', duration: 1500 })
          return
        }
        startChapter = s - 1
        endChapter = Math.min(e - 1, count - 1)
        break
    }

    const bookUrl = this.bookData.bookUrl || ''
    const tocUrl = bookUrl

    const task = downloadManager.addTask(
      bookUrl,
      this.bookData.bookName,
      this.bookData.author || '',
      this.bookSource,
      tocUrl,
      startChapter,
      endChapter
    )

    let msg = ''
    switch (this.selectedOption) {
      case 0: msg = '开始缓存后50章'; break
      case 1: msg = '开始缓存后面全部章节'; break
      case 2: msg = '开始缓存全部章节'; break
      case 3: msg = `开始缓存第${this.StartText}-${this.EndText}章`; break
    }
    promptAction.showToast({ message: msg, duration: 2000 })

    if (this.onDownloadStart) {
      this.onDownloadStart(task)
    }

    this.controller?.close()
  }
}
