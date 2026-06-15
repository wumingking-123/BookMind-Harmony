import bookHistoryDao from '../../../../database/dao/BookHistoryDao'
import { BookHistory } from '../../../../database/entities/BookHistory'
import BookHistoryInfo from './BookHistoryInfo'
import { ThemeStorageKey } from '../../../../common/constants/Theme'
import { ThemeItem } from '../../../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius
} from '../../../../common/constants/DesignTokens'

@Component
export default struct BookHistoryContent {
  @State bookHistory:BookHistory[] = []
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @Prop searchValue:string
  @Prop @Watch('changeBookType')currentIndex: number
  //更新数据累加刷新数据页面
  @StorageLink('BOOK_IS_BOOK_HISTORY_REFRESHING') @Watch('getBookHistoryList') isBookHistoryRefreshing: number = 0
  aboutToAppear(): void {
    this.getBookHistoryList()
  }
  changeBookType(){
    this.getBookHistoryList()
    this.isBookHistoryRefreshing++
  }
  getBookHistoryList(){
    bookHistoryDao.search({
      type:this.currentIndex,
      sort:0
    }).then((val)=>{
      this.bookHistory = val
    })
  }

  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  build() {
    if (this.bookHistory.length === 0){
      Column({ space: InkSpacing.LG }) {
        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width(100)
            .height(100)
            .borderRadius(InkRadius.FULL)
            .backgroundColor(this.theme.secondColor)
          Image($r('app.media.icon_no_source_find'))
            .width(64)
            .height(64)
            .opacity(0.7)
        }
        .width(100)
        .height(100)

        Text('暂无浏览记录')
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK_LIGHT)

        Text('去书架看看有什么好书吧')
          .fontSize(InkTypography.CAPTION)
          .fontColor(InkPalette.INK_MIST)
      }
      .margin({ top: 80 })
    } else {
      Column(
        {space:10}
      ){
        Column(
          { space: 10 }
        ) {
          ForEach(this.bookHistory, (item: BookHistory) => {
            BookHistoryInfo({
              bookHistory:item
            })
          })
        }
        .backgroundColor('rgba(255,250,247,0.8)')
      }
    }
  }
}