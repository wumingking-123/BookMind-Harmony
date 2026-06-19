import { showMessage } from '../componets/common/promptShow'
import ReadShow from '../componets/common/ReadShow'
import { NavItem } from '../componets/dataList/type'
import { updateAppData } from '../storage/appData'
import BookShelf from './view/BookShelf'
import Find from './view/Find/Find'
import MyCenter from './view/myCenter/MyCenter'
import Subscription from './view/Subscription'
import { BusinessError, emitter } from '@kit.BasicServicesKit'
import { JSON } from '@kit.ArkTS'
import { image } from '@kit.ImageKit'
import { ThemeStorageKey } from '../common/constants/Theme'
import { ThemeItem } from '../common/model/Theme'
import { InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkMotion, InkLayout }
  from '../common/constants/DesignTokens'
import { IconBookShelf, IconFind, IconSubscribe, IconMine } from '../componets/common/TabIcons'

@Entry
@Component
struct Main {
  @State showReadShow: boolean = true
  @State currentTabIndex: number = 0
  @State isShow: boolean = true
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @StorageLink('isNightMode') isNightMode: boolean = false
  @StorageProp('APP_INDEX_SCROLLABLE') APP_INDEX_SCROLLABLE: boolean = true
  @State ShowBar: boolean = true
  tabController: TabsController = new TabsController()

  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  onPageShow(): void {
    setTimeout(() => {
      this.showReadShow = false
      this.isShow = false
    }, 5000)

    getContext(this).eventHub.on('SubscriptionBatchEdit', (params: boolean) => {
      this.ShowBar = params
      this.APP_INDEX_SCROLLABLE = !this.APP_INDEX_SCROLLABLE
    })
  }

  screenShot() {
    let index = this.currentTabIndex
    this.tabController.changeIndex(0)
    this.getUIContext().getComponentSnapshot().get('main', ((err: Error, pixmap: image.PixelMap) => {
      if (err) {
        console.log('error: ' + JSON.stringify(err))
        return
      }
      AppStorage.setOrCreate('screen_shot', pixmap)
    }))
    this.tabController.changeIndex(index)
  }

  aboutToAppear(): void {
    emitter.on('screen_shot', () => {
      this.screenShot()
    })
  }

  @State tabScale: number[] = [1.1, 1, 1, 1]

  // Tab 配置
  tabNames: string[] = ['书架', '发现', '订阅', '我的']

  @Builder TabBuilder(index: number, name: string) {
    Column({ space: 3 }) {
      // 矢量图标 — 根据 index 选择对应组件
      if (index === 0) {
        IconBookShelf({
          color: this.currentTabIndex === index ? this.theme.mainColor : InkPalette.INK_MIST,
          iconSize: 22,
          isSelected: this.currentTabIndex === index
        })
          .scale({ x: this.tabScale[index], y: this.tabScale[index] })
      } else if (index === 1) {
        IconFind({
          color: this.currentTabIndex === index ? this.theme.mainColor : InkPalette.INK_MIST,
          iconSize: 22,
          isSelected: this.currentTabIndex === index
        })
          .scale({ x: this.tabScale[index], y: this.tabScale[index] })
      } else if (index === 2) {
        IconSubscribe({
          color: this.currentTabIndex === index ? this.theme.mainColor : InkPalette.INK_MIST,
          iconSize: 22,
          isSelected: this.currentTabIndex === index
        })
          .scale({ x: this.tabScale[index], y: this.tabScale[index] })
      } else {
        IconMine({
          color: this.currentTabIndex === index ? this.theme.mainColor : InkPalette.INK_MIST,
          iconSize: 22,
          isSelected: this.currentTabIndex === index
        })
          .scale({ x: this.tabScale[index], y: this.tabScale[index] })
      }

      // Tab 文字
      Text(name)
        .fontSize(10)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? this.theme.mainColor : InkPalette.INK_MIST)

      // 活跃指示点
      Row()
        .width(this.currentTabIndex === index ? 4 : 0)
        .height(this.currentTabIndex === index ? 4 : 0)
        .borderRadius(InkRadius.FULL)
        .backgroundColor(this.theme.mainColor)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .gesture(
      LongPressGesture({ repeat: index === 0, duration: 1000 })
        .onAction((event: GestureEvent) => {
          if (event.repeat) {
            updateAppData(!this.APP_INDEX_SCROLLABLE)
            showMessage(this.APP_INDEX_SCROLLABLE ? '标签栏已锁定' : '标签栏已解锁')
          }
        })
    )
  }

  build() {
    Column() {
      // 主 Tab 容器
      Tabs({
        barPosition: BarPosition.End,
        controller: this.tabController
      }) {
        ForEach(this.tabNames, (name: string, index: number) => {
          TabContent() {
            Column() {
              if (index === 0) {
                BookShelf()
              } else if (index === 1) {
                Find()
              } else if (index === 2) {
                Subscription({ currentTabIndex: this.currentTabIndex })
              }
              if (index === 3) {
                MyCenter()
              }
            }
          }
          .tabBar(this.TabBuilder(index, name))
        })
      }
      .barBackgroundColor(this.isNightMode ? '#2A2826' : InkPalette.PAPER)
      .barHeight(this.ShowBar ? InkLayout.TAB_BAR_HEIGHT + this.bottomRectHeight : 0)
      .scrollable(!this.APP_INDEX_SCROLLABLE)
      .barMode(BarMode.Fixed)
      .onChange((index) => {
        // 两阶段动画：缩入 → 弹出
        animateTo({ duration: 80, curve: Curve.FastOutLinearIn }, () => {
          this.tabScale[this.currentTabIndex] = 1
          this.tabScale[index] = 0.85
        })
        this.currentTabIndex = index
        setTimeout(() => {
          animateTo({ duration: 150, curve: Curve.LinearOutSlowIn }, () => {
            this.tabScale[index] = 1.1
          })
        }, 80)
      })

      // 继续阅读浮层
      if (this.showReadShow) {
        ReadShow({ showReadShow: this.showReadShow })
          .offset({ y: -InkLayout.TAB_BAR_HEIGHT - this.bottomRectHeight - 16 })
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(this.isNightMode ? '#1A1A1C' : InkPalette.PAPER)
    .height('100%')
    .backgroundColor(InkPalette.PAPER)
    .id('main')
  }
}