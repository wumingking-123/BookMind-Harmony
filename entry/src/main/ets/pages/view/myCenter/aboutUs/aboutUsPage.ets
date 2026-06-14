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
  @State version: string = "V1.0.0.1"
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

  firstUrl_list(value: number | string) {
    switch (value) {
      case 0:
        try {
          const request: Want = {
            parameters: {
              bundleName: 'com.legado.app'
            }
          };
          productViewManager.loadProduct(getContext(this) as common.UIAbilityContext, request, {
            onError: (error: BusinessError) => {
              hilog.info(0, 'TAG', `loadProduct onError. code is ${error.code}, message is ${error.message}`);
            }
          });
        } catch (err) {
          const error = err as BusinessError;
          hilog.error(0, 'TAG', `loadProduct failed. code is ${error.code}, message is ${error.message}`);
        }
        break
      case 1:
        router.pushUrl({
          url: "pages/view/myCenter/aboutUs/versionLogPage"
        })
        break
      case 2:
        break
    }
  }

  endUrl_list(value: number | string) {
    switch (value) {
      case 0:
        router.pushUrl({
          url: "pages/view/myCenter/aboutUs/PrivacyAgreementPage"
        })
        break
      case 1:
        router.pushUrl({
          url: "pages/view/myCenter/aboutUs/OpenSourceLicensePage"
        })
        break
      case 2:
        router.pushUrl({
          url: "pages/view/myCenter/aboutUs/DisclaimerPage"
        })
        break
      case 3:
        break
    }
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
              .width(72)
              .height(72)
              .borderRadius(InkRadius.LG)
              .shadow(InkShadow.SOFT)
            Text('鸿蒙阅读')
              .fontSize(InkTypography.TITLE)
              .fontWeight(FontWeight.Medium)
              .fontColor(InkPalette.INK)
            Text(`版本号: ${this.version}`)
              .fontSize(InkTypography.CAPTION)
              .fontColor(InkPalette.INK_MIST)
          }
          .width('100%')
          .padding({ top: InkSpacing.XL, bottom: InkSpacing.LG })
          .alignItems(HorizontalAlign.Center)

          // 第一组设置
          this.middleClick(this.first_list, "app.media.ic_public_right", this.version, "first")

          // 社交媒体等卡片网格
          Grid() {
            GridItem() {
              this.middleBox(0, "app.media.official_website", "官网")
            }

            GridItem() {
              this.middleBox(1, "app.media.wechat_public_account", "公众号")
            }

            GridItem() {
              this.middleBox(2, "app.media.channel", "QQ频道")
            }

            GridItem() {
              this.middleBox(3, "app.media.QQ", "QQ群")
            }
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .columnsGap(InkSpacing.MD)
          .height(84)
          .width('100%')
          .bindSheet($$this.isShowQQ, this.QQDialog(), {
            height: 280,
            showClose: false,
            dragBar: false,
            backgroundColor: InkPalette.PAPER
          })

          // 第二组设置
          this.middleClick(this.end_list, "app.media.ic_public_right", null, "end")

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

  @Builder
  middleBox(index: number, image: string, text: string) {
    Column({ space: InkSpacing.XS }) {
      Image($r(`${image}`))
        .size({ width: 24, height: 24 })
        .fillColor(this.getMainColor())
      Text(text)
        .maxLines(1)
        .fontSize(InkTypography.CAPTION)
        .fontColor(InkPalette.INK_LIGHT)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width("100%")
    .height(72)
    .borderRadius(InkRadius.CARD)
    .backgroundColor(Color.White)
    .shadow(InkShadow.SUBTLE)
    .onClick(() => {
      switch (index) {
        case 0:
          break
        case 1:
          break
        case 2:
          break
        case 3:
          this.isShowQQ = true
          break
      }
    })
  }

  @Builder
  middleClick(list: Array<dataItem>, image: string, version: string | null, urlList: string) {
    Column() {
      ForEach(list, (item: dataItem, index) => {
        Column() {
          Row() {
            Text(item.title)
              .fontSize(InkTypography.BODY)
              .fontColor(InkPalette.INK)
            Blank()
            if (version && index === 0) {
              Text(version)
                .fontSize(InkTypography.BODY_SMALL)
                .fontColor(InkPalette.INK_MIST)
                .margin({ right: InkSpacing.XS })
            }
            Image($r(`${image}`))
              .size({ width: 18, height: 18 })
              .fillColor(InkPalette.INK_WHISPER)
          }
          .width("100%")
          .height(InkLayout.MIN_TOUCH_TARGET)
          .onClick(() => {
            switch (urlList) {
              case 'first':
                this.firstUrl_list(index)
                break
              case 'end':
                this.endUrl_list(index)
                break
            }
          })

          if (index < list.length - 1) {
            Divider()
              .color(InkPalette.PAPER_WARM)
              .strokeWidth(0.5)
          }
        }
      })
    }
    .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
    .backgroundColor(Color.White)
    .borderRadius(InkRadius.CARD)
    .shadow(InkShadow.SUBTLE)
  }

  @Builder
  QQDialog() {
    Column() {
      Row()
        .width(32)
        .height(4)
        .borderRadius(2)
        .backgroundColor(InkPalette.INK_MIST)
        .margin({ top: InkSpacing.MD })

      Text("QQ群")
        .fontSize(InkTypography.TITLE_SMALL)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK)
        .width("100%")
        .textAlign(TextAlign.Center)
        .padding({ top: InkSpacing.LG, bottom: InkSpacing.MD })

      List() {
        ForEach(this.qqList, (item: string) => {
          ListItem() {
            Row() {
              Text(item)
                .fontSize(InkTypography.BODY)
                .fontColor(InkPalette.INK)
              Blank()
              Image($r('app.media.ic_public_right'))
                .width(18)
                .height(18)
                .fillColor(InkPalette.INK_WHISPER)
            }
            .width('100%')
            .height(InkLayout.MIN_TOUCH_TARGET)
            .padding({ left: InkSpacing.XL, right: InkSpacing.XL })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)

      Divider()
        .color(InkPalette.PAPER_WARM)

      Text('取消')
        .fontSize(InkTypography.BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK_GHOST)
        .width('100%')
        .textAlign(TextAlign.Center)
        .height(InkLayout.MIN_TOUCH_TARGET)
        .alignSelf(ItemAlign.Center)
        .onClick(() => {
          this.isShowQQ = false
        })
    }
    .width("100%")
    .height(280)
    .backgroundColor(InkPalette.PAPER)
  }
}
