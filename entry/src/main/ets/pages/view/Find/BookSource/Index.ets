import { common } from '@kit.AbilityKit'
import axios, { AxiosResponse } from '@ohos/axios'
import Header from '../../../../componets/common/Header'
import Help from '../../../../componets/dialog/help'
import { IconTitleVo } from '../../../../componetsmodel/IconTitleVo'
import { FileHandler } from '../../../../common/utils/FileHandler'
import ImportCommon from '../../../../componets/import/ImportCommon'
import { showMessage } from '../../../../componets/common/promptShow';
import SourceView from './components/SourceView'
import { getPasteDataSync, isNetworkUrl, sleep } from '../../../../common/utils/utils'
import { router } from '@kit.ArkUI'
import { BookSource } from '../../../../database/entities/BookSource'
import { ThemeItem } from '../../../../common/model/Theme'
import { ThemeStorageKey } from '../../../../common/constants/Theme'
import { InkPalette, InkTypography } from '../../../../common/constants/DesignTokens'

@Entry
@Component
@Preview
struct BookSourcePage {
  titleArray: Array<string> = ['小说', '漫画']
  dialogRightData: IconTitleVo[] = [
    new IconTitleVo($r('app.media.icon_rule_paste'), '粘贴导入'),
    new IconTitleVo($r('app.media.icon_rule_export'), '本地导入'),
    new IconTitleVo($r('app.media.icon_find_shelf'), '新建书源'),
    new IconTitleVo($r('app.media.icon_find_shelf'), '批量管理'),
    new IconTitleVo($r('app.media.icon_rule_help'), '导入帮助')
  ]
  @State currentIndex: number = 0
  tabsController: TabsController = new TabsController();
  @State isShowHelp: boolean = false
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem
  @State @Watch('onChange')isShowImport: boolean = false
  @State sourceList: BookSource[] = []
  @State isBatch: boolean = false
  @State refresh: number = 0

  aboutToAppear() {
  }

  onPageShow() {
    this.refresh += 1
  }

  onChange() {
    if (!this.isShowImport) {
      console.log('TagInfo', 111)
      this.refresh += 1
    }
  }

  async pasteAnalyze() {
    try {
      const url = getPasteDataSync()
      if (!url) {
        showMessage('未获取到粘贴信息，请求默认数据')
        await sleep()
        // return
      }
      // if (!isNetworkUrl(url ?? '')) {
      //   showMessage('复制的链接不正确')
      //   return
      // }
      const res: AxiosResponse = await axios
        .get(url ?? 'https://node.wisdoms.xin/static/file/20240704/sy.json');
      this.sourceList = res.data;
      this.isShowImport = true;
    } catch (err) {
      console.error('错误 ' + err);
    }
  }

  build() {
    Column() {
      // 公共头部、搜索框
      Column() {
        if (!this.isBatch) {
          Header({
            customTitleBuilder: () => {
              this.titleBuilder(this.tabsController)
            },
            dialogRightData: this.dialogRightData,
            dialogRightChange: (index: number) => {
              switch (index) {
                case 0:
                  this.pasteAnalyze()
                  break;
                case 1:
                  let context = getContext(this) as common.Context;
                  FileHandler.pickerFile(context)
                    .then((res: BookSource[]) => {
                      this.sourceList = res;
                      this.isShowImport = true
                    })
                  break;
                case 2:
                  router.pushUrl({ url: 'pages/view/Find/BookSource/AddSourcePage' })
                  break;
                case 3:
                  this.isBatch = true
                  break;
                case 4:
                  this.isShowHelp = true;
                  break;
              }
            }
          })
        }
      }

      // 快速操作按钮
      Row({ space: 12 }) {
        Button('一键导入')
          .fontSize(13)
          .height(36)
          .backgroundColor(this.theme.mainColor)
          .fontColor(Color.White)
          .layoutWeight(1)
          .borderRadius(18)
          .onClick(() => {
            this.pasteAnalyze()
          })

        Button('快速添加')
          .fontSize(13)
          .height(36)
          .backgroundColor('#ffffff')
          .fontColor(this.theme.mainColor)
          .layoutWeight(1)
          .borderRadius(18)
          .borderWidth(1)
          .borderColor(this.theme.mainColor)
          .onClick(() => {
            router.pushUrl({ url: 'pages/view/Find/BookSource/AddSourcePage' })
          })

        Button('本地导入')
          .fontSize(13)
          .height(36)
          .backgroundColor('#ffffff')
          .fontColor('#666666')
          .layoutWeight(1)
          .borderRadius(18)
          .borderWidth(1)
          .borderColor('#dddddd')
          .onClick(() => {
            let context = getContext(this) as common.Context;
            FileHandler.pickerFile(context)
              .then((res: BookSource[]) => {
                this.sourceList = res;
                this.isShowImport = true
              })
          })
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .width('100%')
      .backgroundColor('#ffffff')

      // 头部卡片下方视图
      Tabs({
        barPosition: BarPosition.Start,
        controller: this.tabsController
      }) {
        ForEach(this.titleArray, (item: string, index: number) => {
          TabContent() {
            SourceView({ index, isBatch: this.isBatch, refresh: this.refresh })
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
      .scrollable(this.isBatch ? false : true)

      Flex()
        .bindSheet(this.isShowHelp, this.dialogHelpFuction(), {
          height: '50%',
          showClose: false,
          dragBar: false,
          onDisappear: () => {
            this.isShowHelp = false
          }
        })
      Flex()
        .bindSheet(this.isShowImport, this.dialogImportFunction(), {
          detents: [SheetSize.FIT_CONTENT, SheetSize.LARGE, 200],
          dragBar: true,
          showClose: false,
          onDisappear: () => {
            this.isShowImport = false
          }
        })
    }
    .backgroundColor('#f5f5f5')
  }

  @Builder
  titleBuilder(tabsController: TabsController) {
    Row({ space: 4 }) {
      this.titleTab('小说', 0, tabsController)
      this.titleTab('漫画', 1, tabsController)
    }
    .height(36)
    .padding(3)
    .borderRadius(20)
    .backgroundColor('rgba(0,0,0,0.04)')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  titleTab(title: string, idx: number, tabsController: TabsController) {
    Row() {
      Text(title)
        .fontSize(this.currentIndex === idx ? InkTypography.TITLE_SMALL : InkTypography.BODY)
        .fontWeight(this.currentIndex === idx ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentIndex === idx ? Color.White : InkPalette.INK_LIGHT)
        .animation({ duration: 200, curve: Curve.EaseOut })
    }
    .height('100%')
    .padding({ left: 20, right: 20 })
    .backgroundColor(this.currentIndex === idx ? this.theme.mainColor : Color.Transparent)
    .borderRadius(17)
    .onClick(() => {
      this.currentIndex = idx
      tabsController.changeIndex(idx)
    })
  }

  @Builder
  dialogHelpFuction() {
    Flex() {
      Help({
        btnClick: () => {
          this.isShowHelp = false
        }
      })
    }
  }

  @Builder
  dialogImportFunction() {
    Flex() {
      ImportCommon({
        sourceList: this.sourceList,
        show: this.isShowImport
      })
    }
  }
}