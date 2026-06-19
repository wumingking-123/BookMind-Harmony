import { BookSource } from '../../database/entities/BookSource'
import { SearchRule } from '../../database/entities/rule/SearchRule'
import { TocRule } from '../../database/entities/rule/TocRule'
import { ContentRule } from '../../database/entities/rule/ContentRule'
import { ExploreRule } from '../../database/entities/rule/ExploreRule'
import { BookInfoRule } from '../../database/entities/rule/BookInfoRule'
import { ExploreItem } from '../../database/types/BookSourceType'

function exploreItem(title: string, url: string, isSeparator: boolean = false): ExploreItem {
  const item: ExploreItem = { title, url }
  if (isSeparator) {
    item.style = { layout_flexBasisPercent: 1 }
  }
  return item
}

/**
 * 默认书源数据
 * 首次启动时自动加载，用户可在书源管理页面启用/禁用
 */
export function getDefaultBookSources(): BookSource[] {
  const sources: BookSource[] = []

  // 刺猬猫PC版（规则最完整）
  sources.push(createCiWeiMaoPCSource())

  // 刺猬猫WAP版（移动版）
  sources.push(createCiWeiMaoWapSource())

  // 福书网
  sources.push(createFuShuCunSource())

  // 爱去小说网
  sources.push(createAiQuNovelSource())

  // 歪歪书库
  sources.push(createYYSKSource())

  return sources
}

/**
 * 刺猬猫PC版书源
 * 来源：书源.txt - 💰 刺猬猫PC
 * 规则最完整，包含搜索、发现、目录、正文全部规则
 */
function createCiWeiMaoPCSource(): BookSource {
  const source = new BookSource()
  source.bookSourceUrl = 'https://www.ciweimao.com'
  source.bookSourceName = '刺猬猫PC'
  source.bookSourceGroup = '精品'
  source.bookSourceType = 0
  source.bookSourceGrade = 2
  source.bookSourceScore = '4.0分'
  source.enabled = true
  source.enabledExplore = true
  source.lastUpdateTime = Date.now()
  source.respondTime = 6811
  source.customOrder = 100
  source.weight = 0
  source.isTop = false
  source.showRecentIcon = true
  source.showExplore = true
  source.loginUrl = 'https://www.ciweimao.com/signup/login?redirect=https://www.ciweimao.com'

  // 发现页URL（JSON格式，ExploreItem[]）- 仅使用rank-index路径（book_list路径返回503）
  const pcExploreList: ExploreItem[] = [
    exploreItem('全部排行', '', true),
    exploreItem('点击榜', 'https://www.ciweimao.com/rank-index/no-vip-click-week/{{page}}'),
    exploreItem('收藏榜', 'https://www.ciweimao.com/rank-index/favor-week/{{page}}'),
    exploreItem('推荐榜', 'https://www.ciweimao.com/rank-index/recommend-week/{{page}}'),
    exploreItem('月票榜', 'https://www.ciweimao.com/rank-index/yp-week/{{page}}'),
    exploreItem('订阅榜', 'https://www.ciweimao.com/rank-index/buy-week/{{page}}'),
    exploreItem('吐槽榜', 'https://www.ciweimao.com/rank-index/tsukkomi-week/{{page}}'),
    exploreItem('新书榜', 'https://www.ciweimao.com/rank-index/yp_new-week/{{page}}'),
    exploreItem('刀片榜', 'https://www.ciweimao.com/rank-index/blade-week/{{page}}'),
    exploreItem('更新榜', 'https://www.ciweimao.com/rank-index/get-update-most-week/{{page}}')
  ]
  source.exploreUrl = JSON.stringify(pcExploreList)

  // 搜索URL
  source.searchUrl = '/get-search-book-list/0-0-0-0-0-0/全部/{{key}}/{{page}}'

  // 搜索规则（legado格式）
  const searchRule = new SearchRule()
  searchRule.bookList = 'class.rank-book-list@tag.li||class.book-list-table@tag.tr!0'
  searchRule.name = 'class.cnt.0@class.tit.0@tag.a.0@text||class.name@tag.a@text'
  searchRule.author = 'class.cnt.0@tag.p.1@tag.a.0@text||class.author@text'
  searchRule.bookUrl = 'class.cnt.0@class.tit.0@tag.a.0@href||class.name@tag.a@href'
  searchRule.coverUrl = 'class.cover@tag.img@data-original||tag.img.0@src'
  searchRule.intro = 'class.desc@text'
  searchRule.kind = ''
  searchRule.lastChapter = '@css:p:matches(最近更新)@text||.chapter@text'
  source.ruleSearch = searchRule

  // 发现规则（legado格式）
  const exploreRule = new ExploreRule()
  exploreRule.bookList = 'class.rank-book-list@tag.li||class.book-list-table@tag.tr!0'
  exploreRule.name = 'class.tit@tag.a.0@text||class.name@tag.a.0@text'
  exploreRule.author = 'class.author@tag.a.0@text||p@tag.a.0@text'
  exploreRule.bookUrl = 'class.tit@tag.a.0@href||class.name@tag.a.0@href'
  exploreRule.coverUrl = 'class.lazyload@data-original'
  exploreRule.intro = 'class.desc@text'
  exploreRule.kind = 'class.type@tag.p.0@text'
  exploreRule.lastChapter = 'class.cnt@tag.p.1@text||class.chapter@tag.p.0@text'
  exploreRule.wordCount = 'class.cnt@tag.p.1@text'
  source.ruleExplore = exploreRule

  // 书籍信息规则
  const bookInfoRule = new BookInfoRule()
  bookInfoRule.coverUrl = 'class.cover ly-fl@tag.img@src'
  bookInfoRule.intro = 'class.book-desc.0@text'
  bookInfoRule.tocUrl = 'class.btn btn-lg btn-danger@tag.a.0@href||text.所有章节@href'
  source.ruleBookInfo = bookInfoRule

  // 目录规则
  const tocRule = new TocRule()
  tocRule.chapterList = '.book-chapter-box@li@a'
  tocRule.chapterName = 'text'
  tocRule.chapterUrl = "href##$##,{'webView': true}"
  source.ruleToc = tocRule

  // 正文规则
  const contentRule = new ContentRule()
  contentRule.content = '#J_BookRead .chapter@textNodes'
  source.ruleContent = contentRule

  return source
}

/**
 * 刺猬猫WAP版书源（移动版）
 * 来源：书源.txt - 🌐 刺猬猫网（wap.ciweimao.com）
 * WAP版页面更简洁，适合移动设备
 * 注意：WAP站目前有验证码拦截，可能无法正常访问
 */
function createCiWeiMaoWapSource(): BookSource {
  const source = new BookSource()
  source.bookSourceUrl = 'https://wap.ciweimao.com'
  source.bookSourceName = '刺猬猫'
  source.bookSourceGroup = '精品'
  source.bookSourceType = 0
  source.bookSourceGrade = 2
  source.bookSourceScore = '4.0分'
  source.enabled = true
  source.enabledExplore = true
  source.enabledCookieJar = true
  source.lastUpdateTime = Date.now()
  source.respondTime = 11881
  source.customOrder = 200
  source.weight = 0
  source.isTop = false
  source.showRecentIcon = true
  source.showExplore = true

  // 发现页URL（JSON格式，ExploreItem[]）
  const wapExploreList: ExploreItem[] = [
    exploreItem('全部', 'https://wap.ciweimao.com/book_list/0/{{page}}', true),
    exploreItem('玄幻奇幻', 'https://wap.ciweimao.com/book_list/yijiehuanxiang/{{page}}'),
    exploreItem('都市青春', 'https://wap.ciweimao.com/book_list/qingchunrichang/{{page}}'),
    exploreItem('灵异未知', 'https://wap.ciweimao.com/book_list/shenmiweizhi/{{page}}'),
    exploreItem('历史军事', 'https://wap.ciweimao.com/book_list/zhanzhenglishi/{{page}}'),
    exploreItem('科幻无限', 'https://wap.ciweimao.com/book_list/weilaihuanxiang/{{page}}'),
    exploreItem('游戏竞技', 'https://wap.ciweimao.com/book_list/youxishijie/{{page}}'),
    exploreItem('仙侠武侠', 'https://wap.ciweimao.com/book_list/rexuejingji/{{page}}'),
    exploreItem('免费同人', 'https://wap.ciweimao.com/book_list/tongrenfenlei/{{page}}'),
    exploreItem('女频', 'https://wap.ciweimao.com/book_list/nvpinfenlei/{{page}}')
  ]
  source.exploreUrl = JSON.stringify(wapExploreList)

  // 搜索URL
  source.searchUrl = 'https://wap.ciweimao.com:443/book_list?keyword={{key}}'

  // 搜索规则
  const searchRule = new SearchRule()
  searchRule.bookList = '.book-item'
  searchRule.name = 'h3@text'
  searchRule.author = '.author@text'
  searchRule.bookUrl = 'a@href'
  searchRule.coverUrl = 'img@data-original'
  searchRule.intro = '.desc@textNodes'
  searchRule.kind = '.author@text'
  searchRule.lastChapter = '.new@text'
  source.ruleSearch = searchRule

  // 发现规则（WAP站无专用发现规则，使用搜索规则解析）
  const exploreRule = new ExploreRule()
  exploreRule.bookList = '.book-item'
  exploreRule.name = 'h3@text'
  exploreRule.author = '.author@text'
  exploreRule.bookUrl = 'a@href'
  exploreRule.coverUrl = 'img@data-original'
  exploreRule.intro = '.desc@textNodes'
  exploreRule.kind = '.author@text'
  exploreRule.lastChapter = '.new@text'
  source.ruleExplore = exploreRule

  // 目录规则
  const tocRule = new TocRule()
  tocRule.chapterList = 'class.catalogue-list less@li@a'
  tocRule.chapterName = 'text'
  tocRule.chapterUrl = 'href'
  source.ruleToc = tocRule

  // 正文规则
  const contentRule = new ContentRule()
  contentRule.content = '.chapter@textNodes'
  source.ruleContent = contentRule

  return source
}

/**
 * 福书网书源
 * 女频小说网站，支持搜索、发现、目录、正文
 */
function createFuShuCunSource(): BookSource {
  const source = new BookSource()
  source.bookSourceUrl = 'https://www.fushucun.com'
  source.bookSourceName = '福书网'
  source.bookSourceGroup = '女频'
  source.bookSourceType = 0
  source.charset = 'GBK'
  source.bookSourceGrade = 2
  source.bookSourceScore = '4.0分'
  source.enabled = true
  source.enabledExplore = true
  source.lastUpdateTime = Date.now()
  source.respondTime = 180000
  source.customOrder = 300
  source.weight = 0
  source.isTop = false
  source.showRecentIcon = true
  source.showExplore = true
  source.enabledCookieJar = true
  // 请求头配置
  source.header = JSON.stringify({
    'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Referer': 'https://www.fushucun.com/'
  })

  // 发现页URL（JSON格式）- 第一页是index.html，后续页是index_N.html
  const fscExploreList: ExploreItem[] = [
    exploreItem('穿越重生', 'https://www.fushucun.com/chuanyuechongsheng/index.html', true),
    exploreItem('玄幻网游', 'https://www.fushucun.com/xuanhuanwangyou/index.html'),
    exploreItem('现代都市', 'https://www.fushucun.com/xiandaixiaoshuo/index.html'),
    exploreItem('古代架空', 'https://www.fushucun.com/gudaixiaoshuo/index.html'),
    exploreItem('同人BL', 'https://www.fushucun.com/tongrenxiaoshuo/index.html'),
    exploreItem('百合GL', 'https://www.fushucun.com/baihexiaoshuo/index.html')
  ]
  source.exploreUrl = JSON.stringify(fscExploreList)

  // 搜索URL（POST方式，GBK编码）
  source.searchUrl = 'https://www.fushucun.com/e/search/index.php,{"charset":"gbk","method":"POST","body":"keyboard={{key}}&show=title&tempid=1&classid=2%252C6&x=23&y=15&page={{page}}"}'
  // 搜索结果页URL（两步搜索：POST获取searchid后，GET结果页）
  source.searchResultUrl = '/e/search/result/index.php?searchid={{searchid}}&page={{page}}'

  // 搜索规则
  const searchRule = new SearchRule()
  searchRule.checkKeyWord = '系统'
  searchRule.bookList = 'ul.article-list > li'
  searchRule.bookUrl = 'a@href'
  searchRule.name = 'a@text##(.*?)——.*##$1'
  searchRule.author = 'a@text##.*——(.*)##$1'
  searchRule.kind = ''
  searchRule.lastChapter = 'span@text'
  source.ruleSearch = searchRule

  // 发现规则
  const exploreRule = new ExploreRule()
  exploreRule.bookList = '.box@li'
  exploreRule.name = 'a@text'
  exploreRule.author = 'a@text'
  exploreRule.bookUrl = 'a@href'
  exploreRule.coverUrl = 'img@src'
  exploreRule.kind = 'a@text'
  source.ruleExplore = exploreRule

  // 书籍信息规则
  const bookInfoRule = new BookInfoRule()
  bookInfoRule.intro = '#id@p.[:4]'
  source.ruleBookInfo = bookInfoRule

  // 目录规则
  const tocRule = new TocRule()
  tocRule.chapterList = 'select[name="titleselect"] option'
  tocRule.chapterName = 'text'
  tocRule.chapterUrl = 'value'
  source.ruleToc = tocRule

  // 正文规则
  const contentRule = new ContentRule()
  contentRule.content = 'td#text@html'
  source.ruleContent = contentRule

  return source
}

/**
 * 爱去小说网书源
 * 综合小说网站，支持耽美、女生、男生等多分类
 * charset: GBK
 */
function createAiQuNovelSource(): BookSource {
  const source = new BookSource()
  source.bookSourceUrl = 'https://www.aiqu225.com'
  source.bookSourceName = '爱去小说网'
  source.bookSourceGroup = '综合'
  source.bookSourceType = 0
  source.charset = 'GBK'
  source.bookSourceGrade = 2
  source.bookSourceScore = '4.0分'
  source.enabled = true
  source.enabledExplore = true
  source.enabledCookieJar = true
  source.lastUpdateTime = Date.now()
  source.respondTime = 7378
  source.customOrder = 310
  source.weight = 0
  source.isTop = false
  source.showRecentIcon = true
  source.showExplore = true

  // 发现页URL（JSON格式，ExploreItem[]）
  const aiquExploreList: ExploreItem[] = [
    exploreItem('耽美-全部', '/txt-xx/15/list15_{{page}}.htm', true),
    exploreItem('耽美-现代耽美', '/txt-xx/dmxs/xddm/list117_{{page}}.htm'),
    exploreItem('耽美-古代架空', '/txt-xx/dmxs/gdjk/list118_{{page}}.htm'),
    exploreItem('耽美-穿越重生', '/txt-xx/dmxs/cycs/list119_{{page}}.htm'),
    exploreItem('耽美-玄幻科幻', '/txt-xx/dmxs/xhkh/list120_{{page}}.htm'),
    exploreItem('耽美-BL同人', '/txt-xx/dmxs/bltr/list121_{{page}}.htm'),
    exploreItem('耽美-GL百合', '/txt-xx/dmxs/glbh/list122_{{page}}.htm'),
    exploreItem('女生-都市言情', '/txt-xx/nsxs/dsyq/list110_{{page}}.htm'),
    exploreItem('女生-古代言情', '/txt-xx/nsxs/gdyq/list111_{{page}}.htm'),
    exploreItem('女生-穿越重生', '/txt-xx/nsxs/cycs/list112_{{page}}.htm'),
    exploreItem('女生-玄幻仙侠', '/txt-xx/nsxs/xhxx/list113_{{page}}.htm'),
    exploreItem('女生-青春同人', '/txt-xx/nsxs/qctr/list114_{{page}}.htm'),
    exploreItem('女生-网游科幻', '/txt-xx/nsxs/wykh/list115_{{page}}.htm'),
    exploreItem('男生-玄幻奇幻', '/txt-xx/nsbook/xhqh/list124_{{page}}.htm'),
    exploreItem('男生-武侠仙侠', '/txt-xx/nsbook/wxxx/list125_{{page}}.htm'),
    exploreItem('男生-都市重生', '/txt-xx/nsbook/dscs/list126_{{page}}.htm'),
    exploreItem('男生-历史军事', '/txt-xx/nsbook/lsjs/list127_{{page}}.htm'),
    exploreItem('男生-恐怖推理', '/txt-xx/nsbook/kbtl/list128_{{page}}.htm'),
    exploreItem('男生-科幻网游', '/txt-xx/nsbook/khwy/list129_{{page}}.htm'),
    exploreItem('男生-二次元', '/txt-xx/nsbook/ecy/list130_{{page}}.htm'),
    exploreItem('军事历史', '/txt-xx/25/list25_{{page}}.htm'),
    exploreItem('名人传记', '/txt-xx/22/list22_{{page}}.htm'),
    exploreItem('中外名著', '/txt-xx/28/list28_{{page}}.htm'),
    exploreItem('当代文学', '/txt-xx/27/list27_{{page}}.htm'),
    exploreItem('其他小说', '/txt-xx/30/list30_{{page}}.htm'),
    exploreItem('推理悬疑', '/txt-xx/16/list16_{{page}}.htm'),
    exploreItem('浪漫爱情', '/txt-xx/19/list19_{{page}}.htm')
  ]
  source.exploreUrl = JSON.stringify(aiquExploreList)

  // 搜索URL（GET方式，GBK编码）
  source.searchUrl = '/search.asp?word={{key}}&page={{page}},{"charset":"gbk"}'

  // 搜索规则（CSS选择器格式）
  const searchRule = new SearchRule()
  searchRule.checkKeyWord = '反派龙傲天揣了我的崽GB'
  searchRule.bookList = '@css:div.search-card'
  searchRule.name = 'div.search-card-title a.searchtitle@text##[《》]'
  searchRule.author = 'span.search-card-author a@text'
  searchRule.bookUrl = 'div.search-card-title a.searchtitle@href'
  searchRule.kind = 'span.search-card-category a@text'
  source.ruleSearch = searchRule

  // 发现规则
  const exploreRule = new ExploreRule()
  exploreRule.bookList = '@css:div.book-item'
  exploreRule.name = 'div.book-title a@title'
  exploreRule.bookUrl = 'a@href'
  exploreRule.coverUrl = 'img@src'
  source.ruleExplore = exploreRule

  // 书籍信息规则
  const bookInfoRule = new BookInfoRule()
  bookInfoRule.name = 'title@text##[《》]|txt下载.*'
  bookInfoRule.author = '@css:a[href*=searchzuozhe] font[color*=008800]@text##作者：|作者名称：'
  bookInfoRule.intro = '@css:p:has(strong font:contains(小说简介)) + p@html@js:result.replace(/<br\\s*\\/?>/ig,\'\\n\').replace(/<[^>]+>/g,\'\').replace(/&nbsp;/g,\' \')'
  bookInfoRule.tocUrl = 'a[href*=softdownfree]@href'
  source.ruleBookInfo = bookInfoRule

  // 目录规则
  const tocRule = new TocRule()
  tocRule.chapterList = '@css:a[href*=downbook]'
  tocRule.chapterName = 'text'
  tocRule.chapterUrl = 'href'
  source.ruleToc = tocRule

  // 正文规则（使用JS处理，提取"文案"到"下载本书"之间的内容）
  const contentRule = new ContentRule()
  contentRule.content = '@js:var s=result;var a=s.indexOf(\'文案\');if(a>-1)s=s.substring(a);var b=s.indexOf(\'下载本书\');if(b>-1)s=s.substring(0,b);s.replace(/《[^》]+》作者[\\s\\S]*?移到底部/g,\'\').replace(/\\u3000\\u3000/g,\'\\n\')'
  contentRule.nextContentUrl = '@css:a.page-link:contains(下一页)@href'
  source.ruleContent = contentRule

  return source
}

/**
 * 歪歪书库书源
 * 综合小说网站，支持搜索、发现、目录、正文
 */
function createYYSKSource(): BookSource {
  const source = new BookSource()
  source.bookSourceUrl = 'https://www.yysk.net'
  source.bookSourceName = '歪歪书库'
  source.bookSourceGroup = '综合'
  source.bookSourceType = 0
  source.bookSourceGrade = 2
  source.bookSourceScore = '3.0分'
  source.enabled = true
  source.enabledExplore = true
  source.enabledCookieJar = true
  source.lastUpdateTime = Date.now()
  source.respondTime = 180000
  source.customOrder = 124
  source.weight = 0
  source.isTop = false
  source.showRecentIcon = true
  source.showExplore = true

  // 发现页URL
  const yyskExploreList: ExploreItem[] = [
    exploreItem('玄幻小说', '/list1/{{page}}.html', true),
    exploreItem('武侠小说', '/list2/{{page}}.html'),
    exploreItem('都市小说', '/list3/{{page}}.html'),
    exploreItem('历史小说', '/list4/{{page}}.html'),
    exploreItem('网游小说', '/list5/{{page}}.html'),
    exploreItem('科幻小说', '/list6/{{page}}.html'),
    exploreItem('言情小说', '/list7/{{page}}.html'),
    exploreItem('其他小说', '/list8/{{page}}.html'),
    exploreItem('排行榜', '/top/{{page}}.html'),
    exploreItem('完本小说', '/full/{{page}}.html')
  ]
  source.exploreUrl = JSON.stringify(yyskExploreList)

  // 搜索URL（GET方式）
  source.searchUrl = '/search.php?q={{key}}'

  // 搜索规则
  const searchRule = new SearchRule()
  searchRule.bookList = 'dl'
  searchRule.name = 'dd h3 a@text##^\\[.*?\\]'
  searchRule.author = 'dd.book_other span@text'
  searchRule.bookUrl = 'dd h3 a@href'
  searchRule.coverUrl = 'dt a img@src'
  searchRule.kind = 'dd h3 a@text##^\\[(.*?)\\].*##$1'
  source.ruleSearch = searchRule

  // 发现规则
  const exploreRule = new ExploreRule()
  exploreRule.bookList = 'dl'
  exploreRule.name = 'dd h3 a@text'
  exploreRule.author = 'dd.book_other span@text'
  exploreRule.bookUrl = 'dd h3 a@href'
  exploreRule.coverUrl = 'dt a img@src'
  source.ruleExplore = exploreRule

  // 书籍信息规则
  const bookInfoRule = new BookInfoRule()
  bookInfoRule.name = '.info h1@text'
  bookInfoRule.author = '.options li.0 a@text'
  bookInfoRule.coverUrl = '.pic img@src'
  bookInfoRule.intro = '.intro@text##简介：'
  bookInfoRule.kind = '.options li.-1@text'
  source.ruleBookInfo = bookInfoRule

  // 目录规则
  const tocRule = new TocRule()
  tocRule.chapterList = 'ul.row li.col-md-3'
  tocRule.chapterName = 'tag.a@text'
  tocRule.chapterUrl = 'tag.a@href'
  source.ruleToc = tocRule

  // 正文规则
  const contentRule = new ContentRule()
  contentRule.content = 'article@text'
  contentRule.nextContentUrl = 'a@text.下一章@href'
  source.ruleContent = contentRule

  return source
}
