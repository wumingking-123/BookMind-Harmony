/**
 * @author 2008
 * @datetime 2024/8/18 2:03
 * @className: AnalyzerRule
 */
import { BookSource } from '../../../database/entities/BookSource';
import { HtmlParser } from './HtmlParser';
import { CssSelectorParser } from './CssSelectorParser';
import { JsonPathParser } from './JsonPathParser';

export interface IRuleAnalyzer {
  body: string  //请求内容
  bookSource?: BookSource//书源
}

export class RuleAnalyzerData {
  body: string = ''  //请求内容
  bookSource?: BookSource//书源

  constructor(data?: IRuleAnalyzer) {
    this.body = data?.body || ''
    this.bookSource = data?.bookSource
  }
}

interface SourceRule {
  type: 'css' | 'json' | 'regex';
  selector: string;
  extraction?: string;  // '@text', '@href', '@src', attribute name
  index?: number;
}

export class RuleAnalyzer {
  ruleAnalyzerData: RuleAnalyzerData = new RuleAnalyzerData()

  init(ruleAnalyzerData: RuleAnalyzerData) {
    this.ruleAnalyzerData = ruleAnalyzerData
  }

  /**
   * 分解规则生成规则列表
   * 支持的规则格式：
   * - CSS选择器 (默认): div.class, #id, tag[attr=value]
   * - JSON路径: $.data.list[0].name 或 @Json:$.data.list
   * - 正则: @Regex:pattern 或 :pattern
   * - 组合规则: rule1@@rule2 或 rule1&&rule2
   */
  splitSourceRule(ruleStr?: string, allInOne: boolean = false): SourceRule[] {
    if (!ruleStr) return [];

    const rules: SourceRule[] = [];

    // 分割组合规则
    let segments: string[];
    if (allInOne) {
      segments = [ruleStr];
    } else {
      segments = ruleStr.split(/@@|&&/);
    }

    for (const segment of segments) {
      const trimmed = segment.trim();
      if (!trimmed) continue;

      // JSON路径规则
      if (trimmed.startsWith('@Json:') || trimmed.startsWith('$.')) {
        const selector = trimmed.startsWith('@Json:') ? trimmed.substring(6) : trimmed;
        rules.push({ type: 'json', selector });
        continue;
      }

      // 正则规则
      if (trimmed.startsWith('@Regex:') || trimmed.startsWith(':')) {
        const selector = trimmed.startsWith('@Regex:') ? trimmed.substring(7) : trimmed.substring(1);
        rules.push({ type: 'regex', selector });
        continue;
      }

      // CSS选择器规则（默认）
      // 提取提取方法后缀 @text, @href, @src 等
      let selector = trimmed;
      let extraction: string | undefined;
      let index: number | undefined;

      // 检查是否有索引 [n]
      const indexMatch = selector.match(/\[(\d+)\]$/);
      if (indexMatch) {
        index = parseInt(indexMatch[1]);
        selector = selector.substring(0, selector.length - indexMatch[0].length);
      }

      // 检查是否有提取方法
      const extractionMatch = selector.match(/@(\w+)$/);
      if (extractionMatch) {
        extraction = '@' + extractionMatch[1];
        selector = selector.substring(0, selector.length - extractionMatch[0].length);
      }

      // 检查是否是属性提取 [attr]
      const attrMatch = selector.match(/\[([a-zA-Z]+)\]$/);
      if (attrMatch && !extraction) {
        extraction = attrMatch[1];
        selector = selector.substring(0, selector.length - attrMatch[0].length);
      }

      rules.push({ type: 'css', selector: selector.trim(), extraction, index });
    }

    return rules;
  }

  /**
   * 应用规则到HTML，返回匹配的元素列表
   */
  getElements(rule: string): string[] {
    if (!rule || !this.ruleAnalyzerData.body) return [];

    const rules = this.splitSourceRule(rule);
    if (rules.length === 0) return [];

    let currentHtml = this.ruleAnalyzerData.body;
    let matched: string[] = [];

    for (const sourceRule of rules) {
      matched = [];

      switch (sourceRule.type) {
        case 'css':
          matched = this.applyCssRule(currentHtml, sourceRule.selector);
          break;
        case 'json':
          matched = this.applyJsonRule(currentHtml, sourceRule.selector);
          break;
        case 'regex':
          matched = this.applyRegexRule(currentHtml, sourceRule.selector);
          break;
      }

      // 应用索引
      if (sourceRule.index !== undefined && sourceRule.index >= 0) {
        if (sourceRule.index < matched.length) {
          matched = [matched[sourceRule.index]];
        } else {
          return [];
        }
      }

      if (matched.length === 0) return [];

      // 如果还有后续规则，用第一个匹配继续
      currentHtml = matched[0];
    }

    return matched;
  }

  /**
   * 从单个元素提取文本
   */
  extractText(element: string, rule?: string): string {
    if (!element) return '';

    // 如果没有规则，直接返回去除标签的文本
    if (!rule) {
      return HtmlParser.decodeHtmlEntities(HtmlParser.stripTags(element));
    }

    const rules = this.splitSourceRule(rule);
    if (rules.length === 0) return '';

    let current = element;

    for (const sourceRule of rules) {
      let matched: string[] = [];

      switch (sourceRule.type) {
        case 'css':
          matched = this.applyCssRule(current, sourceRule.selector);
          break;
        case 'json':
          matched = this.applyJsonRule(current, sourceRule.selector);
          break;
        case 'regex':
          matched = this.applyRegexRule(current, sourceRule.selector);
          break;
      }

      if (matched.length === 0) return '';
      current = matched[0];
    }

    // 应用提取方法
    const lastRule = rules[rules.length - 1];
    return this.applyExtraction(current, lastRule.extraction);
  }

  /**
   * 从单个元素提取属性
   */
  extractAttribute(element: string, rule?: string): string {
    if (!element) return '';

    // 如果没有规则，尝试提取href
    if (!rule) {
      return HtmlParser.getAttribute(element, 'href');
    }

    const rules = this.splitSourceRule(rule);
    if (rules.length === 0) return '';

    let current = element;

    for (const sourceRule of rules) {
      let matched: string[] = [];

      switch (sourceRule.type) {
        case 'css':
          matched = this.applyCssRule(current, sourceRule.selector);
          break;
        case 'json':
          matched = this.applyJsonRule(current, sourceRule.selector);
          break;
        case 'regex':
          matched = this.applyRegexRule(current, sourceRule.selector);
          break;
      }

      if (matched.length === 0) return '';
      current = matched[0];
    }

    // 应用属性提取
    const lastRule = rules[rules.length - 1];
    if (lastRule.extraction && !lastRule.extraction.startsWith('@')) {
      return HtmlParser.getAttribute(current, lastRule.extraction);
    }

    // 默认提取href或src
    if (lastRule.extraction === '@href') {
      return HtmlParser.getAttribute(current, 'href');
    }
    if (lastRule.extraction === '@src') {
      return HtmlParser.getAttribute(current, 'src');
    }

    return HtmlParser.getAttribute(current, 'href') || HtmlParser.getAttribute(current, 'src');
  }

  /**
   * 应用CSS选择器规则
   */
  private applyCssRule(html: string, selector: string): string[] {
    return CssSelectorParser.applySelector(html, selector);
  }

  /**
   * 应用JSON路径规则
   */
  private applyJsonRule(body: string, path: string): string[] {
    try {
      const jsonObj: Object = JSON.parse(body) as Object;
      return JsonPathParser.evaluate(jsonObj, path);
    } catch (e) {
      console.log('JSON解析失败: ' + e);
      return [];
    }
  }

  /**
   * 应用正则规则
   */
  private applyRegexRule(body: string, pattern: string): string[] {
    try {
      const regex = new RegExp(pattern, 'gi');
      const matches: string[] = [];
      let match: RegExpExecArray | null;

      while ((match = regex.exec(body)) !== null) {
        // 如果有捕获组，返回第一个捕获组
        if (match.length > 1) {
          matches.push(match[1]);
        } else {
          matches.push(match[0]);
        }
      }

      return matches;
    } catch (e) {
      console.log('正则解析失败: ' + e);
      return [];
    }
  }

  /**
   * 应用提取方法
   */
  private applyExtraction(element: string, extraction?: string): string {
    if (!extraction) {
      // 默认提取文本
      return HtmlParser.decodeHtmlEntities(HtmlParser.stripTags(element));
    }

    switch (extraction) {
      case '@text':
        return HtmlParser.decodeHtmlEntities(HtmlParser.stripTags(element));
      case '@src':
        return HtmlParser.getAttribute(element, 'src');
      case '@href':
        return HtmlParser.getAttribute(element, 'href');
      case '@html':
        return HtmlParser.getElementContent(element);
      case '@content':
        return HtmlParser.getElementContent(element);
      default:
        // 尝试作为属性名提取
        return HtmlParser.getAttribute(element, extraction);
    }
  }
}
