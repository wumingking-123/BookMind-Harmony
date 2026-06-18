import CommonConstants from '../../common/constants/CommonConstants'
import ReadRecordItem from '../../componets/bookDetail/ReadRecordItem'
import TagIndex from '../../componets/bookDetail/TagIndex'
import { router, SwipeRefresher } from '@kit.ArkUI'
import { chaptersItem } from '../../componets/dataList/ReaderChaptersItem'
import { FileHandler } from '../../common/utils/FileHandler'
import { BookContentHolder } from '../../common/utils/BookContentHolder'
import ChaptersDataSource from '../../common/LazyIDataSource/ChaptersDataSource'
import { Books } from '../../database/entities/Books'
import { BookHistory } from '../../database/entities/BookHistory'
import bookHistoryUtils from '../../common/utils/BookHistoryUtils'
import booksUtil from '../../common/utils/booksUtils'
import readRecordDao from '../../database/dao/ReadRecordDao'
import bookMarkDao from '../../database/dao/BookMarkDao'
import { BookMark } from '../../database/entities/BookMark'
import bookHistoryDao from '../../database/dao/BookHistoryDao'
import { ThemeStorageKey } from '../../common/constants/Theme'
import { ThemeItem } from '../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../common/constants/DesignTokens'
import { isNetworkUrl } from '../../common/utils/utils'
import requestUtils from '../../common/utils/requestUtils'
import { TocAnalysis, TocAnalysisData } from '../../common/model/TocAnalysis'
import { BookSource } from '../../database/entities/BookSource'
import bookSourceDao from '../../database/dao/BookSourceDao'
import { RuleAnalyzer, RuleAnalyzerData } from '../../common/model/analyzeRule/RuleAnalyzer'

/**
 * 标题图片样式
 */
@Extend(Image)
function titleImageStyle() {
  .fillColor(Color.White)
  .width(24)
  .height(24)
}

/**
 * 分割线样式
 */
@Extend(Divider)
function recordDividerStyle() {
  .vertical(true)
  .width(0.5)
  .height(20)
  .color(InkPalette.OVERLAY_LIGHT)
}

/**
 * 加入书架dialog
 */
@CustomDialog
struct AddBookShelfDialog {
  controller?: CustomDialogController

  build() {
    Row() {
      Image($r('app.media.ic_public_confirm'))
        .width(20)
        .height(20)
        .fillColor(InkPalette.PAPER)
      Text('加入书架成功')
        .fontSize(InkTypography.BODY)
        .fontColor(InkPalette.PAPER)
        .margin({ left: InkSpacing.SM })
      Blank()
      Text('移入分组')
        .fontSize(InkTypography.BODY)
        .fontColor(InkPalette.AMBER_LIGHT)
    }
    .height(52)
    .width('100%')
    .padding({ left: InkSpacing.XL, right: InkSpacing.XL })
    .backgroundColor(InkPalette.INK)
    .borderRadius(InkRadius.MD)
  }
}

@Entry
@Component
struct BookDetailPage {
  @State isShow: boolean = true
  @State currentIndex: number = 0
  // 是否加入书架
  @State isAddBookShelf: boolean = false
  @State bookData: Books = router.getParams() as Books
  // 加入书架dialog
  dialogController: CustomDialogController = new CustomDialogController({
    builder: AddBookShelfDialog(),
    cornerRadius: InkRadius.MD,
    offset: { dx: 0, dy: -100 },
    customStyle: false,
  })
  @State txtFiles: chaptersItem[] = []
  @State txtFile: ChaptersDataSource = new ChaptersDataSource()
  @State readTimeMins: number = 0
  @State readDays: number = 0
  @State readCount: number = 0
  @State displayTags: string[] = []
  @State hasHistory: boolean = false
  @State bookBookmarks: BookMark[] = []
  @State tabList: string[] = ['目录', '书源', '书签']
  private _bookSource: BookSource | undefined = undefined

  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  onPageShow() {
    this.isShow = true
  }

  checkIsLocalBook(): boolean {
    if (this.bookData.isLocalBook === true || Number(this.bookData.isLocalBook) === 1 || String(this.bookData.isLocalBook) === 'true' || String(this.bookData.isLocalBook) === '1') {
      return true;
    }
    return false;
  }

  async aboutToAppear() {
    console.log('router BookDetailPage:' + JSON.stringify(router.getParams()))
    if (router.getParams() as Books) {
      this.bookData = router.getParams() as Books
      
      // 映射 kind 到 customTag
      let params = router.getParams() as Record<string, Object>
      if (params && params.kind && !this.bookData.customTag) {
        this.bookData.customTag = params.kind as string
      }

      // 校验是否加入书架
      if (!this.bookData.isJoin) {
        this.bookData.isJoin = await booksUtil.isExistBooks(this.bookData.bookUrl, this.bookData.bookName)
      }
      // 从数据库读取最新的阅读进度与完整信息
      if (this.bookData.id) {
        let savedBooks = await booksUtil.getBookByIds(this.bookData.id)
        if (savedBooks.length > 0) {
          this.bookData = savedBooks[0]
        }
      }

      this.updateDisplayTags()

      const bookUrl = this.bookData?.bookUrl || ''
      let temp: chaptersItem[] = []
      console.log('[BookDetailPage] bookUrl: ' + bookUrl)
      console.log('[BookDetailPage] bookName: ' + this.bookData?.bookName)
      if (isNetworkUrl(bookUrl)) {
        // 在线书籍：通过网络获取目录
        await this.loadOnlineToc(bookUrl)
      } else {
        // 本地文件：读取本地目录
        temp = await FileHandler.readFile(bookUrl)
        this.txtFile.pushAllData(temp)
        this.txtFiles = this.txtFile.getListData()
      }
      this.initUrlBook()

      // 如果是本地小说，且数据库中未存储字数，或者字数为空，则计算实际字数并保存
      if (!this.bookData.wordCount && temp && temp.length > 0) {
        let totalChars = 0;
        for (let chapter of temp) {
          totalChars += chapter.content ? chapter.content.length : 0;
        }
        if (totalChars > 0) {
          if (totalChars >= 10000) {
            this.bookData.wordCount = (totalChars / 10000).toFixed(1) + '万字';
          } else {
            this.bookData.wordCount = totalChars + '字';
          }
          // 保存到数据库
          if (this.bookData.id) {
            await booksUtil.partialUpdate(this.bookData);
          }
          this.updateDisplayTags()
        }
      }
      
      // 读取实际阅读记录
      let record = await readRecordDao.getRecordByBookName(this.bookData.bookName);
      if (record) {
        this.readTimeMins = Math.floor(record.readTime / 60);
        this.readDays = record.readDays;
        this.readCount = record.readCount;
      } else {
        this.readTimeMins = 0;
        this.readDays = 0;
        this.readCount = 0;
      }

      // 检查是否有阅读历史记录
      let histories = await bookHistoryDao.search();
      this.hasHistory = histories.some(h => h.id === this.bookData.id || h.bookName === this.bookData.bookName);

      // 加载本书相关的书签
      let allBookmarks = await bookMarkDao.queryAll();
      this.bookBookmarks = allBookmarks.filter(bm => bm.bookName && bm.bookName.trim() === this.bookData.bookName.trim());

      // 根据是否是本地书初始化 Tab 标签
      if (this.checkIsLocalBook()) {
        this.tabList = ['目录', '书签']
      } else {
        this.tabList = ['目录', '书源', '书签']
      }
    }
  }

  updateDisplayTags() {
    let tagList: string[] = [];

    // 1. 本地/线上分类
    if (this.checkIsLocalBook()) {
      tagList.push('本地导入');
      // 提取文件后缀
      let ext = '';
      if (this.bookData.bookUrl) {
        let dotIdx = this.bookData.bookUrl.lastIndexOf('.');
        if (dotIdx > 0) {
          ext = this.bookData.bookUrl.substring(dotIdx + 1).toUpperCase();
        }
      }
      if (ext) {
        tagList.push(ext);
      }
    } else {
      // 线上书源
      if (this.bookData.originName) {
        tagList.push(this.bookData.originName);
      }
    }

    // 2. 自定义分类标签
    if (this.bookData.customTag) {
      let splitTags = this.bookData.customTag.split(/[,，\s]+/);
      for (let tag of splitTags) {
        if (tag.trim() && !tagList.includes(tag.trim())) {
          tagList.push(tag.trim());
        }
      }
    }

    // 3. 字数标签
    let wc = this.bookData.wordCount;
    if (wc) {
      let formattedWc = '';
      wc = wc.trim();
      if (wc.endsWith('字') || wc.endsWith('万') || wc.endsWith('k') || wc.endsWith('K')) {
        formattedWc = wc;
      } else {
        let num = parseInt(wc);
        if (!isNaN(num) && num > 0) {
          if (num >= 10000) {
            formattedWc = (num / 10000).toFixed(1) + '万字';
          } else {
            formattedWc = num + '字';
          }
        } else {
          formattedWc = wc;
        }
      }
      if (formattedWc && !tagList.includes(formattedWc)) {
        tagList.push(formattedWc);
      }
    }

    // 默认兜底标签
    if (tagList.length === 0) {
      tagList.push('未分类');
    }

    this.displayTags = tagList;
  }

  /**
   * 在线书籍：获取目录
   */
  async loadOnlineToc(bookUrl: string) {
    try {
      // 查找匹配的书源
      const source = await this.findBookSource(bookUrl)
      console.log('[BookDetailPage] findBookSource result: ' + (source ? source.bookSourceName + ' (' + source.bookSourceUrl + ')' : 'null'))
      if (!source || !source.ruleToc) {
        console.log('[BookDetailPage] 未找到匹配书源或目录规则, bookUrl=' + bookUrl)
        return
      }

      // 获取目录页HTML（优先用tocUrl，否则用bookUrl）
      let tocUrl = bookUrl
      if (source.ruleBookInfo?.tocUrl) {
        // 先获取书籍详情页，提取tocUrl
        try {
          const detailHtml = await requestUtils.requestUrlHtml(bookUrl, source.charset)
          const analyzer = new RuleAnalyzer()
          analyzer.init(new RuleAnalyzerData({ body: detailHtml, bookSource: source }))
          const extractedTocUrl = analyzer.extractText(detailHtml, source.ruleBookInfo.tocUrl)
          if (extractedTocUrl && isNetworkUrl(extractedTocUrl)) {
            tocUrl = extractedTocUrl
          } else if (extractedTocUrl) {
            tocUrl = source.bookSourceUrl + extractedTocUrl
          }
        } catch (e) {
          console.log('BookDetailPage: 获取详情页失败，使用bookUrl作为目录页: ' + (e as Error).message)
        }
      }

      // 请求目录页HTML
      const tocHtml = await requestUtils.requestUrlHtml(tocUrl, source.charset)
      if (!tocHtml || tocHtml.length < 100) {
        console.log('BookDetailPage: 目录页内容为空或过短')
        return
      }
      // 调试：打印HTML中包含catalogue或list的关键片段
      const debugMatch = tocHtml.match(/catalogue[^"]{0,50}/gi)
      console.log('[BookDetailPage] HTML中catalogue匹配: ' + JSON.stringify(debugMatch))
      // 打印前2000字的HTML结构
      console.log('[BookDetailPage] 目录HTML前2000字: ' + tocHtml.substring(0, 2000))

      // 使用TocAnalysis解析目录
      const tocAnalysis = new TocAnalysis()
      tocAnalysis.init(new TocAnalysisData({
        body: tocHtml,
        bookSource: source,
        bookUrl: bookUrl
      }))
      const chapters = await tocAnalysis.getChapterList()

      // 转换为UI需要的chaptersItem格式
      const items: chaptersItem[] = []
      for (const ch of chapters) {
        items.push(new chaptersItem(
          ch.index,
          ch.title,
          `第${ch.index + 1}章`,
          ch.url // 将章节URL存入content字段，阅读时使用
        ))
      }

      this.txtFile.pushAllData(items)
      this.txtFiles = this.txtFile.getListData()
      this._bookSource = source
      console.log('BookDetailPage: 在线目录加载成功, ' + items.length + ' 章')
    } catch (e) {
      console.log('BookDetailPage: 在线目录加载失败: ' + (e as Error).message)
    }
  }

  /**
   * 根据bookUrl查找匹配的书源
   */
  async findBookSource(bookUrl: string): Promise<BookSource | null> {
    try {
      // 从bookUrl中提取域名，匹配书源
      const match = bookUrl.match(/^(https?:\/\/[^\/]+)/)
      if (!match) {
        console.log('[findBookSource] 无法提取域名: ' + bookUrl)
        return null
      }
      const domain = match[1]
      console.log('[findBookSource] 提取域名: ' + domain)

      const sources = await bookSourceDao.getEnabledPartByGroup()
      console.log('[findBookSource] 启用书源数量: ' + sources.length)
      for (const s of sources) {
        const srcDomain = s.bookSourceUrl ? s.bookSourceUrl.replace(/^https?:\/\//, '') : ''
        console.log('[findBookSource] 检查书源: ' + s.bookSourceName + ' (' + srcDomain + ')')
        if (s.bookSourceUrl && domain.includes(srcDomain)) {
          // 获取完整书源（包含规则）
          const fullSource = await bookSourceDao.getBookSource(s.bookSourceUrl)
          console.log('[findBookSource] 匹配成功: ' + s.bookSourceName + ', hasRuleToc=' + !!fullSource?.ruleToc + ', hasRuleContent=' + !!fullSource?.ruleContent)
          if (fullSource) return fullSource
        }
      }
      console.log('[findBookSource] 无匹配书源')
      return null
    } catch (e) {
      console.log('[findBookSource] 查找书源失败: ' + (e as Error).message)
      return null
    }
  }

  initUrlBook() {
    let book = this.bookData.bookUrl
    console.log(book)
  }

  @StorageLink('BOOK_IS_BOOK_REFRESHING') isBookRefreshing: number = 0

  // 加入书架函数
  addBookShelf() {
    booksUtil.addBooks(this.bookData)
    this.dialogController.open()
    this.isAddBookShelf = true
    // 1s后关闭dialog
    setTimeout(() => {
      this.isBookRefreshing++
      this.dialogController.close()
    }, 1000)
  }

  /**
   * 目录面板 Panel
   */
  @Builder
  catalogPanel() {
    Column() {
      // 拖拽指示条
      Row()
        .width(32)
        .height(4)
        .borderRadius(2)
        .backgroundColor(InkPalette.INK_MIST)
        .margin({ top: InkSpacing.MD, bottom: InkSpacing.MD })

      // 搜索目录 — 墨韵风格
      Row({ space: InkSpacing.SM }) {
        Image($r('app.media.search'))
          .width(16)
          .height(16)
          .fillColor(InkPalette.INK_MIST)
        Text('搜索目录')
          .fontSize(InkTypography.BODY)
          .fontColor(InkPalette.INK_MIST)
      }
      .height(40)
      .borderRadius(InkRadius.SEARCH)
      .backgroundColor(InkPalette.PAPER_WARM)
      .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
      .width('100%')

      Tabs({ barPosition: BarPosition.Start }) {
        ForEach(this.tabList, (name: string, idx: number) => {
          TabContent() {
            if (name === '目录') {
              Column() {
                if (this.txtFiles.length === 0) {
                  SwipeRefresher({ content: '目录加载中...', isLoading: true })
                } else {
                  List() {
                    LazyForEach(this.txtFile, (item: chaptersItem, index: number) => {
                      ListItem() {
                        Row() {
                          Text(`${item.chapterTitleNumber} ${item.title}`
                            .replace(new RegExp('\\s{1,}', 'g'), ' ')
                            .replaceAll('=', ''))
                            .fontSize(InkTypography.BODY)
                            .fontColor(InkPalette.INK)
                            .layoutWeight(1)
                        }
                        .width('100%')
                        .height(48)
                        .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
                      }
                      .onClick(() => {
                        // Cache chapter list to avoid serialization overhead
                        BookContentHolder.setChapters(this.txtFiles);
                        // 跳转到阅读器
                        router.pushUrl({
                          url: canIUse("SystemCapability.Reader.ReaderService.ReaderCore")
                            ? 'pages/view/Reader/ReaderPageKit'
                            : 'pages/view/Reader/ReaderPage2',
                          params: {
                            bookData: this.bookData,
                            clickBookChapter: index
                          }
                        })
                        if (this.txtFiles && this.txtFile.getListData()[index]) {
                          this.jumpReadPage(`${item.chapterTitleNumber} ${item.title}`, index)
                        }
                      })
                    })
                  }
                  .chainAnimation(true)
                  .edgeEffect(EdgeEffect.Fade)
                  .divider({
                    strokeWidth: 0.5,
                    color: InkPalette.PAPER_DEEP,
                    startMargin: InkSpacing.LG,
                    endMargin: InkSpacing.LG
                  })
                }
              }
            } else if (name === '书源') {
              Column() {
                SwipeRefresher({ content: '书源加载中...', isLoading: true })
              }
            } else if (name === '书签') {
              Column() {
                if (this.bookBookmarks.length === 0) {
                  Column({ space: InkSpacing.LG }) {
                    Stack({ alignContent: Alignment.Center }) {
                      Row()
                        .width(100)
                        .height(100)
                        .borderRadius(InkRadius.FULL)
                        .backgroundColor(InkPalette.PAPER_WARM)
                      Image($r('app.media.find_empty'))
                        .width(64)
                        .height(64)
                        .opacity(0.6)
                    }
                    .width(100)
                    .height(100)

                    Text('暂无书签')
                      .fontSize(InkTypography.BODY)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(InkPalette.INK_LIGHT)
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                  .padding({ top: InkSpacing.HUGE })
                } else {
                  List() {
                    ForEach(this.bookBookmarks, (item: BookMark, index: number) => {
                      ListItem() {
                        Column({ space: 6 }) {
                          Row() {
                            Text(item.chapterName || item.bookText || '未知章节')
                              .fontSize(InkTypography.BODY)
                              .fontColor(InkPalette.INK)
                              .layoutWeight(1)
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                            Text(new Date(item.time).toLocaleDateString())
                              .fontSize(InkTypography.CAPTION)
                              .fontColor(InkPalette.INK_MIST)
                          }
                          .width('100%')

                          if (item.content) {
                            Text(item.content)
                              .fontSize(InkTypography.BODY_SMALL)
                              .fontColor(InkPalette.INK_LIGHT)
                              .lineHeight(InkTypography.BODY_SMALL * InkTypography.LINE_HEIGHT_NORMAL)
                              .maxLines(2)
                              .textOverflow({ overflow: TextOverflow.Ellipsis})
                              .width('100%')
                          }
                        }
                        .padding({ left: InkSpacing.LG, right: InkSpacing.LG, top: 12, bottom: 12 })
                        .width('100%')
                        .onClick(async () => {
                          BookContentHolder.setChapters(this.txtFiles);
                          router.pushUrl({
                            url: canIUse("SystemCapability.Reader.ReaderService.ReaderCore")
                              ? 'pages/view/Reader/ReaderPageKit'
                              : 'pages/view/Reader/ReaderPage2',
                            params: {
                              bookData: this.bookData,
                              clickBookChapter: item.chapterIndex,
                              clickBookPage: item.chapterPos
                            }
                          });
                          this.jumpReadPage(item.chapterName, item.chapterIndex);
                        })
                      }
                    })
                  }
                  .chainAnimation(true)
                  .edgeEffect(EdgeEffect.Fade)
                  .divider({
                    strokeWidth: 0.5,
                    color: InkPalette.PAPER_DEEP,
                    startMargin: InkSpacing.LG,
                    endMargin: InkSpacing.LG
                  })
                  .scrollBar(BarState.Off)
                  .width('100%')
                  .layoutWeight(1)
                  .padding({ bottom: 20 })
                }
              }
              .width('100%')
              .height('100%')
            }
          }
          .tabBar(this.catalogTab(idx, name, this.getTabCount(name)))
        }, (name: string) => name)
      }
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentIndex = index
      })

      // 底部按钮 — 加入书架 / 继续阅读或立即阅读 (大圆角胶囊)
      Row({ space: InkSpacing.LG }) {
        Button(this.bookData.isJoin ? '已加书架' : '加入书架')
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .width(140)
          .height(48)
          .borderRadius(InkRadius.BUTTON_LARGE)
          .backgroundColor(InkPalette.PAPER_WARM)
          .fontColor(InkPalette.INK)
          .onClick(() => {
            !this.bookData.isJoin ? this.addBookShelf() : ''
          })

        Button(this.bookData.bookType === 2 ? '开始播放' : (this.hasHistory ? '继续阅读' : '立即阅读'))
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .width(140)
          .height(48)
          .borderRadius(InkRadius.BUTTON_LARGE)
          .backgroundColor(this.bookData.bookType === 2 || this.txtFile.totalCount() > 0 ? this.theme.mainColor : InkPalette.INK_MIST)
          .fontColor(InkPalette.PAPER)
          .enabled(this.bookData.bookType === 2 || this.txtFile.totalCount() > 0)
          .onClick(() => {
            let savedIndex = this.bookData.durChapterIndex || 0;
            if (savedIndex >= this.txtFiles.length) {
              savedIndex = 0;
            }
            if (this.bookData.bookType === 2) {
              // 有声书直接跳转播放器
              router.pushUrl({
                url: 'pages/view/Reader/ReaderPage2',
                params: { bookData: this.bookData, clickBookChapter: savedIndex, clickBookPage: this.bookData.durChapterPos || 0 }
              })
            } else {
              // 小说/漫画跳转阅读器
              BookContentHolder.setChapters(this.txtFiles);
              router.pushUrl({
                url: canIUse("SystemCapability.Reader.ReaderService.ReaderCore")
                  ? 'pages/view/Reader/ReaderPageKit'
                  : 'pages/view/Reader/ReaderPage2',
                params: { bookData: this.bookData, clickBookChapter: savedIndex, clickBookPage: this.bookData.durChapterPos || 0 }
              })
              let chapterItem = this.txtFile.getListData()[savedIndex];
              if (this.txtFiles && chapterItem) {
                this.jumpReadPage(`${chapterItem.chapterTitleNumber} ${chapterItem.title}`, savedIndex)
              }
            }
          })
      }
    }
    .padding({ left: InkSpacing.XL, right: InkSpacing.XL, top: InkSpacing.MD, bottom: InkSpacing.MD })
    .width('100%')
    .height('100%')
    .backgroundColor(InkPalette.PAPER)
  }

  getTabCount(name: string): number {
    if (name === '目录') {
      return this.txtFile.totalCount()
    } else if (name === '书源') {
      return 24
    } else if (name === '书签') {
      return this.bookBookmarks.length
    }
    return 0
  }

  /**
   * tab页签
   */
  @Builder
  catalogTab(index: number, name: string, count: number) {
    Column({ space: 4 }) {
      Row({ space: 4 }) {
        Text(name)
          .fontSize(InkTypography.BODY)
          .fontColor(this.currentIndex === index ? InkPalette.INK : InkPalette.INK_MIST)
          .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)

        Text(count.toString())
          .fontSize(InkTypography.CAPTION)
          .fontColor(this.currentIndex === index ? InkPalette.INK_FAINT : InkPalette.INK_MIST)
      }

      // 活跃指示器
      Row()
        .width(this.currentIndex === index ? 16 : 0)
        .height(2)
        .borderRadius(1)
        .backgroundColor(this.theme.mainColor)
        .animation({ duration: 200, curve: Curve.EaseOut })
    }
    .padding({ top: InkSpacing.SM, bottom: InkSpacing.SM })
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      // todo 状态栏
      Row()
        .width('100%')
        .height(40)

      // 标题栏 — 墨韵风格，大触控区域
      Row() {
        // 返回按钮
        Row() {
          Image($r('app.media.ic_public_return_left'))
            .fillColor(Color.White)
            .width(24)
            .height(24)
        }
        .width(InkLayout.MIN_TOUCH_TARGET)
        .height(InkLayout.MIN_TOUCH_TARGET)
        .borderRadius(InkRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { router.back() })

        Text('书籍详情')
          .fontColor(Color.White)
          .fontSize(InkTypography.TITLE_SMALL)
          .fontWeight(FontWeight.Medium)

        Blank()

        // 右侧功能
        Row({ space: InkSpacing.SM }) {
          Row() {
            Image($r('app.media.ic_public_edit'))
              .fillColor(Color.White)
              .width(22)
              .height(22)
          }
          .width(InkLayout.MIN_TOUCH_TARGET)
          .height(InkLayout.MIN_TOUCH_TARGET)
          .borderRadius(InkRadius.FULL)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            router.pushUrl({ url: '/pages/view/BookEditor/BookEditorPage' })
          })

          Row() {
            Image($r('app.media.ic_public_share'))
              .fillColor(Color.White)
              .width(22)
              .height(22)
          }
          .width(InkLayout.MIN_TOUCH_TARGET)
          .height(InkLayout.MIN_TOUCH_TARGET)
          .borderRadius(InkRadius.FULL)
          .justifyContent(FlexAlign.Center)

          Row() {
            Image($r('app.media.more'))
              .fillColor(Color.White)
              .width(22)
              .height(22)
          }
          .width(InkLayout.MIN_TOUCH_TARGET)
          .height(InkLayout.MIN_TOUCH_TARGET)
          .borderRadius(InkRadius.FULL)
          .justifyContent(FlexAlign.Center)
        }
      }
      .padding({ left: InkSpacing.LG, right: InkSpacing.LG, top: InkSpacing.XS, bottom: InkSpacing.XS })
      .width('100%')

      // 小说标题区域 — 封面 + 信息 + 标签
      Row({ space: InkSpacing.XL }) {
        Stack() {
          Image(this.bookData.coverUrl)
            .alt($r('app.media.icon_book_default_cover_ten'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .borderRadius(InkRadius.BOOK_COVER)
        }
        .width(80)
        .height(107)
        .borderRadius(InkRadius.BOOK_COVER)
        .shadow(InkShadow.DEEP)
        .clip(true)

        Column({ space: InkSpacing.SM }) {
          Text(this.bookData.bookName.replace(new RegExp('\\..*', 'g'), ''))
            .fontSize(InkTypography.TITLE_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Blank(4)

          Row({ space: InkSpacing.XS }) {
            Text(this.bookData.author ?? '未知作者')
              .fontSize(InkTypography.CAPTION)
              .fontColor('#80FFFFFF')
            Image($r('app.media.ic_public_right'))
              .width(14)
              .height(14)
              .fillColor('#80FFFFFF')
          }

          Row({ space: InkSpacing.SM }) {
            ForEach(this.displayTags, (tag: string) => {
              TagIndex({ tag: tag })
            }, (tag: string) => tag)
          }
        }
        .height(107)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .padding({ left: InkSpacing.XL, right: InkSpacing.XL, top: InkSpacing.MD })
      .width('100%')

      // 阅读记录
      Row() {
        Row() {
          ReadRecordItem({
            count: this.readTimeMins >= 60 ? Math.floor(this.readTimeMins / 60) : this.readTimeMins,
            unit: this.readTimeMins >= 60 ? '小时' : '分钟',
            placeText: '阅读时长'
          })
          Divider().recordDividerStyle()
          ReadRecordItem({ count: this.readDays, unit: '天', placeText: '阅读天数' })
          Divider().recordDividerStyle()
          ReadRecordItem({ count: this.readCount, unit: '次', placeText: 'N刷次数' })
        }
        .borderRadius(InkRadius.MD)
        .padding({ top: InkSpacing.LG, bottom: InkSpacing.LG })
        .width('100%')
        .backgroundColor(InkPalette.OVERLAY_LIGHT)
      }
      .padding({ left: InkSpacing.XL, right: InkSpacing.XL, top: InkSpacing.LG })
      .width('100%')

      // 书籍简介
      Flex() {
        Text(this.bookData.intro ?? '暂无简介')
          .fontColor('#CCFFFFFF')
          .fontSize(InkTypography.BODY)
          .lineHeight(InkTypography.BODY * InkTypography.LINE_HEIGHT_RELAXED)
      }
      .padding({ left: InkSpacing.XL, right: InkSpacing.XL, top: InkSpacing.LG })
      .width('100%')
      // 章节目录Panel
      .bindSheet($$this.isShow, this.catalogPanel(), {
        detents: [SheetSize.MEDIUM, SheetSize.LARGE, 200],
        backgroundColor: InkPalette.PAPER,
        showClose: false,
        dragBar: false,
        enableOutsideInteractive: true,
      })
    }
    .height('100%')
    .width('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [InkPalette.INK, 0],
        ['#2D3A3A', 0.4],
        [InkPalette.INK_LIGHT, 1]
      ]
    })
  }

  // @StorageLink('BOOK_IS_BOOK_HISTORY_REFRESHING') isBookHistoryRefreshing: number = 0
  // 跳转阅读界面更新或者添加阅读历史记录方法
  async jumpReadPage(durChapterTitle: string, durChapterIndex: number) {
    let bookHistory = new BookHistory()
    bookHistory.id = this.bookData.id
    bookHistory.bookName = this.bookData.bookName
    bookHistory.author = this.bookData.author
    bookHistory.durChapterTime = Date.now()
    bookHistory.bookType = this.bookData.bookType
    bookHistory.bookUrl = this.bookData.bookUrl ?? ''
    bookHistory.coverUrl = this.bookData.coverUrl ?? ''
    bookHistory.originBookId = this.bookData.id
    bookHistory.durChapterTitle = durChapterTitle
    bookHistory.durChapterIndex = durChapterIndex
    bookHistoryUtils.addBooks(bookHistory)
  }

  startReadOrPlay() {
    let savedIndex = this.bookData.durChapterIndex || 0
    if (savedIndex >= this.txtFiles.length) {
      savedIndex = 0
    }
    let chapterItem = this.txtFile.getListData()[savedIndex]
    if (this.bookData.bookType !== 2) {
      BookContentHolder.setBookSource(this._bookSource)
      BookContentHolder.setChapters(this.txtFiles)
    }
    router.pushUrl({
      url: 'pages/view/Reader/ReaderPage2',
      params: {
        bookData: this.bookData,
        clickBookChapter: savedIndex
      }
    })
    if (this.txtFiles && chapterItem) {
      this.jumpReadPage(`${chapterItem.chapterTitleNumber} ${chapterItem.title}`, savedIndex)
    }
  }
}
