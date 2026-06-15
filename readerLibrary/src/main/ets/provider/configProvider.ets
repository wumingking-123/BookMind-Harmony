import { BGColorType, BG_COLOR_ARRAY, Constants, FlipPageType } from '../common/constants/Constants';
import { ReaderChapterItem, ReaderChapterPageItem } from '../common/entity/ReaderChaptersItem';
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

  build() {
    Row() {
      ReaderConfigProvider({
        turnStyle: this.turnStyle,
        fontSize: this.fontSize,
        lineHeightRatio: this.lineHeightRatio,
        bgColor: this.bgColor,
        child: this.child,
        chapterList: this.chapterList,
        currentChapterIndex: this.currentChapterIndex
      })
    }
  }
}

@Concurrent
async function calChapterContent(width: number, height: number, targetParagraphList: string[], fontSize: number,
  lineHeightRatio: number): Promise<string[][]> {
  try {
    return await NovelContentParseHelper.calculateChapterContent(targetParagraphList,
      fontSize,
      fontSize * lineHeightRatio, width, height)
  } catch (e) {
    console.info('loadNovel 出错 ' + e)
    return [];
  }
}

@Component
struct ReaderSourceProvider {
  @BuilderParam child: () => void // 通用组件
  @Provide('chapterList') chapterList: ReaderChapterItem[] = [];
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
  @Consume('currentPageIndex') currentPageIndex: number
  @State targetStartPos: number = 0

  onConfigSizeChange() {
    let currentChapter = this.chapterList?.[this.currentChapterIndex];
    if (currentChapter?.chapterPageList?.[this.currentPageIndex]) {
      this.targetStartPos = currentChapter.chapterPageList[this.currentPageIndex].startIndex;
    }
    this.forceCalChapterContent()
  }

  onDisplaySizeChange() {
    this.forceCalChapterContent()
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
    lineHeightRatio: number, forceUpdate: boolean) {
    if (!this.chapterList || !this.chapterList[chapterIndex]) {
      return
    }
    if (!forceUpdate) {
      if (this.chapterList[chapterIndex].chapterPageList.length !== 0) {
        return
      }
    }
    if (!this.chapterList[chapterIndex].paragraphList || this.chapterList[chapterIndex].paragraphList.length === 0) {
      if (this.chapterList[chapterIndex].content) {
        this.chapterList[chapterIndex].paragraphList = this.chapterList[chapterIndex].content
          .split('\n')
          .map((value: string) => value.trim())
          .filter((value: string) => value.length > 0)
          .map((value: string) => value + '\n');
      } else {
        this.chapterList[chapterIndex].paragraphList = []
      }
    }
    let paragraphsToCal = this.getFormattedParagraphs(this.chapterList[chapterIndex].paragraphList);
    taskPool.execute(calChapterContent, width, height, paragraphsToCal, fontSize,
      lineHeightRatio).then((chapterList) => {
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
          this.chapterList[chapterIndex].chapterPageList = newPages;

          if (chapterIndex === this.currentChapterIndex) {
            let newPageIndex = 0;
            let pageList = newPages;
            if (pageList.length > 0) {
              for (let i = 0; i < pageList.length; i++) {
                if (this.targetStartPos >= pageList[i].startIndex) {
                  newPageIndex = i;
                } else {
                  break;
                }
              }
              if (newPageIndex >= pageList.length) {
                newPageIndex = pageList.length - 1;
              }
            }
            this.currentPageIndex = newPageIndex;
          }
          this.chapterList = Array.from(this.chapterList)
        }
      }
    })
  }

  calChapterContent() {
    let width = this.displaySize[0];
    let height = this.displaySize[1];

    if (width !== 0 && height !== 0 && this.chapterList.length !== 0) {
      this.calContentOfTargetChapter(width, height, this.currentChapterIndex,
        this.fontSize, this.lineHeightRatio, false);
      if (this.currentChapterIndex > 0) {
        this.calContentOfTargetChapter(width, height, this.currentChapterIndex - 1,
          this.fontSize, this.lineHeightRatio, false);
      }
      if (this.currentChapterIndex < this.chapterList.length - 1) {
        this.calContentOfTargetChapter(width, height, this.currentChapterIndex + 1,
          this.fontSize, this.lineHeightRatio, false);
      }
    }
  }

  forceCalChapterContent() {
    let width = this.displaySize[0];
    let height = this.displaySize[1];

    if (width !== 0 && height !== 0 && this.chapterList.length !== 0) {
      this.calContentOfTargetChapter(width, height, this.currentChapterIndex,
        this.fontSize, this.lineHeightRatio, true);
      if (this.currentChapterIndex > 0) {
        this.calContentOfTargetChapter(width, height, this.currentChapterIndex - 1,
          this.fontSize, this.lineHeightRatio, true);
      }
      if (this.currentChapterIndex < this.chapterList.length - 1) {
        this.calContentOfTargetChapter(width, height, this.currentChapterIndex + 1,
          this.fontSize, this.lineHeightRatio, true);
      }
    }
  }

  aboutToAppear(): void {
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
        currentChapterIndex: this.currentChapterIndex
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