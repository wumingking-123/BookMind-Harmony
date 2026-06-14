import CommonConstants from '../../../common/constants/CommonConstants'
import { IconTitleVo } from '../../../componetsmodel/IconTitleVo'
import { router } from '@kit.ArkUI'
import SubscriptionContent from './components/SubscriptionContent'
import { showMessage } from '../../../componets/common/promptShow'
import { getPasteDataSync, isNetworkUrl, sleep } from '../../../common/utils/utils'
import axios, { AxiosResponse } from '@ohos/axios'
import { rssGroupList, rssSources } from '../../../database/entities/rssSources'
import SubscriptionImport from '../../../componets/import/SubscriptionImport'
import subscriptionDao from '../../../database/dao/SubscriptionDao'
import dialogNewSources from './RssSources/dialogNewSources'
import RssSourcesHistory from './components/RssSourcesHistory'
import rssSourcesHistoryDao from '../../../database/dao/RssSourcesHistoryDao'
import { rssSourcesHistory } from '../../../database/entities/rssSourcesHistory'
import { FileHandler } from 'ets/common/utils/FileHandler'
import { ThemeItem } from '../../../common/model/Theme'
import { ThemeStorageKey } from '../../../common/constants/Theme'
import rssSourcesUtils from '../../../common/utils/rssSourcesUtils'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkMotion
} from '../../../common/constants/DesignTokens'

@Component
export default struct SubscriptionIndex {
  @State isShowImport: boolean = false
  @State isShowNewSources: boolean = false
  @Prop @Watch('currentTabIndexChange') currentTabIndex: number
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @StorageLink(CommonConstants.RSS_SOURCES_REFRESHING) @Watch('getList') refreshing: number = 0
  @State moreList: IconTitleVo[] = [
    new IconTitleVo($r('app.media.icon_rule_paste'), '粘贴导入'),
    new IconTitleVo($r('app.media.icon_rule_export'), '本地导入'),
    new IconTitleVo($r('app.media.icon_rule_add'), '新建订阅'),
    new IconTitleVo($r('app.media.icon_rule_batch'), '批量管理'),
  ]
  @Provide('batchList') batchList: Record<number, boolean> = {}
  @State RecentlyUsed: rssSourcesHistory[] = []
  @State loading: boolean = false
  @State subscriptionList: rssSources[] = []
  @State rssSourcesList: rssSources[] = []
  @State groupList: rssGroupList[] = []
  @State batchEdit: boolean = false
  @State newGroupType: string = ''
  @Provide('batchAll') batchAll: boolean = false
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  refresh = () => {
    this.resetState()
    this.getList()
    setTimeout(() => {
      rssSourcesHistoryDao.search().then((rssSourcesHistoryList: rssSourcesHistory[]) => {
        this.RecentlyUsed = rssSourcesHistoryList
      })
    }, 100)
  }

  currentTabIndexChange() {
    this.refresh()
  }

  resetState() {
    this.subscriptionList = []
    this.groupList = []
  }

  getList() {
    subscriptionDao.search().then(data => {
      const rssSources = data ?? []
      this.rssSourcesList = rssSources
      rssSources.forEach((item: rssSources) => {
        if (item.id) {
          this.batchList[item.id] = false
        }
      })
      this.getGroupList()
    }).catch(() => {})
  }

  getGroupList() {
    const groupMap: Record<string, rssGroupList> = {}
    this.rssSourcesList.forEach((item: rssSources) => {
      const title = item.sourceGroup
      if (title) {
        if (!groupMap[title]) {
          groupMap[title] = { title: title, list: [] }
        }
        groupMap[title].list.push(item)
      }
    })
    this.groupList = Object.values(groupMap)
  }

  build() {
    Column() {
      Column() {
        // 搜索栏
        Row({ space: InkSpacing.MD }) {
          if (!this.batchEdit) {
            // Logo
            Image($r('app.media.icon_subscription_index'))
              .width(40)
              .height(20)

            // 搜索框 — 墨韵风格
            Search({ placeholder: '搜索订阅', icon: '/common/images/search.svg' })
              .layoutWeight(1)
              .height(44)
              .backgroundColor(InkPalette.PAPER_PURE)
              .borderRadius(InkRadius.SEARCH)
              .shadow(InkShadow.SUBTLE)
              .onClick(() => {
                router.pushUrl({ url: 'pages/view/Subscription/components/SubscriptionSearch' })
              })
              .focusOnTouch(false)

            // 添加按钮
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
            .bindMenu(this.MenuBuilder)
          } else {
            Text(this.batchAll ? '取消全选' : '全选')
              .fontSize(InkTypography.BODY)
              .fontColor(InkPalette.INK)
              .width('33%')
              .onClick(() => {
                this.batchAll = !this.batchAll
                Object.keys(this.batchList).forEach((key: string) => {
                  this.batchList[key] = this.batchAll
                })
              })

            Blank(1)

            Text(`已选 ${Object.values(this.batchList).filter(value => value === true).length} 项`)
              .fontSize(InkTypography.BODY)
              .fontColor(InkPalette.INK_GHOST)
              .width('33%')

            Blank(1)

            Text('完成')
              .fontSize(InkTypography.BODY)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.theme.mainColor)
              .width('33%')
              .textAlign(TextAlign.End)
              .onClick(() => {
                this.batchAll = false
                this.batchEdit = false
                Object.keys(this.batchList).forEach((key: string) => {
                  this.batchList[key] = false
                })
                getContext(this).eventHub.emit('SubscriptionBatchEdit', true)
              })
          }
        }
        .width('100%')
        .padding({ top: this.topRectHeight + InkSpacing.LG, bottom: InkSpacing.MD })

        // 最近使用
        if (!this.batchEdit) {
          RssSourcesHistory({ RecentlyUsed: this.RecentlyUsed })
        }

        // 内容区
        if (this.loading) {
          Column() {
            LoadingProgress()
              .color(this.theme.mainColor)
              .width(48)
            Text('加载中...')
              .fontSize(InkTypography.BODY)
              .fontColor(InkPalette.INK_MIST)
              .margin({ top: InkSpacing.MD })
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
        } else if (!this.groupList.length) {
          SubscriptionContent({
            subscriptionTitle: '收藏',
            batchEdit: this.batchEdit,
            showAddDialog: () => { this.isShowNewSources = true }
          })
        } else {
          Scroll() {
            Column({ space: InkSpacing.MD }) {
              ForEach(this.groupList, (item: rssGroupList) => {
                SubscriptionContent({
                  subscriptionTitle: item.title,
                  contentList: item.list,
                  batchEdit: this.batchEdit,
                  refresh: this.refresh
                })
              })
            }
          }
          .align(Alignment.Top)
          .padding({ bottom: InkSpacing.XL })
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .scrollable(ScrollDirection.Vertical)
        }
      }
      .padding({ left: InkSpacing.PAGE_HORIZONTAL, right: InkSpacing.PAGE_HORIZONTAL })
      .layoutWeight(1)

      // 批量操作栏
      if (this.batchEdit) {
        Row() {
          Column({ space: InkSpacing.XS }) {
            Image($r('app.media.folder'))
              .width(20)
              .height(20)
              .fillColor(InkPalette.INK_FAINT)
            Text('移动至')
              .fontSize(InkTypography.MICRO)
              .fontColor(InkPalette.INK)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { showMessage('功能开发中，暂未开放') })

          Column({ space: InkSpacing.XS }) {
            Image($r('app.media.edit_share'))
              .width(20)
              .height(20)
              .fillColor(InkPalette.INK_FAINT)
            Text('分享')
              .fontSize(InkTypography.MICRO)
              .fontColor(InkPalette.INK)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { showMessage('功能开发中，暂未开放') })

          Column({ space: InkSpacing.XS }) {
            Image($r('app.media.export_1'))
              .width(20)
              .height(20)
              .fillColor(InkPalette.INK_FAINT)
            Text('导出')
              .fontSize(InkTypography.MICRO)
              .fontColor(InkPalette.INK)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { showMessage('功能开发中，暂未开放') })

          Column({ space: InkSpacing.XS }) {
            Image($r('app.media.delete'))
              .width(20)
              .height(20)
              .fillColor(InkPalette.INK_FAINT)
            Text('删除')
              .fontSize(InkTypography.MICRO)
              .fontColor(InkPalette.INK)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
                let checkRssSources = Object.values(this.batchList).filter(value => value === true).length
                if (checkRssSources <= 0) {
                  showMessage('请选择要删除的订阅源')
                  return
                }
                Object.keys(this.batchList).forEach((key: string) => {
                  if (this.batchList[key]) {
                    subscriptionDao.deleteRssSourcesById({ id: Number(key) })
                    this.batchList[key] = false
                  }
                })
                setTimeout(() => { this.refresh() }, 200)
                showMessage('删除成功!')
          })
        }
        .height(64)
        .width('100%')
        .backgroundColor(InkPalette.PAPER)
        .shadow(InkShadow.SOFT)
        .padding({ top: InkSpacing.SM })
      }

      Flex().width(0).height(0)
        .bindSheet($$this.isShowImport, this.dialogImportFunction(), {
          detents: [SheetSize.FIT_CONTENT, SheetSize.LARGE, 200],
          dragBar: true,
          showClose: false,
          onDisappear: () => { this.isShowImport = false }
        })

      Flex().width(0).height(0)
        .bindSheet($$this.isShowNewSources, this.dialogNewSourcesFunction(), {
          height: 200,
          dragBar: true,
          showClose: false,
          onDisappear: () => { this.isShowNewSources = false }
        })
    }
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[this.theme.mainColor, 0], [this.theme.secondColor, 0.15]]
    })
  }

  @Builder
  dialogImportFunction() {
    Flex() {
      SubscriptionImport({ subscriptionList: this.subscriptionList, show: this.isShowImport })
        .onDisAppear(() => { this.refresh() })
    }
  }

  @Builder
  dialogNewSourcesFunction() {
    Column() {
      dialogNewSources({ btnClick: () => { this.isShowNewSources = false } })
        .onDisAppear(() => { this.refresh() })
    }
  }

  @Builder
  MenuBuilder() {
    Column() {
      ForEach(this.moreList, (item: IconTitleVo, index) => {
        Column() {
          Row({ space: InkSpacing.SM }) {
            Image(item.icon)
              .width(20)
              .height(20)
              .fillColor(InkPalette.INK_FAINT)
            Text(item.title)
              .fontSize(InkTypography.BODY)
              .fontColor(InkPalette.INK)
          }
          .height(44)
          .width('100%')
          .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
          .onClick(() => { this.MenuOnclick(index) })

          if (index < this.moreList.length - 1) {
            Divider()
              .color(InkPalette.PAPER_DEEP)
              .margin({ left: 44 })
          }
        }
      })
    }
    .width(160)
    .backgroundColor(InkPalette.PAPER)
    .borderRadius(InkRadius.MD)
    .shadow(InkShadow.MEDIUM)
    .padding({ top: InkSpacing.XS, bottom: InkSpacing.XS })
  }

  async MenuOnclick(value: number | string) {
    switch (value) {
      case 0:
        this.pasteAnalyze()
        break
      case 1:
        showMessage('请选择本地json文件导入')
        this.localImport()
        break
      case 2:
        this.isShowNewSources = true
        break
      case 3:
        this.batchEdit = true
        getContext(this).eventHub.emit('SubscriptionBatchEdit', false)
        break
    }
  }

  async localImport() {
    let FileResult = await FileHandler.documentPickerFile(1, ['.json'])
    FileHandler.ReadJSONFile(FileResult[0]).then(result => {
      this.subscriptionList = JSON.parse(result) as rssSources[]
      this.isShowImport = true
    })
  }

  async pasteAnalyze() {
    try {
      let url = getPasteDataSync()
      if (!url) {
        showMessage('未获取到粘贴信息，请求默认数据')
        await sleep()
      }
      if (!isNetworkUrl(url ?? '')) {
        showMessage('复制的链接不正确')
        await sleep()
        url = undefined
      }
      const res: AxiosResponse = await axios
        .get(url ?? 'http://yuedu.miaogongzi.net/shuyuan/miaogongziDY.json')
      this.subscriptionList = res.data
      this.isShowImport = true
    } catch (err) {
      console.error('错误 ' + err)
    }
  }
}
