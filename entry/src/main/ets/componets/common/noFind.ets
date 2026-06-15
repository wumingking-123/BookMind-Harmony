/**
 * @className: noFind
 * 公用暂无相关内容 — 墨韵风格空状态
 * 支持3种场景：暂无内容 / 网络异常 / 加载失败
 */
import { ThemeStorageKey } from '../../common/constants/Theme'
import { ThemeItem } from '../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow
} from '../../common/constants/DesignTokens'

@Component
export default struct noFind {
  @Prop hintIndex: number = 0
  hintMessage: string[] = ['暂无相关内容', '网络异常，请检查后重试', '内容加载失败，请刷新重试']
  hintSubMessage: string[] = ['去探索更多精彩内容吧', '请检查网络连接后重试', '下拉页面即可刷新']
  hintIcon: Resource[] = [
    $r('app.media.icon_no_source_find'),
    $r('app.media.icon_no_source_find'),
    $r('app.media.icon_no_source_find')
  ]
  onclick: () => void = () => {}
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  build() {
    Column({ space: InkSpacing.LG }) {
      // 图标 — 带柔和背景圆
      Stack({ alignContent: Alignment.Center }) {
        // 背景圆
        Row()
          .width(120)
          .height(120)
          .borderRadius(InkRadius.FULL)
          .backgroundColor(this.theme.secondColor)

        // 图标
        Image(this.hintIcon[this.hintIndex])
          .width(80)
          .height(80)
          .opacity(0.8)
      }
      .width(120)
      .height(120)

      // 主提示文字
      Text(this.hintMessage[this.hintIndex])
        .fontSize(InkTypography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK_LIGHT)
        .textAlign(TextAlign.Center)

      // 副提示文字
      Text(this.hintSubMessage[this.hintIndex])
        .fontSize(InkTypography.CAPTION)
        .fontColor(InkPalette.INK_MIST)
        .textAlign(TextAlign.Center)
        .width(240)

      // 重试按钮 (仅网络异常和加载失败时显示)
      if (this.hintIndex !== 0) {
        Button('重试')
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .width(120)
          .height(44)
          .borderRadius(InkRadius.BUTTON_LARGE)
          .backgroundColor(this.theme.mainColor)
          .shadow(InkShadow.SOFT)
          .onClick(() => {
            this.onclick()
          })
      }
    }
    .height('100%')
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
