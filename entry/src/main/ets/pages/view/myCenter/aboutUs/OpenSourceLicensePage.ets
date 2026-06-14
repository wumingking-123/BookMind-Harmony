import { router } from '@kit.ArkUI';
import { ThemeStorageKey } from '../../../../common/constants/Theme';
import { ThemeItem } from '../../../../common/model/Theme';
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../../common/constants/DesignTokens';

@Entry
@Component
struct OpenSourceLicensePage {
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @State rowsData: Array<string> = [
    'GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007',
    'Copyright (C) 2007 Free Software Foundation, Inc. https://fsf.org/ Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it is not allowed.',
    'Preamble',
    'The GNU General Public License is a free, copyleft license for software and other kinds of works.',
    'The licenses for most software and other practical works are designed to take away your freedom to share and change the works. By contrast, the GNU General Public License is intended to guarantee your freedom to share and change all versions of a program--to make sure it remains free software for all its users. We, the Free Software Foundation, use the GNU General Public License for most of our software; it applies also to any other work released this way by its authors. You can apply it to your programs, too.',
    'When we speak of free software, we are referring to freedom, not price. Our General Public Licenses are designed to make sure that you have the freedom to distribute copies of free software (and charge for them if you wish), that you receive source code or can get it if you want it, that you can change the software or use pieces of it in new free programs, and that you know you can do these things.',
    'To protect your rights, we need to prevent others from denying you these rights or asking you to surrender the rights. Therefore, you have certain responsibilities if you distribute copies of the software, or if you modify it: responsibilities to respect the freedom of others.',
    'For example, if you distribute copies of such a program, whether gratis or for a fee, you must pass on to the recipients the same freedoms that you received. You must make sure that they, too, receive or can get the source code. And you must show them these terms so they know their rights.',
    'Developers that use the GNU GPL protect your rights with two steps: (1) assert copyright on the software, and (2) offer you this License giving you legal permission to copy, distribute and/or modify it.',
    'For the developers\' and authors\' protection, the GPL clearly explains that there is no warranty for this free software. For both users\' and authors\' sake, the GPL requires that modified versions be marked as changed, so that their problems will not be attributed erroneously to authors of previous versions.',
    'Some devices are designed to deny users access to install or run modified versions of the software inside them, although the manufacturer can do so. This is fundamentally incompatible with the aim of protecting users\' freedom to change the software. The systematic pattern of such abuse occurs in the area of products for individuals to use, which is precisely where it is most unacceptable. Therefore, we have designed this version of the GPL to prohibit the practice for those products. If such problems arise substantially in other domains, we stand ready to extend this provision to those domains in future versions of the GPL, as needed to protect the freedom of users.',
  ]
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

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

        Text('开源许可')
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

      // 可滚动的内容区域
      Scroll() {
        Column({ space: InkSpacing.LG }) {
          Column({ space: InkSpacing.MD }) {
            ForEach(this.rowsData, (item: string, index: number) => {
              Row() {
                Text(item)
                  .fontSize(index === 0 || index === 2 ? InkTypography.TITLE_SMALL : InkTypography.BODY)
                  .fontWeight(index === 0 || index === 2 ? FontWeight.Medium : FontWeight.Normal)
                  .fontColor(index === 0 || index === 2 ? InkPalette.INK : InkPalette.INK_LIGHT)
                  .lineHeight(24)
              }
              .width("100%")
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