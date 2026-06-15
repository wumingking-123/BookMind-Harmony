import { promptAction } from '@kit.ArkUI'
import { preferences } from '@kit.ArkData'

// 字体粗细枚举
export enum FontWeightType {
  LIGHT = 300,
  NORMAL = 400,
  MEDIUM = 500,
  BOLD = 700
}

// 字体类型枚举
export enum FontType {
  SIMPLIFIED = 'simplified',
  TRADITIONAL = 'traditional'
}

@Component
export default struct LayoutMoreDialog {
  @Consume('readerPadding') ReaderPadding: number
  @Consume('fontWeight') fontWeight: number
  @Consume('fontType') fontType: string
  @Consume('isFirstLineIndent') isFirstLineIndent: boolean
  @Consume('letterSpacing') letterSpacing: number

  aboutToAppear() {
  }

  saveSettings() {
    // Parent watches @Consume changes and persists them automatically.
  }

  // 转换繁体中文（简单示例，实际应使用系统API）
  convertToTraditional(text: string): string {
    // 这里应该调用系统API进行繁简转换
    // 暂时返回原文本，实际项目中需要集成转换库
    promptAction.showToast({
      message: '繁体转换功能待实现',
      duration: 2000
    })
    return text
  }

  build() {
    Column({ space: 24 }) {
      // 标题
      Row() {
        Text('更多排版设置')
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#1F2329')
      }
      .width('100%')
      .padding({ top: 20, bottom: 12 })

      // 边距设置
      Row({ space: 16 }) {
        Text('页边距')
          .fontSize(15)
          .fontColor('#1F2329')
          .width(70)

        Slider({
          value: this.ReaderPadding,
          max: 40,
          min: 8,
          step: 4,
          style: SliderStyle.InSet
        })
          .trackThickness(4)
          .selectedColor('#A89B7E')
          .blockColor('#A89B7E')
          .trackBorderRadius(2)
          .blockSize({ width: 24, height: 24 })
          .layoutWeight(1)
          .onChange((value) => {
            this.ReaderPadding = value
            this.saveSettings()
          })

        Text(`${this.ReaderPadding.toFixed(0)}`)
          .fontSize(14)
          .fontColor('#646A73')
          .width(30)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 字间距设置
      Row({ space: 16 }) {
        Text('字间距')
          .fontSize(15)
          .fontColor('#1F2329')
          .width(70)

        Slider({
          value: this.letterSpacing,
          max: 10,
          min: -2,
          step: 0.5,
          style: SliderStyle.InSet
        })
          .trackThickness(4)
          .selectedColor('#A89B7E')
          .blockColor('#A89B7E')
          .trackBorderRadius(2)
          .blockSize({ width: 24, height: 24 })
          .layoutWeight(1)
          .onChange((value) => {
            this.letterSpacing = value
            this.saveSettings()
          })

        Text(`${this.letterSpacing.toFixed(1)}`)
          .fontSize(14)
          .fontColor('#646A73')
          .width(30)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Divider().color('#F0F0F0')

      // 字体粗细
      Column({ space: 12 }) {
        Row() {
          Text('字体粗细')
            .fontSize(15)
            .fontColor('#1F2329')
        }
        .width('100%')

        Row({ space: 12 }) {
          this.FontWeightButton('细体', FontWeightType.LIGHT)
          this.FontWeightButton('常规', FontWeightType.NORMAL)
          this.FontWeightButton('中粗', FontWeightType.MEDIUM)
          this.FontWeightButton('粗体', FontWeightType.BOLD)
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)

      Divider().color('#F0F0F0')

      // 字体类型（简繁体）
      Column({ space: 12 }) {
        Row() {
          Text('字体类型')
            .fontSize(15)
            .fontColor('#1F2329')
        }
        .width('100%')

        Row({ space: 12 }) {
          this.FontTypeButton('简体', FontType.SIMPLIFIED)
          this.FontTypeButton('繁体', FontType.TRADITIONAL)
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)

      Divider().color('#F0F0F0')

      // 首行缩进
      Row() {
        Row() {
          Text('首行缩进')
            .fontSize(15)
            .fontColor('#1F2329')

          Text('段落首行空两格')
            .fontSize(12)
            .fontColor('#8F959E')
            .margin({ left: 8 })
        }
        .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.isFirstLineIndent })
          .selectedColor('#A89B7E')
          .onChange((isOn: boolean) => {
            this.isFirstLineIndent = isOn
            this.saveSettings()
            promptAction.showToast({
              message: isOn ? '已开启首行缩进' : '已关闭首行缩进',
              duration: 1500
            })
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .padding({ left: 20, right: 20, bottom: 20 })
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  // 字体粗细按钮
  @Builder
  FontWeightButton(text: string, weight: FontWeightType) {
    Button(text)
      .fontSize(14)
      .fontColor(this.fontWeight === weight ? '#FFFFFF' : '#646A73')
      .backgroundColor(this.fontWeight === weight ? '#A89B7E' : '#F7F8FA')
      .borderRadius(8)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .layoutWeight(1)
      .onClick(() => {
        this.fontWeight = weight
        this.saveSettings()
        promptAction.showToast({
          message: `已切换至${text}`,
          duration: 1500
        })
      })
  }

  // 字体类型按钮
  @Builder
  FontTypeButton(text: string, type: FontType) {
    Button(text)
      .fontSize(14)
      .fontColor(this.fontType === type ? '#FFFFFF' : '#646A73')
      .backgroundColor(this.fontType === type ? '#A89B7E' : '#F7F8FA')
      .borderRadius(8)
      .padding({ left: 24, right: 24, top: 8, bottom: 8 })
      .layoutWeight(1)
      .onClick(() => {
        this.fontType = type
        this.saveSettings()
        if (type === FontType.TRADITIONAL) {
          // 这里应该触发全文繁体转换
          this.convertToTraditional('')
        }
        promptAction.showToast({
          message: `已切换至${text}`,
          duration: 1500
        })
      })
  }
}
