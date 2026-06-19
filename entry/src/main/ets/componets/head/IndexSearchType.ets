import CommonConstants from '../../common/constants/CommonConstants'
import FontConstants from '../../common/constants/FontConstants'
import PaddingConstants from '../../common/constants/PaddingConstants'
import { ThemeStorageKey } from '../../common/constants/Theme'
import { ThemeItem } from '../../common/model/Theme'
import { BOOK_SEARCH_TYPE } from '../../database/entities/Books'
import { InkPalette, InkTypography, InkSpacing, InkRadius } from '../../common/constants/DesignTokens'

@Component
export default struct IndexSearchType {
  @Prop title:string
  @Link searchValue:string
  @State isShown: boolean = false
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  build() {
    if (BOOK_SEARCH_TYPE.includes(this.title)){
      Row(
        {
          space: 4
        }
      ) {
        Text(this.title)
          .fontColor(this.searchValue === this.title ? InkPalette.INK : InkPalette.INK_LIGHT)
          .fontSize(InkTypography.BODY)
          .fontWeight(this.searchValue === this.title ? FontWeight.Medium : FontWeight.Normal)
          .animation({ duration: 200, curve: Curve.EaseOut })
        Image(this.isShown ? $r('app.media.direction_upper') : $r('app.media.direction_down'))
          .width(14).height(14)
          .opacity(this.title === this.searchValue ? 1 : 0.3)
      }
      .onClick(() => {
        this.searchValue = this.title
        this.isShown = !this.isShown
      })
      .bindPopup(this.isShown, {
        builder: this.MenuBuilder(),
        placement: Placement.Bottom,
        enableArrow: true,
        radius: InkRadius.MD,
        popupColor: InkPalette.PAPER,
        onStateChange: (e) => {
          if (!e.isVisible) {
            this.isShown = false;
          }
        }
      })
    } else {
      Row(
        {
          space: 4
        }
      ) {
        Text(this.title)
          .fontColor(this.searchValue === this.title ? InkPalette.INK : InkPalette.INK_LIGHT)
          .fontSize(InkTypography.BODY)
          .fontWeight(this.searchValue === this.title ? FontWeight.Medium : FontWeight.Normal)
          .animation({ duration: 200, curve: Curve.EaseOut })
      }
      .onClick(() => {
        // Allow clicking title to be selected directly if not a dropdown
        this.searchValue = this.title
      })
    }

  }

  @Builder MenuBuilder() {
    Column() {
      ForEach(BOOK_SEARCH_TYPE, (item:string, index) => {
        Column() {
          Row() {
            Text(item)
              .fontSize(InkTypography.BODY)
              .fontWeight(this.searchValue === item ? FontWeight.Medium : FontWeight.Normal)
              .fontColor(this.searchValue === item ? this.theme.mainColor : InkPalette.INK)
            if (item === this.searchValue) {
              Image($r('app.media.hook')).width(16).height(16)
            }
          }
          .padding({
            top: InkSpacing.MD,
            bottom: InkSpacing.MD,
            left: InkSpacing.LG,
            right: InkSpacing.LG
          })
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .align(Alignment.Center)
          .onClick(() => {
            this.title = item
            this.searchValue = item
            this.isShown = false
          })
          if (index != BOOK_SEARCH_TYPE.length - 1) {
            Divider().width('85%').color(InkPalette.PAPER_DEEP)
          }
        }
      })
    }
    .padding({ top: InkSpacing.XS, bottom: InkSpacing.XS })
    .width(140)
    .backgroundColor(InkPalette.PAPER)
    .borderRadius(InkRadius.MD)
  }
}