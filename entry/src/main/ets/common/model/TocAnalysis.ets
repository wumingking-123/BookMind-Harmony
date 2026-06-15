/**
 * 目录规则解析器
 * 解析书籍目录页，提取章节列表
 */
import { BookSource } from '../../database/entities/BookSource';
import { BookChapter } from './BookChapter';
import { RuleAnalyzer, RuleAnalyzerData } from './analyzeRule/RuleAnalyzer';
import { isNetworkUrl } from '../utils/utils';
import requestUtil from '../utils/requestUtils';

export interface ITocAnalysis {
  body: string;
  bookSource: BookSource;
  bookUrl: string;
}

export class TocAnalysisData {
  body: string = '';
  bookSource?: BookSource;
  bookUrl: string = '';

  constructor(data?: ITocAnalysis) {
    this.body = data?.body || '';
    this.bookSource = data?.bookSource;
    this.bookUrl = data?.bookUrl || '';
  }
}

export class TocAnalysis {
  private tocData: TocAnalysisData = new TocAnalysisData();
  private maxPages: number = 50; // 最大分页数，防止无限循环

  init(data: TocAnalysisData) {
    this.tocData = data;
  }

  /**
   * 解析目录，返回章节列表
   */
  async getChapterList(): Promise<BookChapter[]> {
    const chapters: BookChapter[] = [];
    if (!this.tocData.bookSource?.ruleToc || !this.tocData.body) return chapters;

    const rule = this.tocData.bookSource.ruleToc;
    let currentBody = this.tocData.body;
    let pageCount = 0;

    while (currentBody && pageCount < this.maxPages) {
      const pageChapters = this.parseChapterList(currentBody, rule, chapters.length);

      if (pageChapters.length === 0) break;
      chapters.push(...pageChapters);

      // 检查是否有下一页
      if (rule.nextTocUrl) {
        const nextUrl = this.getNextPageUrl(currentBody, rule.nextTocUrl);
        if (nextUrl && nextUrl !== '') {
          try {
            currentBody = await requestUtil.requestUrlHtml(nextUrl);
          } catch (e) {
            console.log('获取下一页目录失败: ' + e);
            break;
          }
        } else {
          break;
        }
      } else {
        break;
      }

      pageCount++;
    }

    return chapters;
  }

  /**
   * 解析单页目录
   */
  private parseChapterList(body: string, rule: object, startIndex: number): BookChapter[] {
    const chapters: BookChapter[] = [];
    const tocRule = rule as { chapterList?: string; chapterName?: string; chapterUrl?: string };
    const analyzer = new RuleAnalyzer();
    analyzer.init(new RuleAnalyzerData({
      body: body,
      bookSource: this.tocData.bookSource
    }));

    // 获取章节列表元素
    if (!tocRule.chapterList) return chapters;
    const chapterElements = analyzer.getElements(tocRule.chapterList);
    if (chapterElements.length === 0) return chapters;

    // 提取每个章节信息
    for (let i = 0; i < chapterElements.length; i++) {
      const element = chapterElements[i];
      const chapter = new BookChapter();

      // 提取章节名
      chapter.title = analyzer.extractText(element, tocRule.chapterName);

      // 提取章节URL
      chapter.url = analyzer.extractAttribute(element, tocRule.chapterUrl);

      // 解析相对URL
      if (chapter.url && !isNetworkUrl(chapter.url)) {
        chapter.url = this.tocData.bookSource?.bookSourceUrl + chapter.url;
      }

      chapter.index = startIndex + i;
      chapter.bookUrl = this.tocData.bookUrl;
      chapter.baseUrl = this.tocData.bookSource?.bookSourceUrl || '';

      chapters.push(chapter);
    }

    return chapters;
  }

  /**
   * 获取下一页URL
   */
  private getNextPageUrl(body: string, nextTocUrlRule: string): string {
    const analyzer = new RuleAnalyzer();
    analyzer.init(new RuleAnalyzerData({
      body: body,
      bookSource: this.tocData.bookSource
    }));

    const nextUrl = analyzer.extractAttribute(body, nextTocUrlRule);

    if (nextUrl && !isNetworkUrl(nextUrl)) {
      return this.tocData.bookSource?.bookSourceUrl + nextUrl;
    }

    return nextUrl;
  }
}
