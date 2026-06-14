import { router } from '@kit.ArkUI'
import { ThemeStorageKey } from '../../common/constants/Theme'
import { ThemeItem } from '../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../common/constants/DesignTokens'

@Component
export struct MyCenterTitle {
  @Prop title: string

  // 是否显示编辑按钮
  isShowEdit?: boolean = false
  // 是否显示菜单
  isShowMore?: boolean = false

  // 编辑标题按钮事件
  onEditClickEvent?: (event: ClickEvent) => void
  
  @StorageLink("onSelect") onSelect: number = 0
  @StorageProp('topRectHeight') topRectHeight: number = 0

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
      // 头部标题栏 Row
      Row() {
        Row() {
          Image($r("app.media.ic_public_return_left"))
            .width(24)
            .height(24)
            .fillColor(InkPalette.INK)
        }
        .width(InkLayout.MIN_TOUCH_TARGET)
        .height(InkLayout.MIN_TOUCH_TARGET)
        .borderRadius(InkRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          router.back()
        })

        Row() {
          Row() {
            if (this.isShowEdit) {
              Blank(24)
                .margin({ right: InkSpacing.SM })
            }

            Text(this.title)
              .fontSize(InkTypography.TITLE)
              .fontWeight(FontWeight.Medium)
              .fontColor(InkPalette.INK)
              .textAlign(TextAlign.Center)

            if (this.isShowEdit) {
              Image($r("app.media.ic_public_edit"))
                .size({ width: 16, height: 16 })
                .margin({ left: InkSpacing.SM })
                .fillColor(this.getMainColor())
                .onClick(this.onEditClickEvent)
            }
          }
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)

        if (this.isShowMore) {
          Row() {
            Image($r("app.media.more_vertical"))
              .width(24)
              .height(24)
              .fillColor(InkPalette.INK_FAINT)
          }
          .width(InkLayout.MIN_TOUCH_TARGET)
          .height(InkLayout.MIN_TOUCH_TARGET)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .bindMenu(this.menu)
        } else {
          Blank(24)
        }
      }
      .width("100%")
      .height(InkLayout.HEADER_HEIGHT)
      .margin({ top: this.topRectHeight })
    }
  }

  @Builder menu() {
    Column() {
      Menu() {
        MenuItemGroup() {
          MenuItem(this.menuItemUi("按时间排序", 0))
          MenuItem(this.menuItemUi("按名称排序", 1))
          MenuItem(this.menuItemUi("按大小排序", 2))
        }
        MenuItem(this.logout())
      }
      .radius(InkRadius.CARD)
      .backgroundColor(InkPalette.PAPER)
    }
  }

  @Builder menuItemUi(text: string, index: number) {
    Row() {
      Row() {
        Text(text)
          .fontSize(InkTypography.BODY)
          .fontWeight(this.onSelect === index ? FontWeight.Medium : FontWeight.Normal)
          .fontColor(index === this.onSelect ? this.getMainColor() : InkPalette.INK)
          .layoutWeight(1)
        if (this.onSelect === index) {
          Image($r("app.media.ic_public_confirm"))
            .height(18)
            .width(18)
            .fillColor(this.getMainColor())
        }
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)
    }
    .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
    .height(44)
    .onClick(() => {
      this.onSelect = index
    })
  }

  @Builder logout() {
    Row() {
      Row() {
        Image($r("sys.media.ohos_ic_public_remove"))
          .height(18)
          .width(18)
          .fillColor(InkPalette.ERROR)
          .margin({ right: InkSpacing.SM })
        Text("退出登录")
          .fontSize(InkTypography.BODY)
          .fontColor(InkPalette.ERROR)
      }
      .alignItems(VerticalAlign.Center)
    }
    .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
    .height(44)
  }
}