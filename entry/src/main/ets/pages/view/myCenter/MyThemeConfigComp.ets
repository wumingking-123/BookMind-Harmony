import { ThemeColor, ThemeStorageKey } from '../../../common/constants/Theme'
import { ThemeItem } from '../../../common/model/Theme'
import { promptAction, router } from '@kit.ArkUI'
import { themeManager } from '../../../common/utils/ThemeManager'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../common/constants/DesignTokens'

// 个性主题组件模块
@Component
export struct MyThemeConfigComp {
  @StorageProp(ThemeStorageKey.THEMEINDEX)
  activeIndex: number = 0 // 被选中的主题
  @State longPressGestureIndex: number = 0 // 长按选中主题

  @StorageProp(ThemeStorageKey.THEMELIST)
  themeList: ThemeItem[] = []

  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  dialog: CustomDialogController = new CustomDialogController({
    builder: this.dialogBuilder,
    customStyle: true,
    alignment: DialogAlignment.Center,
    autoCancel: false
  })

  // 构建自定义弹窗
  @Builder
  dialogBuilder() {
    Column({ space: InkSpacing.XL }) {
      Text('删除主题')
        .fontSize(InkTypography.TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK)

      Text('确定要删除这个主题吗？')
        .fontSize(InkTypography.BODY)
        .fontColor(InkPalette.INK_GHOST)

      Row({ space: InkSpacing.MD }) {
        Button('取消')
          .fontSize(InkTypography.BODY)
          .fontColor(this.theme.mainColor)
          .backgroundColor(this.theme.secondColor)
          .onClick(() => { this.dialog.close() })
          .width(112)
          .height(44)
          .borderRadius(InkRadius.BUTTON_LARGE)

        Button('确定')
          .fontSize(InkTypography.BODY)
          .fontColor(Color.White)
          .backgroundColor(this.theme.mainColor)
          .onClick(() => {
            if (this.themeList.length > 1) {
              themeManager.deleteTheme(this.longPressGestureIndex)
            } else {
              this.getUIContext().getPromptAction().showToast({ message: '至少需要保留一个主题' })
            }
            this.dialog.close()
          })
          .width(112)
          .height(44)
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

  // 构建个性主题下列表元素
  @Builder
  themeItemBuilder(item: ThemeItem, index: number) {
    Column({ space: InkSpacing.SM }) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [[item.mainColor, 0], [item.secondColor, 1]]
          })
          .borderRadius(InkRadius.MD)

        // 使用中标记
        if (this.activeIndex === index) {
          Text('使用中')
            .fontSize(InkTypography.MICRO)
            .fontColor(Color.White)
            .backgroundColor(item.mainColor)
            .textAlign(TextAlign.Center)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius({ topRight: InkRadius.MD, bottomLeft: InkRadius.MD })
            .position({ right: 0, top: 0 })
        }
      }
      .width('100%')
      .height(72)
      .borderRadius(InkRadius.MD)
      .shadow(InkShadow.SUBTLE)

      Text(item.text)
        .fontSize(InkTypography.BODY_SMALL)
        .fontColor(InkPalette.INK)
        .height(20)
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
  }

  build() {
    Column() {
      Grid() {
        // 自定义主题入口
        GridItem() {
          Column({ space: InkSpacing.SM }) {
            Column() {
              Image($r('app.media.my_theme_config_custom'))
                .width(24)
                .height(24)
                .fillColor(InkPalette.INK_MIST)
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .width('100%')
            .height(72)
            .borderRadius(InkRadius.MD)
            .backgroundColor(InkPalette.PAPER_WARM)
            .border({ width: 1, color: InkPalette.PAPER_DEEP, style: BorderStyle.Dashed })

            Text('自定义')
              .fontSize(InkTypography.BODY_SMALL)
              .fontColor(InkPalette.INK_GHOST)
              .height(20)
              .width('100%')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
        }
        .onClick(() => {
          router.pushUrl({
            url: '/pages/view/myCenter/CreateCustomTheme'.slice(1)
          })
        })

        ForEach(this.themeList, (item: ThemeItem, index: number) => {
          GridItem() {
            this.themeItemBuilder(item, index)
          }
          .onClick(() => {
            this.activeIndex = index
            themeManager.setTheme(this.themeList[index], index)
          })
          .gesture(
            LongPressGesture()
              .onAction(() => {
                // 不允许删除内置主题 (前10个)
                if (index < 10) {
                  this.getUIContext().getPromptAction().showToast({ message: '内置主题不可删除' })
                  return
                }
                this.dialog.open()
                this.longPressGestureIndex = index
              })
          )
        })
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(InkSpacing.MD)
      .rowsGap(InkSpacing.MD)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
