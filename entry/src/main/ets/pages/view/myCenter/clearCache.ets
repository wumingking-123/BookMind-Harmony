import { PublicConstants } from '../../../common/constants/PublicConstants'
import { ColumnModifier } from '../../../common/utils/ComponetModifier'
import { dataItem } from '../../../componets/dataList/dataItem'
import { MyCenterTitle } from '../../../componets/myCenter/MyCenterTitle'
import { ThemeStorageKey } from '../../../common/constants/Theme'
import { ThemeItem } from '../../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../common/constants/DesignTokens'

@Entry
@Component
struct clearCache {
  @State clearList: dataItem[] = [
    new dataItem("系统缓存", 34.35),
    new dataItem("小说缓存", 34.35),
    new dataItem("漫画缓存", 34.35),
    new dataItem("听书缓存", 34.35),
    new dataItem("字体缓存", 34.35),
  ]
  @State @Watch("ClearChange") clearDialogStatus: boolean = false
  @State index: number = 0
  
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
      // 标题栏
      MyCenterTitle({ title: "清理缓存" })

      Scroll() {
        Column({ space: InkSpacing.LG }) {
          Column() {
            ForEach(this.clearList, (item: dataItem, index: number) => {
              Column() {
                Row() {
                  Text(item.title)
                    .fontSize(InkTypography.BODY)
                    .fontColor(InkPalette.INK)
                    .layoutWeight(1)
                  
                  Text(item.value + " MB")
                    .fontSize(InkTypography.BODY_SMALL)
                    .fontColor(InkPalette.INK_MIST)
                    .margin({ right: InkSpacing.SM })

                  Image($r("app.media.ic_public_right"))
                    .size({ width: 18, height: 18 })
                    .fillColor(InkPalette.INK_WHISPER)
                }
                .width("100%")
                .height(InkLayout.MIN_TOUCH_TARGET)
                .onClick(() => {
                  this.index = index
                  this.clearDialogStatus = true
                })

                if (index < this.clearList.length - 1) {
                  Divider()
                    .color(InkPalette.PAPER_WARM)
                    .strokeWidth(0.5)
                }
              }
            })
          }
          .backgroundColor(Color.White)
          .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
          .borderRadius(InkRadius.CARD)
          .shadow(InkShadow.SUBTLE)
          .width("100%")
        }
        .padding({
          left: InkSpacing.PAGE_HORIZONTAL,
          right: InkSpacing.PAGE_HORIZONTAL,
          top: InkSpacing.LG,
          bottom: InkSpacing.XXL
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width("100%")
    .height("100%")
    .backgroundColor(InkPalette.PAPER_EMBEDDED)
  }

  // 弹窗关闭
  exitApp() {
    this.clearDialogStatus = false
  }
  onCancel() {
    this.clearDialogStatus = false
  }

  onAccept(index: number) {
    console.log(index.toString());
    this.clear(index)
    this.clearDialogStatus = false
  }
  
  ClearChange() {
    if (this.clearDialogStatus) {
      this.clearInfoDel?.open()
    }
  }

  @Builder
  confirmDialogBuilder() {
    Column({ space: InkSpacing.XL }) {
      Text('确认清除缓存吗？')
        .fontSize(InkTypography.TITLE_SMALL)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK)

      Text('清除缓存后可能需要重新加载部分内容。')
        .fontSize(InkTypography.BODY)
        .fontColor(InkPalette.INK_GHOST)

      Row({ space: InkSpacing.MD }) {
        Button('取消')
          .fontSize(InkTypography.BODY)
          .fontColor(this.getMainColor())
          .backgroundColor(this.getSecondColor())
          .onClick(() => { this.onCancel() })
          .width(112)
          .height(40)
          .borderRadius(InkRadius.BUTTON_LARGE)

        Button('确认')
          .fontSize(InkTypography.BODY)
          .fontColor(Color.White)
          .backgroundColor(this.getMainColor())
          .onClick(() => { this.onAccept(this.index) })
          .width(112)
          .height(40)
          .borderRadius(InkRadius.BUTTON_LARGE)
      }
      .justifyContent(FlexAlign.Center)
    }
    .padding(InkSpacing.XXL)
    .width(280)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(InkPalette.PAPER)
    .borderRadius(InkRadius.DIALOG)
    .shadow(InkShadow.FLOATING)
  }

  clearInfoDel: CustomDialogController | null = new CustomDialogController({
    builder: this.confirmDialogBuilder(),
    cancel: this.exitApp,
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  })

  // 清除方法
  clear(index: number) {
    switch (index) {
      case 0:
        console.log("系统缓存");
        break;
      case 1:
        console.log("小说缓存");
        break;
      case 2:
        console.log("漫画缓存");
        break;
      case 3:
        console.log("听书缓存");
        break;
      case 4:
        console.log("字体缓存");
        break;
    }
  }
}