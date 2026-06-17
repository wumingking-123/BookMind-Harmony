import { ReaderChapterItem } from '@ohos/readerLibrary/src/main/ets/common/entity/ReaderChaptersItem';
import { Books } from '../../database/entities/Books';
import { BookMark } from '../../database/entities/BookMark';
import bookMarkUtils from '../../common/utils/BookMarkUtils';

@Component
export struct ReaderCatalog {
  @Prop bookData: Books | undefined;
  @Prop chapterList: ReaderChapterItem[];
  @Prop currentChapterIndex: number;
  @Prop isNightMode: boolean;
  @Link isShowCatalog: boolean;
  @Link isShowSetting: boolean;

  @State catalogSearchKey: string = "";
  @Link catalogTabIndex: number;
  private catalogScroller: Scroller = new Scroller();

  @State bookmarkList: BookMark[] = [];

  jumpToChapter?: (chapterIndex: number, pageIndex: number) => void;

  aboutToAppear() {
    this.loadBookmarks();
  }

  async loadBookmarks() {
    if (!this.bookData) return;
    this.bookmarkList = await bookMarkUtils.getBookMarks(this.bookData.bookName, this.bookData.author);
  }

  build() {
    Column() {
      // 顶部 Tab 切换
      Row() {
        Text('目录')
          .fontSize(16)
          .fontWeight(this.catalogTabIndex === 0 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.catalogTabIndex === 0 ? '#E07A5F' : (this.isNightMode ? '#8A7D71' : '#6B5E52'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => this.catalogTabIndex = 0)
          
        Text('书签')
          .fontSize(16)
          .fontWeight(this.catalogTabIndex === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.catalogTabIndex === 1 ? '#E07A5F' : (this.isNightMode ? '#8A7D71' : '#6B5E52'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.catalogTabIndex = 1;
            this.loadBookmarks();
          })
      }
      .width('100%')
      .height(48)
      .border({ width: { bottom: 1 }, color: this.isNightMode ? 'rgba(255,255,255,0.05)' : '#F0F0F0' })

      if (this.catalogTabIndex === 0) {
        Row() {
          Search({ placeholder: '搜索章节...', value: this.catalogSearchKey })
            .width('100%')
            .height(36)
            .onChange((val) => {
              this.catalogSearchKey = val;
            })
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 8 })

        List({ scroller: this.catalogScroller }) {
          ForEach(this.chapterList.filter(item => item.title.includes(this.catalogSearchKey) || String(item.chapterTitleNumber).includes(this.catalogSearchKey)), (item: ReaderChapterItem) => {
            ListItem() {
              Row() {
                Text(`${item.chapterTitleNumber || ''} ${item.title || ''}`.replace(new RegExp('\\s{1,}', 'g'), ' '))
                  .fontSize(14)
                  .fontColor(this.currentChapterIndex === this.chapterList.indexOf(item)
                    ? '#A89B7E' 
                    : (this.isNightMode ? '#EDE4D3' : '#1F2329'))
                  .fontWeight(this.currentChapterIndex === this.chapterList.indexOf(item)
                    ? FontWeight.Bold 
                    : FontWeight.Normal)
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                if (this.currentChapterIndex === this.chapterList.indexOf(item)) {
                  Image($r('app.media.ic_select'))
                    .width(16)
                    .height(16)
                    .fillColor('#A89B7E')
                }
              }
              .width('100%')
              .height(44)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                const realIndex = this.chapterList.indexOf(item);
                if (realIndex !== -1) {
                  if (this.jumpToChapter) {
                    this.jumpToChapter(realIndex, 0);
                  } else {
                    // Fallback
                  }
                  this.isShowCatalog = false;
                  this.isShowSetting = false;
                }
              })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .onAppear(() => {
          setTimeout(() => {
            this.catalogScroller.scrollToIndex(this.currentChapterIndex);
          }, 100);
        })
      } else {
        if (this.bookmarkList.length === 0) {
          Column() {
            Image($r('app.media.find_empty'))
              .width(100)
              .height(100)
              .opacity(this.isNightMode ? 0.3 : 0.6)
              .margin({ bottom: 16 })
            Text('暂无书签，快去添加吧~')
              .fontSize(14)
              .fontColor(this.isNightMode ? '#555555' : '#999999')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.bookmarkList, (item: BookMark, index: number) => {
              ListItem() {
                Row() {
                  Column({ space: 8 }) {
                    Row() {
                      Text(item.chapterName || item.bookText)
                        .fontSize(14)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.isNightMode ? '#A89B7E' : '#E07A5F')
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      
                      Text(new Date(item.time).toLocaleDateString())
                        .fontSize(11)
                        .fontColor(this.isNightMode ? '#555555' : '#999999')
                    }
                    .width('100%')

                    Text(item.content)
                      .fontSize(13)
                      .fontColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
                      .lineHeight(18)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .padding({ top: 12, bottom: 12, left: 16 })
                  .onClick(() => {
                    if (this.jumpToChapter) {
                      this.jumpToChapter(item.chapterIndex, item.chapterPos);
                    }
                    this.isShowCatalog = false;
                    this.isShowSetting = false;
                  })

                  Image($r('app.media.delete'))
                    .width(20)
                    .height(20)
                    .fillColor(this.isNightMode ? '#555555' : '#D0D0D0')
                    .margin({ left: 12, right: 16 })
                    .onClick(async () => {
                      if (!this.bookData) return;
                      let success = await bookMarkUtils.deleteBookMark(item.time);
                      if (success) {
                        this.loadBookmarks();
                      }
                    })
                }
                .width('100%')
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isNightMode ? '#252527' : '#F6F5F2')
  }
}
