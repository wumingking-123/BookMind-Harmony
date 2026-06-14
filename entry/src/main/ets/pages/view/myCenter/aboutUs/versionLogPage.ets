import { router } from '@kit.ArkUI';
import { ThemeStorageKey } from '../../../../common/constants/Theme';
import { ThemeItem } from '../../../../common/model/Theme';
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../../common/constants/DesignTokens';

@Entry
@Component
struct VersionLogPage {
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @State List: Array<string> = [
    '更新icon图标',
    '关于我们-QQ群增加Beta群',
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

        Text('版本更新日志')
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

      Scroll() {
        Column({ space: InkSpacing.LG }) {
          this.versionCard("V1.0.0.1", "2024/9/8", this.List)
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

  @Builder
  versionCard(version: string, date: string, updateInfo: Array<string>) {
    Column() {
      Row() {
        Row()
          .width(4)
          .height(16)
          .borderRadius(2)
          .backgroundColor(this.getMainColor())
          .margin({ right: InkSpacing.SM })
        Text(version)
          .fontSize(InkTypography.TITLE_SMALL)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)
        Blank()
        Text(date)
          .fontSize(InkTypography.CAPTION)
          .fontColor(InkPalette.INK_MIST)
      }
      .margin({ bottom: InkSpacing.MD })
      .width("100%")

      Column({ space: InkSpacing.SM }) {
        ForEach(updateInfo, (item: string) => {
          Row() {
            Text(`• ${item}`)
              .fontSize(InkTypography.BODY_SMALL)
              .fontColor(InkPalette.INK_LIGHT)
              .lineHeight(18)
          }
          .width("100%")
        })
      }
      .alignItems(HorizontalAlign.Start)
      .width("100%")
    }
    .borderRadius(InkRadius.CARD)
    .backgroundColor(Color.White)
    .padding(InkSpacing.LG)
    .width("100%")
    .shadow(InkShadow.SUBTLE)
  }
}