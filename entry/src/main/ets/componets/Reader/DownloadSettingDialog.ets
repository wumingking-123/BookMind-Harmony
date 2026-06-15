import { AddDownloadDialog } from 'ets/componets/Reader/AddDownloadDialog';
import { ThemeStorageKey } from '../../common/constants/Theme';
import { ThemeItem } from '../../common/model/Theme';
import downloadManager from '../../common/utils/DownloadManager';
import { BookSource } from '../../database/entities/BookSource';

@Component
export default struct DownloadSettingDialog {
  @Link isShowDownload: boolean// 下载-缓存结束章节
  @Link isShowSetting: boolean// 下载-缓存结束章节
  bookUrl: string = ''
  bookName: string = ''
  bookAuthor: string = ''
  bookSource?: BookSource
  tocUrl: string = ''
  totalChapters: number = 0
  currentChapter: number = 0

  // 加入下载列表Dialog
  DownloadDialogController: CustomDialogController = new CustomDialogController({
    builder: AddDownloadDialog(),
    cornerRadius: 8,
    offset: { dx: 0, dy: -100 }
  })
  @State selectedIndex: number = -1
  @State StartText: string = "1" // 下载-缓存开始章节
  @State EndText: string = "2" // 下载-缓存结束章节
  controller: TextInputController = new TextInputController()
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  build() {
    Column() {
      Grid() {
        GridItem() {
          Row() {
            Text("缓存后50章")
            Blank(1)
            Checkbox()
              .select(this.selectedIndex === 0)
              .onChange((value: boolean) => {
                if (value) this.selectedIndex = 0
              })
          }
          .width("100%")
        }
        .onClick(() => {
          this.selectedIndex = 0
        })

        GridItem() {
          Row() {
            Text("缓存后面全部章节")
            Blank(1)
            Checkbox()
              .select(this.selectedIndex === 1)
              .onChange((value: boolean) => {
                if (value) this.selectedIndex = 1
              })
          }
          .width("100%")
        }
        .onClick(() => {
          this.selectedIndex = 1
        })

        GridItem() {
          Row() {
            Text("缓存全部")
            Blank(1)
            Checkbox()
              .select(this.selectedIndex === 2)
              .onChange((value: boolean) => {
                if (value) this.selectedIndex = 2
              })
          }
          .width("100%")
        }
        .onClick(() => {
          this.selectedIndex = 2
        })

        GridItem() {
          Row() {
            Text("自定义缓存")
            Blank(1)
            Checkbox()
              .select(this.selectedIndex === 3)
              .onChange((value: boolean) => {
                if (value) this.selectedIndex = 3
              })
          }
          .width("100%")
        }
        .onClick(() => {
          this.selectedIndex = 3
        })

        GridItem() {
          Row({ space: 16 }) {
            TextInput({ text: this.StartText, controller: this.controller })
              .type(InputType.Number)
              .width(107)
              .height(38)
              .borderRadius(8)
              .fontSize(20)
              .fontWeight(400)
              .lineHeight(22)
              .textAlign(TextAlign.Center)
              .backgroundColor("white")
              .border({
                width: 1,
                color: "gray"
              })
              .onChange((value: string) => {
                this.StartText = value
              })

            Text("至")

            TextInput({ text: this.EndText, controller: this.controller })
              .type(InputType.Number)
              .width(107)
              .height(38)
              .borderRadius(8)
              .fontSize(20)
              .fontWeight(400)
              .lineHeight(22)
              .textAlign(TextAlign.Center)
              .backgroundColor("white")
              .border({
                width: 1,
                color: "gray"
              })
              .onChange((value: string) => {
                this.EndText = value
              })
          }
          .width("100%")
        }
      }
      .padding({
        top: 16
      })
      .height("80%")
      .columnsTemplate("1fr")
      .rowsTemplate("1fr 1fr 1fr 1fr 1fr")

      Blank(1)
      Grid() {
        GridItem() {
          Button() {
            Text("取消")
              .lineHeight(24)
              .fontColor(this.theme.mainColor)
              .font({
                size: 16,
                weight: 500
              })
          }
          .width("80%")
          .height(40)
          .backgroundColor(this.theme.secondColor)
          .onClick(() => {
            this.isShowDownload = false
            this.isShowSetting = false
          })
        }

        GridItem() {
          Button() {
            Text("确定")
              .fontColor("white")
              .lineHeight(24)
              .font({
                size: 16,
                weight: 500
              })
          }
          .width("80%")
          .height(40)
          .backgroundColor(this.theme.mainColor)
          .onClick(() => {
            this.startDownload()
            this.isShowDownload = false
            this.isShowSetting = false
            this.DownloadDialogController.open()
            setTimeout(() => {
              this.DownloadDialogController.close()
            }, 1000)
          })
        }
      }
      .height(64)
      .columnsTemplate("1fr 1fr")
      .rowsTemplate("1fr")
      .width("100%")
      .padding({
        top: 12,
        bottom: 12
      })
    }
    .height(500)
    .padding({
      left: 20,
      right: 20
    })
  }

  private startDownload(): void {
    if (!this.bookSource) return;

    let start = 0;
    let end = -1; // -1 表示全部

    switch (this.selectedIndex) {
      case 0: // 后50章
        start = this.currentChapter;
        end = Math.min(this.currentChapter + 49, this.totalChapters - 1);
        break;
      case 1: // 后面全部
        start = this.currentChapter;
        end = this.totalChapters - 1;
        break;
      case 2: // 全部
        start = 0;
        end = this.totalChapters - 1;
        break;
      case 3: // 自定义
        start = parseInt(this.StartText) - 1;
        end = parseInt(this.EndText) - 1;
        if (isNaN(start) || start < 0) start = 0;
        if (isNaN(end) || end >= this.totalChapters) end = this.totalChapters - 1;
        break;
      default:
        return;
    }

    downloadManager.addTask(
      this.bookUrl,
      this.bookName,
      this.bookAuthor,
      this.bookSource,
      this.tocUrl,
      start,
      end
    );
  }
}
