import { promptAction } from '@kit.ArkUI'
import { FlipPageType } from '@ohos/readerLibrary/src/main/ets/common/constants/Constants'

// 翻页模式配置
interface FlipModeConfig {
  name: string
  description: string
  icon: Resource
  type: FlipPageType
}

@Component
export default struct FlipModeDialog {
  @Consume('turnStyle') @Watch('onTurnStyleChange') turnStyle: FlipPageType
  @State selectedMode: FlipPageType = FlipPageType.COVER_FLIP_PAGE

  onTurnStyleChange() {
    this.selectedMode = this.turnStyle
  }

  // 翻页模式列表
  private flipModeList: FlipModeConfig[] = [
    {
      name: '覆盖翻页',
      description: '像翻书一样，新页面覆盖旧页面',
      icon: $r('app.media.cover_icon'),
      type: FlipPageType.COVER_FLIP_PAGE
    },
    {
      name: '仿真翻页',
      description: '真实的卷页效果，最接近纸质书',
      icon: $r('app.media.simulate_icon'),
      type: FlipPageType.SIMULATE_FLIP_PAGE
    },
    {
      name: '滑动翻页',
      description: '平滑的左右滑动切换页面',
      icon: $r('app.media.slide_icon'),
      type: FlipPageType.SLIDE_FLIP_PAGE
    },
    {
      name: '上下滚动',
      description: '连续滚动阅读，无翻页动画',
      icon: $r('app.media.scroll_icon'),
      type: FlipPageType.UP_DOWN_FLIP_PAGE
    }
  ]

  aboutToAppear() {
    this.selectedMode = this.turnStyle
  }

  build() {
    Column({ space: 16 }) {
      // 标题
      Row() {
        Text('翻页模式')
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#1F2329')
      }
      .width('100%')
      .padding({ top: 20, bottom: 8 })

      // 模式列表
      Column({ space: 12 }) {
        ForEach(this.flipModeList, (item: FlipModeConfig) => {
          this.FlipModeCard(item)
        })
      }
      .width('100%')

      // 底部说明
      Row() {
        Text('提示：不同的翻页模式会影响阅读体验，请选择适合您的方式')
          .fontSize(12)
          .fontColor('#8F959E')
          .lineHeight(18)
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
  FlipModeCard(item: FlipModeConfig) {
    Row({ space: 16 }) {
      // 图标
      Image(item.icon)
        .width(48)
        .height(48)
        .fillColor(this.selectedMode === item.type ? '#A89B7E' : '#8F959E')

      // 文字说明
      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(15)
          .fontColor('#1F2329')
          .fontWeight(500)
        
        Text(item.description)
          .fontSize(12)
          .fontColor('#8F959E')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 选中标记
      if (this.selectedMode === item.type) {
        Image($r('app.media.ic_public_ok'))
          .width(20)
          .height(20)
          .fillColor('#A89B7E')
      } else {
        Column()
          .width(20)
          .height(20)
          .border({
            width: 2,
            color: '#E5E6EB',
            radius: 10
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.selectedMode === item.type ? '#F7F4F0' : '#FFFFFF')
    .borderRadius(12)
    .border({
      width: this.selectedMode === item.type ? 2 : 1,
      color: this.selectedMode === item.type ? '#A89B7E' : '#E5E6EB'
    })
    .onClick(() => {
      this.selectedMode = item.type
      this.turnStyle = item.type
      promptAction.showToast({
        message: `已切换至${item.name}`,
        duration: 1500
      })
    })
  }
}
