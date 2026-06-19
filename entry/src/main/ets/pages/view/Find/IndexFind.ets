import { router } from '@kit.ArkUI'
import dialogTitleFuction from '../../../componets/common/dialogTitleFuction'
import { IconTitleVo } from '../../../componetsmodel/IconTitleVo'
import ImportCommon from '../../../componets/import/ImportCommon'
import { FileHandler } from '../../../common/utils/FileHandler'
import axios, { AxiosResponse } from '@ohos/axios'
import { common } from '@kit.AbilityKit'
import Help from '../../../componets/dialog/help'
import { getPasteDataSync, isNetworkUrl, sleep } from '../../../common/utils/utils'
import { showMessage } from '../../../componets/common/promptShow'
import FindContent from './components/FindContent'
import { BookSource } from '../../../database/entities/BookSource'
import { ThemeItem } from '../../../common/model/Theme'
import { ThemeStorageKey } from '../../../common/constants/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkMotion
} from '../../../common/constants/DesignTokens'

@Component
export default struct IndexFind {
  private scrollController: Scroller = new Scroller()
  titleArray: string[] = ['小说', '漫画', '有声书']
  @State currentIndex: number = 0
  tabsController: TabsController = new TabsController()
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @StorageProp('APP_INDEX_SCROLLABLE') APP_INDEX_SCROLLABLE: boolean = false
  @State groupCoverShow: boolean = false
  @State bookType: string = '全部'
  @State GROUP: string = '标签'
  @State isShowFuction: boolean = false
  @State isShowHelp: boolean = false
  @State isShowImport: boolean = false
  @State sourceList: BookSource[] = []
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Row({ space: InkSpacing.XS }) {
          ForEach(this.titleArray, (title: string, index: number) => {
            Column({ space: 4 }) {
              Text(title)
                .fontSize(InkTypography.BODY)
                .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.currentIndex === index ? InkPalette.INK : InkPalette.INK_MIST)
                .animation({ duration: InkMotion.FAST, curve: Curve.EaseOut })

              Row()
                .width(this.currentIndex === index ? 16 : 0)
                .height(2)
                .borderRadius(1)
                .backgroundColor(this.theme.mainColor)
                .animation({ duration: InkMotion.NORMAL, curve: Curve.EaseOut })
            }
            .padding({ left: InkSpacing.MD, right: InkSpacing.MD, top: InkSpacing.SM, bottom: InkSpacing.SM })
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.currentIndex = index
              this.tabsController.changeIndex(index)
            })
          })
        }

        Blank()

        Row() {
          Image($r('app.media.addSubscription'))
            .width(20)
            .height(20)
            .fillColor(InkPalette.INK_FAINT)
        }
        .width(36)
        .height(36)
        .borderRadius(InkRadius.FULL)
        .backgroundColor(InkPalette.OVERLAY_LIGHT)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .bindMenu(this.isShowFuction, this.dialogRightFuction(), {
          onDisappear: () => { this.isShowFuction = false }
        })
        .onClick(() => { this.isShowFuction = true })
      }
      .width('100%')
      .padding({
        top: this.topRectHeight === 0 ? 30 : this.topRectHeight,
        left: InkSpacing.PAGE_HORIZONTAL,
        right: InkSpacing.PAGE_HORIZONTAL,
        bottom: InkSpacing.SM
      })

      Tabs({
        barPosition: BarPosition.Start,
        controller: this.tabsController
      }) {
        ForEach(this.titleArray, (item: string) => {
          TabContent() {
            FindContent({ currentIndex: this.currentIndex })
          }
          .align(Alignment.Top)
        })
      }
      .layoutWeight(1)
      .barWidth(0)
      .barHeight(0)
      .onChange((index) => {
        this.tabsController.changeIndex(index)
        this.currentIndex = index
      })
      .scrollable(this.APP_INDEX_SCROLLABLE)

      Flex()
        .bindSheet(this.isShowHelp, this.dialogHelpFuction(), {
          height: '50%',
          showClose: false,
          dragBar: false,
          onDisappear: () => { this.isShowHelp = false }
        })
      Flex()
        .bindSheet(this.isShowImport, this.dialogImportFunction(), {
          detents: [SheetSize.FIT_CONTENT, SheetSize.LARGE, 200],
          dragBar: true,
          showClose: false,
          onDisappear: () => { this.isShowImport = false }
        })
    }
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[this.theme.mainColor, 0], [this.theme.secondColor, 0.15]]
    })
  }

  FIND_Dialog_Right_Fuction: IconTitleVo[] = [
    new IconTitleVo($r('app.media.icon_rule_paste'), '粘贴导入'),
    new IconTitleVo($r('app.media.icon_rule_export'), '本地导入'),
    new IconTitleVo($r('app.media.icon_find_shelf'), '书源管理'),
    new IconTitleVo($r('app.media.icon_rule_help'), '导入帮助')
  ]

  @Builder
  dialogRightFuction() {
    Column() {
      ForEach(this.FIND_Dialog_Right_Fuction, (item: IconTitleVo, index: number) => {
        dialogTitleFuction({
          title: item.title,
          icon: item.icon,
          isBorder: this.FIND_Dialog_Right_Fuction.length !== index + 1
        })
          .onClick(() => { this.findBindMenuFunction(index) })
      })
    }
    .backgroundColor(InkPalette.PAPER)
    .borderRadius(InkRadius.MD)
    .shadow(InkShadow.MEDIUM)
  }

  async pasteAnalyze() {
    try {
      let url = getPasteDataSync()
      if (!url) {
        showMessage('未获取到粘贴信息')
        await sleep()
      }
      if (!isNetworkUrl(url ?? '')) {
        showMessage('复制的链接不正确')
        await sleep()
        url = undefined
      }
      const res: AxiosResponse = await axios
        .get(url ?? 'https://node.wisdoms.xin/static/file/20240704/sy.json')
      this.sourceList = res.data
      this.isShowImport = true
    } catch (err) {
      console.error('错误 ' + err)
    }
  }

  findBindMenuFunction(index: number) {
    switch (index) {
      case 0:
        this.pasteAnalyze()
        break
      case 1:
        let context = getContext(this) as common.Context
        FileHandler.pickerFile(context).then((res: BookSource[]) => {
          this.sourceList = res
          this.isShowImport = true
        })
        break
      case 2:
        router.pushUrl({ url: 'pages/view/Find/BookSource/Index' })
        break
      case 3:
        this.isShowHelp = true
        break
    }
  }

  @Builder
  dialogHelpFuction() {
    Flex() {
      Help({ btnClick: () => { this.isShowHelp = false } })
    }
  }

  @Builder
  dialogImportFunction() {
    Flex() {
      ImportCommon({ sourceList: this.sourceList, show: this.isShowImport })
    }
  }
}
