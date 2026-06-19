import { router } from '@kit.ArkUI';
import { ThemeStorageKey } from '../../../common/constants/Theme';
import { ThemeItem } from '../../../common/model/Theme';
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../common/constants/DesignTokens';

@Entry
@Component
struct HelpCenterPage {
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @State SearchValue: string = ""
  @State MoreQuestionsIndex: number = 0
  @State MoreQuestionsRightWidth: number | string = 0
  @State questionsList: Array<string> = ["热门问题", "校验问题", "书源问题", "订阅问题", "备份恢复"]
  @State questionsShowList: Array<string> = [
    "1、为什么第一次安装好后什么都没有？",
    "2、遇到目录为空怎么办？",
    "3、替换净化是什么？",
  ]
  @State MoreQuestionsSideBarList: Array<string> = [
    "热门问题",
    "书源校验",
    "书源",
    "订阅源",
    "备份",
    "替换净化",
    "朗读引擎",
    "其他问题",
  ]
  @State MoreQuestionsItemList: Array<string> = [
    "为什么第一次安装好后打开什么都没有",
    "遇到目录为空怎么办",
    "替换净化是什么",
    "如何进行云备份",
    "如何导入本地书籍"
  ]
  scroller: Scroller = new Scroller()

  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  getMainColor(): string {
    return this.theme?.mainColor || InkPalette.CINNABAR;
  }

  getSecondColor(): string {
    return this.theme?.secondColor || InkPalette.PAPER_WARM;
  }

  build() {
    Column() {
      // 头部标题栏
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor(InkPalette.INK)
        }
        .width(InkLayout.MIN_TOUCH_TARGET)
        .height(InkLayout.MIN_TOUCH_TARGET)
        .borderRadius(InkRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { router.back() })

        Text('帮助中心')
          .fontSize(InkTypography.TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)
          .position({ left: '50%' })
          .translate({ x: '-50%' })
      }
      .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
      .width('100%')
      .height(InkLayout.HEADER_HEIGHT)
      .margin({ top: this.topRectHeight })

      // 搜索框区域
      Column() {
        Search({ value: this.SearchValue, placeholder: '搜索问题关键词' })
          .width("100%")
          .height(40)
          .backgroundColor(Color.White)
          .placeholderColor(InkPalette.INK_GHOST)
          .borderRadius(InkRadius.SEARCH)
          .shadow(InkShadow.SUBTLE)
      }
      .padding({ left: InkSpacing.PAGE_HORIZONTAL, right: InkSpacing.PAGE_HORIZONTAL, bottom: InkSpacing.LG })

      Scroll(this.scroller) {
        Flex({ direction: FlexDirection.Row }) {
          // 帮助中心左页
          Column() {
            Column() {
              Row() {
                Text("猜你想问")
                  .fontSize(InkTypography.TITLE_SMALL)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(InkPalette.INK)
                Blank()
                Row() {
                  Text("更多问题")
                    .fontSize(InkTypography.CAPTION)
                    .fontColor(InkPalette.INK_MIST)
                  Image($r("app.media.ic_public_right"))
                    .width(16)
                    .height(16)
                    .fillColor(InkPalette.INK_MIST)
                }
                .onClick(() => {
                  this.scroller.scrollEdge(Edge.End)
                })
              }
              .width("100%")

              Row() {
                Scroll() {
                  Row({ space: InkSpacing.SM }) {
                    ForEach(this.questionsList, (item: string, index) => {
                      this.question(item, index)
                    })
                  }
                }
                .scrollBar(BarState.Off)
                .scrollable(ScrollDirection.Horizontal)
              }
              .margin({ top: InkSpacing.LG, bottom: InkSpacing.LG })
              .width("100%")

              Column() {
                ForEach(this.questionsShowList, (item: string, index) => {
                  Column() {
                    Row() {
                      Text(item)
                        .fontSize(InkTypography.BODY)
                        .fontColor(InkPalette.INK_LIGHT)
                        .layoutWeight(1)
                      Image($r("app.media.ic_public_right"))
                        .width(18)
                        .height(18)
                        .fillColor(InkPalette.INK_WHISPER)
                    }
                    .width("100%")
                    .height(InkLayout.MIN_TOUCH_TARGET)
                    .onClick(() => {})

                    if (index < this.questionsShowList.length - 1) {
                      Divider()
                        .color(InkPalette.PAPER_WARM)
                        .strokeWidth(0.5)
                    }
                  }
                })
              }
              .width("100%")
            }
            .borderRadius(InkRadius.CARD)
            .width("100%")
            .backgroundColor(Color.White)
            .padding(InkSpacing.LG)
            .shadow(InkShadow.SUBTLE)
          }
          .width("50%")
          .padding({ left: InkSpacing.PAGE_HORIZONTAL, right: InkSpacing.PAGE_HORIZONTAL })

          // 帮助中心右页
          Column() {
            Row() {
              SideBarContainer(SideBarContainerType.Overlay) {
                Column() {
                  ForEach(this.MoreQuestionsSideBarList, (item: string, index) => {
                    Row() {
                      if (this.MoreQuestionsIndex === index) {
                        Row()
                          .width(3)
                          .height(16)
                          .borderRadius(1.5)
                          .backgroundColor(this.getMainColor())
                          .margin({ right: InkSpacing.XS })
                      }
                      Text(item)
                        .fontSize(InkTypography.CAPTION)
                        .fontWeight(this.MoreQuestionsIndex === index ? FontWeight.Medium : FontWeight.Normal)
                        .fontColor(this.MoreQuestionsIndex === index ? this.getMainColor() : InkPalette.INK)
                        .width("100%")
                        .textAlign(TextAlign.Center)
                    }
                    .height(48)
                    .width("100%")
                    .backgroundColor(this.MoreQuestionsIndex === index ? this.getSecondColor() : Color.White)
                    .onClick(() => {
                      this.MoreQuestionsIndex = index
                    })
                  })
                }
                .backgroundColor(Color.White)
              }
              .showControlButton(false)
              .width("28%")
              .borderRadius({ topLeft: InkRadius.CARD, bottomLeft: InkRadius.CARD })

              // 右侧内容显示
              Column() {
                ForEach(this.MoreQuestionsItemList, (item: string, index) => {
                  Column() {
                    Row() {
                      Text(item)
                        .fontSize(InkTypography.BODY)
                        .fontColor(InkPalette.INK_LIGHT)
                        .layoutWeight(1)
                      Image($r("app.media.ic_public_right"))
                        .width(18)
                        .height(18)
                        .fillColor(InkPalette.INK_WHISPER)
                    }
                    .width("100%")
                    .height(InkLayout.MIN_TOUCH_TARGET)

                    if (index < this.MoreQuestionsItemList.length - 1) {
                      Divider()
                        .color(InkPalette.PAPER_WARM)
                        .strokeWidth(0.5)
                    }
                  }
                })
              }
              .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
              .height("100%")
              .layoutWeight(1)
              .backgroundColor(Color.White)
              .borderRadius({ topRight: InkRadius.CARD, bottomRight: InkRadius.CARD })
            }
            .width("100%")
            .height(432)
            .shadow(InkShadow.SUBTLE)
          }
          .width("50%")
          .padding({ left: InkSpacing.PAGE_HORIZONTAL, right: InkSpacing.PAGE_HORIZONTAL })
        }
        .width("200%")
      }
      .scrollBar(BarState.Off)
      .scrollable(ScrollDirection.Horizontal)
      .scrollSnap({ snapAlign: ScrollSnapAlign.START, snapPagination: "100%" })
      .layoutWeight(1)
    }
    .height("100%")
    .backgroundColor(InkPalette.PAPER_EMBEDDED)
  }

  @Builder
  question(title: string, index: number) {
    Column() {
      Text(title)
        .fontColor(index === 0 ? this.getMainColor() : InkPalette.INK_LIGHT)
        .fontSize(InkTypography.CAPTION)
        .fontWeight(index === 0 ? FontWeight.Medium : FontWeight.Normal)
    }
    .borderRadius(InkRadius.SM)
    .padding({ left: InkSpacing.MD, right: InkSpacing.MD, top: InkSpacing.SM, bottom: InkSpacing.SM })
    .backgroundColor(index === 0 ? this.getSecondColor() : InkPalette.PAPER_WARM)
  }
}