/**
 * HTML正则解析引擎
 * 用于在无DOM环境下解析HTML文档
 */
export class HtmlParser {
  /**
   * 匹配指定标签的所有元素
   */
  static matchTags(html: string, tagName: string): string[] {
    const regex = new RegExp(`<${tagName}\\b[^>]*>[\\s\\S]*?<\\/${tagName}>`, 'gi');
    return html.match(regex) || [];
  }

  /**
   * 按属性匹配元素
   */
  static matchByAttribute(html: string, attrName: string, attrValue: string): string[] {
    const regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\b${attrName}\\s*=\\s*["']${this.escapeRegex(attrValue)}["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
    return html.match(regex) || [];
  }

  /**
   * 按class匹配元素
   */
  static matchByClass(html: string, className: string): string[] {
    const regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\bclass\\s*=\\s*["'][^"']*\\b${this.escapeRegex(className)}\\b[^"']*["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
    return html.match(regex) || [];
  }

  /**
   * 按id匹配元素
   */
  static matchById(html: string, id: string): string[] {
    const regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\bid\\s*=\\s*["']${this.escapeRegex(id)}["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
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
   * 去除HTML标签
   */
  static stripTags(html: string): string {
    return html.replace(/<[^>]+>/g, '').trim();
  }

  /**
   * 解码HTML实体
   */
  static decodeHtmlEntities(text: string): string {
    const entities: Record<string, string> = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&nbsp;': ' ',
      '&apos;': "'"
    };

    let result = text.replace(/&[a-zA-Z]+;/g, (match) => {
      return entities[match] || match;
    });

    // 解码数字实体 &#123; 或 &#x1F;
    result = result.replace(/&#(\d+);/g, (_, code) => {
      return String.fromCharCode(parseInt(code));
    });
    result = result.replace(/&#x([0-9a-fA-F]+);/g, (_, code) => {
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
    const regex = new RegExp(`<${tagName}\\b[^>]*\\bclass\\s*=\\s*["'][^"']*\\b${this.escapeRegex(className)}\\b[^"']*["'][^>]*>[\\s\\S]*?<\\/${tagName}>`, 'gi');
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
        regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\b${attrName}\\s*=\\s*["']${this.escapeRegex(attrValue)}["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
        break;
      case '~=':
        regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\b${attrName}\\s*=\\s*["'][^"']*\\b${this.escapeRegex(attrValue)}\\b[^"']*["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
        break;
      case '^=':
        regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\b${attrName}\\s*=\\s*["']${this.escapeRegex(attrValue)}[^"']*["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
        break;
      case '$=':
        regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\b${attrName}\\s*=\\s*["'][^"']*${this.escapeRegex(attrValue)}["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
        break;
      case '*=':
        regex = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*\\b${attrName}\\s*=\\s*["'][^"']*${this.escapeRegex(attrValue)}[^"']*["'][^>]*>[\\s\\S]*?<\\/\\1>`, 'gi');
        break;
      default:
        return [];
    }
    return html.match(regex) || [];
  }
}
