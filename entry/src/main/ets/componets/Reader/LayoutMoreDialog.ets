@Component
export default struct LayoutMore {
  @Link ReaderPadding: number
  @Link fontWeight: number
  @Link isIndent: boolean
  @Link isSimplified: boolean

  build() {
    Column({ space: 20 }) {
      // 边距调节
      Column({ space: 8 }) {
        Text('边距')
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
        Row({ space: 16 }) {
          Text(`${this.ReaderPadding}`)
            .fontSize(14)
            .fontColor('#666666')
            .width(30)
            .textAlign(TextAlign.Center)
          Slider({
            value: this.ReaderPadding,
            max: 32,
            min: 12,
            step: 4,
            style: SliderStyle.InSet
          })
            .selectedColor('rgba(0, 0, 0, 0.04)')
            .blockSize({ width: 24, height: 24 })
            .layoutWeight(1)
            .onChange((value) => {
              this.ReaderPadding = value
            })
        }
        .width('100%')
      }
      .width('100%')

      // 字体粗细
      Column({ space: 8 }) {
        Text('字体粗细')
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
        Row({ space: 12 }) {
          Button('细')
            .fontSize(13)
            .fontWeight(FontWeight.Normal)
            .height(36)
            .layoutWeight(1)
            .borderRadius(8)
            .backgroundColor(this.fontWeight === 300 ? '#333333' : '#F5F5F5')
            .fontColor(this.fontWeight === 300 ? '#FFFFFF' : '#666666')
            .onClick(() => {
              this.fontWeight = 300
            })
          Button('中')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .height(36)
            .layoutWeight(1)
            .borderRadius(8)
            .backgroundColor(this.fontWeight === 400 ? '#333333' : '#F5F5F5')
            .fontColor(this.fontWeight === 400 ? '#FFFFFF' : '#666666')
            .onClick(() => {
              this.fontWeight = 400
            })
          Button('粗')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .height(36)
            .layoutWeight(1)
            .borderRadius(8)
            .backgroundColor(this.fontWeight === 600 ? '#333333' : '#F5F5F5')
            .fontColor(this.fontWeight === 600 ? '#FFFFFF' : '#666666')
            .onClick(() => {
              this.fontWeight = 600
            })
        }
        .width('100%')
      }
      .width('100%')

      // 简体/繁体
      Column({ space: 8 }) {
        Text('字体样式')
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
        Row({ space: 12 }) {
          Button('简体')
            .fontSize(13)
            .height(36)
            .layoutWeight(1)
            .borderRadius(8)
            .backgroundColor(this.isSimplified ? '#333333' : '#F5F5F5')
            .fontColor(this.isSimplified ? '#FFFFFF' : '#666666')
            .onClick(() => {
              this.isSimplified = true
            })
          Button('繁体')
            .fontSize(13)
            .height(36)
            .layoutWeight(1)
            .borderRadius(8)
            .backgroundColor(!this.isSimplified ? '#333333' : '#F5F5F5')
            .fontColor(!this.isSimplified ? '#FFFFFF' : '#666666')
            .onClick(() => {
              this.isSimplified = false
            })
        }
        .width('100%')
      }
      .width('100%')

      // 首行缩进
      Row() {
        Text('首行缩进')
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: $$this.isIndent })
          .height(20)
          .width(40)
          .onChange((isOn) => {
            this.isIndent = isOn
          })
      }
      .width('100%')
    }
    .height(500)
    .padding({
      left: 20,
      right: 20,
      top: 16
    })
  }
}
