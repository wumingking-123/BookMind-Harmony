import { promptAction } from '@kit.ArkUI'
import { BG_COLOR_ARRAY, BGColorType } from '@ohos/readerLibrary/src/main/ets/common/constants/Constants'

// 背景色配置
interface BgColorConfig {
  name: string
  color: string
  textColor: string
  type: number
}

@Component
export default struct BackgroundColorDialog {
  @Consume('bgColor') @Watch('onBgColorChange') bgColor: string
  @State selectedBgIndex: number = 0
  @State customBgColor: string = '#FFFFFF'
  @State showCustomColorPicker: boolean = false

  onBgColorChange() {
    this.updateSelectedIndex()
  }

  updateSelectedIndex() {
    const currentIndex = this.bgColorList.findIndex(item => item.color === this.bgColor)
    if (currentIndex !== -1) {
      this.selectedBgIndex = currentIndex
    }
  }

  // 预设背景色列表 - 使用现有的BGColorType
  private bgColorList: BgColorConfig[] = [
    { name: '纯白', color: BG_COLOR_ARRAY[BGColorType.WHITE], textColor: '#000000', type: BGColorType.WHITE },
    { name: '米黄', color: BG_COLOR_ARRAY[BGColorType.YELLOW], textColor: '#3D3226', type: BGColorType.YELLOW },
    { name: '淡绿', color: BG_COLOR_ARRAY[BGColorType.GREEN], textColor: '#2D3A2E', type: BGColorType.GREEN },
    { name: '淡蓝', color: BG_COLOR_ARRAY[BGColorType.BLUE], textColor: '#1A2933', type: BGColorType.BLUE },
    { name: '暗色', color: BG_COLOR_ARRAY[BGColorType.GREY], textColor: '#C4C4C4', type: BGColorType.GREY }
  ]

  aboutToAppear() {
    // 查找当前选中的背景色索引
    const currentIndex = this.bgColorList.findIndex(item => item.color === this.bgColor)
    if (currentIndex !== -1) {
      this.selectedBgIndex = currentIndex
    }
  }

  build() {
    Column({ space: 20 }) {
      // 标题
      Row() {
        Text('背景颜色')
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#1F2329')
      }
      .width('100%')
      .padding({ top: 20, bottom: 8 })

      // 预设颜色网格
      Grid() {
        ForEach(this.bgColorList, (item: BgColorConfig, index: number) => {
          GridItem() {
            this.ColorCard(item, index)
          }
        })

        // 自定义颜色
        GridItem() {
          this.CustomColorCard()
        }
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')
      .height(200)

      // 说明文字
      Row() {
        Text('提示：选择合适的背景色可以有效减轻眼睛疲劳')
          .fontSize(12)
          .fontColor('#8F959E')
          .lineHeight(18)
      }
      .width('100%')
      .padding({ top: 8 })
    }
    .padding({ left: 20, right: 20, bottom: 24 })
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  // 颜色卡片
  @Builder
  ColorCard(item: BgColorConfig, index: number) {
    Column({ space: 8 }) {
      // 颜色预览区
      Stack() {
        Column() {
          // 示例文字
          Text('字')
            .fontSize(20)
            .fontColor(item.textColor)
            .fontWeight(500)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(item.color)
        .borderRadius(8)
        .justifyContent(FlexAlign.Center)

        // 选中标记
        if (this.selectedBgIndex === index) {
          Image($r('app.media.ic_public_ok'))
            .width(20)
            .height(20)
            .fillColor('#FFFFFF')
            .position({ x: '75%', y: '8%' })
        }
      }
      .width('100%')
      .height(80)
      .borderWidth(this.selectedBgIndex === index ? 2 : 1)
      .borderColor(this.selectedBgIndex === index ? '#A89B7E' : '#E5E6EB')
      .borderRadius(8)

      // 颜色名称
      Text(item.name)
        .fontSize(13)
        .fontColor('#646A73')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .onClick(() => {
      this.selectedBgIndex = index
      this.bgColor = item.color
      promptAction.showToast({
        message: `已切换至${item.name}背景`,
        duration: 1500
      })
    })
  }

  // 自定义颜色卡片
  @Builder
  CustomColorCard() {
    Column({ space: 8 }) {
      Stack() {
        Column() {
          Image($r('app.media.add'))
            .width(24)
            .height(24)
            .fillColor('#8F959E')
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.customBgColor)
        .borderRadius(8)
        .justifyContent(FlexAlign.Center)
        .border({
          width: 1,
          color: '#E5E6EB',
          style: BorderStyle.Dashed
        })

        // 选中标记
        if (this.selectedBgIndex === 99) {
          Image($r('app.media.ic_public_ok'))
            .width(20)
            .height(20)
            .fillColor('#A89B7E')
            .position({ x: '75%', y: '8%' })
        }
      }
      .width('100%')
      .height(80)

      Text('自定义')
        .fontSize(13)
        .fontColor('#646A73')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .onClick(() => {
      promptAction.showToast({
        message: '自定义颜色功能开发中',
        duration: 2000
      })
      // 这里可以打开颜色选择器
      // this.showCustomColorPicker = true
    })
  }
}
