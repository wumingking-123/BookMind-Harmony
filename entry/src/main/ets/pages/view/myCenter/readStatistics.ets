import { ColumnModifier } from '../../../common/utils/ComponetModifier';
import { router } from '@kit.ArkUI';
import CommonConstants from '../../../common/constants/CommonConstants';
import { dataItem } from '../../../componets/dataList/dataItem';
import { readStatisticsDataList } from '../../../componets/myCenter/readStatisticsDataList';
import { readBookList } from '../../../componets/dataList/readBookList';
import { readTabs } from '../../../componets/myCenter/readTabs';
import { PublicConstants } from '../../../common/constants/PublicConstants';
import readRecordDao from '../../../database/dao/ReadRecordDao';
import booksDao from '../../../database/dao/BooksDao';
import bookMarkUtils from '../../../common/utils/BookMarkUtils';
import { BookMark } from '../../../database/entities/BookMark';


@Entry
@Component
struct readStatistics {

  Column = new ColumnModifier()
  @State type:number|string=(router.getParams() as dataItem).value
  @State read_list:dataItem[]=[
    new dataItem("小说",12),
    new dataItem("漫画",12),
    new dataItem("有声书",12),
  ]
  @State title_list:dataItem[]=[
    new dataItem("读过",12),
    new dataItem("读完",12),
    new dataItem("书签",12),
  ]
  @State read_index:number=0
  @State translateNum:number=0
  @State translateX:number=120
  @State dateValue:number[]=[2023,36]
  @Provide delStatus:boolean=false

  @State delDialog:boolean=false
  @State bookList: readBookList[] = []
  @State allBookmarkList: BookMark[] = []
  @Builder head(){
    Row(){
      Row(){
        Image($r("app.media.return_left"))
          .size({width:CommonConstants.TITLE_IMG_SIZE,height:CommonConstants.TITLE_IMG_SIZE})
          .onClick(()=>{
            router.back()
          })
      }.width("33%")
      Row(){
        Text(this.title_list[this.type].title).fontSize(16).fontWeight(600).lineHeight(24)
      }.width("33%")
      .justifyContent(FlexAlign.Center)
      Row(){
        Text(this.delStatus?"完成":"管理")
          .fontSize(14)
          .fontWeight(500)
          .lineHeight(22)
          .fontColor("rgba(0, 0, 0, 0.45)")
          .onClick(()=>{
            this.delStatus=!this.delStatus
          })
      }.width("33%").justifyContent(FlexAlign.End)
    }.width("100%")
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({top:12,bottom:12})
  }

  @Builder delBottom(){
      Button({ type: ButtonType.Normal, stateEffect: true }){
        Row(){
          Text("删除").fontColor(Color.Red)
        }.height("100%")
      }.backgroundColor(PublicConstants.THEME_COLOR_WHITE)
      .width("100%")
      .height(50)
      .borderColor("rgba(0, 0, 0, 0.06)")
      .borderWidth({
        top:1
      })
      .visibility(this.delStatus?Visibility.Visible:Visibility.None)
      .transition(
        TransitionEffect.asymmetric(
          TransitionEffect.OPACITY.animation({ duration: 500 }).combine(
            TransitionEffect.translate({ y: 50 }).animation({  duration: 500 }))
          ,
          TransitionEffect.OPACITY.animation({ duration: 500 }).combine(
            TransitionEffect.translate({ y: 0}).animation({ duration: 500 }))
        )
      )
    .onClick(()=>{
      this.deleteList()
    })
  }
  build() {
    Column(){
      Column(){
        this.head()
        if (this.type === 2) {
          // 书签列表
          if (this.allBookmarkList.length === 0) {
            Column() {
              Image($r('app.media.find_empty'))
                .width(100)
                .height(100)
                .opacity(0.6)
                .margin({ bottom: 16 })
              Text('暂无书签')
                .fontSize(14)
                .fontColor('#999999')
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            List() {
              ForEach(this.allBookmarkList, (item: BookMark, index: number) => {
                ListItem() {
                  Row() {
                    Column({ space: 8 }) {
                      Row() {
                        Text(item.chapterName || item.bookText || '未知章节')
                          .fontSize(14)
                          .fontWeight(FontWeight.Medium)
                          .fontColor('#E07A5F')
                          .layoutWeight(1)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })

                        Text(new Date(item.time).toLocaleDateString())
                          .fontSize(11)
                          .fontColor('#999999')
                      }
                      .width('100%')

                      Text(item.bookName)
                        .fontSize(12)
                        .fontColor('#6B5E52')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      if (item.content) {
                        Text(item.content)
                          .fontSize(13)
                          .fontColor('#8A7D71')
                          .lineHeight(18)
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    .padding({ top: 12, bottom: 12, left: 16 })

                    Image($r('app.media.delete'))
                      .width(20)
                      .height(20)
                      .fillColor('#D0D0D0')
                      .margin({ left: 12, right: 16 })
                      .onClick(async () => {
                        let success = await bookMarkUtils.deleteBookMark(item.time);
                        if (success) {
                          this.allBookmarkList = this.allBookmarkList.filter(b => b.time !== item.time);
                          this.title_list = [
                            new dataItem("读过", this.title_list[0].value),
                            new dataItem("读完", this.title_list[1].value),
                            new dataItem("书签", this.allBookmarkList.length),
                          ];
                        }
                      })
                  }
                  .width('100%')
                  .backgroundColor(Color.White)
                  .borderRadius(12)
                  .margin({ left: 16, right: 16, bottom: 8 })
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
            .padding({ top: 8 })
          }
        } else {
          readTabs({
            read_list:this.read_list
          })
          readStatisticsDataList({
            dateValue:this.dateValue,
            bookList:this.bookList
          })
        }
      }.attributeModifier(this.Column)
      .height(CommonConstants.FULL_HEIGHT)
      .width(CommonConstants.FULL_WIDTH)
    }.overlay( this.delBottom(), {
      align: Alignment.Bottom,
      offset: { x: 0, y: 0 }
    })

  }

  //删除列表
  deleteList(){
    this.clearInfoDel?.open()
  }
  onCancel(){

  }
  onAccept(){
    this.bookList=this.bookList.filter(item=>item.status!=true)
    this.bookList.forEach(item=>console.log(item.status+"--"))
    this.delStatus=!this.delStatus

  }
  exitApp() {
    this.delDialog = false
  }
  @Builder
  confirmDialogBuilder() {
    Column({ space: 16 }) {
      Text('确认删除吗？')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
      Row({ space: 16 }) {
        Button('取消')
          .onClick(() => { this.onCancel() })
        Button('确认')
          .onClick(() => { this.onAccept() })
      }
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }
  clearInfoDel: CustomDialogController | null = new CustomDialogController({
    builder: this.confirmDialogBuilder(),
    cancel: this.exitApp,
    autoCancel: true,
    alignment: DialogAlignment.Center,
    offset:{dx:0,dy:20},
    customStyle: true
  })
  async aboutToAppear() {
    console.log(this.type+"------")
    let allBooks = await booksDao.search();
    let records = await readRecordDao.getAllRecords();

    // 加载所有书签
    let allBookmarks = await bookMarkUtils.getAllBookMarks();
    this.allBookmarkList = allBookmarks;

    // 按书名分组统计书签数量
    let bookmarkCountMap: Map<string, number> = new Map();
    for (let bm of allBookmarks) {
      let key = bm.bookName + '|' + bm.bookAuthor;
      bookmarkCountMap.set(key, (bookmarkCountMap.get(key) || 0) + 1);
    }

    let newList: readBookList[] = [];
    let totalTime = 0;
    let totalDays = 0;

    for (let r of records) {
      let book = allBooks.find(b => b.bookName === r.bookName);
      if (book) {
        totalTime += r.readTime;
        totalDays += r.readDays;

        let hrs = Math.floor(r.readTime / 3600);
        let mins = Math.floor((r.readTime % 3600) / 60);
        let cover = book.coverUrl ? book.coverUrl : $r("app.media.book_cover");
        let bookAuthor = book.author || '未知';

        let schedule = 0;
        if (book.totalChapterNum > 0 && book.durChapterIndex !== undefined) {
           schedule = Math.floor((book.durChapterIndex / book.totalChapterNum) * 100);
        }

        let bmCount = bookmarkCountMap.get(r.bookName + '|' + bookAuthor) || 0;
        newList.push(new readBookList(r.bookName, cover, bookAuthor, [hrs, mins], new Date(r.lastRead), schedule, bmCount, r.readCount, false));
      }
    }

    this.bookList = newList;
    let totalHrs = Math.floor(totalTime / 3600);
    this.dateValue = [totalDays, totalHrs];

    // 更新 title_list 中的书签数量
    this.title_list = [
      new dataItem("读过", records.length),
      new dataItem("读完", newList.filter(b => b.schedule >= 100).length),
      new dataItem("书签", allBookmarks.length),
    ];
  }

}