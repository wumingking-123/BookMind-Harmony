import { SearchBook } from '../../database/entities/SearchBook'
import { router } from '@kit.ArkUI'
import clickUtil from '../../common/utils/ClickUtils'
import { ThemeStorageKey } from '../../common/constants/Theme'
import { ThemeItem } from '../../common/model/Theme'

@Component
export struct SearchBookItem {
  @Prop SearchValue:string
  @Prop book:SearchBook
  @State fontColor:string="rgba(0, 0, 0, 0.45)"
  @Prop index:number
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem
  build() {
    Row({space:20}){
      Image(this.book.coverUrl).size({
        width:70,
        height:100
      })
        .alt($r('app.media.icon_book_default_cover_five'))
      Column({space:5}){
        //书名
        Row(){
          Text(this.book.name)
            .fontColor(this.SearchValue=== this.book.name ? this.theme.mainColor :"#000000")
        }
        //作者及书源数量
        Row({space:2}){
          Text(this.book.author)
            .fontSize(14)
            .fontColor(this.fontColor)
          Text("·")
            .fontSize(14)
            .fontColor(this.fontColor)
          Text("共"+this.book.belongCount+"个源")
            .fontSize(14)
            .fontColor(this.fontColor)
        }

        //书籍描述
        Text(this.book.intro)
          .layoutWeight(1)
          .fontSize(14)
          .maxLines(2)
          .fontColor(this.fontColor)
          .textOverflow({overflow:TextOverflow.Ellipsis})
      }.alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .onClick(()=>{
      clickUtil.preventClick(()=>{
        router.pushUrl({
          url: 'pages/view/BookDetailPage',
          params: {
            bookName: this.book.name,
            coverUrl: this.book.coverUrl,
            author: this.book.author,
            intro: this.book.intro,
            kind:this.book.kind,
            bookUrl:this.book.bookUrl,
            wordCount:this.book.wordCount,
            bookType:this.book.bookType,
            toUrl:this.book.tocUrl,
            source:this.book.source,
            sourceList:this.book.sourceList,
            origin:this.book.source?.bookSourceUrl,
            originName:this.book.source?.bookSourceName
          }
        })
      })
    })

    .size({
      width:"100%",
      height:120
    }).margin({left:20,right:20})
  }

}