import { BGColorType, BG_COLOR_ARRAY, Constants, FlipPageType } from '../common/constants/Constants';
import { ReaderChapterItem, ReaderChapterPageItem } from '../common/entity/ReaderChaptersItem';
import { BookContentHolder } from 'ets/common/utils/BookContentHolder';
import { isNetworkUrl } from 'ets/common/utils/utils';
import { NovelContentParseHelper } from '../common/helper/NovelContentParseHelper';
import { display } from '@kit.ArkUI';
import taskPool from '@ohos.taskpool';
import { preferences } from '@kit.ArkData';

@Component
export struct ReaderProvider {
  @BuilderParam child: () => void // 通用组件
  fontSize: number = Constants.INIT_FONT_SIZE
  lineHeightRatio: number = Constants.INIT_LINE_HEIGHT_RATIO
  bgColor: string = BG_COLOR_ARRAY[BGColorType.WHITE]
  currentPageIndex: number = 0
  currentChapterIndex: number = 0
  displaySize: number[] = [0, 0]
  curPosition: number = 0
  turnStyle: FlipPageType = FlipPageType.COVER_FLIP_PAGE
  chapterList: ReaderChapterItem[] = [];
  fontWeight: number = 400

  build() {
    Row() {
      ReaderConfigProvider({
        turnStyle: this.turnStyle,
        fontSize: this.fontSize,
        lineHeightRatio: this.lineHeightRatio,
        bgColor: this.bgColor,
        child: this.child,
        chapterList: this.chapterList,
        currentChapterIndex: this.currentChapterIndex,
        fontWeight: this.fontWeight,
        currentPageIndex: this.currentPageIndex
      })
    }
  }
}

@Concurrent
async function calChapterContent(width: number, height: number, targetParagraphList: string[], fontSize: number,
  lineHeightRatio: number, paragraphSpacing: number, letterSpacing: number): Promise<string[][]> {
  try {
    return await NovelContentParseHelper.calculateChapterContent(targetParagraphList,
      fontSize,
      fontSize * lineHeightRatio, width, height, paragraphSpacing, letterSpacing)
  } catch (e) {
    console.info('loadNovel 出错 ' + e)
    return [];
  }
}

@Component
struct ReaderSourceProvider {
  @BuilderParam child: () => void // 通用组件
  @Provide('chapterList') @Watch('calChapterContent') chapterList: ReaderChapterItem[] = [];
  @Consume('lineHeightRatio') @Watch('onConfigSizeChange') lineHeightRatio: number
  @Consume('fontSize') @Watch('onConfigSizeChange') fontSize: number
  @Consume('displaySize') @Watch('onDisplaySizeChange') displaySize: number[]
  @Consume('currentChapterIndex') @Watch('calChapterContent') currentChapterIndex: number
  @Consume('paragraphSpacing') @Watch('onConfigSizeChange') paragraphSpacing: number
  @Consume('fontWeight') @Watch('onConfigSizeChange') fontWeight: number
  @Consume('fontType') @Watch('onConfigSizeChange') fontType: string
  @Consume('isFirstLineIndent') @Watch('onConfigSizeChange') isFirstLineIndent: boolean
  @Consume('letterSpacing') @Watch('onConfigSizeChange') letterSpacing: number
  @Consume('readerPadding') @Watch('onConfigSizeChange') readerPadding: number

  @Provide('renderFontSize') renderFontSize: number = Constants.INIT_FONT_SIZE;
  @Provide('renderLineHeightRatio') renderLineHeightRatio: number = Constants.INIT_LINE_HEIGHT_RATIO;
  @Provide('renderParagraphSpacing') renderParagraphSpacing: number = 0;
  @Provide('renderFontWeight') renderFontWeight: number = 400;
  @Provide('renderFontType') renderFontType: string = 'simplified';
  @Provide('renderIsFirstLineIndent') renderIsFirstLineIndent: boolean = true;
  @Provide('renderLetterSpacing') renderLetterSpacing: number = 0;
  @Provide('renderReaderPadding') renderReaderPadding: number = 24;

  @Consume('currentPageIndex') currentPageIndex: number
  @State targetStartPosRaw: number = 0
  @State private configVersion: number = 0
  private lastChapterIndex: number = 0
  private configChangeTimeout: number = -1
  private fetchingChapters: Set<number> = new Set()
  private isFirstInit: boolean = true

  private getTargetPosInUnformatted(): number {
    let currentChapter = this.chapterList?.[this.currentChapterIndex];
    if (!currentChapter?.chapterPageList?.[this.currentPageIndex]) {
      return 0;
    }
    let formattedPos = currentChapter.chapterPageList[this.currentPageIndex].startIndex;
    let formattedParagraphs = this.getFormattedParagraphs(currentChapter.paragraphList);

    let pStart = 0;
    for (let i = 0; i < formattedParagraphs.length; i++) {
      let pLen = formattedParagraphs[i].length;
      if (formattedPos < pStart + pLen) {
        let offsetInP = formattedPos - pStart;
        let origOffset = offsetInP;
        if (this.isFirstLineIndent && formattedParagraphs[i].startsWith('\u3000\u3000')) {
          origOffset = Math.max(0, offsetInP - 2);
        }
        let originalStartPos = 0;
        for (let j = 0; j < i; j++) {
          originalStartPos += currentChapter.paragraphList[j].length;
        }
        return originalStartPos + origOffset;
      }
      pStart += pLen;
    }
    return 0;
  }

  onConfigSizeChange() {
    this.targetStartPosRaw = this.getTargetPosInUnformatted();
    this.configVersion++;
    if (this.configChangeTimeout !== -1) {
      clearTimeout(this.configChangeTimeout);
    }
    this.configChangeTimeout = setTimeout(() => {
      this.forceCalChapterContent()
    }, 300);
  }

  aboutToAppear(): void {
    this.renderFontSize = this.fontSize;
    this.renderLineHeightRatio = this.lineHeightRatio;
    this.renderParagraphSpacing = this.paragraphSpacing;
    this.renderFontWeight = this.fontWeight;
    this.renderFontType = this.fontType;
    this.renderIsFirstLineIndent = this.isFirstLineIndent;
    this.renderLetterSpacing = this.letterSpacing;
    this.renderReaderPadding = this.readerPadding;
    this.lastChapterIndex = this.currentChapterIndex;
  }

  onDisplaySizeChange() {
    this.configVersion++;
    if (this.configChangeTimeout !== -1) {
      clearTimeout(this.configChangeTimeout);
    }
    this.configChangeTimeout = setTimeout(() => {
      this.forceCalChapterContent()
    }, 300);
  }

  private getFormattedParagraphs(paragraphs: string[]): string[] {
    return paragraphs.map((p) => {
      let trimmed = p.trim();
      if (trimmed.length === 0 || (trimmed.startsWith('[img:') && trimmed.endsWith(']'))) {
        return p;
      }
      
      let processed = p;
      if (this.fontType === 'traditional') {
        processed = this.convertToTraditional(p);
      }

      if (this.isFirstLineIndent) {
        let content = processed.replace(/^\s+/, '');
        return '\u3000\u3000' + content;
      } else {
        return processed.replace(/^\s+/, '');
      }
    });
  }

  private convertToTraditional(text: string): string {
    const simp = "国学爱书阅读电脑手机发现设置个人中心关于我们目录进度样式背景色夜间模式书籍目录书架";
    const trad = "國學愛書閱讀電腦手機發現設置個人中心關於我們目錄進度樣式背景色夜間模式書籍目錄書架";
    let result = "";
    for (let i = 0; i < text.length; i++) {
      let char = text.charAt(i);
      let idx = simp.indexOf(char);
      if (idx !== -1) {
        result += trad.charAt(idx);
      } else {
        result += char;
      }
    }
    return result;
  }

  private calContentOfTargetChapter(width: number, height: number, chapterIndex: number, fontSize: number,
    lineHeightRatio: number, forceUpdate: boolean, restorePosition: boolean, isBackwards: boolean) {
    if (!this.chapterList || !this.chapterList[chapterIndex]) {
      console.log('[calContentOfTargetChapter] chapterIndex ' + chapterIndex + ' not found')
      return
    }
    if (!forceUpdate) {
      if (this.chapterList[chapterIndex].chapterPageList.length !== 0) {
        console.log('[calContentOfTargetChapter] chapter ' + chapterIndex + ' already has pages, skip')
        return
      }
    }
    if (!this.chapterList[chapterIndex].paragraphList || this.chapterList[chapterIndex].paragraphList.length === 0) {
      if (this.chapterList[chapterIndex].content) {
        let content = this.chapterList[chapterIndex].content
        if (isNetworkUrl(content) && BookContentHolder.resolveContent) {
          console.log('[calContentOfTargetChapter] chapter ' + chapterIndex + ' is URL, fetching: ' + content.substring(0, 80))
          if (!this.fetchingChapters.has(chapterIndex)) {
            this.fetchingChapters.add(chapterIndex)
            BookContentHolder.resolveContent(content).then((resolved: string) => {
              this.fetchingChapters.delete(chapterIndex)
              if (resolved && resolved.length > 0) {
                this.chapterList[chapterIndex].content = resolved
                this.chapterList[chapterIndex].paragraphList = []
                this.chapterList[chapterIndex].chapterPageList = []
                this.forceCalChapterContent()
              }
            })
          }
          return
        }
        console.log('[calContentOfTargetChapter] chapter ' + chapterIndex + ' splitting text, content length: ' + content.length)
        this.chapterList[chapterIndex].paragraphList = content
          .split('\n')
          .map((value: string) => value.trim())
          .filter((value: string) => value.length > 0)
          .map((value: string) => value + '\n');
        console.log('[calContentOfTargetChapter] chapter ' + chapterIndex + ' paragraphList length: ' + this.chapterList[chapterIndex].paragraphList.length)
      } else {
        console.log('[calContentOfTargetChapter] chapter ' + chapterIndex + ' has no content')
        this.chapterList[chapterIndex].paragraphList = []
      }
    }
    let paragraphsToCal = this.getFormattedParagraphs(this.chapterList[chapterIndex].paragraphList);

    let targetStartPos = 0;
    if (restorePosition && chapterIndex === this.currentChapterIndex) {
      let currentChapter = this.chapterList[chapterIndex];
      let pStart = 0;
      let formattedStartPos = 0;
      for (let i = 0; i < currentChapter.paragraphList.length; i++) {
        let pLen = currentChapter.paragraphList[i].length;
        if (this.targetStartPosRaw < pStart + pLen) {
          let offsetInP = this.targetStartPosRaw - pStart;
          let formOffset = offsetInP;
          if (this.isFirstLineIndent && paragraphsToCal[i].startsWith('\u3000\u3000')) {
            formOffset = offsetInP + 2;
          }
          targetStartPos = formattedStartPos + formOffset;
          break;
        }
        pStart += pLen;
        formattedStartPos += paragraphsToCal[i].length;
      }
    }

    let taskVersion = this.configVersion;
    console.log('[calContentOfTargetChapter] chapter ' + chapterIndex + ' starting taskPool, paragraphs: ' + paragraphsToCal.length + ', w:' + width + ' h:' + height + ' fs:' + fontSize)
    taskPool.execute(calChapterContent, width, height, paragraphsToCal, fontSize,
      lineHeightRatio, this.paragraphSpacing, this.letterSpacing).then((chapterList) => {
      if (taskVersion !== this.configVersion) {
        console.info(`Discarding outdated calculation for chapter ${chapterIndex}`);
        return;
      }
      console.log('[calContentOfTargetChapter] chapter ' + chapterIndex + ' taskPool result, isArray: ' + Array.isArray(chapterList) + ', length: ' + (Array.isArray(chapterList) ? chapterList.length : 0))
      if (Array.isArray(chapterList)) {
        let startIndex = 0
        let result: string[][] = chapterList as string[][]
        if (result.length !== 0) {
          let newPages = result.map((item) => {
            let contentLength = item.reduce((accumulator, currentString) => {
              return accumulator + currentString.length;
            }, 0)
            let pageItem = new ReaderChapterPageItem(startIndex, startIndex + contentLength, item);
            startIndex += contentLength;
            return pageItem
          })

          let oldChapter = this.chapterList[chapterIndex];
          let newChapter = new ReaderChapterItem(
            oldChapter.number,
            oldChapter.title,
            oldChapter.chapterTitleNumber,
            oldChapter.content,
            oldChapter.paragraphList,
            newPages
          );
          console.log('[calContentOfTargetChapter] chapter ' + chapterIndex + ' pages created: ' + newPages.length)

          if (chapterIndex === this.currentChapterIndex) {
            let newPageIndex = 0;
            let pageList = newPages;
            if (pageList.length > 0) {
              if (restorePosition) {
                for (let i = 0; i < pageList.length; i++) {
                  if (targetStartPos >= pageList[i].startIndex) {
                    newPageIndex = i;
                  } else {
                    break;
                  }
                }
                if (newPageIndex >= pageList.length) {
                  newPageIndex = pageList.length - 1;
                }
              } else {
                if (this.isFirstInit) {
                  newPageIndex = this.currentPageIndex;
                  if (newPageIndex >= pageList.length) newPageIndex = pageList.length - 1;
                  if (newPageIndex < 0) newPageIndex = 0;
                  this.isFirstInit = false;
                } else if (isBackwards) {
                  newPageIndex = pageList.length - 1;
                } else {
                  newPageIndex = 0;
                }
              }
            }

            this.renderFontSize = this.fontSize;
            this.renderLineHeightRatio = this.lineHeightRatio;
            this.renderParagraphSpacing = this.paragraphSpacing;
            this.renderFontWeight = this.fontWeight;
            this.renderFontType = this.fontType;
            this.renderIsFirstLineIndent = this.isFirstLineIndent;
            this.renderLetterSpacing = this.letterSpacing;
            this.renderReaderPadding = this.readerPadding;
            this.currentPageIndex = newPageIndex;
            console.log('[calContentOfTargetChapter] currentPageIndex set to: ' + newPageIndex)
          }
          this.chapterList[chapterIndex] = newChapter;
          this.chapterList = Array.from(this.chapterList)
        }
      }
    }).catch((e: Error) => {
      console.log('[calContentOfTargetChapter] chapter ' + chapterIndex + ' taskPool error: ' + e.message)
    })
  }

  calChapterContent() {
    let isBackwards = this.currentChapterIndex < this.lastChapterIndex;
    this.lastChapterIndex = this.currentChapterIndex;
    this.configVersion++;
    let width = this.displaySize[0];
    let height = this.displaySize[1];
    console.log('[ReaderSourceProvider] calChapterContent called, displaySize: [' + width + ', ' + height + '], chapterList.length: ' + this.chapterList.length + ', currentChapterIndex: ' + this.currentChapterIndex)

    if (width !== 0 && height !== 0 && this.chapterList.length !== 0) {
      let ch = this.chapterList[this.currentChapterIndex]
      console.log('[ReaderSourceProvider] current chapter content length: ' + (ch?.content?.length ?? 0) + ', paragraphList.length: ' + (ch?.paragraphList?.length ?? 0) + ', chapterPageList.length: ' + (ch?.chapterPageList?.length ?? 0))
      this.calContentOfTargetChapter(width, height, this.currentChapterIndex,
        this.fontSize, this.lineHeightRatio, false, false, isBackwards);
      if (this.currentChapterIndex > 0) {
        this.calContentOfTargetChapter(width, height, this.currentChapterIndex - 1,
          this.fontSize, this.lineHeightRatio, false, false, false);
      }
      if (this.currentChapterIndex < this.chapterList.length - 1) {
        this.calContentOfTargetChapter(width, height, this.currentChapterIndex + 1,
          this.fontSize, this.lineHeightRatio, false, false, false);
      }
    } else {
      console.log('[ReaderSourceProvider] calChapterContent skipped - displaySize or chapterList empty')
    }
  }

  forceCalChapterContent() {
    let width = this.displaySize[0];
    let height = this.displaySize[1];

    if (width !== 0 && height !== 0 && this.chapterList.length !== 0) {
      this.calContentOfTargetChapter(width, height, this.currentChapterIndex,
        this.fontSize, this.lineHeightRatio, true, true, false);
      if (this.currentChapterIndex > 0) {
        this.calContentOfTargetChapter(width, height, this.currentChapterIndex - 1,
          this.fontSize, this.lineHeightRatio, true, false, false);
      }
      if (this.currentChapterIndex < this.chapterList.length - 1) {
        this.calContentOfTargetChapter(width, height, this.currentChapterIndex + 1,
          this.fontSize, this.lineHeightRatio, true, false, false);
      }
    }
  }

  build() {
    Row() {
      this.child()
    }
  }
}

@Component
struct ReaderConfigProvider {
  @BuilderParam child: () => void // 通用组件
  @Provide('turnStyle') @Watch('onSettingsChanged') turnStyle: FlipPageType = FlipPageType.COVER_FLIP_PAGE;
  @Provide('fontSize') @Watch('onSettingsChanged') fontSize: number = Constants.INIT_FONT_SIZE;
  @Provide('currentLuminance') currentLuminance: number = 0 // 亮度
  @Provide('lineHeightRatio') @Watch('onSettingsChanged') lineHeightRatio: number = Constants.INIT_LINE_HEIGHT_RATIO;
  @Provide('bgColor') @Watch('onSettingsChanged') bgColor: string = BG_COLOR_ARRAY[BGColorType.WHITE];
  @Provide('paragraphSpacing') @Watch('onSettingsChanged') paragraphSpacing: number = 0;
  @Provide('readerPadding') @Watch('onSettingsChanged') readerPadding: number = 24;
  @Provide('fontWeight') @Watch('onSettingsChanged') fontWeight: number = 400;
  @Provide('fontType') @Watch('onSettingsChanged') fontType: string = 'simplified';
  @Provide('isFirstLineIndent') @Watch('onSettingsChanged') isFirstLineIndent: boolean = true;
  @Provide('letterSpacing') @Watch('onSettingsChanged') letterSpacing: number = 0;
  chapterList: ReaderChapterItem[] = [];
  currentChapterIndex: number = 0;
  currentPageIndex: number = 0;

  async aboutToAppear() {
    try {
      const pref = await preferences.getPreferences(getContext(this), 'readerSettings')
      this.turnStyle = await pref.get('turnStyle', FlipPageType.COVER_FLIP_PAGE) as FlipPageType
      this.fontSize = await pref.get('fontSize', Constants.INIT_FONT_SIZE) as number
      this.lineHeightRatio = await pref.get('lineHeightRatio', Constants.INIT_LINE_HEIGHT_RATIO) as number
      this.bgColor = await pref.get('bgColor', BG_COLOR_ARRAY[BGColorType.WHITE]) as string
      this.paragraphSpacing = await pref.get('paragraphSpacing', 0) as number
      this.readerPadding = await pref.get('readerPadding', 24) as number
      this.fontWeight = await pref.get('fontWeight', 400) as number
      this.fontType = await pref.get('fontType', 'simplified') as string
      this.isFirstLineIndent = await pref.get('isFirstLineIndent', true) as boolean
      this.letterSpacing = await pref.get('letterSpacing', 0) as number
    } catch (e) {
      console.error('Failed to load reader settings:', e)
    }
  }

  async onSettingsChanged() {
    try {
      const pref = await preferences.getPreferences(getContext(this), 'readerSettings')
      await pref.put('turnStyle', this.turnStyle)
      await pref.put('fontSize', this.fontSize)
      await pref.put('lineHeightRatio', this.lineHeightRatio)
      await pref.put('bgColor', this.bgColor)
      await pref.put('paragraphSpacing', this.paragraphSpacing)
      await pref.put('readerPadding', this.readerPadding)
      await pref.put('fontWeight', this.fontWeight)
      await pref.put('fontType', this.fontType)
      await pref.put('isFirstLineIndent', this.isFirstLineIndent)
      await pref.put('letterSpacing', this.letterSpacing)
      await pref.flush()
    } catch (e) {
      console.error('Failed to save reader settings:', e)
    }
  }

  build() {
    Row() {
      ReaderStatusProvider({
        child: this.child,
        chapterList: this.chapterList,
        currentChapterIndex: this.currentChapterIndex,
        currentPageIndex: this.currentPageIndex
      })
    }
  }
}

@Component
struct ReaderStatusProvider {
  @BuilderParam child: () => void // 通用组件
  @Provide('curPosition') curPosition: number = 0;
  @Provide('currentPageIndex') currentPageIndex: number = 0;
  @Provide('currentChapterIndex') currentChapterIndex: number = 0;
  @Provide('displaySize') displaySize: number[] = [0, 0];
  @Provide('screenH') screenH: number = 0;
  @Provide('screenW') screenW: number = 0;
  chapterList: ReaderChapterItem[] = [];

  constructor() {
    super();
  }

  aboutToAppear(): void {
    this.screenW = px2vp(display.getDefaultDisplaySync().width);
    this.screenH = px2vp(display.getDefaultDisplaySync().height - (AppStorage.get('avoidHeight') as number));
  }

  build() {
    Row() {
      ReaderSourceProvider(
        { chapterList: this.chapterList, child: this.child }
      )
    }
  }
}