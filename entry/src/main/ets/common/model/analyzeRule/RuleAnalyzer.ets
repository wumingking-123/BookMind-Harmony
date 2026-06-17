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
  // 当前正则匹配的捕获组（用于 $N 引用）
  currentRegexGroups: string[] = []

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
   * 判断是否为legado规则格式
   * legado格式特征：用 @ 作为链式分隔符
   * 例如：class.xxx@tag.a@text, a[data-bid]@data-bid
   */
  private isLegadoRule(rule: string): boolean {
    if (!rule) return false
    // JSON和正则规则不是legado
    if (rule.startsWith('@Json:') || rule.startsWith('$.') || rule.startsWith('@Regex:') || rule.startsWith(':')) {
      return false
    }
    // 检测 ## 正则替换语法（legado特有，如 a@text##pattern##replacement）
    if (rule.indexOf('##') >= 0) {
      return true
    }
    // 检测class.、tag.、id. 前缀（legado特有）
    if (/(?:^|@)(?:class|tag|id)\b/.test(rule)) {
      return true
    }
    // 检测 @ 在 ] 之后（如 a[data-bid]@data-bid），这是legado链式格式
    if (/\]@/.test(rule)) {
      return true
    }
    // 检测 @ 在 CSS类名之后（如 .book-chapter-box@li@a）
    if (/\.[a-zA-Z_-][a-zA-Z0-9_-]*@/.test(rule)) {
      return true
    }
    // 检测末尾的提取方法 @text, @href, @src, @html, @content
    if (/@(text|href|src|html|content)\b/.test(rule)) {
      return true
    }
    return false
  }

  /**
   * 应用legado规则到HTML
   * legado格式：选择器链@提取方法
   * 例如：class.book-info-title.0@tag.a.0@text
   *       a[data-bid]@data-bid
   * @ 作为链式分隔符，最后的@xxx如果是提取方法则提取文本/属性
   */
  private applyLegadoRule(html: string, rule: string): string[] {
    if (!html || !rule) return []

    // 处理 @js: 前缀（跳过，无法执行JS）
    if (rule.startsWith('@js:')) {
      console.log('跳过@js:规则: ' + rule.substring(0, 50))
      return []
    }

    // 处理 || 回退语法：rule1||rule2，第一个匹配成功就返回
    if (rule.indexOf('||') >= 0) {
      const alternatives = rule.split('||')
      for (const alt of alternatives) {
        const results = this.applyLegadoRule(html, alt.trim())
        if (results.length > 0 && results[0] !== '') {
          return results
        }
      }
      return []
    }

    // 处理正则替换 ## 语法：rule##pattern##replacement
    let baseRule = rule
    let replacePattern = ''
    let replaceValue = ''
    const hashIndex = rule.indexOf('##')
    if (hashIndex > 0) {
      baseRule = rule.substring(0, hashIndex)
      const afterHash = rule.substring(hashIndex + 2)
      const secondHash = afterHash.indexOf('##')
      if (secondHash >= 0) {
        replacePattern = afterHash.substring(0, secondHash)
        replaceValue = afterHash.substring(secondHash + 2)
      } else {
        replacePattern = afterHash
        replaceValue = ''
      }
    }

    // 分割 @ 链式规则
    const allParts = baseRule.split('@')

    // 识别提取方法（最后一个部分如果是已知提取方法）
    const extractionMethods = ['text', 'href', 'src', 'html', 'content']
    let selectorParts: string[] = []
    let extractionMethod = ''

    const lastPart = allParts[allParts.length - 1].trim()
    if (extractionMethods.indexOf(lastPart) >= 0) {
      selectorParts = allParts.slice(0, allParts.length - 1)
      extractionMethod = lastPart
    } else {
      selectorParts = allParts
      extractionMethod = ''
    }

    // 处理选择器链
    let currentElements: string[] = [html]
    for (let i = 0; i < selectorParts.length; i++) {
      const part = selectorParts[i].trim()
      if (!part) continue
      const matched = this.applyLegadoStep(currentElements, part)
      if (matched.length === 0) return []
      currentElements = matched
    }

    // 应用提取方法到所有匹配元素
    const results: string[] = []
    for (const element of currentElements) {
      // 如果没有提取方法，返回原始HTML元素（不剥离标签）
      // 提取方法由调用方（extractText/extractAttribute）处理
      let value = extractionMethod ? this.extractLegadoValue(element, extractionMethod) : element

      // 应用正则替换
      if (replacePattern && value) {
        try {
          const regex = new RegExp(replacePattern, 'g')
          value = value.replace(regex, replaceValue)
        } catch (e) {
          // 忽略无效正则
        }
      }
      results.push(value)
    }

    return results
  }

  /**
   * 对元素列表应用单步legado选择器
   */
  private applyLegadoStep(elements: string[], part: string): string[] {
    const newElements: string[] = []

    for (const element of elements) {
      let matched: string[] = []

      if (part.startsWith('class.')) {
        // 类选择器：class.name 或 class.name.0
        const classPart = part.substring(6)
        const dotIdx = classPart.indexOf('.')
        let className = classPart
        let idx = -1
        if (dotIdx > 0) {
          className = classPart.substring(0, dotIdx)
          const parsed = parseInt(classPart.substring(dotIdx + 1))
          if (!isNaN(parsed)) {
            idx = parsed
          }
        }
        matched = HtmlParser.matchByClass(element, className)
        if (idx >= 0 && idx < matched.length) {
          matched = [matched[idx]]
        }
      } else if (part.startsWith('tag.')) {
        // 标签选择器：tag.div 或 tag.a.0 或 tag.a!0
        const tagPart = part.substring(4)
        const dotIdx = tagPart.indexOf('.')
        let tagName = tagPart
        let idx = -1
        if (dotIdx > 0) {
          tagName = tagPart.substring(0, dotIdx)
          const idxMatch = tagPart.substring(dotIdx + 1).match(/(\d+)/)
          if (idxMatch) {
            idx = parseInt(idxMatch[1])
          }
        }
        matched = HtmlParser.matchTags(element, tagName)
        if (idx >= 0 && idx < matched.length) {
          matched = [matched[idx]]
        }
      } else if (part.startsWith('id.')) {
        // ID选择器：id.xxx
        matched = HtmlParser.matchById(element, part.substring(3))
      } else if (part.startsWith('.')) {
        // CSS类选择器：.classname 或 .classname.0 或 .class1.class2（复合类选择器）
        const classPart = part.substring(1)
        const dotIdx = classPart.indexOf('.')
        let className = classPart
        let idx = -1
        if (dotIdx > 0) {
          className = classPart.substring(0, dotIdx)
          const afterDot = classPart.substring(dotIdx + 1)
          const parsed = parseInt(afterDot)
          if (!isNaN(parsed)) {
            idx = parsed
          }
        }
        matched = HtmlParser.matchByClass(element, className)
        // 如果单类匹配无结果且是复合选择器（如.box.single），用CSS解析器处理
        if (matched.length === 0 && dotIdx > 0 && isNaN(parseInt(classPart.substring(dotIdx + 1)))) {
          matched = CssSelectorParser.applySelector(element, part)
        }
        if (idx >= 0 && idx < matched.length) {
          matched = [matched[idx]]
        }
      } else if (part.startsWith('text.')) {
        // legado文本过滤：text.XXXX → 包含指定文本的元素
        const filterText = part.substring(5)
        for (const el of element) {
          const text = HtmlParser.stripTags(el)
          if (text.includes(filterText)) {
            matched.push(el)
          }
        }
      } else if (/^\d+$/.test(part)) {
        // 纯数字索引：从当前元素列表中选择
        const idx = parseInt(part)
        if (idx < elements.length) {
          matched = [elements[idx]]
        }
      } else if (part.startsWith('[')) {
        // 属性选择器 [attr=value]
        matched = CssSelectorParser.applySelector(element, part)
      } else {
        // 尝试作为CSS选择器（如 a[data-bid]）
        matched = CssSelectorParser.applySelector(element, part)
        // 如果CSS选择器没匹配到，尝试按属性存在匹配（如 a[data-bid]）
        if (matched.length === 0) {
          const attrExist = part.match(/^([a-zA-Z]+)\[([a-zA-Z][a-zA-Z0-9_-]*)\]$/)
          if (attrExist) {
            const regex = new RegExp(
              `<${attrExist[1]}\\b[^>]*\\b${attrExist[2]}\\s*=\\s*["'][^"']*["'][^>]*>[\\s\\S]*?<\\/${attrExist[1]}>`,
              'gi'
            )
            matched = element.match(regex) || []
          }
        }
      }

      newElements.push(...matched)
    }

    return newElements
  }

  /**
   * 从元素中按提取方法提取值
   */
  private extractLegadoValue(element: string, extraction: string): string {
    if (!extraction) {
      return HtmlParser.decodeHtmlEntities(HtmlParser.stripTags(element))
    }

    switch (extraction) {
      case 'text':
        return HtmlParser.decodeHtmlEntities(HtmlParser.stripTags(element))
      case 'href':
        return HtmlParser.getAttribute(element, 'href')
      case 'src':
        return HtmlParser.getAttribute(element, 'src')
      case 'html':
      case 'content':
        return HtmlParser.getElementContent(element)
      default:
        // 作为属性名提取（如 data-bid）
        return HtmlParser.getAttribute(element, extraction)
    }
  }

  /**
   * 应用规则到HTML，返回匹配的元素列表
   */
  getElements(rule: string): string[] {
    if (!rule || !this.ruleAnalyzerData.body) return [];

    // legado规则特殊处理
    if (this.isLegadoRule(rule)) {
      return this.applyLegadoRule(this.ruleAnalyzerData.body, rule)
    }

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

    // 纯提取关键字（'text', 'html', 'content'）直接提取，不作为CSS选择器
    if (rule === 'text') {
      return HtmlParser.decodeHtmlEntities(HtmlParser.stripTags(element));
    }
    if (rule === 'html' || rule === 'content') {
      return HtmlParser.getElementContent(element);
    }

    // legado规则处理
    if (this.isLegadoRule(rule)) {
      const results = this.applyLegadoRule(element, rule)
      if (results.length > 0) {
        return HtmlParser.decodeHtmlEntities(HtmlParser.stripTags(results[0]))
      }
      return ''
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

    // 纯属性名（如 'href', 'src', 'data-original'）直接提取
    if (/^[a-zA-Z][a-zA-Z0-9_-]*$/.test(rule)) {
      return HtmlParser.getAttribute(element, rule);
    }

    // legado规则处理
    if (this.isLegadoRule(rule)) {
      const results = this.applyLegadoRule(element, rule)
      if (results.length > 0) {
        const val = results[0]
        // 如果结果像URL，直接返回；否则尝试提取href
        if (val.startsWith('http') || val.startsWith('/')) {
          return val
        }
        return HtmlParser.getAttribute(val, 'href') || HtmlParser.getAttribute(val, 'src') || val
      }
      return ''
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
   * 当有多个捕获组时，存储到 currentRegexGroups 供 $N 引用
   */
  private applyRegexRule(body: string, pattern: string): string[] {
    try {
      const regex = new RegExp(pattern, 'gi');
      const matches: string[] = [];
      let match: RegExpExecArray | null;

      while ((match = regex.exec(body)) !== null) {
        if (match.length > 2) {
          // 多个捕获组：存储所有组，返回第一个组作为主结果
          this.currentRegexGroups = match.slice(1)
          matches.push(match[1]);
        } else if (match.length > 1) {
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
   * 处理 $N 引用规则（支持多种格式）
   * $N - 简单引用第N个捕获组
   * $N##pattern - 引用并用pattern做正则替换（删除匹配内容）
   * $N,$M - 逗号分隔的多组引用
   * $N##pattern,$M##pattern - 混合格式
   */
  private resolveCaptureGroupRule(rule: string): string {
    if (!rule || this.currentRegexGroups.length === 0) return ''

    // 逗号分隔：$6,$7 或 $1,$4$5
    if (rule.indexOf(',') >= 0) {
      const parts = rule.split(',')
      const results: string[] = []
      for (const part of parts) {
        const val = this.resolveSingleGroupRef(part.trim())
        if (val) results.push(val)
      }
      return results.join(',')
    }

    // 单个引用：$N 或 $N##pattern
    return this.resolveSingleGroupRef(rule)
  }

  /**
   * 解析单个 $N 或 $N##pattern 或 $N$M 引用
   */
  private resolveSingleGroupRef(rule: string): string {
    if (!rule) return ''

    const hashIdx = rule.indexOf('##')
    let refPart = rule
    let replacePattern = ''

    if (hashIdx > 0) {
      refPart = rule.substring(0, hashIdx)
      replacePattern = rule.substring(hashIdx + 2)
    }

    // 提取所有 $N 引用（支持 $4$5 连续引用）
    const allRefs = refPart.match(/\$(\d+)/g)
    if (!allRefs || allRefs.length === 0) return ''

    let value = ''
    for (const ref of allRefs) {
      const idx = parseInt(ref.substring(1))
      if (idx >= 1 && idx <= this.currentRegexGroups.length) {
        value += this.currentRegexGroups[idx - 1] || ''
      }
    }

    // 应用 ## 替换（删除匹配内容）
    if (replacePattern && value) {
      try {
        const regex = new RegExp(replacePattern, 'g')
        value = value.replace(regex, '')
      } catch (e) {
        // 忽略无效正则
      }
    }

    return value.trim()
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
