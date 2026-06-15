import { promptAction, router } from '@kit.ArkUI'
import { ThemeStorageKey, SplashStyle as SplashStyleEnum } from '../../../common/constants/Theme'
import { ThemeItem } from '../../../common/model/Theme'
import { MyThemeConfigComp } from './MyThemeConfigComp'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkMotion, InkLayout, InkShadow
} from '../../../common/constants/DesignTokens'
import { pickerAvatar, PhotoSelectResultClean } from '../../../common/utils/photoViewPicker'
import picker from '@ohos.file.picker'

// 中间导航区需要渲染的元素列表
interface NavItemType {
  text: string
  img: ResourceStr
}

// 桌面图标样式
interface IconStyleType {
  name: string
  icon: Resource
  bgColor: string
}

// 启动页样式
interface SplashStyleType {
  name: string
  desc: string
}

@Entry
@Component
struct MyThemeConfig {
  @StorageLink('topRectHeight') topRectHeight: number = 0
  // 中间导航区需要渲染的元素列表
  navList: NavItemType[] = [
    { text: '个性主题', img: $r('app.media.my_theme_config_theme') },
    { text: '启动页', img: $r('app.media.my_theme_config_welcome') },
  ]
  @State activeNavIndex: number = 0
  @StorageLink(ThemeStorageKey.SPLASH_INDEX) activeSplashIndex: number = 0
  @StorageLink(ThemeStorageKey.SPLASH_CUSTOM_IMAGE) splashCustomImage: string = ''
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  // 启动页样式列表 — 与 welcomePage 中的样式对应
  splashStyles: SplashStyleType[] = [
    { name: '默认', desc: '琥珀暖光，宣纸质感' },
    { name: '水墨', desc: '深色墨韵，沉静内敛' },
    { name: '素笺', desc: '纯白纸感，清新淡雅' },
    { name: '丹青', desc: '主题色渐变，灵动飘逸' },
    { name: '青瓷', desc: '淡雅青瓷，极简素雅' },
    { name: '自定义图片', desc: '上传相册图片作为背景' },
  ]

  // 构建中间导航区TabBar元素
  @Builder
  tabBarBuilder(item: NavItemType, index: number) {
    Column({ space: InkSpacing.SM }) {
      Row() {
        Image(item.img)
          .width(22)
          .height(22)
          .fillColor(this.activeNavIndex === index ? InkPalette.PAPER : this.theme.mainColor)
      }
      .width(44)
      .height(44)
      .borderRadius(InkRadius.MD)
      .backgroundColor(this.activeNavIndex === index ? this.theme.mainColor : this.theme.secondColor)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .animation({ duration: InkMotion.FAST, curve: Curve.EaseOut })

      Text(item.text)
        .fontSize(InkTypography.CAPTION)
        .fontColor(this.activeNavIndex === index ? InkPalette.INK : InkPalette.INK_MIST)
        .fontWeight(this.activeNavIndex === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .padding({
      left: index === 0 ? InkSpacing.MD : 0,
      right: index === this.navList.length - 1 ? InkSpacing.MD : 0
    })
    .alignItems(HorizontalAlign.Center)
  }

  // 启动页配置
  @Builder
  SplashConfigPanel() {
    Column({ space: InkSpacing.XL }) {
      Text('选择启动页风格')
        .fontSize(InkTypography.BODY)
        .fontColor(InkPalette.INK_GHOST)

      // 启动页预览列表
      ForEach(this.splashStyles, (item: SplashStyleType, index: number) => {
        Row({ space: InkSpacing.LG }) {
          // 预览图 — 模拟启动页效果
          Stack({ alignContent: Alignment.Center }) {
            if (index === SplashStyleEnum.CUSTOM && this.splashCustomImage) {
              Image(this.splashCustomImage)
                .width(64)
                .height(114)
                .borderRadius(InkRadius.SM)
                .objectFit(ImageFit.Cover)
            } else {
              Column()
                .width(64)
                .height(114)
                .borderRadius(InkRadius.SM)
                .backgroundColor(index === SplashStyleEnum.INK ? InkPalette.INK : (
                  index === SplashStyleEnum.PAPER ? InkPalette.PAPER_WARM : (
                    index === SplashStyleEnum.PAINTING ? this.theme.mainColor : (
                      index === SplashStyleEnum.CELADON ? InkPalette.CELADON_MIST : InkPalette.AMBER_GLOW
                    )
                  )
                ))
            }
 
            Text('卷')
              .fontSize(20)
              .fontColor(index === SplashStyleEnum.INK ? InkPalette.PAPER : InkPalette.INK)
              .fontWeight(FontWeight.Lighter)
          }
          .width(64)
          .height(114)
          .borderRadius(InkRadius.SM)
          .shadow(InkShadow.SOFT)
 
          // 信息
          Column({ space: InkSpacing.XS }) {
            Text(item.name)
              .fontSize(InkTypography.BODY)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.activeSplashIndex === index ? this.theme.mainColor : InkPalette.INK)
 
            Text(item.desc)
              .fontSize(InkTypography.CAPTION)
              .fontColor(InkPalette.INK_MIST)
 
            if (index === SplashStyleEnum.CUSTOM) {
              Button(this.splashCustomImage ? '更换图片' : '上传图片')
                .fontSize(InkTypography.MICRO + 1)
                .height(24)
                .padding({ left: InkSpacing.SM, right: InkSpacing.SM })
                .backgroundColor(this.theme.mainColor)
                .fontColor(Color.White)
                .borderRadius(InkRadius.SM)
                .margin({ top: InkSpacing.XS })
                .onClick(async () => {
                  let res: picker.PhotoSelectResult | undefined = await pickerAvatar()
                  if (res) {
                    let cleanRes = res as PhotoSelectResultClean
                    if (cleanRes.photoUris && cleanRes.photoUris.length > 0) {
                      this.splashCustomImage = cleanRes.photoUris[0]
                      this.activeSplashIndex = index
                      this.getUIContext().getPromptAction().showToast({ message: '自定义图片设置成功，下次启动生效' })
                    }
                  }
                })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 选中指示
          if (this.activeSplashIndex === index) {
            Image($r('app.media.ic_public_confirm'))
              .width(20)
              .height(20)
              .fillColor(this.theme.mainColor)
          }
        }
        .width('100%')
        .height(120)
        .padding(InkSpacing.MD)
        .borderRadius(InkRadius.CARD)
        .backgroundColor(this.activeSplashIndex === index ? this.theme.secondColor : InkPalette.PAPER)
        .shadow(this.activeSplashIndex === index ? InkShadow.MEDIUM : InkShadow.SUBTLE)
        .onClick(() => {
          this.activeSplashIndex = index
          this.getUIContext().getPromptAction().showToast({ message: `已切换为「${item.name}」启动页，下次启动生效` })
        })
      })
    }
    .width('100%')
    .padding({ bottom: InkSpacing.XXL + InkSpacing.XL })
  }

  build() {
    Column() {
      // 头部标题栏
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor(InkPalette.INK)
        }
        .width(InkLayout.MIN_TOUCH_TARGET)
        .height(InkLayout.MIN_TOUCH_TARGET)
        .borderRadius(InkRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { router.back() })

        Text('主题')
          .fontSize(InkTypography.TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)
          .position({ left: '50%' })
          .translate({ x: '-50%' })
      }
      .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
      .width('100%')
      .height(InkLayout.HEADER_HEIGHT)
      .margin({ top: this.topRectHeight })

      // 中间导航区
      Tabs({ barPosition: BarPosition.Start }) {
        ForEach(this.navList, (item: NavItemType, index) => {
          TabContent() {
            Column() {
              if (index === 0) {
                MyThemeConfigComp()
              } else {
                Scroll() {
                  this.SplashConfigPanel()
                }
                .scrollBar(BarState.Off)
                .edgeEffect(EdgeEffect.Spring)
                .width('100%')
                .height('100%')
              }
            }
            .padding({ left: InkSpacing.XL, right: InkSpacing.XL, top: InkSpacing.XXL })
            .borderRadius({ topLeft: InkRadius.LG, topRight: InkRadius.LG })
            .backgroundColor(InkPalette.PAPER)
            .width('100%')
            .height('100%')
          }
          .tabBar(this.tabBarBuilder(item, index))
        })
      }
      .onTabBarClick((index) => {
        this.activeNavIndex = index
      })
      .scrollable(false)
      .width('100%')
      .barHeight(80)
      .layoutWeight(1)
    }
    .height('100%')
    .width('100%')
    .backgroundColor(InkPalette.PAPER_EMBEDDED)
  }
}
