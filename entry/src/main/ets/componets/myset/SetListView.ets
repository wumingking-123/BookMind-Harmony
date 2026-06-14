import { SetList } from '../dataList/SetListGroup'
import { ThemeStorageKey } from '../../common/constants/Theme'
import { ThemeItem } from '../../common/model/Theme'
import { InkPalette, InkTypography, InkSpacing, InkRadius } from '../../common/constants/DesignTokens'

@Component
export struct SetListView {
  topLeft: number = 0
  topRight: number = 0
  bottomLeft: number = 0
  bottomRight: number = 0

  @ObjectLink setList: SetList
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  build() {
    Row() {
      if (this.setList.bottomText != null && this.setList.bottomText.length > 0) {
        Column() {
          Text(this.setList.value)
            .fontSize(InkTypography.BODY)
            .fontColor(InkPalette.INK)
            .margin({ bottom: InkSpacing.XS })
            .width('100%')
          Text(this.setList.bottomText)
            .fontSize(InkTypography.CAPTION)
            .fontColor(InkPalette.INK_GHOST)
            .width('100%')
        }
        .width('75%')
        .alignItems(HorizontalAlign.Start)
      } else {
        Text(this.setList.value)
          .fontSize(InkTypography.BODY)
          .fontColor(InkPalette.INK)
          .id('text')
      }

      Row() {
        if (this.setList.rightText != null && this.setList.rightText.length > 0) {
          Text(this.setList.rightText)
            .fontSize(InkTypography.BODY_SMALL)
            .fontColor(InkPalette.INK_LIGHT)
            .margin({ right: InkSpacing.SM })
        }

        if (this.setList.showArrow) {
          Image($r("app.media.right"))
            .size({ width: 20, height: 20 })
            .fillColor(InkPalette.INK_MIST)
        } else {
          Toggle({ type: ToggleType.Switch, isOn: this.setList.toggleStatus })
            .selectedColor(this.theme.mainColor || InkPalette.CINNABAR)
            .hoverEffect(HoverEffect.None)
            .onChange((isOn: boolean) => {
              this.setList.toggleStatus = isOn
              if (this.setList.storageName) {
                AppStorage.setOrCreate(this.setList.storageName, isOn)
              }
            })
        }
      }
      .alignItems(VerticalAlign.Center)

    }
    .width("100%")
    .backgroundColor(Color.Transparent)
    .padding({ left: InkSpacing.LG, right: InkSpacing.LG, top: InkSpacing.MD, bottom: InkSpacing.MD })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .borderRadius({ topLeft: this.topLeft, topRight: this.topRight, bottomLeft: this.bottomLeft, bottomRight: this.bottomRight })
    .onChildTouchTest((touchinfo) => { // 将事件交给text处理，text不处理将由自己处理
      return { id: 'text', strategy: TouchTestStrategy.FORWARD }
    })
  }
}