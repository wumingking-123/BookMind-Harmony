import { display, promptAction, router, window } from '@kit.ArkUI';
import sourceView from './sourceView';
import { NetworkInput } from 'ets/componets/Reader/NetworkInput';
import DownloadSettingDialog from '../../../componets/Reader/DownloadSettingDialog';
import LayoutMoreDialog from '../../../componets/Reader/LayoutMoreDialog';
import BackgroundColorDialog from '../../../componets/Reader/BackgroundColorDialog';
import FlipModeDialog from '../../../componets/Reader/FlipModeDialog';
import { MusicPlayer } from 'ets/componets/Reader/MusicPlayer';
import { AudioPlayer } from 'ets/componets/Reader/AudioPlayer';
import purificationView from './purificationView';
import { Books } from '../../../database/entities/Books';
import { BookContentHolder } from '../../../common/utils/BookContentHolder';
import { InkPalette, InkSpacing, InkRadius, InkShadow, InkMotion, InkTypography } from '../../../common/constants/DesignTokens';
import { CoverFlipView, } from '@ohos/readerLibrary';
import {
  BGColorType,
  BG_COLOR_ARRAY,
  Constants,
  FlipPageType
} from '@ohos/readerLibrary/src/main/ets/common/constants/Constants';
import { SlideFlipView } from '@ohos/readerLibrary/src/main/ets/view/SlideFlipView';
import { UpDownFlipView } from '@ohos/readerLibrary/src/main/ets/view/UpDownFlipView';
import { BusinessError } from '@kit.BasicServicesKit';
import { SimulateCurlView } from '@ohos/readerLibrary/src/main/ets/view/SimulateCurlView';
import {
  ReaderChapterItem,
} from '@ohos/readerLibrary/src/main/ets/common/entity/ReaderChaptersItem';
import { ReaderProvider } from '@ohos/readerLibrary/src/main/ets/provider/configProvider';
import bookMarkUtils from '../../../common/utils/BookMarkUtils';
import { BookMark } from '../../../database/entities/BookMark';


interface ParamsObj {
  bookData: Books,
  clickBookChapter: number
}

@Entry
@Component
struct ReaderPage2 {
  @State bookData: Books | undefined = undefined
  currentChapters: number = 0
  chapterList: ReaderChapterItem[] = [];
  async aboutToAppear() {
    let temp = router.getParams() as ParamsObj
    this.bookData = temp.bookData
    console.log('router ReaderPage2:' + (this.bookData?.bookUrl || ''))

    // 从 BookContentHolder 获取章节数据 (避免通过 router 传递大量数据)
    let rawFile = BookContentHolder.getChapters();
    if (!rawFile || rawFile.length === 0) {
      console.error('BookContentHolder is empty, no chapters to display');
      return;
    }
    this.chapterList = rawFile.map((value) => {
      return new ReaderChapterItem(value.number, value.title, value.chapterTitleNumber, value.content);
    })

    this.currentChapters = temp.clickBookChapter

    this.changeSystemBarStatue();
  }


  changeSystemBarStatue(): void {
    window.getLastWindow(getContext(this), (err, data) => {
      const errCode = err.code;
      if (errCode) {
        return;
      }
      let SystemBarProperties: window.SystemBarProperties = {
        statusBarColor: BG_COLOR_ARRAY[BGColorType.WHITE],
        navigationBarColor: BG_COLOR_ARRAY[BGColorType.WHITE],
        navigationBarContentColor: Constants.TRANSPARENT
      };
      try {
        data.setWindowSystemBarProperties(SystemBarProperties, (err: BusinessError) => {
          const errCode: number = err.code;
          if (errCode) {
            console.error('Failed to set the system bar properties. Cause: ' + JSON.stringify(err));
            return;
          }
          data.setWindowBackgroundColor(BG_COLOR_ARRAY[BGColorType.WHITE]);
        });
      } catch (exception) {
        console.error('Failed to set the system bar properties. Cause: ' + JSON.stringify(exception));
      }
    });
  }

  onBgColorChanged() {
    this.changeSystemBarStatue();
  }

  build() {
    // 有声书显示播放器
    if (this.bookData?.bookType === 2) {
      Column() {
        // 返回按钮
        Row() {
          Image($r('app.media.ic_public_return_left'))
            .width(24)
            .height(24)
            .fillColor(InkPalette.INK)
            .onClick(() => { router.back(); })
        }
        .width('100%')
        .padding({ left: 16, top: 12 })

        AudioPlayer({ bookData: this.bookData })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(InkPalette.PAPER)
    } else {
      // 小说/漫画显示阅读器
      Row() {
        ReaderProvider({
          chapterList: this.chapterList,
          currentChapterIndex: this.currentChapters,
          child: this.contentBuilder
        })
      }
      .height('100%')
      .width('100%')
    }
  }

  @Builder
  contentBuilder() {
    Row() {
      ContentContainer({ bookData: this.bookData })
    }
  }
}

// 好像因为层级结构的关系，这块需要包裹一个控件，ReaderPageContent才可以获取到Provider提供的部分。
// todo：研究确认一下
@Component
struct ContentContainer {
  @Prop bookData: Books | undefined
  build() {
    Row() {
      ReaderPageContent({ bookData: this.bookData })
    }
  }
}

@Component
struct ReaderPageContent {
  @Prop bookData: Books | undefined
  @State isShowSetting: boolean = false
  @State isShowContentSetting: boolean = false
  @State isShowDownload: boolean = false
  @State isShowListen: boolean = false
  @State isShowMoreLayout: boolean = false
  @State isShowBgColorDialog: boolean = false
  @State isShowFlipModeDialog: boolean = false
  @State isAutoRead: boolean = false
  @State isFontChanged: boolean = false
  @State isShowSource: boolean = false
  @State isShowPurification: boolean = false
  @State isShowBookMarkList: boolean = false
  @State isCurrentBookMarked: boolean = false
  @State bookMarkList: BookMark[] = []
  @State screenH: number = 0
  @State screenW: number = 0
  @State readerPadding: number = 24 // 边距
  @State followSystemBrightness: boolean = true
  @State isNightMode: boolean = false
  private autoReadTimer: number = -1
  @Consume('fontSize') fontSize: number
  @Consume('lineHeightRatio') lineHeightRatio: number
  @Consume('bgColor') bgColor: string
  @Consume('chapterList') chapterList: ReaderChapterItem[]
  @Consume('turnStyle') turnStyle: FlipPageType
  @Consume('currentPageIndex') @Watch('onFlush') currentPageIndex: number
  @Consume('paragraphSpacing') paragraphSpacing: number
  @Consume('currentChapterIndex') currentChapterIndex: number
  @Consume('currentLuminance') currentLuminance: number
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0

  aboutToAppear(): void {
    this.screenW = px2vp(display.getDefaultDisplaySync().width);
    this.screenH = px2vp(display.getDefaultDisplaySync().height - (AppStorage.get('avoidHeight') as number));
    if (this.bookData && this.bookData.bookType === 2) {
      this.isShowListen = true;
    }
    this.checkCurrentBookMark()
    this.loadBookMarkList()
    this.loadBrightness()
  }

  aboutToDisappear(): void {
    if (this.autoReadTimer !== -1) {
      clearInterval(this.autoReadTimer)
      this.autoReadTimer = -1
    }
  }

  // 书签相关方法
  async checkCurrentBookMark() {
    let bookData = AppStorage.get<Books>('readerBookData')
    if (bookData) {
      this.isCurrentBookMarked = await bookMarkUtils.isBookMarked(
        bookData.bookName, bookData.author, this.currentChapterIndex)
    }
  }

  async loadBookMarkList() {
    let bookData = AppStorage.get<Books>('readerBookData')
    if (bookData) {
      this.bookMarkList = await bookMarkUtils.getBookMarks(bookData.bookName, bookData.author)
    }
  }

  async toggleBookMark() {
    let bookData = AppStorage.get<Books>('readerBookData')
    if (!bookData) return

    if (this.isCurrentBookMarked) {
      let marks = await bookMarkUtils.getBookMarks(bookData.bookName, bookData.author)
      let currentMark = marks.find(m => m.chapterIndex === this.currentChapterIndex)
      if (currentMark) {
        await bookMarkUtils.deleteBookMark(currentMark.time)
      }
      this.isCurrentBookMarked = false
      promptAction.showToast({ message: '已取消书签', duration: 1500 })
    } else {
      let ch = this.chapterList[this.currentChapterIndex]
      let mark = new BookMark()
      mark.bookName = bookData.bookName
      mark.bookAuthor = bookData.author
      mark.chapterIndex = this.currentChapterIndex
      mark.chapterPos = this.currentPageIndex
      mark.chapterName = `${ch?.chapterTitleNumber ?? ''} ${ch?.title ?? ''}`
      mark.bookText = ch?.paragraphList?.[0]?.substring(0, 50) ?? ''
      mark.content = ''
      await bookMarkUtils.addBookMark(mark)
      this.isCurrentBookMarked = true
      promptAction.showToast({ message: '已添加书签', duration: 1500 })
    }
    this.loadBookMarkList()
  }

  jumpToBookMark(mark: BookMark) {
    this.currentChapterIndex = mark.chapterIndex
    this.currentPageIndex = mark.chapterPos
    this.isShowBookMarkList = false
    this.isShowSetting = false
  }

  async deleteBookMarkItem(mark: BookMark) {
    await bookMarkUtils.deleteBookMark(mark.time)
    this.loadBookMarkList()
    this.checkCurrentBookMark()
  }

  get totalChapter(): number {
    return this.chapterList.length;
  }

  // 加载当前亮度
  async loadBrightness() {
    try {
      // 尝试获取系统亮度（需要权限）
      // 这里简化处理，实际需要调用系统API
      this.currentLuminance = 50 // 默认值
    } catch (err) {
      console.error('获取亮度失败:', err)
    }
  }

  // 设置亮度
  async setBrightness(value: number) {
    try {
      // 设置屏幕亮度（需要调用系统API）
      console.log('设置亮度:', value)
      promptAction.showToast({
        message: `亮度已调整至 ${value.toFixed(0)}%`,
        duration: 1000
      })
    } catch (err) {
      console.error('设置亮度失败:', err)
    }
  }

  // 切换夜间模式
  toggleNightMode() {
    this.isNightMode = !this.isNightMode
    if (this.isNightMode) {
      // 切换到夜间模式
      this.bgColor = BG_COLOR_ARRAY[BGColorType.GREY]
      this.currentLuminance = Math.min(this.currentLuminance, 30)
      this.setBrightness(this.currentLuminance)
      promptAction.showToast({
        message: '已切换至夜间模式',
        duration: 1500
      })
    } else {
      // 切换到日间模式
      this.bgColor = BG_COLOR_ARRAY[BGColorType.WHITE]
      promptAction.showToast({
        message: '已切换至日间模式',
        duration: 1500
      })
    }
  }

  // 切换自动阅读
  toggleAutoRead() {
    this.isAutoRead = !this.isAutoRead
    
    if (this.isAutoRead) {
      // 开始自动阅读
      promptAction.showToast({
        message: '自动阅读已开启',
        duration: 1500
      })
      
      // 每3秒翻页一次
      this.autoReadTimer = setInterval(() => {
        // 检查是否到达最后一页
        if (this.currentChapterIndex >= this.totalChapter - 1 &&
          this.currentPageIndex >= this.chapterList[this.currentChapterIndex].chapterPageList.length - 1) {
          // 到达最后一页，停止自动阅读
          this.toggleAutoRead()
          promptAction.showToast({
            message: '已阅读完毕',
            duration: 2000
          })
        } else {
          // 翻到下一页
          if (this.currentPageIndex < this.chapterList[this.currentChapterIndex].chapterPageList.length - 1) {
            this.currentPageIndex++
          } else if (this.currentChapterIndex < this.totalChapter - 1) {
            this.currentChapterIndex++
            this.currentPageIndex = 0
          }
        }
      }, 3000)
    } else {
      // 停止自动阅读
      if (this.autoReadTimer !== -1) {
        clearInterval(this.autoReadTimer)
        this.autoReadTimer = -1
      }
      promptAction.showToast({
        message: '自动阅读已关闭',
        duration: 1500
      })
    }
  }

  build() {
    Stack() {
      // 1. 小说文本内容层 (Z-Index 1)
      Row() {
        Row() {
          if (this.turnStyle === FlipPageType.COVER_FLIP_PAGE) {
            CoverFlipView()
          }
          if (this.turnStyle === FlipPageType.SIMULATE_FLIP_PAGE) {
            SimulateCurlView()
          }
          if (this.turnStyle === FlipPageType.SLIDE_FLIP_PAGE) {
            SlideFlipView()
          }
          if (this.turnStyle === FlipPageType.UP_DOWN_FLIP_PAGE) {
            UpDownFlipView()
          }
        }
        .width(Constants.FULL_PERCENT)
        .height(Constants.FULL_PERCENT)
      }
      .width(Constants.FULL_PERCENT)
      .height(Constants.FULL_PERCENT)
      .backgroundColor(this.bgColor)
      .padding({
        top: this.topRectHeight,
        bottom: this.bottomRectHeight,
      })
      .zIndex(1)
      .onClick((event?: ClickEvent) => {
        // 根据用户要求：删除点击翻页，点击屏幕任何区域均只用来呼出或隐藏菜单栏
        this.isShowSetting = !this.isShowSetting
      })

      // 2. 菜单设置层 (Z-Index 2)
      if (this.isShowSetting) {
        // 全屏半透明遮罩，点击关闭菜单
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.15)')
          .zIndex(2)
          .onClick(() => {
            this.isShowSetting = false
          })

        // 顶部工具栏 (Z-Index 3)
        Column() {
          Column() {
            Row({ space: 12 }) {
              Image($r("app.media.ic_public_return_left"))
                .width(24)
                .height(24)
                .fillColor(this.isNightMode ? '#E5E6EB' : '#1F2329')
                .onClick(() => {
                  router.back()
                })
              
              Column() {
                Text(`${this.chapterList[this.currentChapterIndex]?.chapterTitleNumber || ''} ${this.chapterList[this.currentChapterIndex]?.title || ''}`
                  .replace(new RegExp('\\s{1,}', 'g'), ' ')
                  .replaceAll('=', ''))
                  .fontSize(16)
                  .fontColor(this.isNightMode ? '#E5E6EB' : '#1F2329')
                  .fontWeight(550)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Row({ space: 16 }) {
                Image($r("app.media.refresh"))
                  .width(22)
                  .height(22)
                  .fillColor(this.isNightMode ? '#E5E6EB' : '#1F2329')
                  .onClick(() => {
                    promptAction.showToast({
                      message: '正在刷新章节...',
                      duration: 1500
                    })
                  })
                
                Image($r("app.media.down"))
                  .width(22)
                  .height(22)
                  .fillColor(this.isNightMode ? '#E5E6EB' : '#1F2329')
                  .onClick(() => {
                    this.isShowDownload = true
                  })
                  .bindSheet($$this.isShowDownload, this.DownloadDialog(), {
                    height: 500,
                    showClose: true,
                    dragBar: true,
                    blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
                  })
                
                Image($r("app.media.more"))
                  .width(22)
                  .height(22)
                  .fillColor(this.isNightMode ? '#E5E6EB' : '#1F2329')
                  .onClick(() => {
                    promptAction.showToast({
                      message: '更多功能开发中',
                      duration: 1500
                    })
                  })
              }
            }
            .padding({ top: this.topRectHeight + 12, left: 20, right: 20, bottom: 12 })
            .width("100%")

            // 搜索框
            Row() {
              NetworkInput()
            }
            .padding({ left: 20, right: 20, bottom: 16 })
            .width("100%")
          }
          .width("100%")
          .backgroundColor(this.isNightMode ? 'rgba(30, 30, 32, 0.96)' : 'rgba(250, 247, 240, 0.96)')
          .backgroundBlurStyle(this.isNightMode ? BlurStyle.Thick : BlurStyle.Thin)
          .borderRadius({ bottomLeft: 16, bottomRight: 16 })
          .shadow({
            radius: 12,
            color: this.isNightMode ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.08)',
            offsetY: 4
          })
          .transition(TransitionEffect.move(TransitionEdge.TOP).animation({ duration: 300, curve: Curve.EaseOut }))
          .onClick(() => {
            // Consume click event to prevent bubbling
          })
        }
        .width("100%")
        .height("100%")
        .justifyContent(FlexAlign.Start)
        .zIndex(3)
        .onClick(() => {
          this.isShowSetting = false
        })

        // 底部面板 (Z-Index 3)
        Column() {
          Column() {
            // ==================== 子面板 1: 进度面板 ====================
            if (!this.isShowContentSetting) {
              Column({ space: 16 }) {
                // 换源和净化
                Row({ space: 12 }) {
                  Button({ type: ButtonType.Normal }) {
                    Row({ space: 6 }) {
                      Image($r("app.media.change_source_icon"))
                        .width(16)
                        .height(16)
                        .fillColor(this.isNightMode ? '#A89B8C' : '#6B5E52')
                      Text("换源")
                        .fontSize(13)
                        .fontColor(this.isNightMode ? '#EDE4D3' : '#1A1612')
                        .fontWeight(500)
                    }
                  }
                  .borderRadius(8)
                  .height(38)
                  .layoutWeight(1)
                  .backgroundColor(this.isNightMode ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.04)')
                  .bindSheet($$this.isShowSource, this.sourceViewBuilder(), {
                    height: '95%',
                    showClose: true,
                    dragBar: true,
                    maskColor: 'rgba(0,0,0,0.6)',
                  })
                  .onClick(() => {
                    this.isShowSource = true
                  })

                  Button({ type: ButtonType.Normal }) {
                    Row({ space: 6 }) {
                      Image($r("app.media.purify_icon"))
                        .width(16)
                        .height(16)
                        .fillColor(this.isNightMode ? '#A89B8C' : '#6B5E52')
                      Text("净化")
                        .fontSize(13)
                        .fontColor(this.isNightMode ? '#EDE4D3' : '#1A1612')
                        .fontWeight(500)
                    }
                  }
                  .borderRadius(8)
                  .height(38)
                  .layoutWeight(1)
                  .backgroundColor(this.isNightMode ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.04)')
                  .bindSheet($$this.isShowPurification, this.purificationViewBuilder(), {
                    height: '40%',
                    showClose: true,
                    dragBar: true,
                    maskColor: 'rgba(0,0,0,0.6)',
                  })
                  .onClick(() => {
                    this.isShowPurification = true
                  })
                }
                .width("100%")

                // 进度控制滑块
                Row({ space: 12 }) {
                  Text("上一章")
                    .fontSize(13)
                    .fontColor(this.isNightMode ? '#EDE4D3' : '#4A4039')
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .borderRadius(6)
                    .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
                    .opacity(this.currentChapterIndex > 0 ? 1 : 0.4)
                    .onClick(() => {
                      if (this.currentChapterIndex > 0) {
                        this.currentChapterIndex--
                        this.currentPageIndex = 0
                        promptAction.showToast({ message: '上一章', duration: 1000 })
                      }
                    })

                  Slider({
                    value: this.currentChapterIndex,
                    max: this.totalChapter - 1,
                    min: 0,
                    step: 1,
                    style: SliderStyle.InSet
                  })
                    .trackThickness(6)
                    .selectedColor('#A89B7E')
                    .blockColor('#A89B7E')
                    .trackBorderRadius(3)
                    .blockSize({ width: 20, height: 20 })
                    .layoutWeight(1)
                    .onChange((value) => {
                      this.currentChapterIndex = Number(value.toFixed(0))
                      this.currentPageIndex = 0
                    })

                  Text("下一章")
                    .fontSize(13)
                    .fontColor(this.isNightMode ? '#EDE4D3' : '#4A4039')
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .borderRadius(6)
                    .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
                    .opacity(this.currentChapterIndex < this.totalChapter - 1 ? 1 : 0.4)
                    .onClick(() => {
                      if (this.currentChapterIndex < this.totalChapter - 1) {
                        this.currentChapterIndex++
                        this.currentPageIndex = 0
                        promptAction.showToast({ message: '下一章', duration: 1000 })
                      }
                    })
                }
                .width('100%')

                // 进度百分比信息
                Text(`第 ${this.currentChapterIndex + 1} 章 / 共 ${this.totalChapter} 章`)
                  .fontSize(12)
                  .fontColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
                  .textAlign(TextAlign.Center)
                  .width('100%')
              }
              .width("100%")
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
            }

            // ==================== 子面板 2: 样式面板 ====================
            if (this.isShowContentSetting) {
              Column({ space: 16 }) {
                // 亮度调节行
                Row({ space: 12 }) {
                  Image($r('app.media.brightness_low'))
                    .width(18)
                    .height(18)
                    .fillColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
                  
                  Slider({
                    value: this.currentLuminance,
                    max: 100,
                    min: 0,
                    step: 1,
                    style: SliderStyle.InSet
                  })
                    .trackThickness(6)
                    .selectedColor('#A89B7E')
                    .blockColor('#A89B7E')
                    .trackBorderRadius(3)
                    .blockSize({ width: 20, height: 20 })
                    .layoutWeight(1)
                    .enabled(!this.followSystemBrightness)
                    .onChange((value) => {
                      this.currentLuminance = value
                      this.setBrightness(value)
                    })

                  Image($r('app.media.brightness_high'))
                    .width(18)
                    .height(18)
                    .fillColor(this.isNightMode ? '#8A7D71' : '#6B5E52')

                  Button(this.followSystemBrightness ? '跟随系统' : '手动调节')
                    .fontSize(11)
                    .fontColor(this.isNightMode ? '#EDE4D3' : '#4A4039')
                    .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
                    .borderRadius(6)
                    .height(28)
                    .padding({ left: 10, right: 10 })
                    .onClick(() => {
                      this.followSystemBrightness = !this.followSystemBrightness
                      promptAction.showToast({
                        message: this.followSystemBrightness ? '已跟随系统亮度' : '已切换手动调节',
                        duration: 1500
                      })
                    })
                }
                .width('100%')

                // 字号调节行
                Row({ space: 12 }) {
                  Text('A-')
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
                    .width(24)
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      if (this.fontSize > 12) this.fontSize--
                    })
                  
                  Slider({
                    value: this.fontSize,
                    max: 48,
                    min: 12,
                    step: 1,
                    style: SliderStyle.InSet
                  })
                    .trackThickness(6)
                    .selectedColor('#A89B7E')
                    .blockColor('#A89B7E')
                    .trackBorderRadius(3)
                    .blockSize({ width: 20, height: 20 })
                    .layoutWeight(1)
                    .onChange((value) => {
                      this.fontSize = value
                    })
                  
                  Text('A+')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.isNightMode ? '#E5E6EB' : '#1F2329')
                    .width(24)
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      if (this.fontSize < 48) this.fontSize++
                    })

                  Text(`${this.fontSize.toFixed(0)}px`)
                    .fontSize(12)
                    .fontColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
                    .width(36)
                    .textAlign(TextAlign.End)
                }
                .width('100%')

                // 间距和段落设置
                Row({ space: 8 }) {
                  Button('紧凑')
                    .layoutWeight(1)
                    .fontSize(12)
                    .height(32)
                    .fontColor(this.lineHeightRatio === 1.6 ? '#FFFFFF' : (this.isNightMode ? '#EDE4D3' : '#6B5E52'))
                    .backgroundColor(this.lineHeightRatio === 1.6 ? '#A89B7E' : (this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)'))
                    .borderRadius(6)
                    .onClick(() => {
                      this.lineHeightRatio = 1.6
                      this.paragraphSpacing = 0
                      promptAction.showToast({ message: '已切换紧凑排版', duration: 1000 })
                    })
                  
                  Button('适中')
                    .layoutWeight(1)
                    .fontSize(12)
                    .height(32)
                    .fontColor(this.lineHeightRatio === 1.8 ? '#FFFFFF' : (this.isNightMode ? '#EDE4D3' : '#6B5E52'))
                    .backgroundColor(this.lineHeightRatio === 1.8 ? '#A89B7E' : (this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)'))
                    .borderRadius(6)
                    .onClick(() => {
                      this.lineHeightRatio = 1.8
                      this.paragraphSpacing = 2
                      promptAction.showToast({ message: '已切换适中排版', duration: 1000 })
                    })
                  
                  Button('宽松')
                    .layoutWeight(1)
                    .fontSize(12)
                    .height(32)
                    .fontColor(this.lineHeightRatio === 2.0 ? '#FFFFFF' : (this.isNightMode ? '#EDE4D3' : '#6B5E52'))
                    .backgroundColor(this.lineHeightRatio === 2.0 ? '#A89B7E' : (this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)'))
                    .borderRadius(6)
                    .onClick(() => {
                      this.lineHeightRatio = 2.0
                      this.paragraphSpacing = 4
                      promptAction.showToast({ message: '已切换宽松排版', duration: 1000 })
                    })
                  
                  Button('更多设置')
                    .layoutWeight(1.2)
                    .fontSize(12)
                    .height(32)
                    .fontColor('#A89B7E')
                    .backgroundColor(this.isNightMode ? 'rgba(168,155,126,0.15)' : '#F7F4F0')
                    .borderRadius(6)
                    .border({ width: 1, color: '#A89B7E' })
                    .bindSheet($$this.isShowMoreLayout, this.LayoutMoreDialogBuilder(), {
                      height: 520,
                      showClose: true,
                      dragBar: true,
                      blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
                    })
                    .onClick(() => {
                      this.isShowMoreLayout = true
                    })
                }
                .width('100%')

                // 背景、翻页、自动控制行
                Row({ space: 8 }) {
                  Button() {
                    Row({ space: 4 }) {
                      Image($r('app.media.background'))
                        .width(14)
                        .height(14)
                        .fillColor(this.isNightMode ? '#A89B8C' : '#6B5E52')
                      Text('阅读背景')
                        .fontSize(12)
                        .fontColor(this.isNightMode ? '#EDE4D3' : '#4A4039')
                    }
                  }
                  .layoutWeight(1)
                  .height(34)
                  .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
                  .borderRadius(6)
                  .bindSheet($$this.isShowBgColorDialog, this.BgColorDialogBuilder(), {
                    height: 420,
                    showClose: true,
                    dragBar: true,
                    blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
                  })
                  .onClick(() => {
                    this.isShowBgColorDialog = true
                  })

                  Button() {
                    Row({ space: 4 }) {
                      Image($r('app.media.flip_mode'))
                        .width(14)
                        .height(14)
                        .fillColor(this.isNightMode ? '#A89B8C' : '#6B5E52')
                      Text('翻页模式')
                        .fontSize(12)
                        .fontColor(this.isNightMode ? '#EDE4D3' : '#4A4039')
                    }
                  }
                  .layoutWeight(1)
                  .height(34)
                  .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
                  .borderRadius(6)
                  .bindSheet($$this.isShowFlipModeDialog, this.FlipModeDialogBuilder(), {
                    height: 480,
                    showClose: true,
                    dragBar: true,
                    blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
                  })
                  .onClick(() => {
                    this.isShowFlipModeDialog = true
                  })

                  Button() {
                    Row({ space: 4 }) {
                      Image(this.isAutoRead ? $r('app.media.pause') : $r('app.media.play'))
                        .width(14)
                        .height(14)
                        .fillColor(this.isNightMode ? '#A89B8C' : '#6B5E52')
                      Text(this.isAutoRead ? '暂停滚页' : '自动阅读')
                        .fontSize(12)
                        .fontColor(this.isNightMode ? '#EDE4D3' : '#4A4039')
                    }
                  }
                  .layoutWeight(1)
                  .height(34)
                  .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
                  .borderRadius(6)
                  .onClick(() => {
                    this.toggleAutoRead()
                  })
                }
                .width('100%')
              }
              .width("100%")
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
            }

            Divider().color(this.isNightMode ? 'rgba(255,255,255,0.1)' : '#F0F0F0').margin({ top: 8, bottom: 8 })

            // ==================== 底部固定导航栏 ====================
            Grid() {
              GridItem() {
                Column({ space: 4 }) {
                  Image($r("app.media.catalog"))
                    .width(22)
                    .height(22)
                    .fillColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
                  Text("目录")
                    .fontSize(11)
                    .fontColor(this.isNightMode ? '#A89B8C' : '#6B5E52')
                }
              }
              .onClick(() => {
                promptAction.showToast({ message: '目录功能开发中', duration: 1500 })
              })

              GridItem() {
                Column({ space: 4 }) {
                  Image($r("app.media.refresh")) // 用刷新图标临时表达进度
                    .width(22)
                    .height(22)
                    .fillColor(!this.isShowContentSetting ? '#A89B7E' : (this.isNightMode ? '#8A7D71' : '#6B5E52'))
                  Text("进度")
                    .fontSize(11)
                    .fontColor(!this.isShowContentSetting ? '#A89B7E' : (this.isNightMode ? '#A89B8C' : '#6B5E52'))
                }
              }
              .onClick(() => {
                this.isShowContentSetting = false
              })

              GridItem() {
                Column({ space: 4 }) {
                  Image($r("app.media.listen"))
                    .width(22)
                    .height(22)
                    .fillColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
                  Text("听书")
                    .fontSize(11)
                    .fontColor(this.isNightMode ? '#A89B8C' : '#6B5E52')
                }
              }
              .bindContentCover($$this.isShowListen, this.BookListen(), {
                modalTransition: ModalTransition.DEFAULT,
                backgroundColor: "rgba(51, 106, 128, 0.75)"
              })
              .onClick(() => {
                if (this.bookData?.bookType === 2) {
                  this.isShowListen = true
                } else {
                  promptAction.showToast({ message: '当前书籍不支持听书', duration: 1500 })
                }
              })

              GridItem() {
                Column({ space: 4 }) {
                  Image($r("app.media.bookmark"))
                    .width(22)
                    .height(22)
                    .fillColor(this.isCurrentBookMarked ? '#FF6B6B' : (this.isNightMode ? '#8A7D71' : '#6B5E52'))
                  Text("书签")
                    .fontSize(11)
                    .fontColor(this.isCurrentBookMarked ? '#FF6B6B' : (this.isNightMode ? '#A89B8C' : '#6B5E52'))
                }
              }
              .onClick(() => {
                this.toggleBookMark()
              })
              .bindSheet($$this.isShowBookMarkList, this.BookMarkListSheet(), {
                height: 400,
                showClose: false,
                dragBar: true,
                blurStyle: BlurStyle.COMPONENT_ULTRA_THIN
              })

              GridItem() {
                Column({ space: 4 }) {
                  Image(this.isNightMode ? $r("app.media.day_icon") : $r("app.media.night_icon"))
                    .width(22)
                    .height(22)
                    .fillColor(this.isNightMode ? '#A89B7E' : '#6B5E52')
                  Text(this.isNightMode ? "日间" : "夜间")
                    .fontSize(11)
                    .fontColor(this.isNightMode ? '#A89B8C' : '#6B5E52')
                }
              }
              .onClick(() => {
                this.toggleNightMode()
              })

              GridItem() {
                Column({ space: 4 }) {
                  Image(this.isShowContentSetting ? $r("app.media.my_center_set_icon_fill") : $r("app.media.my_center_set_icon"))
                    .width(22)
                    .height(22)
                    .fillColor(this.isShowContentSetting ? '#A89B7E' : (this.isNightMode ? '#8A7D71' : '#6B5E52'))
                  Text("设置")
                    .fontSize(11)
                    .fontColor(this.isShowContentSetting ? '#A89B7E' : (this.isNightMode ? '#A89B8C' : '#6B5E52'))
                }
              }
              .onClick(() => {
                this.isShowContentSetting = true
              })
            }
            .columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr")
            .width("100%")
            .height(56)
            .padding({ bottom: this.bottomRectHeight })
          }
          .width("100%")
          .backgroundColor(this.isNightMode ? 'rgba(30, 30, 32, 0.96)' : 'rgba(250, 247, 240, 0.96)')
          .backgroundBlurStyle(this.isNightMode ? BlurStyle.Thick : BlurStyle.Thin)
          .borderRadius({ topLeft: 16, topRight: 16 })
          .shadow({
            radius: 12,
            color: this.isNightMode ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.08)',
            offsetY: -4
          })
          .transition(TransitionEffect.move(TransitionEdge.BOTTOM).animation({ duration: 300, curve: Curve.EaseOut }))
          .onClick(() => {
            // Consume click event to prevent bubbling
          })
        }
        .width("100%")
        .height("100%")
        .justifyContent(FlexAlign.End)
        .zIndex(3)
        .onClick(() => {
          this.isShowSetting = false
        })
      }
    }
    .height('100%')
    .width('100%')
  }

  private clickAnimateTo(isLeft: boolean) {
    if (isLeft) {
      // 向左翻 = 翻前页
      const prevChapter = this.currentChapterIndex;
      const prevPage = this.currentPageIndex;
      const prevIdx = prevPage > 0
        ? [prevChapter, prevPage - 1]
        : (prevChapter > 0 && this.chapterList[prevChapter - 1].chapterPageList.length > 0
          ? [prevChapter - 1, this.chapterList[prevChapter - 1].chapterPageList.length - 1]
          : null);

      if (prevIdx === null) {
        promptAction.showToast({ message: Constants.MSG_FLIP_OVER, duration: Constants.PROMPT_DURATION });
        return;
      }
      this.currentChapterIndex = prevIdx[0];
      this.currentPageIndex = prevIdx[1];
    } else {
      // 向右翻 = 翻后页
      const curChapter = this.currentChapterIndex;
      const curPage = this.currentPageIndex;
      const pageCount = this.chapterList[curChapter]?.chapterPageList.length ?? 0;
      const nextIdx = curPage < pageCount - 1
        ? [curChapter, curPage + 1]
        : (curChapter < this.chapterList.length - 1 && this.chapterList[curChapter + 1].chapterPageList.length > 0
          ? [curChapter + 1, 0]
          : null);

      if (nextIdx === null) {
        promptAction.showToast({ message: Constants.MSG_FLIP_OVER, duration: Constants.PROMPT_DURATION });
        return;
      }
      this.currentChapterIndex = nextIdx[0];
      this.currentPageIndex = nextIdx[1];
    }
  }

  onFlush() {
    console.info('currentPageNum=' + this.currentPageIndex + ', isFontChanged=' + this.isFontChanged);
    if (this.isFontChanged && this.currentPageIndex === 0) {
      this.isFontChanged = false;
      this.currentPageIndex = 0;
    }
  }

  @Builder
  BookMarkListSheet() {
    Column() {
      Row() {
        Text('书签列表')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('长按删除')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.bookMarkList.length === 0) {
        Column() {
          Text('暂无书签')
            .fontColor('#999999')
            .fontSize(14)
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.bookMarkList, (mark: BookMark) => {
            ListItem() {
              Row() {
                Column({ space: 4 }) {
                  Text(mark.chapterName)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(mark.bookText)
                    .fontSize(12)
                    .fontColor('#999999')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(new Date(mark.time).toLocaleString())
                    .fontSize(11)
                    .fontColor('#BBBBBB')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Image($r("app.media.ic_public_right"))
                  .width(16)
                  .height(16)
                  .fillColor('#CCCCCC')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .onClick(() => {
                this.jumpToBookMark(mark)
              })
              .gesture(
                LongPressGesture({ repeat: false })
                  .onAction(() => {
                    this.deleteBookMarkItem(mark)
                  })
              )
            }
          })
        }
        .divider({
          strokeWidth: 0.5,
          color: '#F0F0F0',
          startMargin: 16,
          endMargin: 16
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  sourceViewBuilder() {
    Column() {
      Column() {
        Row().width(36).height(4).backgroundColor($r('app.string.color_black_15')).borderRadius(12)
      }
      .padding({ top: 12 })

      sourceView()
    }
  }

  @Builder
  purificationViewBuilder() {
    Column() {
      purificationView({
        isShowPurification: this.isShowPurification
      })
    }
  }

  @Builder
  DialogString() {
    Row() {
      Text("喜欢就加入书架吧")
        .lineHeight(22)
        .font({
          size: 14,
          weight: 400
        })
        .fontColor($r("app.string.color_black_45"))
    }
    .margin({
      top: 12,
      bottom: 16
    })
  }

  onBackPress() {
    // this.dialogController.open();
    return false
  }

  @Builder
  BookListen() {
    MusicPlayer({ WidthMinus: 118, isShowListen: this.isShowListen, bookData: this.bookData })
      .width("100%")
      .height("100%")
  }

  @Builder
  DownloadDialog() {
    Column() {
      DownloadSettingDialog({
        isShowDownload: this.isShowDownload,
        isShowSetting: this.isShowSetting,
      })
    }
  }

  @Builder
  LayoutMoreDialogBuilder() {
    LayoutMoreDialog()
      .height(520)
      .width("100%")
  }

  @Builder
  BgColorDialogBuilder() {
    BackgroundColorDialog()
      .width("100%")
  }

  @Builder
  FlipModeDialogBuilder() {
    FlipModeDialog()
      .width("100%")
  }
}