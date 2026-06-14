import { ThemeStorageKey } from '../../common/constants/Theme'
import { ThemeItem } from '../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkMotion, InkRadius
} from '../../common/constants/DesignTokens'

@Component
export default struct BookMark {
  isBackground: boolean = true
  @Prop title: string
  @Prop currentIndex: number
  @Prop index: number

  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  build() {
    Column({ space: 6 }) {
      Text(this.title)
        .fontSize(this.currentIndex === this.index ? InkTypography.TITLE_SMALL : InkTypography.BODY)
        .fontWeight(this.currentIndex === this.index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentIndex === this.index ? InkPalette.INK : InkPalette.INK_MIST)
        .animation({ duration: InkMotion.FAST, curve: Curve.EaseOut })

      // 活跃指示器 — 圆角胶囊
      Row()
        .width(this.currentIndex === this.index ? 20 : 0)
        .height(3)
        .borderRadius(InkRadius.TAB_INDICATOR)
        .backgroundColor(this.theme.mainColor)
        .animation({ duration: InkMotion.NORMAL, curve: Curve.EaseOut })
    }
    .padding({ left: InkSpacing.MD, right: InkSpacing.MD, top: InkSpacing.XS, bottom: InkSpacing.XS })
    .alignItems(HorizontalAlign.Center)
    .margin(this.index !== 0 ? { left: InkSpacing.XS } : {})
  }
}
