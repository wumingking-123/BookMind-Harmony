import { dataItem } from 'ets/componets/dataList/dataItem';
import VersionUpdateCustomDialog from 'ets/componets/aboutUs/VersionUpdate';
import { router } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';
import { productViewManager } from '@kit.StoreKit';
import { ThemeStorageKey } from '../../../../common/constants/Theme';
import { ThemeItem } from '../../../../common/model/Theme';
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../../common/constants/DesignTokens';

@Entry
@Component
struct AboutUsPage {
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @State isShowQQ: boolean = false
  @State version: string = "1.0.0"
  @State first_list: dataItem[] = [
    new dataItem("检查更新", 1),
    new dataItem("更新日志", 2),
    new dataItem("开发人员", 3),
  ];
  @State end_list: dataItem[] = [
    new dataItem("用户隐私与协议", 1),
    new dataItem("开源许可", 2),
    new dataItem("免责声明", 3),
    new dataItem("崩溃日志", 4),
  ]
  
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  // 升级弹窗
  dialogController: CustomDialogController = new CustomDialogController({
    builder: VersionUpdateCustomDialog({}),
    cornerRadius: InkRadius.DIALOG,
    gridCount: 3,
    alignment: DialogAlignment.Center,
  })
  @State qqList: Array<string> = [
    'Beta群:887615035'
  ]

  getMainColor(): string {
    return this.theme?.mainColor || InkPalette.CINNABAR;
  }

  getSecondColor(): string {
    return this.theme?.secondColor || InkPalette.PAPER_WARM;
  }

  // 空的实现


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

        Text('关于我们')
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
          // Logo/应用图标及版本信息
          Column({ space: InkSpacing.SM }) {
            Image($r('app.media.app_icon'))
              .width(84)
              .height(84)
              .borderRadius(InkRadius.LG)
              .shadow(InkShadow.SOFT)
              .margin({ bottom: InkSpacing.SM })
              
            Text('鸿蒙阅读')
              .fontSize(InkTypography.TITLE_LARGE)
              .fontWeight(FontWeight.Bold)
              .fontColor(InkPalette.INK)
              
            Text(`版本号: ${this.version}`)
              .fontSize(InkTypography.BODY_SMALL)
              .fontColor(InkPalette.INK_MIST)
          }
          .width('100%')
          .padding({ top: InkSpacing.XXL, bottom: InkSpacing.LG })
          .alignItems(HorizontalAlign.Center)

          // 开发人员信息
          Column({ space: InkSpacing.MD }) {
            Text('开发人员')
              .fontSize(InkTypography.TITLE_SMALL)
              .fontWeight(FontWeight.Medium)
              .fontColor(InkPalette.INK)
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ bottom: InkSpacing.XS })

            Row({ space: InkSpacing.XL }) {
              Column({ space: InkSpacing.XS }) {
                Image($r('app.media.avatar_wang'))
                  .width(64)
                  .height(64)
                  .borderRadius(InkRadius.FULL)
                  .backgroundColor(this.theme?.secondColor || InkPalette.PAPER_WARM)
                Text('王振祎')
                  .fontSize(InkTypography.BODY)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(InkPalette.INK)
              }
              .alignItems(HorizontalAlign.Center)

              Column({ space: InkSpacing.XS }) {
                Image($r('app.media.avatar_huang'))
                  .width(64)
                  .height(64)
                  .borderRadius(InkRadius.FULL)
                  .backgroundColor(this.theme?.secondColor || InkPalette.PAPER_WARM)
                Text('黄俊杰')
                  .fontSize(InkTypography.BODY)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(InkPalette.INK)
              }
              .alignItems(HorizontalAlign.Center)
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
          }
          .width('100%')
          .padding(InkSpacing.XL)
          .backgroundColor(Color.White)
          .borderRadius(InkRadius.CARD)
          .shadow(InkShadow.SUBTLE)

          Blank(InkSpacing.MASSIVE)
        }
        .padding({
          left: InkSpacing.PAGE_HORIZONTAL,
          right: InkSpacing.PAGE_HORIZONTAL,
          bottom: this.bottomRectHeight + InkSpacing.XXL
        })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(InkPalette.PAPER_EMBEDDED)
  }

  // 移除旧的 builder

}
