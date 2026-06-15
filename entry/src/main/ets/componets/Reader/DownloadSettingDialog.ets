import { AddDownloadDialog } from 'ets/componets/Reader/AddDownloadDialog';
import { ThemeStorageKey } from '../../common/constants/Theme';
import { ThemeItem } from '../../common/model/Theme';
import { promptAction } from '@kit.ArkUI';

@Component
export default struct DownloadSettingDialog {
  @Link isShowDownload: boolean
  @Link isShowSetting: boolean
  @State selectedOption: number = -1 // 选中的选项 0-3
  @State StartText: string = "1" // 缓存开始章节
  @State EndText: string = "50" // 缓存结束章节
  controller: TextInputController = new TextInputController()
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  // 下载选项配置
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
              TextInput({ text: this.StartText, controller: this.controller })
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
              TextInput({ text: this.EndText, controller: this.controller })
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
            this.isShowDownload = false
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

  // 选项条目
  @Builder
  OptionItem(text: string, index: number) {
    Row({ space: 12 }) {
      // 单选框
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

      // 选项文字
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

  // 开始下载
  startDownload() {
    if (this.selectedOption === -1) {
      promptAction.showToast({
        message: '请选择缓存选项',
        duration: 1500
      })
      return
    }

    let message = ''
    switch (this.selectedOption) {
      case 0:
        message = '开始缓存后50章'
        break
      case 1:
        message = '开始缓存后面全部章节'
        break
      case 2:
        message = '开始缓存全部章节'
        break
      case 3:
        if (!this.StartText || !this.EndText) {
          promptAction.showToast({
            message: '请输入有效的章节范围',
            duration: 1500
          })
          return
        }
        message = `开始缓存第${this.StartText}-${this.EndText}章`
        break
    }

    promptAction.showToast({
      message: message,
      duration: 2000
    })

    // TODO: 实现实际的下载逻辑
    this.isShowDownload = false
  }
}
