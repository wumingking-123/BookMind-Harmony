/**
 * @className: noSourceFind
 * 公用无发现功能 — 墨韵风格空状态
 */
import { ThemeStorageKey } from '../../common/constants/Theme'
import { ThemeItem } from '../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow
} from '../../common/constants/DesignTokens'

@Component
export default struct noSourceFind {
  @Prop title: string = '该书源暂无发现功能，请切换至其他书源吧'
  @Prop isShowButton: boolean = false
  setOnclick: () => void = () => {}
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  build() {
    Column({ space: InkSpacing.LG }) {
      // 图标 — 带柔和背景圆
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(120)
          .height(120)
          .borderRadius(InkRadius.FULL)
          .backgroundColor(this.theme.secondColor)

        Image($r('app.media.icon_no_source_find'))
          .width(80)
          .height(80)
          .opacity(0.8)
      }
      .width(120)
      .height(120)

      // 提示文字
      Text(this.title)
        .fontSize(InkTypography.BODY)
        .fontColor(InkPalette.INK_LIGHT)
        .textAlign(TextAlign.Center)
        .width(260)
        .lineHeight(InkTypography.LINE_HEIGHT_RELAXED * InkTypography.BODY)

      // 一键隐藏按钮
      if (!this.isShowButton) {
        Button('一键隐藏')
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .width(120)
          .height(44)
          .borderRadius(InkRadius.BUTTON_LARGE)
          .backgroundColor(this.theme.mainColor)
          .shadow(InkShadow.SOFT)
          .onClick(() => {
            this.setOnclick()
          })
      }
    }
    .width('100%')
    .padding({ top: InkSpacing.MASSIVE, bottom: InkSpacing.MASSIVE })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
