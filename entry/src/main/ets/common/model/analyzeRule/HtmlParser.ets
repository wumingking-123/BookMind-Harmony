/**
 * HTML正则解析引擎
 * 用于在无DOM环境下解析HTML文档
 */
export class HtmlParser {
  /**
   * 匹配指定标签的所有元素（支持自闭合标签如 img、br、input）
   */
  static matchTags(html: string, tagName: string): string[] {
    const results: string[] = [];
    // 匹配开闭标签 <tag ...>...</tag>
    const openCloseRegex = new RegExp(`<${tagName}\\b[^>]*>[\\s\\S]*?<\\/${tagName}>`, 'gi');
    let match: RegExpExecArray | null;
    while ((match = openCloseRegex.exec(html)) !== null) {
      results.push(match[0]);
    }
    // 匹配自闭合标签 <tag .../> 或 <tag ...>（HTML5 void元素如img/br无需斜杠）
    const selfClosingRegex = new RegExp(`<${tagName}\\b[^>]*(?:\\/\\s*)?>`, 'gi');
    while ((match = selfClosingRegex.exec(html)) !== null) {
      const matchedStr = match[0];
      // 排除已被开闭标签完整匹配覆盖的开标签
      const isPartOfOpenClose = results.some(oc => oc.includes(matchedStr) && oc.length > matchedStr.length);
      if (!isPartOfOpenClose) {
        results.push(matchedStr);
      }
    }
    return results;
  }

  /**
   * 按属性匹配元素
   */
  static matchByAttribute(html: string, attrName: string, attrValue: string): string[] {
    const regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\b${attrName}\\s*=\\s*["']${HtmlParser.escapeRegex(attrValue)}["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
    return html.match(regex) || [];
  }

  /**
   * 按class匹配元素（同时支持开闭标签和自闭合/void标签）
   */
  static matchByClass(html: string, className: string): string[] {
    const results: string[] = [];
    const escapedClass = HtmlParser.escapeRegex(className);
    // 匹配开闭标签 <tag class="xxx">...</tag>
    const openCloseRegex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\bclass\\s*=\\s*["'][^"']*\\b${escapedClass}\\b[^"']*["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
    let match: RegExpExecArray | null;
    while ((match = openCloseRegex.exec(html)) !== null) {
      results.push(match[0]);
    }
    // 匹配自闭合/void元素 <img class="xxx" ...> 或 <img class="xxx" .../>
    const selfClosingRegex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\bclass\\s*=\\s*["'][^"']*\\b${escapedClass}\\b[^"']*["'][^>]*(?:\\/\\s*)?>`, 'gi');
    while ((match = selfClosingRegex.exec(html)) !== null) {
      results.push(match[0]);
    }
    return results;
  }

  /**
   * 按id匹配元素
   */
  static matchById(html: string, id: string): string[] {
    const regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\bid\\s*=\\s*["']${HtmlParser.escapeRegex(id)}["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
    return html.match(regex) || [];
  }

  /**
   * 获取标签内的内容（不含标签本身）
   */
  static getElementContent(element: string): string {
    const match = element.match(/^<[a-zA-Z][a-zA-Z0-9]*\b[^>]*>([\s\S]*)<\/[a-zA-Z][a-zA-Z0-9]*>$/i);
    return match ? match[1] : '';
  }

  /**
   * 提取属性值
   */
  static getAttribute(element: string, attrName: string): string {
    const regex = new RegExp(`\\b${attrName}\\s*=\\s*["']([^"']*)["']`, 'i');
    const match = element.match(regex);
    return match ? match[1] : '';
  }

  /**
   * 提取所有属性值
   */
  static getAttributes(element: string, attrName: string): string[] {
    const regex = new RegExp(`\\b${attrName}\\s*=\\s*["']([^"']*)["']`, 'gi');
    const matches: string[] = [];
    let match: RegExpExecArray | null;
    while ((match = regex.exec(element)) !== null) {
      matches.push(match[1]);
    }
    return matches;
  }

  /**
   * 去除HTML标签，保留换行语义
   */
  static stripTags(html: string): string {
    let text = html
    // 块级标签 → 换行
    text = text.replace(/<br\s*\/?>/gi, '\n')
    text = text.replace(/<\/p>/gi, '\n')
    text = text.replace(/<\/div>/gi, '\n')
    text = text.replace(/<\/li>/gi, '\n')
    text = text.replace(/<\/h[1-6]>/gi, '\n')
    text = text.replace(/<hr\s*\/?>/gi, '\n')
    // 去除所有剩余标签
    text = text.replace(/<[^>]+>/g, '')
    // 合并多余空行
    text = text.replace(/\n{3,}/g, '\n\n')
    return text.trim()
  }

  /**
   * 解码HTML实体
   */
  static decodeHtmlEntities(text: string): string {
    const entities: Map<string, string> = new Map();
    entities.set('&amp;', '&');
    entities.set('&lt;', '<');
    entities.set('&gt;', '>');
    entities.set('&quot;', '"');
    entities.set('&#39;', "'");
    entities.set('&nbsp;', ' ');
    entities.set('&apos;', "'");

    let result = text.replace(/&[a-zA-Z]+;/g, (match: string) => {
      return entities.has(match) ? entities.get(match)! : match;
    });

    // 解码数字实体 &#123; 或 &#x1F;
    result = result.replace(/&#(\d+);/g, (_match: string, code: string) => {
      return String.fromCharCode(parseInt(code));
    });
    result = result.replace(/&#x([0-9a-fA-F]+);/g, (_match: string, code: string) => {
      return String.fromCharCode(parseInt(code, 16));
    });

    return result;
  }

  /**
   * 获取开标签名
   */
  static getTagName(element: string): string {
    const match = element.match(/^<([a-zA-Z][a-zA-Z0-9]*)\b/);
    return match ? match[1] : '';
  }

  /**
   * 转义正则特殊字符
   */
  static escapeRegex(str: string): string {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  /**
   * 组合选择器匹配：标签+类
   */
  static matchTagWithClass(html: string, tagName: string, className: string): string[] {
    const regex = new RegExp(`<${tagName}\\b[^>]*\\bclass\\s*=\\s*["'][^"']*\\b${HtmlParser.escapeRegex(className)}\\b[^"']*["'][^>]*>[\\s\\S]*?<\\/${tagName}>`, 'gi');
    return html.match(regex) || [];
  }

  /**
   * 通用属性选择器 [attr=value]
   */
  static matchByAttributeSelector(html: string, selector: string): string[] {
    const match = selector.match(/^\[([a-zA-Z]+)([~|^$*]?=)(["']?)(.+?)\3\]$/);
    if (!match) return [];

    const attrName = match[1];
    const operator = match[2];
    const attrValue = match[4];

    let regex: RegExp;
    switch (operator) {
      case '=':
        regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\b${attrName}\\s*=\\s*["']${HtmlParser.escapeRegex(attrValue)}["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
        break;
      case '~=':
        regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\b${attrName}\\s*=\\s*["'][^"']*\\b${HtmlParser.escapeRegex(attrValue)}\\b[^"']*["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
        break;
      case '^=':
        regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\b${attrName}\\s*=\\s*["']${HtmlParser.escapeRegex(attrValue)}[^"']*["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
        break;
      case '$=':
        regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\b${attrName}\\s*=\\s*["'][^"']*${HtmlParser.escapeRegex(attrValue)}["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
        break;
      case '*=':
        regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\b${attrName}\\s*=\\s*["'][^"']*${HtmlParser.escapeRegex(attrValue)}[^"']*["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
        break;
      default:
        return [];
    }
    return html.match(regex) || [];
  }
}
