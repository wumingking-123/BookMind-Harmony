import searchKeywordDao, { SearchKeyword } from '../../database/dao/SearchKeywordDao';
import { promptAction } from '@kit.ArkUI';

@Component
export struct SearchHistory {
  @State historyList: SearchKeyword[] = []
  @State rotateState: boolean = false
  onSearch: (keyword: string) => void = () => {}

  aboutToAppear() {
    this.loadHistory()
  }

  async loadHistory() {
    this.historyList = await searchKeywordDao.getAll()
  }

  build() {
    Column() {
      // 搜索历史标题
      Row({ space: 90 }) {
        Text("搜索历史").width("40%").height(40).fontWeight(600).fontSize(20)
        Row({ space: 10 }) {
          Row() {
            Text(this.rotateState ? "收起" : "展开").fontColor($r("app.color.search_launch"))
            Image("/common/images/search_launch.svg").width(24).height(24).fillColor($r("app.color.search_launch"))
              .onClick(() => {
                this.rotateState = !this.rotateState
              })
              .animation({ duration: 1000, tempo: 2 })
              .rotate({ angle: this.rotateState ? 180 : 0 })
          }

          Image("/common/images/search_del.svg").width(24).height(24).fillColor($r("app.color.search_launch"))
            .onClick(() => {
              if (this.historyList.length === 0) return
              promptAction.showDialog({
                title: '提示',
                message: '确定要清空所有搜索历史吗？',
                buttons: [
                  { text: '取消', color: '#666666' },
                  { text: '确定', color: '#188BFF' }
                ]
              }).then((result) => {
                if (result.index === 1) {
                  searchKeywordDao.deleteAll().then(() => {
                    this.historyList = []
                  })
                }
              })
            })
        }
      }.width("100%").padding({ top: 10 })

      // 历史记录标签
      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
        ForEach(this.historyList, (item: SearchKeyword) => {
          Text(item.word)
            .padding({ top: 5, left: 15, right: 15 })
            .backgroundColor($r("app.color.search_history"))
            .margin({ right: 10, bottom: 10 })
            .fontSize(13)
            .onClick(() => {
              this.onSearch(item.word)
            })
        })
      }.width("100%")
      .height(this.rotateState ? 180 : 100)
      .padding({ top: 10, bottom: 10 })
      .clip(true)
    }.padding({
      left: 20,
      right: 20
    })
  }
}
