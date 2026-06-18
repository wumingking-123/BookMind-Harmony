import MySetConstants from '../../../common/constants/MySetConstants'
import { SetList, SetGroupList } from '../../../componets/dataList/SetListGroup'
import { SetHead } from '../../../componets/myset/SetHead'
import { SetListView } from '../../../componets/myset/SetListView'
import router from '@ohos.router'
import { ThemeStorageKey } from '../../../common/constants/Theme'
import { ThemeItem } from '../../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../common/constants/DesignTokens'

@Entry
@Component
struct MySetPage {
  @State isShowPreDon: boolean = false
  @State isShowLanguage: boolean = false

  @StorageLink(MySetConstants.SET_REFRESH) setRefresh: boolean = true
  @StorageLink(MySetConstants.SET_JUMP) setJump: boolean = true
  @StorageLink(MySetConstants.SET_REPLACE) setReplace: boolean = true
  @StorageLink(MySetConstants.SET_TIP) setTip: boolean = true
  @StorageLink(MySetConstants.SET_IMG_ANTI) setImgAnti: boolean = true
  @StorageLink(MySetConstants.SET_HEAD) setHead: boolean = true
  @StorageLink(MySetConstants.SET_SEARCH) setSearch: boolean = true
  @StorageLink(MySetConstants.SET_PRE_DOWNLOAD) select: number = 10
  @StorageLink(MySetConstants.SET_LANGUAGE) selectLanguage: string = '跟随系统'
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  private tempNum: number = 10
  private preDow: string = '预先下载' + this.select + '章正文'
  private fruits: string[] = getRandomStringArray()

  @State languageList: string[] = ['跟随系统', '简体中文', '繁体中文', '英文']
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0

  // 书架设置列表
  @State bookSetList: SetList[] = [
    new SetList(false, '自动刷新', this.setRefresh, '', '打开软件时自动更新书籍', MySetConstants.SET_REFRESH),
    new SetList(false, '自动跳转最近阅读', this.setJump, '', '关闭将以底部弹窗形式提示', MySetConstants.SET_JUMP),
    new SetList(false, '默认启用替换净化', this.setReplace, '', '新加入书架的书是否启用替换净化', MySetConstants.SET_REPLACE),
    new SetList(false, '返回时提示放入书架', this.setTip, '', '', MySetConstants.SET_TIP)
  ]

  // 缓存下载设置列表
  @State cacheSetList: SetList[] = [
    new SetList(true, '书籍保存位置', true, '', '打开软件时自动更新书籍', MySetConstants.SET_BOOK_SAVE),
    new SetList(true, '预下载', true, this.preDow, '', MySetConstants.SET_PRE_DOWNLOAD),
    new SetList(true, '图片缓存', true, '当前最大缓存50MB', '', MySetConstants.SET_IMG_CACHE),
    new SetList(false, '图片抗锯齿', this.setImgAnti, '', '', MySetConstants.SET_IMG_ANTI)
  ]

  // 其他设置列表
  @State otherSetList: SetList[] = [
    new SetList(false, '全程响应耳机按键', this.setHead, '', '即使退出也响应耳机按键', MySetConstants.SET_HEAD),
    new SetList(false, '文字操作显示搜索', this.setSearch, '', '长按文字在操作菜单中显示阅读搜索', MySetConstants.SET_SEARCH),
    new SetList(true, '语言', true, '跟随系统', '', MySetConstants.SET_LANGUAGE),
  ]

  // AI 阅读设置列表
  @State aiSetList: SetList[] = [
    new SetList(true, 'AI 阅读助手', true, '', '配置大模型 API，在阅读时使用 AI 辅助', ''),
  ]

  // 设置分组
  @State setGroupList: SetGroupList[] = [
    new SetGroupList('书架', this.bookSetList),
    new SetGroupList('缓存下载', this.cacheSetList),
    new SetGroupList('AI 阅读', this.aiSetList),
    new SetGroupList('其他', this.otherSetList)
  ]

  // 定义分组设置头部
  @Builder itemHead(text: string) {
    Text(text)
      .fontSize(InkTypography.CAPTION)
      .fontColor(InkPalette.INK_GHOST)
      .fontWeight(FontWeight.Medium)
      .letterSpacing(0.5)
      .width('100%')
      .padding({
        left: InkSpacing.XL + InkSpacing.LG,
        right: InkSpacing.XL,
        top: InkSpacing.XL,
        bottom: InkSpacing.SM
      })
      .backgroundColor(InkPalette.PAPER_EMBEDDED)
  }

  aboutToAppear() {
    // 确保列表 UI 状态在页面显示时与持久化存储完美同步
    this.bookSetList[0].toggleStatus = this.setRefresh
    this.bookSetList[1].toggleStatus = this.setJump
    this.bookSetList[2].toggleStatus = this.setReplace
    this.bookSetList[3].toggleStatus = this.setTip

    this.preDow = '预先下载' + this.select + '章正文'
    this.cacheSetList[1].rightText = this.preDow
    this.cacheSetList[3].toggleStatus = this.setImgAnti

    this.otherSetList[0].toggleStatus = this.setHead
    this.otherSetList[1].toggleStatus = this.setSearch
    this.otherSetList[2].rightText = this.selectLanguage
  }

  build() {
    Column() {
      // 标题栏 — 墨韵风格
      Row() {
        Row() {
          Image($r('app.media.ic_public_return_left'))
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

        Text('设置')
          .fontSize(InkTypography.TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)
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
              // 分组头部标题
              Row() {
                Text(group.groupValue)
                  .fontSize(InkTypography.CAPTION)
                  .fontColor(InkPalette.INK_GHOST)
                  .fontWeight(FontWeight.Medium)
                  .letterSpacing(0.5)
              }
              .width('100%')
              .padding({ left: InkSpacing.MD, top: InkSpacing.MD, bottom: InkSpacing.XS })

              // 卡片主体
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
              .backgroundColor(Color.White)
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
    .backgroundColor(InkPalette.PAPER_EMBEDDED)
    // 预下载半模态
    .bindSheet($$this.isShowPreDon, this.preDowSheet(), {
      height: 288,
      dragBar: false,
      showClose: false,
    })
    // 语言设置半模态
    .bindSheet($$this.isShowLanguage, this.languageSheet(), {
      height: 288,
      dragBar: false,
      showClose: false,
    })
  }

  // 通过@Builder构建预下载半模态展示界面
  @Builder
  preDowSheet() {
    PreDownloadSheet({
      select: this.select,
      onConfirm: (val: number) => {
        this.select = val
        this.preDow = '预先下载' + val + '章正文'
        this.cacheSetList[1].rightText = this.preDow
        this.cacheSetList = [...this.cacheSetList] // 强制触发渲染
        this.isShowPreDon = false
      },
      onCancel: () => {
        this.isShowPreDon = false
      }
    })
  }

  // 通过@Builder构建语言设置半模态展示界面
  @Builder
  languageSheet() {
    LanguageSelectSheet({
      selectLanguage: this.selectLanguage,
      onSelect: (val: string) => {
        this.selectLanguage = val
        this.otherSetList[2].rightText = val
        this.otherSetList = [...this.otherSetList] // 强制触发渲染
        this.isShowLanguage = false
      }
    })
  }

  /**
   * 设置列表点击事件
   */
  itemOnclick(value: string) {
    switch (value) {
      case MySetConstants.SET_REFRESH:
        this.setRefresh = !this.setRefresh
        this.bookSetList[0].toggleStatus = this.setRefresh
        this.bookSetList = [...this.bookSetList]
        break
      case MySetConstants.SET_JUMP:
        this.setJump = !this.setJump
        this.bookSetList[1].toggleStatus = this.setJump
        this.bookSetList = [...this.bookSetList]
        break
      case MySetConstants.SET_REPLACE:
        this.setReplace = !this.setReplace
        this.bookSetList[2].toggleStatus = this.setReplace
        this.bookSetList = [...this.bookSetList]
        break
      case MySetConstants.SET_TIP:
        this.setTip = !this.setTip
        this.bookSetList[3].toggleStatus = this.setTip
        this.bookSetList = [...this.bookSetList]
        break
      case MySetConstants.SET_IMG_ANTI:
        this.setImgAnti = !this.setImgAnti
        this.cacheSetList[3].toggleStatus = this.setImgAnti
        this.cacheSetList = [...this.cacheSetList]
        break
      case MySetConstants.SET_HEAD:
        this.setHead = !this.setHead
        this.otherSetList[0].toggleStatus = this.setHead
        this.otherSetList = [...this.otherSetList]
        break
      case MySetConstants.SET_SEARCH:
        this.setSearch = !this.setSearch
        this.otherSetList[1].toggleStatus = this.setSearch
        this.otherSetList = [...this.otherSetList]
        break
      case MySetConstants.SET_BOOK_SAVE:
        break
      case MySetConstants.SET_PRE_DOWNLOAD:
        this.isShowPreDon = !this.isShowPreDon
        break
      case MySetConstants.SET_IMG_CACHE:
        break
      case MySetConstants.SET_LANGUAGE:
        this.isShowLanguage = !this.isShowLanguage
        break
      case '':
        router.pushUrl({ url: 'pages/view/myCenter/AiSettingsPage' })
        break
    }
  }
}

// 预下载选择子组件
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
      // 拖拽指示条
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
          .selectedTextStyle({ color: InkPalette.CINNABAR, font: { size: 16, weight: FontWeight.Bold } })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height(288)
    .backgroundColor(InkPalette.PAPER)
  }
}

// 语言选择子组件
@Component
struct LanguageSelectSheet {
  @Prop selectLanguage: string
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  private languageList: string[] = ['跟随系统', '简体中文', '繁体中文', '英文']
  onSelect?: (value: string) => void

  build() {
    Column() {
      Row()
        .width(32)
        .height(4)
        .borderRadius(2)
        .backgroundColor(InkPalette.INK_MIST)
        .margin({ top: InkSpacing.MD })

      Text('语言设置')
        .fontSize(InkTypography.TITLE_SMALL)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: InkSpacing.LG, bottom: InkSpacing.LG })

      ForEach(this.languageList, (value: string) => {
        Row() {
          Text(value)
            .fontSize(InkTypography.BODY)
            .fontColor(InkPalette.INK)

          Blank()

          if (value === this.selectLanguage) {
            Image($r('app.media.ic_public_confirm'))
              .width(18)
              .height(18)
              .fillColor(this.theme.mainColor || InkPalette.CINNABAR)
          }
        }
        .width('100%')
        .height(52)
        .padding({ left: InkSpacing.XL, right: InkSpacing.XL })
        .onClick(() => {
          if (this.onSelect) {
            this.onSelect(value)
          }
        })
      })
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
