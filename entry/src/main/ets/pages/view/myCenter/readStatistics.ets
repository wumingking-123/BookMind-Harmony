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
import { Books } from '../../../database/entities/Books';
import { promptAction } from '@kit.ArkUI';
import { FileHandler } from '../../../common/utils/FileHandler';
import { BookContentHolder } from '../../../common/utils/BookContentHolder';
import { InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow } from '../../../common/constants/DesignTokens';


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
  @State allBooksList: Books[] = []
  @State selectedBookmarkTimes: number[] = []
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
            if (!this.delStatus) {
              this.selectedBookmarkTimes = [];
              this.bookList.forEach(item => item.status = false);
            }
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
                .margin({ bottom: InkSpacing.LG })
              Text('暂无书签')
                .fontSize(InkTypography.BODY)
                .fontColor(InkPalette.INK_MIST)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            List() {
              ForEach(this.allBookmarkList, (item: BookMark, index: number) => {
                ListItem() {
                  Row() {
                    // 1. Cover Image
                    Image(this.getBookCover(item))
                      .size({ width: 60, height: 80 })
                      .borderRadius(InkRadius.BOOK_COVER)
                      .margin({ right: 12 })

                    // 2. Middle Info
                    Column({ space: 6 }) {
                      Text(item.bookName)
                        .fontSize(InkTypography.BODY_LARGE)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(InkPalette.INK)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Row() {
                        Text(item.bookAuthor || '未知作者')
                          .fontSize(InkTypography.BODY_SMALL)
                          .fontColor(InkPalette.INK_LIGHT)
                        Text(' | ')
                          .fontSize(InkTypography.BODY_SMALL)
                          .fontColor(InkPalette.INK_MIST)
                        Text(item.chapterName || item.bookText || '未知章节')
                          .fontSize(InkTypography.BODY_SMALL)
                          .fontColor(InkPalette.CINNABAR_LIGHT)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .layoutWeight(1)
                      }
                      .width('100%')

                      if (item.content) {
                        Text(item.content)
                          .fontSize(InkTypography.CAPTION)
                          .fontColor(InkPalette.INK_MEDIUM)
                          .lineHeight(InkTypography.CAPTION * InkTypography.LINE_HEIGHT_NORMAL)
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .padding(6)
                          .backgroundColor(InkPalette.PAPER_WARM)
                          .borderRadius(InkRadius.XS)
                          .width('100%')
                      }
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    // 3. Right Status / Controls
                    Column() {
                      if (this.delStatus) {
                        Checkbox({ name: 'bookmark_' + index })
                          .select(this.selectedBookmarkTimes.includes(item.time))
                          .selectedColor(0xed6f21)
                          .shape(CheckBoxShape.CIRCLE)
                          .onChange((value: boolean) => {
                            if (value) {
                              if (!this.selectedBookmarkTimes.includes(item.time)) {
                                this.selectedBookmarkTimes.push(item.time);
                              }
                            } else {
                              this.selectedBookmarkTimes = this.selectedBookmarkTimes.filter(t => t !== item.time);
                            }
                          })
                      } else {
                        Text(new Date(item.time).toLocaleDateString())
                          .fontSize(InkTypography.CAPTION)
                          .fontColor(InkPalette.INK_MIST)
                          .margin({ bottom: 12 })

                        Image($r('app.media.delete'))
                          .width(16)
                          .height(16)
                          .fillColor(InkPalette.INK_MIST)
                          .gesture(
                            TapGesture()
                              .onAction(async () => {
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
                          )
                      }
                    }
                    .alignItems(HorizontalAlign.End)
                    .justifyContent(FlexAlign.SpaceBetween)
                    .height(80)
                    .margin({ left: 8 })
                  }
                  .padding(12)
                  .width('100%')
                  .backgroundColor(InkPalette.PAPER_PURE)
                  .borderRadius(InkRadius.CARD)
                  .shadow(InkShadow.SUBTLE)
                  .onClick(async () => {
                    if (this.delStatus) {
                      if (this.selectedBookmarkTimes.includes(item.time)) {
                        this.selectedBookmarkTimes = this.selectedBookmarkTimes.filter(t => t !== item.time);
                      } else {
                        this.selectedBookmarkTimes.push(item.time);
                      }
                      return;
                    }
                    let book = this.allBooksList.find(b => b.bookName && b.bookName.trim() === item.bookName.trim() && b.author === item.bookAuthor);
                    if (!book) {
                      book = this.allBooksList.find(b => b.bookName && b.bookName.trim() === item.bookName.trim());
                    }
                    if (book) {
                      promptAction.showToast({ message: '正在加载书籍...', duration: 1000 });
                      let temp = await FileHandler.readFile(book.bookUrl || '');
                      BookContentHolder.setChapters(temp);
                      router.pushUrl({
                        url: canIUse("SystemCapability.Reader.ReaderService.ReaderCore")
                          ? 'pages/view/Reader/ReaderPageKit'
                          : 'pages/view/Reader/ReaderPage2',
                        params: {
                          bookData: book,
                          clickBookChapter: item.chapterIndex
                        }
                      });
                    } else {
                      promptAction.showToast({ message: '未找到相关书籍，可能已被删除', duration: 1500 });
                    }
                  })
                }
                .padding({ bottom: 12 })
              })
            }
            .width('100%')
            .layoutWeight(1)
            .padding({ top: 8, left: InkSpacing.LG, right: InkSpacing.LG })
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

  // 查找书籍封面辅助方法
  getBookCover(item: BookMark): ResourceStr {
    if (!item || !item.bookName) {
      return $r("app.media.book_cover");
    }
    let book = this.allBooksList.find(b => b.bookName && b.bookName.trim() === item.bookName.trim() && b.author === item.bookAuthor);
    if (!book) {
      book = this.allBooksList.find(b => b.bookName && b.bookName.trim() === item.bookName.trim());
    }
    if (book) {
      let cover = book.coverUrl || book.cover;
      if (cover && cover !== 'null' && cover !== 'undefined' && cover.trim() !== '') {
        return cover;
      }
    }
    return $r("app.media.book_cover");
  }

  //删除列表
  deleteList(){
    this.clearInfoDel?.open()
  }
  onCancel(){
    this.clearInfoDel?.close()
  }
  async onAccept(){
    if (this.type === 2) {
      // 批量删除书签
      for (let time of this.selectedBookmarkTimes) {
        await bookMarkUtils.deleteBookMark(time);
      }
      this.allBookmarkList = this.allBookmarkList.filter(item => !this.selectedBookmarkTimes.includes(item.time));
      this.selectedBookmarkTimes = [];
      this.title_list = [
        new dataItem("读过", this.title_list[0].value),
        new dataItem("读完", this.title_list[1].value),
        new dataItem("书签", this.allBookmarkList.length),
      ];
    } else {
      this.bookList=this.bookList.filter(item=>item.status!=true)
      this.bookList.forEach(item=>console.log(item.status+"--"))
    }
    this.delStatus = false
    this.clearInfoDel?.close()
  }
  exitApp() {
    this.delDialog = false
  }
  @Builder
  confirmDialogBuilder() {
    Column({ space: 16 }) {
      Text('确认删除吗？')
        .fontSize(InkTypography.TITLE_SMALL)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK)
      Row({ space: 16 }) {
        Button('取消', { type: ButtonType.Normal })
          .onClick(() => { this.onCancel() })
          .backgroundColor(InkPalette.PAPER_WARM)
          .fontColor(InkPalette.INK_LIGHT)
          .borderRadius(8)
          .width(80)
        Button('确认', { type: ButtonType.Normal })
          .onClick(() => { this.onAccept() })
          .backgroundColor(InkPalette.CINNABAR)
          .fontColor(Color.White)
          .borderRadius(8)
          .width(80)
      }
    }
    .padding(24)
    .backgroundColor(InkPalette.PAPER_PURE)
    .borderRadius(InkRadius.DIALOG)
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
    this.allBooksList = allBooks;

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