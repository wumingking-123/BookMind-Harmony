import { ThemeStorageKey } from "../../common/constants/Theme"
import { ThemeItem } from "../../common/model/Theme"
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from "../../common/constants/DesignTokens"

@CustomDialog
export default struct VersionUpdateCustomDialog {
  controller: CustomDialogController
  @State clickUpdate: boolean = false
  @State ProgressValue: number = 40
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  getMainColor(): string {
    return this.theme?.mainColor || InkPalette.CINNABAR;
  }

  getSecondColor(): string {
    return this.theme?.secondColor || InkPalette.PAPER_WARM;
  }

  build() {
    Column() {
      Row({ space: InkSpacing.MD }) {
        Text('发现新版本')
          .fontSize(InkTypography.TITLE_LARGE)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)
        Text('v4.1.14')
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getMainColor())
      }
      .padding({
        top: InkSpacing.XXL,
        left: InkSpacing.XXL,
        right: InkSpacing.XXL
      })
      .height(76)
      .width("100%")
      .backgroundImage($r('app.media.versionUpdateBackground'))
      .backgroundImageSize({ width: "100%", height: 76 })

      Column({ space: InkSpacing.SM }) {
        Row() {
          Text("• 首页风格改版，更全面的内容，焕然一新的视觉用户体验")
            .fontSize(InkTypography.BODY_SMALL)
            .fontColor(InkPalette.INK_LIGHT)
        }

        Row() {
          Text("• 优化了动画细节，让产品更流畅。")
            .fontSize(InkTypography.BODY_SMALL)
            .fontColor(InkPalette.INK_LIGHT)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width("100%")
      .padding({
        top: InkSpacing.LG,
        left: InkSpacing.XXL,
        right: InkSpacing.XXL
      })

      if (!this.clickUpdate) {
        Button("立即更新")
          .backgroundColor(this.getMainColor())
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .width("73%")
          .height(44)
          .borderRadius(InkRadius.BUTTON_LARGE)
          .margin({
            top: InkSpacing.XXL,
            bottom: InkSpacing.LG
          })
          .onClick(() => {
            this.clickUpdate = true
          })
      } else {
        Progress({
          value: this.ProgressValue,
          total: 100,
          type: ProgressType.Capsule,
        })
          .style({
            content: `正在更新（${this.ProgressValue}%）`,
            fontColor: "#FFFFFF",
            font: ({
              size: InkTypography.CAPTION,
              weight: FontWeight.Normal,
            })
          })
          .width("73%")
          .height(36)
          .color(this.getMainColor())
          .backgroundColor(this.getSecondColor())
          .margin({
            top: InkSpacing.XXL,
            bottom: InkSpacing.LG
          })
      }

      Text(!this.clickUpdate ? "暂不更新" : "后台下载")
        .fontSize(InkTypography.BODY_SMALL)
        .fontColor(InkPalette.INK_GHOST)
        .margin({
          bottom: InkSpacing.XXL
        })
        .onClick(() => {
          if (!this.clickUpdate) {
            this.controller.close()
          }
        })
    }
    .backgroundColor(InkPalette.PAPER)
    .borderRadius(InkRadius.DIALOG)
    .shadow(InkShadow.FLOATING)
    .width(280)
  }
}