import { display, promptAction, router, window } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
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

    // 获取并设置初始背景颜色，避免闪烁
    let initialColor = BG_COLOR_ARRAY[BGColorType.WHITE];
    try {
      const pref = await preferences.getPreferences(getContext(this), 'readerSettings');
      initialColor = await pref.get('bgColor', BG_COLOR_ARRAY[BGColorType.WHITE]) as string;
    } catch (e) {
      console.error('Failed to load initial bgColor preference:', e);
    }
    this.changeSystemBarStatue(initialColor);
  }


  changeSystemBarStatue(color: string = BG_COLOR_ARRAY[BGColorType.WHITE]): void {
    window.getLastWindow(getContext(this), (err, data) => {
      const errCode = err.code;
      if (errCode) {
        return;
      }
      let SystemBarProperties: window.SystemBarProperties = {
        statusBarColor: color,
        navigationBarColor: color,
        navigationBarContentColor: Constants.TRANSPARENT
      };
      try {
        data.setWindowSystemBarProperties(SystemBarProperties, (err: BusinessError) => {
          const errCode: number = err.code;
          if (errCode) {
            console.error('Failed to set the system bar properties. Cause: ' + JSON.stringify(err));
            return;
          }
          data.setWindowBackgroundColor(color);
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
  @State screenH: number = 0
  @State screenW: number = 0
  @State readerPadding: number = 24 // 边距
  @State followSystemBrightness: boolean = true
  @State isNightMode: boolean = false
  private autoReadTimer: number = -1
  @Consume('fontSize') @Watch('onFontSizeChanged') fontSize: number
  @Consume('lineHeightRatio') @Watch('onLineHeightRatioChanged') lineHeightRatio: number
  @Consume('bgColor') @Watch('onBgColorChanged') bgColor: string
  @Consume('chapterList') chapterList: ReaderChapterItem[]
  @Consume('turnStyle') turnStyle: FlipPageType
  @Consume('currentPageIndex') @Watch('onFlush') currentPageIndex: number
  @Consume('paragraphSpacing') @Watch('onParagraphSpacingChanged') paragraphSpacing: number
  @Consume('currentChapterIndex') @Watch('onChapterIndexChanged') currentChapterIndex: number
  @Consume('currentLuminance') currentLuminance: number
  @Consume('fontWeight') @Watch('onFontWeightChanged') fontWeight: number
  @Consume('fontType') @Watch('onFontTypeChanged') fontType: string
  @Consume('letterSpacing') @Watch('onLetterSpacingChanged') letterSpacing: number
  @State sliderFontSize: number = 20
  @State sliderChapterIndex: number = 0
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @State isShowCatalog: boolean = false
  @State isBookmarked: boolean = false
  @State catalogSearchKey: string = ""
  @State sessionMinutes: number = 1
  @State isShowMoreMenu: boolean = false
  private sessionStartTime: number = Date.now()
  private sessionTimerId: number = -1
  private catalogScroller: Scroller = new Scroller()
  @State panelFontSize: number = 20
  @State panelFontWeight: number = 400
  @State panelFontType: string = 'simplified'
  @State panelParagraphSpacing: number = 0
  @State panelLetterSpacing: number = 0
  @State panelLineHeightRatio: number = 1.8

  aboutToAppear(): void {
    this.screenW = px2vp(display.getDefaultDisplaySync().width);
    this.screenH = px2vp(display.getDefaultDisplaySync().height - (AppStorage.get('avoidHeight') as number));
    if (this.bookData && this.bookData.bookType === 2) {
      this.isShowListen = true;
    }
    this.loadBrightness()
    this.changeSystemBarStatue()
    this.sliderFontSize = this.fontSize
    this.sliderChapterIndex = this.currentChapterIndex
    this.sessionStartTime = Date.now()
    this.sessionTimerId = setInterval(() => {
      this.sessionMinutes = Math.max(1, Math.floor((Date.now() - this.sessionStartTime) / 60000) + 1);
    }, 30000)
    this.checkBookmarkState()
    
    // 初始化设置面板本地状态
    this.panelFontSize = this.fontSize
    this.panelFontWeight = this.fontWeight
    this.panelFontType = this.fontType
    this.panelParagraphSpacing = this.paragraphSpacing
    this.panelLetterSpacing = this.letterSpacing
    this.panelLineHeightRatio = this.lineHeightRatio
  }

  aboutToDisappear(): void {
    // 清理自动阅读定时器
    if (this.autoReadTimer !== -1) {
      clearInterval(this.autoReadTimer)
      this.autoReadTimer = -1
    }
    if (this.sessionTimerId !== -1) {
      clearInterval(this.sessionTimerId)
      this.sessionTimerId = -1
    }
  }

  onBgColorChanged() {
    this.changeSystemBarStatue();
  }

  onFontSizeChanged() {
    this.panelFontSize = this.fontSize
    this.sliderFontSize = this.fontSize
  }

  onLineHeightRatioChanged() {
    this.panelLineHeightRatio = this.lineHeightRatio
  }

  onParagraphSpacingChanged() {
    this.panelParagraphSpacing = this.paragraphSpacing
  }

  onFontWeightChanged() {
    this.panelFontWeight = this.fontWeight
  }

  onFontTypeChanged() {
    this.panelFontType = this.fontType
  }

  onLetterSpacingChanged() {
    this.panelLetterSpacing = this.letterSpacing
  }

  onChapterIndexChanged() {
    this.sliderChapterIndex = this.currentChapterIndex
    this.checkBookmarkState()
  }

  async checkBookmarkState() {
    if (!this.bookData) {
      return;
    }
    try {
      const pref = await preferences.getPreferences(getContext(this), 'readerSettings');
      const key = `bookmark_${this.bookData.id}_${this.currentChapterIndex}_${this.currentPageIndex}`;
      this.isBookmarked = await pref.get(key, false) as boolean;
    } catch (e) {
      console.error('Failed to check bookmark state:', e);
    }
  }

  async toggleBookmark() {
    if (!this.bookData) {
      return;
    }
    try {
      const pref = await preferences.getPreferences(getContext(this), 'readerSettings');
      const key = `bookmark_${this.bookData.id}_${this.currentChapterIndex}_${this.currentPageIndex}`;
      this.isBookmarked = !this.isBookmarked;
      await pref.put(key, this.isBookmarked);
      await pref.flush();
      promptAction.showToast({
        message: this.isBookmarked ? '已添加书签' : '已取消书签',
        duration: 1500
      });
    } catch (e) {
      console.error('Failed to toggle bookmark:', e);
    }
  }

  calculateReadPercentage(): string {
    if (!this.chapterList || this.chapterList.length === 0) {
      return '0';
    }
    const currentChapterPages = this.chapterList[this.currentChapterIndex]?.chapterPageList?.length ?? 1;
    const currentChapterProgress = currentChapterPages > 0 ? this.currentPageIndex / currentChapterPages : 0;
    const progress = (this.currentChapterIndex + currentChapterProgress) / this.chapterList.length;
    return (progress * 100).toFixed(0);
  }

  @Builder
  NumberAdjuster(label: string, value: string | number, onMinus: () => void, onPlus: () => void) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(11)
        .fontColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
      Row() {
        Text('—')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isNightMode ? '#EDE4D3' : '#1A1612')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => onMinus())
        
        Text(String(value))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isNightMode ? '#EDE4D3' : '#1A1612')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Text('+')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isNightMode ? '#EDE4D3' : '#1A1612')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => onPlus())
      }
      .width('100%')
      .height(34)
      .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
      .borderRadius(6)
    }
    .layoutWeight(1)
  }

  @Builder
  FontSelector() {
    Column({ space: 4 }) {
      Text('字体')
        .fontSize(11)
        .fontColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
      Row() {
        Text(this.panelFontType === 'traditional' ? '系统繁中' : '系统预设')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isNightMode ? '#EDE4D3' : '#1A1612')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(34)
      .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
      .borderRadius(6)
      .onClick(() => {
        this.panelFontType = this.panelFontType === 'traditional' ? 'simplified' : 'traditional';
        this.fontType = this.panelFontType;
        promptAction.showToast({
          message: this.fontType === 'traditional' ? '已切换至系统繁体' : '已切换至系统简体',
          duration: 1500
        });
      })
    }
    .layoutWeight(1)
  }

  @Builder
  MoreMenuBuilder() {
    Column() {
      Row() {
        Image($r('app.media.close'))
          .width(20)
          .height(20)
          .fillColor(this.isNightMode ? '#E5E6EB' : '#1F2329')
          .onClick(() => {
            this.isShowMoreMenu = false;
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ top: 16, left: 16, right: 16, bottom: 8 })

      Row({ space: 16 }) {
        Image(this.bookData?.coverUrl || $r('app.media.book_cover'))
          .width(54)
          .height(72)
          .borderRadius(4)
          .objectFit(ImageFit.Cover)
          .shadow({ radius: 6, color: 'rgba(0,0,0,0.15)', offsetY: 2 })

        Column({ space: 6 }) {
          Text(this.bookData?.bookName || '未知书籍')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isNightMode ? '#EDE4D3' : '#1A1612')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.bookData?.author || '未知作者')
            .fontSize(13)
            .fontColor(this.isNightMode ? '#8A7D71' : '#6B5E52')

          Text(`累计 ${this.sessionMinutes} 分钟 · 平均 ${Math.floor(1200 / Math.max(1, this.sessionMinutes))} 字/分钟`)
            .fontSize(11)
            .fontColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 20 })

      Divider().color(this.isNightMode ? 'rgba(255,255,255,0.08)' : '#F0F0F0')

      List() {
        ListItem() {
          this.MoreMenuRow($r('app.media.my_center_theme_icon'), '主题', () => {
            this.isShowMoreMenu = false;
            this.isShowBgColorDialog = true;
          })
        }

        ListItem() {
          this.MoreMenuRow($r('app.media.my_center_purify_icon'), '删除或替换文字', () => {
            this.isShowMoreMenu = false;
            this.isShowPurification = true;
          })
        }

        ListItem() {
          this.MoreMenuRow($r('app.media.style_icon'), `调节边距 (当前: ${this.readerPadding}vp)`, () => {
            if (this.readerPadding === 16) {
              this.readerPadding = 24;
            } else if (this.readerPadding === 24) {
              this.readerPadding = 32;
            } else {
              this.readerPadding = 16;
            }
            promptAction.showToast({ message: `边距已调整为 ${this.readerPadding}vp`, duration: 1500 });
          })
        }

        ListItem() {
          this.MoreMenuRow($r('app.media.my_center_set_icon'), '其他设置', () => {
            this.isShowMoreMenu = false;
            this.isShowFlipModeDialog = true;
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isNightMode ? '#252527' : '#F6F5F2')
  }

  @Builder
  MoreMenuRow(icon: Resource, title: string, onClick: () => void) {
    Row() {
      Image(icon)
        .width(20)
        .height(20)
        .fillColor(this.isNightMode ? '#A89B8C' : '#6B5E52')
        .margin({ right: 12 })
      
      Text(title)
        .fontSize(14)
        .fontColor(this.isNightMode ? '#EDE4D3' : '#1A1612')
        .layoutWeight(1)

      Image($r('app.media.ic_public_right'))
        .width(16)
        .height(16)
        .fillColor(this.isNightMode ? '#555555' : '#D0D0D0')
    }
    .width('100%')
    .height(48)
    .onClick(() => onClick())
  }

  @Builder
  CatalogBuilder() {
    Column() {
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
                this.currentChapterIndex = realIndex;
                this.currentPageIndex = 0;
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isNightMode ? '#252527' : '#F6F5F2')
  }

  changeSystemBarStatue(): void {
    const color = this.bgColor || BG_COLOR_ARRAY[BGColorType.WHITE];
    window.getLastWindow(getContext(this), (err, data) => {
      const errCode = err.code;
      if (errCode) {
        return;
      }
      let SystemBarProperties: window.SystemBarProperties = {
        statusBarColor: color,
        navigationBarColor: color,
        navigationBarContentColor: Constants.TRANSPARENT
      };
      try {
        data.setWindowSystemBarProperties(SystemBarProperties, (err: BusinessError) => {
          const errCode: number = err.code;
          if (errCode) {
            console.error('Failed to set the system bar properties. Cause: ' + JSON.stringify(err));
            return;
          }
          data.setWindowBackgroundColor(color);
        });
      } catch (exception) {
        console.error('Failed to set the system bar properties. Cause: ' + JSON.stringify(exception));
      }
    });
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
                if (!this.bookData?.isLocalBook) {
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
                }
                
                Image($r("app.media.more"))
                  .width(22)
                  .height(22)
                  .fillColor(this.isNightMode ? '#E5E6EB' : '#1F2329')
                  .onClick(() => {
                    this.isShowMoreMenu = true
                  })
                  .bindSheet($$this.isShowMoreMenu, this.MoreMenuBuilder(), {
                    height: 380,
                    showClose: false,
                    dragBar: true,
                    blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
                  })
              }
            }
            .padding({ top: this.topRectHeight + 12, left: 20, right: 20, bottom: 12 })
            .width("100%")

            // 搜索框
            if (!this.bookData?.isLocalBook) {
              Row() {
                NetworkInput()
              }
              .padding({ left: 20, right: 20, bottom: 16 })
              .width("100%")
            }
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
                Row({ space: 12 }) {
                  Image($r("app.media.ic_public_return_left"))
                    .width(20)
                    .height(20)
                    .fillColor(this.isNightMode ? '#EDE4D3' : '#6B5E52')
                    .opacity(this.currentChapterIndex > 0 ? 1 : 0.4)
                    .onClick(() => {
                      if (this.currentChapterIndex > 0) {
                        this.currentChapterIndex--
                        this.currentPageIndex = 0
                        this.sliderChapterIndex = this.currentChapterIndex
                        promptAction.showToast({ message: '上一章', duration: 1000 })
                      }
                    })

                  Slider({
                    value: this.sliderChapterIndex,
                    max: this.totalChapter - 1,
                    min: 0,
                    step: 1,
                    style: SliderStyle.InSet
                  })
                    .trackThickness(10)
                    .selectedColor('#A89B7E')
                    .blockColor('#E07A5F')
                    .trackBorderRadius(5)
                    .blockSize({ width: 14, height: 14 })
                    .layoutWeight(1)
                    .onChange((value, mode) => {
                      this.sliderChapterIndex = Number(value.toFixed(0))
                      if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                        this.currentChapterIndex = this.sliderChapterIndex
                        this.currentPageIndex = 0
                      }
                    })

                  Image($r("app.media.ic_public_right"))
                    .width(20)
                    .height(20)
                    .fillColor(this.isNightMode ? '#EDE4D3' : '#6B5E52')
                    .opacity(this.currentChapterIndex < this.totalChapter - 1 ? 1 : 0.4)
                    .onClick(() => {
                      if (this.currentChapterIndex < this.totalChapter - 1) {
                        this.currentChapterIndex++
                        this.currentPageIndex = 0
                        this.sliderChapterIndex = this.currentChapterIndex
                        promptAction.showToast({ message: '下一章', duration: 1000 })
                      }
                    })
                }
                .width('100%')
              }
              .width("100%")
              .padding({ left: 20, right: 20, top: 16, bottom: 8 })
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
                  
                  Row({ space: 6 }) {
                    Checkbox()
                      .select(this.followSystemBrightness)
                      .selectedColor('#A89B7E')
                      .unselectedColor(this.isNightMode ? '#555555' : '#D0D0D0')
                      .width(14)
                      .height(14)
                      .onChange((value) => {
                        this.followSystemBrightness = value
                      })
                    Text('系统亮度')
                      .fontSize(12)
                      .fontColor(this.isNightMode ? '#EDE4D3' : '#4A4039')
                  }
                  .onClick(() => {
                    this.followSystemBrightness = !this.followSystemBrightness
                  })
                }
                .width('100%')

                // Middle controls: Font selector, Word size, Font Weight
                Row({ space: 12 }) {
                  this.FontSelector()

                  this.NumberAdjuster('字号', this.panelFontSize, () => {
                    if (this.panelFontSize > 12) {
                      this.panelFontSize--
                      this.fontSize = this.panelFontSize
                    }
                  }, () => {
                    if (this.panelFontSize < 48) {
                      this.panelFontSize++
                      this.fontSize = this.panelFontSize
                    }
                  })

                  this.NumberAdjuster('字重', (this.panelFontWeight / 400).toFixed(1), () => {
                    if (this.panelFontWeight > 300) {
                      this.panelFontWeight -= 100
                      this.fontWeight = this.panelFontWeight
                    }
                  }, () => {
                    if (this.panelFontWeight < 800) {
                      this.panelFontWeight += 100
                      this.fontWeight = this.panelFontWeight
                    }
                  })
                }
                .width('100%')

                // Spacings row: Paragraph spacing, Letter spacing, Line height ratio
                Row({ space: 12 }) {
                  this.NumberAdjuster('段距', this.panelParagraphSpacing, () => {
                    if (this.panelParagraphSpacing > 0) {
                      this.panelParagraphSpacing--
                      this.paragraphSpacing = this.panelParagraphSpacing
                    }
                  }, () => {
                    if (this.panelParagraphSpacing < 20) {
                      this.panelParagraphSpacing++
                      this.paragraphSpacing = this.panelParagraphSpacing
                    }
                  })

                  this.NumberAdjuster('字距', this.panelLetterSpacing.toFixed(1), () => {
                    if (this.panelLetterSpacing > -2) {
                      this.panelLetterSpacing -= 0.5
                      this.letterSpacing = this.panelLetterSpacing
                    }
                  }, () => {
                    if (this.panelLetterSpacing < 10) {
                      this.panelLetterSpacing += 0.5
                      this.letterSpacing = this.panelLetterSpacing
                    }
                  })

                  this.NumberAdjuster('行距', this.panelLineHeightRatio.toFixed(1), () => {
                    if (this.panelLineHeightRatio > 1.2) {
                      this.panelLineHeightRatio -= 0.1
                      this.lineHeightRatio = this.panelLineHeightRatio
                    }
                  }, () => {
                    if (this.panelLineHeightRatio < 3.0) {
                      this.panelLineHeightRatio += 0.1
                      this.lineHeightRatio = this.panelLineHeightRatio
                    }
                  })
                }
                .width('100%')
              }
              .width("100%")
              .padding({ left: 20, right: 20, top: 16, bottom: 8 })
            }

            Divider().color(this.isNightMode ? 'rgba(255,255,255,0.1)' : '#F0F0F0').margin({ top: 8, bottom: 8 })

            // ==================== 底部固定导航栏 ====================
            Row() {
              // 1. 目录
              Column({ space: 4 }) {
                Image($r("app.media.catalog"))
                  .width(22)
                  .height(22)
                  .fillColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
                Text("目录")
                  .fontSize(11)
                  .fontColor(this.isNightMode ? '#A89B8C' : '#6B5E52')
              }
              .layoutWeight(1)
              .bindSheet($$this.isShowCatalog, this.CatalogBuilder(), {
                height: '80%',
                showClose: true,
                dragBar: true,
                blurStyle: BlurStyle.COMPONENT_ULTRA_THIN
              })
              .onClick(() => {
                this.isShowCatalog = true
              })

              // 2. 已读百分比
              Column() {
                Text(`已读 ${this.calculateReadPercentage()}%`)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
              }
              .layoutWeight(1)

              // 3. 夜间/日间
              Column({ space: 4 }) {
                Image(this.isNightMode ? $r("app.media.day_icon") : $r("app.media.night_icon"))
                  .width(22)
                  .height(22)
                  .fillColor(this.isNightMode ? '#A89B7E' : '#6B5E52')
                Text(this.isNightMode ? "日间" : "夜间")
                  .fontSize(11)
                  .fontColor(this.isNightMode ? '#A89B8C' : '#6B5E52')
              }
              .layoutWeight(1)
              .onClick(() => {
                this.toggleNightMode()
              })

              // 4. 书签
              Column({ space: 4 }) {
                 Path()
                  .width(22)
                  .height(22)
                  .commands('M4 2 h14 v18 l-7 -5 l-7 5 Z')
                  .fill(this.isBookmarked ? '#A89B7E' : Constants.TRANSPARENT)
                  .stroke(this.isBookmarked ? Constants.TRANSPARENT : (this.isNightMode ? '#8A7D71' : '#6B5E52'))
                  .strokeWidth(2)
                Text("书签")
                  .fontSize(11)
                  .fontColor(this.isBookmarked ? '#A89B7E' : (this.isNightMode ? '#A89B8C' : '#6B5E52'))
              }
              .layoutWeight(1)
              .onClick(() => {
                this.toggleBookmark()
              })

              // 5. 设置
              Column({ space: 4 }) {
                Image(this.isShowContentSetting ? $r("app.media.my_center_set_icon_fill") : $r("app.media.my_center_set_icon"))
                  .width(22)
                  .height(22)
                  .fillColor(this.isShowContentSetting ? '#A89B7E' : (this.isNightMode ? '#8A7D71' : '#6B5E52'))
                Text("设置")
                  .fontSize(11)
                  .fontColor(this.isShowContentSetting ? '#A89B7E' : (this.isNightMode ? '#A89B8C' : '#6B5E52'))
              }
              .layoutWeight(1)
              .onClick(() => {
                this.isShowContentSetting = !this.isShowContentSetting
              })
            }
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