/**
 * 正文规则解析器
 * 解析章节页面，提取正文内容
 */
import { BookSource } from '../../database/entities/BookSource';
import { RuleAnalyzer, RuleAnalyzerData } from './analyzeRule/RuleAnalyzer';
import { HtmlParser } from './analyzeRule/HtmlParser';
import { isNetworkUrl } from '../utils/utils';
import requestUtil from '../utils/requestUtils';

export interface IContentAnalysis {
  body: string;
  bookSource: BookSource;
  chapterUrl: string;
}

export class ContentAnalysisData {
  body: string = '';
  bookSource?: BookSource;
  chapterUrl: string = '';

  constructor(data?: IContentAnalysis) {
    this.body = data?.body || '';
    this.bookSource = data?.bookSource;
    this.chapterUrl = data?.chapterUrl || '';
  }
}

export interface ContentResult {
  title: string;
  content: string;
}

interface ContentRule {
  content?: string;
  title?: string;
  nextContentUrl?: string;
  replaceRegex?: string;
}

export class ContentAnalysis {
  private contentData: ContentAnalysisData = new ContentAnalysisData();
  private maxPages: number = 20; // 最大分页数

  init(data: ContentAnalysisData) {
    this.contentData = data;
  }

  /**
   * 解析章节内容
   */
  async getContent(): Promise<ContentResult> {
    if (!this.contentData.bookSource?.ruleContent || !this.contentData.body) {
      return { title: '', content: '' };
    }

    const rule = this.contentData.bookSource.ruleContent;
    let currentBody = this.contentData.body;
    let title = '';
    let content = '';
    let pageCount = 0;

    while (currentBody && pageCount < this.maxPages) {
      const result = this.parseContent(currentBody, rule);

      if (pageCount === 0) {
        title = result.title;
      }
      content += result.content;

      // 检查是否有下一页
      if (rule.nextContentUrl) {
        const nextUrl = this.getNextPageUrl(currentBody, rule.nextContentUrl);
        if (nextUrl && nextUrl !== '') {
          try {
            currentBody = await requestUtil.requestUrlHtml(nextUrl, this.contentData.bookSource?.charset);
          } catch (e) {
            console.log('获取下一页内容失败: ' + e);
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

    // 应用替换规则
    if (rule.replaceRegex) {
      content = this.applyReplaceRegex(content, rule.replaceRegex);
    }

    // 清理内容
    content = this.cleanContent(content);

    return { title, content };
  }

  /**
   * 解析单页内容
   */
  private parseContent(body: string, rule: object): ContentResult {
    const contentRule = rule as ContentRule;
    const analyzer = new RuleAnalyzer();
    analyzer.init(new RuleAnalyzerData({
      body: body,
      bookSource: this.contentData.bookSource!
    }));

    // 提取标题
    let title = '';
    if (contentRule.title) {
      title = analyzer.extractText(body, contentRule.title);
    }

    // 提取正文
    let content = '';
    if (contentRule.content) {
      console.log('[parseContent] 开始解析, body长度: ' + body.length + ', rule: ' + contentRule.content)
      content = analyzer.extractText(body, contentRule.content);
      console.log('[parseContent] 解析结果长度: ' + content.length)
      if (content.length > 0) {
        console.log('[parseContent] 前200字符: ' + content.substring(0, 200))
      }
    }

    return { title, content };
  }

  /**
   * 获取下一页URL
   */
  private getNextPageUrl(body: string, nextContentUrlRule: string): string {
    const analyzer = new RuleAnalyzer();
    analyzer.init(new RuleAnalyzerData({
      body: body,
      bookSource: this.contentData.bookSource!
    }));

    const nextUrl = analyzer.extractAttribute(body, nextContentUrlRule);

    if (nextUrl && !isNetworkUrl(nextUrl)) {
      return this.contentData.bookSource?.bookSourceUrl + nextUrl;
    }

    return nextUrl;
  }

  /**
   * 应用替换规则
   */
  private applyReplaceRegex(content: string, replaceRegex: string): string {
    try {
      // 替换规则格式: /pattern/replacement/flags 或直接是正则表达式
      const regexMatch = replaceRegex.match(/^\/(.+?)\/([gimsuy]*)$/);
      if (regexMatch) {
        const pattern = regexMatch[1];
        const flags = regexMatch[2] || 'g';
        const regex = new RegExp(pattern, flags);
        return content.replace(regex, '');
      }

      // 如果不是正则格式，尝试直接作为正则使用
      const regex = new RegExp(replaceRegex, 'g');
      return content.replace(regex, '');
    } catch (e) {
      console.log('替换规则应用失败: ' + e);
      return content;
    }
  }

  /**
   * 清理内容
   */
  private cleanContent(content: string): string {
    // 去除多余空行
    content = content.replace(/\n{3,}/g, '\n\n');

    // 去除首尾空白
    content = content.trim();

    // 解码HTML实体
    content = HtmlParser.decodeHtmlEntities(content);

    return content;
  }
}
