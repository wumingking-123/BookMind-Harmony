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

@Entry
@Component
struct Main {
  @State showReadShow: boolean = true
  @State currentTabIndex: number = 0
  @State isShow: boolean = true
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @StorageProp('APP_INDEX_SCROLLABLE') APP_INDEX_SCROLLABLE: boolean = true
  @State ShowBar: boolean = true
  tabController: TabsController = new TabsController()

  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  onPageShow(): void {
    // initBookListData()
    setTimeout(() => {
      this.showReadShow = false
      this.isShow = false
    }, 5000)

    getContext(this).eventHub.on('SubscriptionBatchEdit', (params: boolean) => {
      this.ShowBar = params
      this.APP_INDEX_SCROLLABLE = !this.APP_INDEX_SCROLLABLE
      console.log('SubscriptionBatchEdit:' + params)
    })
  }

  screenShot() {
    // 切换回首页
    let index = this.currentTabIndex
    this.tabController.changeIndex(0)
    this.getUIContext().getComponentSnapshot().get('main', ((err: Error, pixmap: image.PixelMap) => {
      if (err) {
        console.log('error: ' + JSON.stringify(err))
        return
      }
      AppStorage.setOrCreate('screen_shot', pixmap)
    }))
    // 恢复当前页
    this.tabController.changeIndex(index)
  }

  aboutToAppear(): void {
    // 注册监听截图事件 用于我的页面下主题设置预览
    emitter.on('screen_shot', () => {
      this.screenShot()
    })
  }

  @State tabScale: number[] = [1.1, 1, 1, 1]

  @Builder TabBuilder(index: number, name: string, iconSelect: Resource, iconLine: Resource) {
    Column() {
      Column({ space: 4 }) {
        // Tab 图标 — 选中/未选中状态
        Image(this.currentTabIndex === index ? iconSelect : iconLine)
          .width(24)
          .height(24)
          .fillColor(this.currentTabIndex === index ? this.theme.mainColor : InkPalette.INK_MIST)
          .scale({ x: this.tabScale[index], y: this.tabScale[index] })

        // Tab 文字
        Text(name)
          .fontSize(InkTypography.MICRO + 1)
          .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
          .fontColor(this.currentTabIndex === index ? this.theme.mainColor : InkPalette.INK_MIST)
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .gesture(
      // 长按锁定/解锁标签栏滚动
      LongPressGesture({ repeat: index === 0, duration: 1000 })
        .onAction((event: GestureEvent) => {
          if (event.repeat) {
            updateAppData(!this.APP_INDEX_SCROLLABLE)
            showMessage(this.APP_INDEX_SCROLLABLE ? '标签栏已锁定' : '标签栏已解锁')
          }
        })
    )
  }

  // 底部导航栏配置
  nav: NavItem[] = [
    new NavItem(0, $r('app.media.HOME_theme'), $r('app.media.HOME_line'), '书架'),
    new NavItem(1, $r('app.media.FIND_theme'), $r('app.media.FIND_line'), '发现'),
    new NavItem(2, $r('app.media.SUB_theme'), $r('app.media.SUB_line'), '订阅'),
    new NavItem(3, $r('app.media.MINE_theme'), $r('app.media.MINE_line'), '我的')
  ]

  build() {
    Column() {
      // 底部 TabBar 上方添加精致细微的轻墨分割线
      if (this.ShowBar) {
        Divider()
          .color(InkPalette.INK_WHISPER)
          .strokeWidth(0.5)
      }

      // 主 Tab 容器 — 4 个页面
      Tabs({
        barPosition: BarPosition.End,
        controller: this.tabController
      }) {
        ForEach(this.nav, (item: NavItem) => {
          TabContent() {
            Column() {
              if (item.index === 0) {
                BookShelf()
              } else if (item.index === 1) {
                Find()
              } else if (item.index === 2) {
                Subscription({ currentTabIndex: this.currentTabIndex })
              }
              if (item.index === 3) {
                MyCenter()
              }
            }
          }
          .tabBar(
            this.TabBuilder(item.index, item.title, item.selectImg, item.unselected)
          )
        })
      }
      .barBackgroundColor(InkPalette.PAPER)
      .barHeight(this.ShowBar ? InkLayout.TAB_BAR_HEIGHT + this.bottomRectHeight : 0)
      .scrollable(!this.APP_INDEX_SCROLLABLE)
      .barMode(BarMode.Fixed)
      .onChange((index) => {
        // 先缩小旧 tab
        animateTo({ duration: 80, curve: Curve.FastOutLinearIn }, () => {
          this.tabScale[this.currentTabIndex] = 1
          this.tabScale[index] = 0.85
        })
        this.currentTabIndex = index
        // 再放大新 tab (延迟半帧让缩小先执行)
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
    .width('100%')
    .height('100%')
    .backgroundColor(InkPalette.PAPER)
    .id('main')
  }
}
