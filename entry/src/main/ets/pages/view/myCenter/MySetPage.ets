import MySetConstants from '../../../common/constants/MySetConstants'
import { SetList, SetGroupList } from '../../../componets/dataList/SetListGroup'
import { SetListView } from '../../../componets/myset/SetListView'
import router from '@ohos.router'
import { ThemeStorageKey } from '../../../common/constants/Theme'
import { ThemeItem } from '../../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../common/constants/DesignTokens'
import { window } from '@kit.ArkUI'

@Entry
@Component
struct MySetPage {
  @State isShowPreDon: boolean = false

  @StorageLink(MySetConstants.SET_REFRESH) setRefresh: boolean = true
  @StorageLink(MySetConstants.SET_JUMP) setJump: boolean = true
  @StorageLink(MySetConstants.SET_REPLACE) setReplace: boolean = true
  @StorageLink(MySetConstants.SET_TIP) setTip: boolean = true
  @StorageLink(MySetConstants.SET_PRE_DOWNLOAD) select: number = 10
  @StorageLink('isNightMode') isNightMode: boolean = false
  @StorageLink('setKeepScreenOn') setKeepScreenOn: boolean = false
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  private tempNum: number = 10
  private preDow: string = '预先下载' + this.select + '章正文'
  private fruits: string[] = getRandomStringArray()

  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0

  // 阅读设置列表
  @State readingSetList: SetList[] = [
    new SetList(false, '夜间模式', this.isNightMode, '', '全局切换日间/夜间显示', 'isNightMode'),
    new SetList(false, '阅读时屏幕常亮', this.setKeepScreenOn, '', '阅读界面保持屏幕常亮', 'setKeepScreenOn'),
    new SetList(false, '自动刷新', this.setRefresh, '', '打开软件时自动更新书籍', MySetConstants.SET_REFRESH),
    new SetList(false, '自动跳转最近阅读', this.setJump, '', '关闭将以底部弹窗形式提示', MySetConstants.SET_JUMP),
    new SetList(false, '默认启用替换净化', this.setReplace, '', '新加入书架的书是否启用替换净化', MySetConstants.SET_REPLACE),
    new SetList(false, '返回时提示放入书架', this.setTip, '', '', MySetConstants.SET_TIP),
  ]

  // 缓存下载设置列表
  @State cacheSetList: SetList[] = [
    new SetList(true, '预下载', true, this.preDow, '', MySetConstants.SET_PRE_DOWNLOAD),
  ]

  // AI 阅读设置列表
  @State aiSetList: SetList[] = [
    new SetList(true, 'AI 阅读助手', true, '', '配置大模型 API，在阅读时使用 AI 辅助', ''),
  ]

  // 设置分组
  @State setGroupList: SetGroupList[] = [
    new SetGroupList('阅读', this.readingSetList),
    new SetGroupList('缓存下载', this.cacheSetList),
    new SetGroupList('AI 阅读', this.aiSetList),
  ]

  aboutToAppear() {
    this.readingSetList[0].toggleStatus = this.isNightMode
    this.readingSetList[1].toggleStatus = this.setKeepScreenOn
    this.readingSetList[2].toggleStatus = this.setRefresh
    this.readingSetList[3].toggleStatus = this.setJump
    this.readingSetList[4].toggleStatus = this.setReplace
    this.readingSetList[5].toggleStatus = this.setTip

    this.preDow = '预先下载' + this.select + '章正文'
    this.cacheSetList[0].rightText = this.preDow
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Row() {
          Image($r('app.media.ic_public_return_left'))
            .width(24)
            .height(24)
            .fillColor(this.isNightMode ? '#EDE4D3' : InkPalette.INK)
        }
        .width(InkLayout.MIN_TOUCH_TARGET)
        .height(InkLayout.MIN_TOUCH_TARGET)
        .borderRadius(InkRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { router.back() })

        Text('设置')
          .fontSize(InkTypography.TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isNightMode ? '#EDE4D3' : InkPalette.INK)
          .margin({ left: InkSpacing.SM })
      }
      .width('100%')
      .height(InkLayout.HEADER_HEIGHT)
      .padding({ left: InkSpacing.LG })
      .margin({ top: this.topRectHeight })

      // 设置列表
      List({ space: InkSpacing.MD }) {
        ForEach(this.setGroupList, (group: SetGroupList) => {
          ListItem() {
            Column() {
              Row() {
                Text(group.groupValue)
                  .fontSize(InkTypography.CAPTION)
                  .fontColor(this.isNightMode ? '#8A7D71' : InkPalette.INK_GHOST)
                  .fontWeight(FontWeight.Medium)
                  .letterSpacing(0.5)
              }
              .width('100%')
              .padding({ left: InkSpacing.MD, top: InkSpacing.MD, bottom: InkSpacing.XS })

              Column() {
                if (group.setList) {
                  ForEach(group.setList, (item: SetList, index: number) => {
                    SetListView({
                      setList: item,
                      topLeft: index === 0 ? InkRadius.CARD : 0,
                      topRight: index === 0 ? InkRadius.CARD : 0,
                      bottomLeft: index === group.setList.length - 1 ? InkRadius.CARD : 0,
                      bottomRight: index === group.setList.length - 1 ? InkRadius.CARD : 0
                    })
                      .onClick(() => { this.itemOnclick(item.storageName) })

                    if (index < group.setList.length - 1) {
                      Divider()
                        .color(InkPalette.PAPER_WARM)
                        .strokeWidth(0.5)
                        .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
                    }
                  })
                }
              }
              .backgroundColor(this.isNightMode ? '#2A2826' : Color.White)
              .borderRadius(InkRadius.CARD)
              .shadow(InkShadow.SUBTLE)
              .width('100%')
            }
            .width('100%')
          }
          .padding({ left: InkSpacing.PAGE_HORIZONTAL, right: InkSpacing.PAGE_HORIZONTAL })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .padding({ bottom: this.bottomRectHeight })
    .backgroundColor(this.isNightMode ? '#1A1A1C' : InkPalette.PAPER_EMBEDDED)
    .bindSheet($$this.isShowPreDon, this.preDowSheet(), {
      height: 288,
      dragBar: false,
      showClose: false,
    })
  }

  @Builder
  preDowSheet() {
    PreDownloadSheet({
      select: this.select,
      onConfirm: (val: number) => {
        this.select = val
        this.preDow = '预先下载' + val + '章正文'
        this.cacheSetList[0].rightText = this.preDow
        this.cacheSetList = [...this.cacheSetList]
        this.isShowPreDon = false
      },
      onCancel: () => {
        this.isShowPreDon = false
      }
    })
  }

  itemOnclick(value: string) {
    switch (value) {
      case 'isNightMode':
        this.isNightMode = !this.isNightMode
        this.readingSetList[0].toggleStatus = this.isNightMode
        this.readingSetList = [...this.readingSetList]
        this.applyNightMode()
        break
      case 'setKeepScreenOn':
        this.setKeepScreenOn = !this.setKeepScreenOn
        this.readingSetList[1].toggleStatus = this.setKeepScreenOn
        this.readingSetList = [...this.readingSetList]
        this.applyKeepScreenOn()
        break
      case MySetConstants.SET_REFRESH:
        this.setRefresh = !this.setRefresh
        this.readingSetList[2].toggleStatus = this.setRefresh
        this.readingSetList = [...this.readingSetList]
        break
      case MySetConstants.SET_JUMP:
        this.setJump = !this.setJump
        this.readingSetList[3].toggleStatus = this.setJump
        this.readingSetList = [...this.readingSetList]
        break
      case MySetConstants.SET_REPLACE:
        this.setReplace = !this.setReplace
        this.readingSetList[4].toggleStatus = this.setReplace
        this.readingSetList = [...this.readingSetList]
        break
      case MySetConstants.SET_TIP:
        this.setTip = !this.setTip
        this.readingSetList[5].toggleStatus = this.setTip
        this.readingSetList = [...this.readingSetList]
        break
      case MySetConstants.SET_PRE_DOWNLOAD:
        this.isShowPreDon = !this.isShowPreDon
        break
      case '':
        router.pushUrl({ url: 'pages/view/myCenter/AiSettingsPage' })
        break
    }
  }

  applyNightMode() {
    try {
      window.getLastWindow(getContext(this), (err, win) => {
        if (err.code) return
        // 状态栏完全透明 — 让应用背景延伸到状态栏
        win.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          navigationBarColor: this.isNightMode ? '#E61A1A1C' : '#E6FAF7F0',
          statusBarContentColor: this.isNightMode ? '#EDE4D3' : '#1A1612',
          navigationBarContentColor: this.isNightMode ? '#EDE4D3' : '#1A1612'
        })
        win.setWindowBackgroundColor(this.isNightMode ? '#1A1A1C' : '#FAF7F0')
      })
    } catch (e) {}
  }

  applyKeepScreenOn() {
    try {
      window.getLastWindow(getContext(this), (err, win) => {
        if (err.code) return
        win.setWindowKeepScreenOn(this.setKeepScreenOn)
      })
    } catch (e) {}
  }
}

@Component
struct PreDownloadSheet {
  @Prop select: number
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  private fruits: string[] = getRandomStringArray()
  @State private tempNum: number = 10
  onConfirm?: (value: number) => void
  onCancel?: () => void

  aboutToAppear() {
    this.tempNum = this.select
  }

  build() {
    Column() {
      Row()
        .width(32)
        .height(4)
        .borderRadius(2)
        .backgroundColor(InkPalette.INK_MIST)
        .margin({ top: InkSpacing.MD })

      Row() {
        Text('取消')
          .fontSize(InkTypography.BODY)
          .fontColor(InkPalette.INK_GHOST)
          .onClick(() => {
            if (this.onCancel) {
              this.onCancel()
            }
          })

        Text('预下载')
          .fontSize(InkTypography.TITLE_SMALL)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)

        Text('确定')
          .fontSize(InkTypography.BODY)
          .fontColor(this.theme.mainColor)
          .onClick(() => {
            if (this.onConfirm) {
              this.onConfirm(this.tempNum)
            }
          })
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: InkSpacing.XL, right: InkSpacing.XL })

      Column() {
        TextPicker({ range: this.fruits, selected: this.select })
          .onChange((value: string | string[], index: number | number[]) => {
            if (typeof index === 'number') {
              this.tempNum = index
            }
          })
          .disappearTextStyle({ color: InkPalette.INK_MIST, font: { size: 14, weight: FontWeight.Normal } })
          .textStyle({ color: InkPalette.INK_FAINT, font: { size: 14, weight: FontWeight.Normal } })
          .selectedTextStyle({ color: this.theme.mainColor || InkPalette.CINNABAR, font: { size: 16, weight: FontWeight.Bold } })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height(288)
    .backgroundColor(InkPalette.PAPER)
  }
}

function getRandomStringArray(): string[] {
  let list: string[] = []
  for (let i = 0; i < 100; i++) {
    list.push(i.toString())
  }
  return list
}
