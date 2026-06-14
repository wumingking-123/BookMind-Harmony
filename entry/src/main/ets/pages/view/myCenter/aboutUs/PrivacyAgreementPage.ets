import { router } from '@kit.ArkUI';
import { ThemeStorageKey } from '../../../../common/constants/Theme';
import { ThemeItem } from '../../../../common/model/Theme';
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../../common/constants/DesignTokens';

@Entry
@Component
struct PrivacyAgreementPage {
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @State rowsData: Array<string> = [
    '本应用没有服务端，不收集任何用户信息，只采用了 Google Firebase 收集崩溃报告和性能报告。',
    '存储权限用来打开本地文件和本地备份恢复。其它一些权限是 Google Firebase 需要。',
    '本应用为开源软件，内置 JS 引擎，因书源调用 JS 发生的任何问题由用户自行承担。'
  ]
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  getMainColor(): string {
    return this.theme?.mainColor || InkPalette.CINNABAR;
  }

  build() {
    Column() {
      // 头部标题栏
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor(InkPalette.INK)
        }
        .width(InkLayout.MIN_TOUCH_TARGET)
        .height(InkLayout.MIN_TOUCH_TARGET)
        .borderRadius(InkRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { router.back() })

        Text('用户隐私与协议')
          .fontSize(InkTypography.TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)
          .position({ left: '50%' })
          .translate({ x: '-50%' })
      }
      .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
      .width('100%')
      .height(InkLayout.HEADER_HEIGHT)
      .margin({ top: this.topRectHeight })

      // 内容区域
      Scroll() {
        Column({ space: InkSpacing.LG }) {
          Column({ space: InkSpacing.MD }) {
            ForEach(this.rowsData, (item: string) => {
              Row() {
                // 精致的莫兰迪色圆点
                Row()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(this.getMainColor())
                  .margin({ right: InkSpacing.MD, top: 8 })
                  .alignSelf(ItemAlign.Start)

                Text(item)
                  .fontSize(InkTypography.BODY)
                  .fontColor(InkPalette.INK_LIGHT)
                  .lineHeight(22)
                  .layoutWeight(1)
              }
              .width("100%")
              .alignItems(VerticalAlign.Top)
            })
          }
          .borderRadius(InkRadius.CARD)
          .backgroundColor(Color.White)
          .padding(InkSpacing.LG)
          .width("100%")
          .shadow(InkShadow.SUBTLE)

          Blank(InkSpacing.XXL)
        }
        .padding({
          left: InkSpacing.PAGE_HORIZONTAL,
          right: InkSpacing.PAGE_HORIZONTAL,
          top: InkSpacing.LG,
          bottom: this.bottomRectHeight + InkSpacing.XXL
        })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
    .height("100%")
    .width("100%")
    .backgroundColor(InkPalette.PAPER_EMBEDDED)
  }
}