import PaddingConstants from '../../../../common/constants/PaddingConstants'
import noSourceFind from '../../../../componets/common/noSourceFind'
import RefreshComponent from '../../../../componets/common/RefreshComponent'
import { BookSource } from '../../../../database/entities/BookSource'
import BookFindContent from './BookFindContent'
import { JSON } from '@kit.ArkTS'
import { ExploreRule } from '../../../../database/entities/rule'
import { ExploreItem } from '../../../../database/types/BookSourceType'
import AllCategory, { GroupExploreList } from './AllCategory'
import { ThemeItem } from '../../../../common/model/Theme'
import { ThemeStorageKey } from '../../../../common/constants/Theme'

@Component
export default struct ContentRefresh {
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @Link @Watch('onRefresh')refreshCount: number
  currentIndex: number = 0
  @Prop bookSource: BookSource = {
    bookSourceUrl: '',
    bookSourceName: '',
    bookSourceType: 0,
    customOrder: 0,
    enabled: false,
    enabledExplore: false,
    lastUpdateTime: 0,
    respondTime: 0,
    weight: 0,
    isTop: false,
    showRecentIcon: false,
    showExplore: true
  }
  @State isRefreshing: boolean = false
  @State RefreshingTitle: string = '松开刷新'
  @State counter: number = 0
  @Link hasExploreUrl: boolean
  @State groupExploreList: GroupExploreList[] = []
  @State exploreList: ExploreItem[] = []
  @State showExploreList: ExploreItem[] = []
  @State exploreRule?: ExploreRule = {}
  @State showSheet: boolean = false
  @State selectedTabIndex: number = 0
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  aboutToAppear() {
    this.getList()
  }

  onRefresh() {
    setTimeout(this.getList, 500)
  }

  getList () {
    try {
      this.exploreRule = this.bookSource.ruleExplore
      console.info('TagInfo: 书源地址：', this.bookSource.bookSourceUrl)
      console.info('TagInfo: 发现地址：', JSON.stringify(JSON.parse(this.bookSource.exploreUrl ?? '[]')))
      const exploreList = JSON.parse(this.bookSource.exploreUrl ?? '[]') as ExploreItem[]
      this.exploreList = exploreList
      this.showExploreList = exploreList.filter(item => !!item.url)
      this.selectedTabIndex = 0
      this.getGroupExploreList()
    } catch (err) {
      console.info('TagInfo', JSON.stringify(err))
    }
  }

  getGroupExploreList() {
    const groupMap: Record<string, GroupExploreList> = {};
    let currentTitle = ''
    this.exploreList.forEach((item: ExploreItem) => {
      if (!item.title.trim()) {
        return
      }
      if (item.style?.layout_flexBasisPercent === 1 || !currentTitle) {
        let keyTitle = item.title
        if (item.style?.layout_flexBasisPercent !== 1) {
          keyTitle = 'null'
        }
        groupMap[keyTitle] = {
          title: keyTitle,
          url: keyTitle === 'null' ? '' : item.url,
          columnsTemplate: '1fr',
          list: []
        };
        currentTitle = keyTitle
      }

      let columnsTemplate = '1fr'
      const flexBasis = item.style?.layout_flexBasisPercent ?? 0
      if (flexBasis > 0.33 && flexBasis <= 0.5) {
        columnsTemplate += ' 1fr'
      } else if (flexBasis >= 0.25 && flexBasis <= 0.33) {
        columnsTemplate += ' 1fr 1fr'
      } else if (flexBasis < 0.25) {
        columnsTemplate += ' 1fr 1fr 1fr'
      }
      if (groupMap[currentTitle].columnsTemplate !== columnsTemplate) {
        groupMap[currentTitle].columnsTemplate = columnsTemplate
      }
      groupMap[currentTitle].list.push(item);
    })
    this.groupExploreList = Object.values(groupMap);
    console.info('TagInfo:', JSON.stringify(this.groupExploreList))
  }

  build() {
    if (!this.bookSource.exploreUrl) {
      noSourceFind({
        setOnclick: () => {
          this.hasExploreUrl = true
        }
      })
        .margin({
          top: PaddingConstants.PADDING_20
        })
    } else {
      Column() {
        // 横向分类标签栏
        if (this.showExploreList.length > 1) {
          Scroll() {
            Row({ space: 16 }) {
              ForEach(this.showExploreList, (item: ExploreItem, index: number) => {
                Text(item.title)
                  .fontSize(14)
                  .fontColor(this.selectedTabIndex === index ? this.theme.mainColor : '#999999')
                  .fontWeight(this.selectedTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .borderRadius(16)
                  .backgroundColor(this.selectedTabIndex === index ? this.theme.secondColor : 'transparent')
                  .onClick(() => {
                    this.selectedTabIndex = index
                  })
              })
            }
            .padding({ left: 16, right: 16 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
          .padding({ top: 12, bottom: 4 })
        }

        // 当前选中分类的内容
        if (this.showExploreList.length > 0) {
          Refresh({ refreshing: $$this.isRefreshing, builder: this.refreshComponent }) {
            BookFindContent({
              currentIndex: this.currentIndex,
              bookSourceUrl: this.bookSource.bookSourceUrl,
              exploreItem: this.showExploreList[this.selectedTabIndex],
              exploreRule: this.exploreRule,
              charset: this.bookSource.charset,
              counter: this.counter,
              handleClick: () => {
                this.showSheet = true
              }
            })
            .height('100%')
          }
          .onStateChange((refreshStatus: RefreshStatus) => {
            if (refreshStatus === 1 || refreshStatus === 2) {
              this.RefreshingTitle = '松开刷新'
            } else {
              this.RefreshingTitle = '刷新中...'
            }
          })
          .layoutWeight(1)
          .onRefreshing(() => {
            setTimeout(() => {
              this.counter++
              this.isRefreshing = false
            }, 1000)
          })
        }
      }
      .height('100%')
      .bindSheet(this.showSheet, this.bottomSheet(), {
        detents: [SheetSize.FIT_CONTENT, SheetSize.LARGE, 200],
        dragBar: true,
        showClose: false,
        onDisappear: () => {
          this.showSheet = false
        }
      })
    }
  }

  @Builder
  refreshComponent() {
    RefreshComponent({
      RefreshingTitle: this.RefreshingTitle,
    })
  }

  @Builder
  bottomSheet() {
    Column() {
      AllCategory({
        showSheet: this.showSheet,
        bookSourceUrl: this.bookSource.bookSourceUrl,
        exploreRule: this.exploreRule,
        list: this.groupExploreList
      })
    }
  }
}