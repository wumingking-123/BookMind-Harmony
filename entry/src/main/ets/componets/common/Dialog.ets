import { ThemeStorageKey } from '../../common/constants/Theme'
import { ThemeItem } from '../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow
} from '../../common/constants/DesignTokens'

@CustomDialog
  // 通用弹窗
export default struct Dialog {
  controller?: CustomDialogController
  @Prop title: string = '标题'
  @Prop CancelString: string = '取消'
  @Prop ConfirmString: string = '确定'
  @BuilderParam child: () => void // 通用组件

  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  build() {
    Column({ space: InkSpacing.LG }) {
      // 标题
      Text(this.title)
        .fontSize(InkTypography.TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK)

      // 内容插槽
      this.child()

      // 操作按钮
      Flex({
        justifyContent: FlexAlign.SpaceEvenly,
        alignItems: ItemAlign.Center
      }) {
        Button() {
          Text(this.CancelString)
            .fontColor(this.theme.mainColor)
            .lineHeight(22)
            .fontSize(InkTypography.BODY)
            .fontWeight(FontWeight.Medium)
        }
        .width(112)
        .height(44)
        .borderRadius(InkRadius.BUTTON_LARGE)
        .backgroundColor(this.theme.secondColor)
        .onClick(() => {
          if (this.controller != undefined) {
            this.controller.close()
          }
        })

        Button() {
          Text(this.ConfirmString)
            .fontColor('#FFFFFF')
            .lineHeight(22)
            .fontSize(InkTypography.BODY)
            .fontWeight(FontWeight.Medium)
        }
        .width(112)
        .height(44)
        .borderRadius(InkRadius.BUTTON_LARGE)
        .backgroundColor(this.theme.mainColor)
        .onClick(() => {

        })
      }
    }
    .padding(InkSpacing.XXL)
  }
}
