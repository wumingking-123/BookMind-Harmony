/**
 * @author 2008
 * @datetime 2024/7/14 19:54
 * @className: FindContent
 * 发现页内容组件 — 搜索栏 + 内容区
 */
import { router } from '@kit.ArkUI'
import BodyContent from './BodyContent'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow
} from '../../../../common/constants/DesignTokens'

@Component
export default struct FindContent {
  @Prop currentIndex: number

  build() {
    Column({ space: InkSpacing.SM }) {
      // 搜索栏 — 墨韵风格，大圆角 + 柔和阴影
      Row({ space: InkSpacing.SM }) {
        Image($r('app.media.search'))
          .width(18)
          .height(18)
          .fillColor(InkPalette.INK_MIST)

        Text('搜索书名或作者')
          .fontSize(InkTypography.BODY)
          .fontColor(InkPalette.INK_MIST)
          .layoutWeight(1)
      }
      .height(44)
      .borderRadius(InkRadius.SEARCH)
      .backgroundColor(InkPalette.PAPER_PURE)
      .shadow(InkShadow.SUBTLE)
      .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
      .margin({ left: InkSpacing.PAGE_HORIZONTAL, right: InkSpacing.PAGE_HORIZONTAL })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/view/search/SearchBook'
        })
      })

      // 内容区
      BodyContent({ currentIndex: this.currentIndex })
    }
  }
}
