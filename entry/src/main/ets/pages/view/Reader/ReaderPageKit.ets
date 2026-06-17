import { display, promptAction, window } from '@kit.ArkUI';
import router from '@ohos.router';
import { BookMark } from '../../../database/entities/BookMark';
import bookMarkUtils from '../../../common/utils/BookMarkUtils';
import { ReaderCatalog } from '../../../componets/Reader/ReaderCatalog';
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
import readRecordDao from '../../../database/dao/ReadRecordDao';
import { BookContentHolder } from '../../../common/utils/BookContentHolder';
import { InkPalette, InkSpacing, InkRadius, InkShadow, InkMotion, InkTypography } from '../../../common/constants/DesignTokens';
import {
  BGColorType,
  BG_COLOR_ARRAY,
  Constants,
  FlipPageType
} from '@ohos/readerLibrary/src/main/ets/common/constants/Constants';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  ReaderChapterItem,
} from '@ohos/readerLibrary/src/main/ets/common/entity/ReaderChaptersItem';
import { ReaderProvider } from '@ohos/readerLibrary/src/main/ets/provider/configProvider';
import { bookParser, readerCore, ReadPageComponent } from '@kit.ReaderKit';
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import booksUtil from '../../../common/utils/booksUtils';

interface ParamsObj {
  bookData: Books,
  clickBookChapter: number
}

@Entry
@Component
struct ReaderPageKit {
  @State bookData: Books | undefined = undefined
  currentChapters: number = 0
  chapterList: ReaderChapterItem[] = [];
  private readStartTime: number = 0;

  onPageShow() {
    this.readStartTime = Date.now();
  }

  async onPageHide() {
    if (this.readStartTime > 0 && this.bookData) {
      let timeSpentSeconds = Math.floor((Date.now() - this.readStartTime) / 1000);
      if (timeSpentSeconds > 0) {
        let isFinished = this.currentChapters === (this.chapterList.length - 1);
        await readRecordDao.updateReadRecord(this.bookData.bookName, this.bookData.bookUrl || '', timeSpentSeconds, isFinished);
      }
      this.readStartTime = 0;
    }
  }

  checkIsLocalBook(): boolean {
    if (!this.bookData) return false;
    if (this.bookData.isLocalBook === true || Number(this.bookData.isLocalBook) === 1 || String(this.bookData.isLocalBook) === 'true' || String(this.bookData.isLocalBook) === '1') return true;
    if (this.bookData.bookUrl && !this.bookData.bookUrl.startsWith('http')) return true;
    if (this.bookData.bookGroup === 4) return true;
    if (this.bookData.origin === 'local') return true;
    if (this.bookData.author === '本地导入') return true;
    if (!this.bookData.origin || String(this.bookData.origin).trim() === '' || String(this.bookData.origin) === 'null' || String(this.bookData.origin) === 'undefined') return true;
    return false;
  }

  async aboutToAppear() {
    let temp = router.getParams() as ParamsObj
    this.bookData = temp.bookData
    console.log('router ReaderPageKit:' + (this.bookData?.bookUrl || ''))
    
    let rawFile = BookContentHolder.getChapters();
    if (!rawFile || rawFile.length === 0) {
      console.error('BookContentHolder is empty, no chapters to display');
      return;
    }
    this.chapterList = rawFile.map((value) => {
      return new ReaderChapterItem(value.number, value.title, value.chapterTitleNumber, value.content);
    })

    this.currentChapters = temp.clickBookChapter

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

  build() {
    if (this.bookData?.bookType === 2) {
      Column() {
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
  private readerComponentController: readerCore.ReaderComponentController = new readerCore.ReaderComponentController();
  @State isReaderKitLoaded: boolean = false;
  private isExternalJump: boolean = false;
  @State isShowSetting: boolean = false
  @State isShowContentSetting: boolean = false
  @State isShowDownload: boolean = false
  @State isShowListen: boolean = false
  @State sheetType: string = '' // 'moreMenu' | 'bgColor' | 'flipMode' | 'moreLayout' | 'purification' | 'source'
  @State isShowSheet: boolean = false
  @State isShowPurification: boolean = false // 保留给 purificationView 的 @Link
  @State isAutoRead: boolean = false
  @State isFontChanged: boolean = false
  @State screenH: number = 0
  @State screenW: number = 0
  @State readerPadding: number = 24
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
  @State isShowCatalog: boolean = false;
  @State catalogTabIndex: number = 0;
  @State isBookmarked: boolean = false;
  @State catalogSearchKey: string = ""
  @State sessionMinutes: number = 1
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
    console.log("============== 当前所在界面: ReaderPageKit (组件版) ==============")
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
    
    this.panelFontSize = this.fontSize
    this.panelFontWeight = this.fontWeight
    this.panelFontType = this.fontType
    this.panelParagraphSpacing = this.paragraphSpacing
    this.panelLetterSpacing = this.letterSpacing
    this.panelLineHeightRatio = this.lineHeightRatio

    this.initReaderKit();
  }

  aboutToDisappear(): void {
    if (this.autoReadTimer !== -1) {
      clearInterval(this.autoReadTimer)
      this.autoReadTimer = -1
    }
    if (this.sessionTimerId !== -1) {
      clearInterval(this.sessionTimerId)
      this.sessionTimerId = -1
    }

    if (this.isReaderKitLoaded) {
      this.readerComponentController.off('pageShow');
      this.readerComponentController.releaseBook();
    }
  }

  checkIsLocalBook(): boolean {
    if (!this.bookData) return false;
    if (this.bookData.isLocalBook === true || Number(this.bookData.isLocalBook) === 1 || String(this.bookData.isLocalBook) === 'true' || String(this.bookData.isLocalBook) === '1') return true;
    if (this.bookData.bookUrl && !this.bookData.bookUrl.startsWith('http')) return true;
    if (this.bookData.bookGroup === 4) return true;
    if (this.bookData.origin === 'local' || this.bookData.origin === '未知书源') return true;
    if (this.bookData.author === '本地导入') return true;
    if (!this.bookData.origin || String(this.bookData.origin).trim() === '' || String(this.bookData.origin) === 'null' || String(this.bookData.origin) === 'undefined') return true;
    return false;
  }

  getReaderKitFlipMode(turnStyle: FlipPageType): string {
    if (turnStyle === FlipPageType.SIMULATE_FLIP_PAGE) {
      return '0';
    } else if (turnStyle === FlipPageType.SLIDE_FLIP_PAGE) {
      return '1';
    }
    return '0';
  }

  syncSettingsToReaderKit() {
    if (!this.isReaderKitLoaded) {
      return;
    }
    try {
      let setting: readerCore.ReaderSetting = {
        fontName: '系统字体',
        fontPath: '',
        fontSize: this.fontSize,
        fontColor: this.isNightMode ? '#9E9E9E' : '#1A1612',
        fontWeight: this.fontWeight || 400,
        lineHeight: this.lineHeightRatio,
        nightMode: this.isNightMode,
        themeColor: this.bgColor,
        themeBgImg: '',
        flipMode: this.getReaderKitFlipMode(this.turnStyle),
        scaledDensity: display.getDefaultDisplaySync().scaledDensity || 1,
        viewPortWidth: this.screenW || 1260,
        viewPortHeight: this.screenH || 2000
      };
      console.log('ReaderKit setPageConfig: ' + JSON.stringify(setting));
      this.readerComponentController.setPageConfig(setting);
    } catch (e) {
      console.error('Failed to setPageConfig: ' + JSON.stringify(e));
    }
  }

  async initReaderKit() {
    if (!this.bookData) {
      return;
    }
    try {
      let context = getContext(this) as common.UIAbilityContext;
      await this.readerComponentController.init(context);
      
      let filePath = this.bookData.bookUrl;
      if (!this.bookData.isLocalBook) {
        let tempPath = context.cacheDir + '/temp_online_book.txt';
        let lines: string[] = [];
        this.chapterList.forEach((ch) => {
          lines.push(`第${ch.number}章 ${ch.title}`);
          lines.push(ch.content);
          lines.push('\n');
        });
        let textContent = lines.join('\n');
        
        let file = fs.openSync(tempPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
        fs.writeSync(file.fd, textContent);
        fs.closeSync(file);
        filePath = tempPath;
        console.log('ReaderKit temp file generated at: ' + filePath);
      }
      
      if (filePath) {
        let handler = await bookParser.getDefaultHandler(filePath);
        this.readerComponentController.registerBookParser(handler);
        
        this.readerComponentController.on('pageShow', (data: readerCore.PageDataInfo): void => {
          if (data.state === readerCore.PageState.PAGE_ON_SHOW) {
            this.currentChapterIndex = data.resourceIndex;
            this.sliderChapterIndex = this.currentChapterIndex;
            
            if (this.bookData) {
              this.bookData.durChapterIndex = this.currentChapterIndex;
              this.bookData.durChapterPos = 0;
              booksUtil.partialUpdate(this.bookData);
            }
            this.checkBookmarkState();
          }
        });

        this.isReaderKitLoaded = true;
        this.syncSettingsToReaderKit();
        
        let startIdx = this.currentChapterIndex || 0;
        await this.readerComponentController.startPlay(startIdx, "");
      }
    } catch (e) {
      console.error('Failed to init ReaderKit: ' + JSON.stringify(e));
    }
  }

  onBgColorChanged() {
    this.changeSystemBarStatue();
    this.syncSettingsToReaderKit();
  }

  onFontSizeChanged() {
    this.panelFontSize = this.fontSize
    this.sliderFontSize = this.fontSize
    this.syncSettingsToReaderKit();
  }

  onLineHeightRatioChanged() {
    this.panelLineHeightRatio = this.lineHeightRatio
    this.syncSettingsToReaderKit();
  }

  onParagraphSpacingChanged() {
    this.panelParagraphSpacing = this.paragraphSpacing
    this.syncSettingsToReaderKit();
  }

  onFontWeightChanged() {
    this.panelFontWeight = this.fontWeight
    this.syncSettingsToReaderKit();
  }

  onFontTypeChanged() {
    this.panelFontType = this.fontType
    this.syncSettingsToReaderKit();
  }

  onLetterSpacingChanged() {
    this.panelLetterSpacing = this.letterSpacing
    this.syncSettingsToReaderKit();
  }

  onChapterIndexChanged() {
    this.sliderChapterIndex = this.currentChapterIndex
    this.checkBookmarkState()
    if (this.isReaderKitLoaded && this.isExternalJump) {
      this.isExternalJump = false;
      this.readerComponentController.startPlay(this.currentChapterIndex, "");
    }
  }

  async checkBookmarkState() {
    if (!this.bookData) {
      return;
    }
    try {
      this.isBookmarked = await bookMarkUtils.isBookMarked(
        this.bookData.bookName, 
        this.bookData.author, 
        this.currentChapterIndex, 
        this.currentPageIndex
      );
    } catch (e) {
      console.error('Failed to check bookmark state:', e);
    }
  }

  async toggleBookmark() {
    if (!this.bookData) {
      return;
    }
    try {
      if (this.isBookmarked) {
        await bookMarkUtils.deleteBookMarkByPosition(
          this.bookData.bookName,
          this.bookData.author,
          this.currentChapterIndex,
          this.currentPageIndex
        );
        this.isBookmarked = false;
      } else {
        const currentChapter = this.chapterList[this.currentChapterIndex];
        let snippet = currentChapter?.title || '未知章节';

        // 尝试从 chapterPageList 提取页面内容摘要
        if (currentChapter && currentChapter.chapterPageList && currentChapter.chapterPageList[this.currentPageIndex]) {
          const lines = currentChapter.chapterPageList[this.currentPageIndex].lineContentList;
          if (lines && lines.length > 0) {
            let txt = lines.join('').replace(/\[img:.*?\]/g, '').replace(/\n/g, '').trim();
            if (txt.length > 0) {
              snippet = txt.substring(0, 40) + '...';
            }
          }
        } else if (currentChapter && currentChapter.content) {
          let txt = currentChapter.content.replace(/\[img:.*?\]/g, '').replace(/\n/g, '').trim();
          if (txt.length > 0) {
            snippet = txt.substring(0, 40) + '...';
          }
        }

        let bookmark = new BookMark();
        bookmark.bookName = this.bookData.bookName;
        bookmark.bookAuthor = this.bookData.author;
        bookmark.chapterIndex = this.currentChapterIndex;
        bookmark.chapterPos = this.currentPageIndex;
        bookmark.chapterName = currentChapter?.title || '未知章节';
        bookmark.bookText = currentChapter?.title || '未知章节';
        bookmark.content = snippet;

        await bookMarkUtils.addBookMark(bookmark);
        this.isBookmarked = true;
      }

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
            this.isShowSheet = false;
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
            this.sheetType = 'bgColor';
          })
        }

        ListItem() {
          this.MoreMenuRow($r('app.media.my_center_purify_icon'), '删除或替换文字', () => {
            this.isShowPurification = true;
            this.sheetType = 'purification';
          })
        }

        ListItem() {
          this.MoreMenuRow($r('app.media.style_icon'), '更多排版设置（缩进、间距等）', () => {
            this.sheetType = 'moreLayout';
          })
        }

        ListItem() {
          this.MoreMenuRow($r('app.media.my_center_set_icon'), '其他设置', () => {
            this.sheetType = 'flipMode';
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
    ReaderCatalog({
      bookData: this.bookData,
      catalogTabIndex: $catalogTabIndex,
      chapterList: this.chapterList,
      currentChapterIndex: this.currentChapterIndex,
      isNightMode: this.isNightMode,
      isShowCatalog: $isShowCatalog,
      isShowSetting: $isShowSetting,
      jumpToChapter: (chapterIndex: number, pageIndex: number) => {
        this.isExternalJump = true;
        this.currentChapterIndex = chapterIndex;
        this.currentPageIndex = pageIndex;
        this.isShowCatalog = false;
        this.isShowSetting = false;
        // ReaderPageKit requires flipping to the specific chapter index, but pageIndex support varies.
        // It's mostly handled by currentChapterIndex observer.
      }
    })
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

  async loadBrightness() {
    try {
      this.currentLuminance = 50
    } catch (err) {
      console.error('获取亮度失败:', err)
    }
  }

  async setBrightness(value: number) {
    try {
      console.log('设置亮度:', value)
      promptAction.showToast({
        message: `亮度已调整至 ${value.toFixed(0)}%`,
        duration: 1000
      })
    } catch (err) {
      console.error('设置亮度失败:', err)
    }
  }

  toggleNightMode() {
    this.isNightMode = !this.isNightMode
    if (this.isNightMode) {
      this.bgColor = BG_COLOR_ARRAY[BGColorType.GREY]
      this.currentLuminance = Math.min(this.currentLuminance, 30)
      this.setBrightness(this.currentLuminance)
      promptAction.showToast({
        message: '已切换至夜间模式',
        duration: 1500
      })
    } else {
      this.bgColor = BG_COLOR_ARRAY[BGColorType.WHITE]
      promptAction.showToast({
        message: '已切换至日间模式',
        duration: 1500
      })
    }
    this.syncSettingsToReaderKit();
  }

  toggleAutoRead() {
    this.isAutoRead = !this.isAutoRead
    
    if (this.isAutoRead) {
      promptAction.showToast({
        message: '自动阅读已开启',
        duration: 1500
      })
      
      this.autoReadTimer = setInterval(() => {
        if (this.isReaderKitLoaded) {
          this.readerComponentController.flipPage(true);
        }
      }, 3000)
    } else {
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
      Row() {
        Row() {
          if (this.isReaderKitLoaded) {
            ReadPageComponent({
              controller: this.readerComponentController,
              readerCallback: (err: BusinessError, data: readerCore.ReaderComponentController) => {
                if (!err) {
                  this.readerComponentController = data;
                }
              }
            })
            .width(Constants.FULL_PERCENT)
            .height(Constants.FULL_PERCENT)
          } else {
            Column() {
              LoadingProgress()
                .width(48)
                .height(48)
                .color('#A89B7E')
              Text('正在载入原生阅读器...')
                .fontSize(14)
                .fontColor(this.isNightMode ? '#8A7D71' : '#6B5E52')
                .margin({ top: 12 })
            }
            .width(Constants.FULL_PERCENT)
            .height(Constants.FULL_PERCENT)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
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
        this.isShowSetting = !this.isShowSetting
      })

      if (this.isShowSetting) {
        // 遮罩层 — 纯视觉，不拦截触摸
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.15)')
          .zIndex(2)
          .enabled(false)

        // 点击空白区域关闭菜单的透明层
        Column()
          .width('100%')
          .height('100%')
          .zIndex(2)
          .onClick(() => {
            this.isShowSetting = false
          })

        // 顶部工具栏 — 独立 Stack 子元素
        Column() {
          Column() {
            Row({ space: 12 }) {
              Row() {
                Image($r("app.media.ic_public_return_left"))
                  .width(24)
                  .height(24)
                  .fillColor(this.isNightMode ? '#E5E6EB' : '#1F2329')
              }
              .padding(8)
              .onClick(() => {
                console.log('[ReaderPageKit] 点击返回按钮')
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
                if (!this.checkIsLocalBook()) {
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

                Row() {
                  Image($r("app.media.more"))
                    .width(22)
                    .height(22)
                    .fillColor(this.isNightMode ? '#E5E6EB' : '#1F2329')
                }
                .padding(8)
                .onClick(() => {
                  console.log('[ReaderPageKit] 点击更多按钮')
                  this.sheetType = 'moreMenu';
                  this.isShowSheet = true;
                })
              }
            }
            .padding({ top: this.topRectHeight + 12, left: 20, right: 20, bottom: 12 })
            .width("100%")

            if (!this.checkIsLocalBook()) {
              Row() {
                NetworkInput({ bookData: this.bookData })
              }
              .padding({
                top: 8,
                left: 20,
                right: 20,
                bottom: 12
              })
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
        }
        .width("100%")
        .height("100%")
        .justifyContent(FlexAlign.Start)
        .zIndex(3)
        .hitTestBehavior(HitTestMode.Transparent)

        Column() {
          Column() {
            if (!this.isShowContentSetting) {
              Column({ space: 16 }) {
                Row({ space: 12 }) {
                  Image($r("app.media.chevron_left"))
                    .width(20)
                    .height(20)
                    .fillColor(this.isNightMode ? '#EDE4D3' : '#6B5E52')
                    .opacity(this.currentChapterIndex > 0 ? 1 : 0.4)
                    .onClick(() => {
                      if (this.currentChapterIndex > 0) {
                        this.isExternalJump = true
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
                        this.isExternalJump = true
                        this.currentChapterIndex = this.sliderChapterIndex
                        this.currentPageIndex = 0
                      }
                    })

                  Image($r("app.media.chevron_right"))
                    .width(20)
                    .height(20)
                    .fillColor(this.isNightMode ? '#EDE4D3' : '#6B5E52')
                    .opacity(this.currentChapterIndex < this.totalChapter - 1 ? 1 : 0.4)
                    .onClick(() => {
                      if (this.currentChapterIndex < this.totalChapter - 1) {
                        this.isExternalJump = true
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

            if (this.isShowContentSetting) {
              Column({ space: 16 }) {
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

            Row() {
              // 1. 目录
              Column({ space: 4 }) {
                Image(this.isShowCatalog ? $r("app.media.reader_tab_catalog_fill") : $r("app.media.reader_tab_catalog_outline"))
                  .width(22)
                  .height(22)
                  .fillColor(this.isShowCatalog ? '#E07A5F' : (this.isNightMode ? '#8A7D71' : '#6B5E52'))
                  .opacity(this.isShowCatalog ? 1.0 : 0.6)
                Text("目录")
                  .fontSize(11)
                  .fontColor(this.isShowCatalog ? '#E07A5F' : (this.isNightMode ? '#A89B8C' : '#6B5E52'))
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
                  .opacity(0.8)
              }
              .layoutWeight(1)

              // 3. 夜间/日间
              Column({ space: 4 }) {
                Image(this.isNightMode ? $r("app.media.reader_moon_fill") : $r("app.media.reader_moon_outline"))
                  .width(22)
                  .height(22)
                  .fillColor(this.isNightMode ? '#E07A5F' : (this.isNightMode ? '#8A7D71' : '#6B5E52'))
                  .opacity(this.isNightMode ? 1.0 : 0.6)
                Text("夜间")
                  .fontSize(11)
                  .fontColor(this.isNightMode ? '#E07A5F' : (this.isNightMode ? '#A89B8C' : '#6B5E52'))
              }
              .layoutWeight(1)
              .onClick(() => {
                this.toggleNightMode()
              })

              // 4. 书签
              Column({ space: 4 }) {
                Image(this.isBookmarked ? $r("app.media.reader_tab_bookmark_fill") : $r("app.media.reader_tab_bookmark_outline"))
                  .width(22)
                  .height(22)
                  .fillColor(this.isBookmarked ? '#E07A5F' : (this.isNightMode ? '#8A7D71' : '#6B5E52'))
                  .opacity(this.isBookmarked ? 1.0 : 0.6)
                  .animation({ duration: 250, curve: Curve.Friction })
                Text("书签")
                  .fontSize(11)
                  .fontColor(this.isBookmarked ? '#E07A5F' : (this.isNightMode ? '#A89B8C' : '#6B5E52'))
              }
              .layoutWeight(1)
              .onClick(() => {
                console.log('[ReaderPageKit] 点击书签按钮, isBookmarked=' + this.isBookmarked)
                this.toggleBookmark();
              })

              // 5. 设置
              Column({ space: 4 }) {
                Image(this.isShowContentSetting ? $r("app.media.reader_tab_settings_fill") : $r("app.media.reader_tab_settings_outline"))
                  .width(22)
                  .height(22)
                  .fillColor(this.isShowContentSetting ? '#E07A5F' : (this.isNightMode ? '#8A7D71' : '#6B5E52'))
                  .opacity(this.isShowContentSetting ? 1.0 : 0.6)
                Text("设置")
                  .fontSize(11)
                  .fontColor(this.isShowContentSetting ? '#E07A5F' : (this.isNightMode ? '#A89B8C' : '#6B5E52'))
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
        }
        .width("100%")
        .height("100%")
        .justifyContent(FlexAlign.End)
        .zIndex(3)
        .hitTestBehavior(HitTestMode.Transparent)
      }
    }
    .height('100%')
    .width('100%')
    .bindSheet($$this.isShowSheet, this.SheetContentBuilder(), {
      height: '70%',
      showClose: true,
      dragBar: true,
      blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
      onDisappear: () => {
        this.sheetType = '';
        this.isShowPurification = false;
      }
    })
  }

  onFlush() {
    this.checkBookmarkState()
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
  SheetContentBuilder() {
    Column() {
      if (this.sheetType === 'moreMenu') {
        this.MoreMenuBuilder()
      } else if (this.sheetType === 'bgColor') {
        BackgroundColorDialog()
          .width("100%")
      } else if (this.sheetType === 'flipMode') {
        FlipModeDialog()
          .width("100%")
      } else if (this.sheetType === 'moreLayout') {
        LayoutMoreDialog()
          .width("100%")
      } else if (this.sheetType === 'purification') {
        purificationView({
          isShowPurification: this.isShowPurification
        })
      } else if (this.sheetType === 'source') {
        sourceView()
          .width("100%")
      }
    }
    .width("100%")
  }
}
