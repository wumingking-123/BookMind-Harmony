import { chaptersItem } from 'ets/componets/dataList/ReaderChaptersItem';
import { BookSource } from 'ets/database/entities/BookSource';
import { ContentAnalysis, ContentAnalysisData } from 'ets/common/model/ContentAnalysis';
import requestUtil from 'ets/common/utils/requestUtils';

export class BookContentHolder {
  private static chapters: chaptersItem[] = [];
  private static bookSource: BookSource | undefined = undefined;
  private static resolvingUrls: Map<string, Promise<string>> = new Map();

  // 异步内容解析回调，由ReaderPage2注册，用于将章节URL解析为正文文本
  public static resolveContent: ((url: string) => Promise<string>) | undefined = undefined;

  public static setChapters(chapters: chaptersItem[]) {
    BookContentHolder.chapters = chapters;
  }

  public static getChapters(): chaptersItem[] {
    return BookContentHolder.chapters;
  }

  public static setBookSource(source: BookSource | undefined) {
    BookContentHolder.bookSource = source;
  }

  public static getBookSource(): BookSource | undefined {
    return BookContentHolder.bookSource;
  }

  /**
   * 解析章节URL为正文内容（带去重，同一URL不会重复请求）
   */
  public static async resolveChapterContent(url: string): Promise<string> {
    const existing = BookContentHolder.resolvingUrls.get(url);
    if (existing) {
      console.log('[BookContentHolder] URL已在解析中，复用: ' + url.substring(0, 60))
      return existing;
    }
    const promise = (async () => {
      try {
        const source = BookContentHolder.bookSource;
        if (!source || !source.ruleContent) {
          console.log('[BookContentHolder] 缺少bookSource或ruleContent, source=' + (source ? source.bookSourceName : 'null'))
          return '';
        }
        console.log('[BookContentHolder] 请求章节: ' + url)
        const html = await requestUtil.requestUrlHtml(url, source.charset);
        console.log('[BookContentHolder] 响应长度: ' + (html ? html.length : 0) + ', 编码: ' + (source.charset || 'auto'))
        if (!html || html.length === 0) {
          console.log('[BookContentHolder] 响应为空!')
          return '';
        }
        console.log('[BookContentHolder] ruleContent.content=' + source.ruleContent.content)
        console.log('[BookContentHolder] ruleContent.nextContentUrl=' + (source.ruleContent.nextContentUrl || '无'))
        const analysis = new ContentAnalysis();
        analysis.init(new ContentAnalysisData({
          body: html,
          bookSource: source,
          chapterUrl: url
        }));
        const result = await analysis.getContent();
        console.log('[BookContentHolder] 解析结果长度: ' + (result.content ? result.content.length : 0))
        if (result.content && result.content.length > 0) {
          console.log('[BookContentHolder] 内容前100字: ' + result.content.substring(0, 100))
        }
        return result.content || '';
      } catch (e) {
        console.log('[BookContentHolder] 解析章节内容失败: ' + (e as Error).message + '\n' + (e as Error).stack)
        return '';
      } finally {
        BookContentHolder.resolvingUrls.delete(url);
      }
    })();
    BookContentHolder.resolvingUrls.set(url, promise);
    return promise;
  }

  public static clear() {
    BookContentHolder.chapters = [];
    BookContentHolder.bookSource = undefined;
    BookContentHolder.resolvingUrls.clear();
  }
}
