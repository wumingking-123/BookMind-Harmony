/**
 * CSS选择器解析器
 * 将CSS选择器字符串解析为匹配操作链
 */
import { HtmlParser } from './HtmlParser';

export interface SelectorPart {
  type: 'tag' | 'class' | 'id' | 'attribute' | 'pseudo' | 'universal';
  value: string;
  combinator?: 'descendant' | 'child' | 'sibling' | 'adjacent';
}

export class CssSelectorParser {
  /**
   * 解析CSS选择器字符串
   */
  static parseSelector(selector: string): SelectorPart[] {
    const parts: SelectorPart[] = [];
    // 去除首尾空格
    selector = selector.trim();

    // 按空格和>分割，保留分隔符
    const tokens = CssSelectorParser.tokenize(selector);

    for (let i = 0; i < tokens.length; i++) {
      const token = tokens[i];
      if (token === '>' || token === '+' || token === '~') {
        // 组合符，标记下一个元素的组合类型
        continue;
      }

      const part = CssSelectorParser.parseToken(token);
      if (i > 0 && tokens[i - 1] === '>') {
        part.combinator = 'child';
      } else if (i > 0 && tokens[i - 1] === '+') {
        part.combinator = 'adjacent';
      } else if (i > 0 && tokens[i - 1] === '~') {
        part.combinator = 'sibling';
      } else if (i > 0) {
        part.combinator = 'descendant';
      }

      parts.push(part);
    }

    return parts;
  }

  /**
   * 分词
   */
  private static tokenize(selector: string): string[] {
    const tokens: string[] = [];
    let current = '';
    let i = 0;

    while (i < selector.length) {
      const char = selector[i];

      if (char === ' ') {
        if (current) {
          tokens.push(current);
          current = '';
        }
        // 跳过多余空格
        while (i < selector.length && selector[i] === ' ') i++;
        continue;
      }

      if (char === '>' || char === '+' || char === '~') {
        if (current) {
          tokens.push(current);
          current = '';
        }
        tokens.push(char);
        i++;
        continue;
      }

      current += char;
      i++;
    }

    if (current) {
      tokens.push(current);
    }

    return tokens;
  }

  /**
   * 解析单个token
   */
  private static parseToken(token: string): SelectorPart {
    // 通配符 *
    if (token === '*') {
      return { type: 'universal', value: '*' };
    }

    // ID选择器 #id
    if (token.startsWith('#')) {
      return { type: 'id', value: token.substring(1) };
    }

    // 类选择器 .class
    if (token.startsWith('.')) {
      return { type: 'class', value: token.substring(1) };
    }

    // 属性选择器 [attr=value]
    if (token.startsWith('[')) {
      return { type: 'attribute', value: token };
    }

    // 伪类选择器 :nth-child(n)
    if (token.includes(':')) {
      const parts: string[] = token.split(':');
      const pseudo: string = parts.length > 1 ? parts[1] : parts[0];
      return { type: 'pseudo', value: pseudo };
    }

    // 标签选择器
    return { type: 'tag', value: token };
  }

  /**
   * 应用选择器匹配HTML
   */
  static applySelector(html: string, selector: string): string[] {
    const parts = CssSelectorParser.parseSelector(selector);
    if (parts.length === 0) return [];

    let results: string[] = [html];

    for (const part of parts) {
      const newResults: string[] = [];

      for (const htmlFragment of results) {
        const matched = CssSelectorParser.matchPart(htmlFragment, part);
        newResults.push(...matched);
      }

      results = newResults;
      if (results.length === 0) break;
    }

    return results;
  }

  /**
   * 匹配单个选择器部分
   */
  private static matchPart(html: string, part: SelectorPart): string[] {
    switch (part.type) {
      case 'tag':
        return HtmlParser.matchTags(html, part.value);

      case 'class':
        return HtmlParser.matchByClass(html, part.value);

      case 'id':
        return HtmlParser.matchById(html, part.value);

      case 'attribute':
        return HtmlParser.matchByAttributeSelector(html, part.value);

      case 'pseudo':
        return CssSelectorParser.matchPseudo(html, part.value);

      case 'universal':
        return CssSelectorParser.matchAllElements(html);

      default:
        return [];
    }
  }

  /**
   * 匹配伪类选择器
   */
  private static matchPseudo(html: string, pseudo: string): string[] {
    // 处理 :nth-child(n)
    const nthMatch = pseudo.match(/^nth-child\((\d+)\)$/);
    if (nthMatch) {
      const index = parseInt(nthMatch[1]) - 1;
      // 返回父元素的第n个子元素
      const parentMatch = html.match(/<[a-zA-Z][a-zA-Z0-9]*\b[^>]*>([\s\S]*?)<\/[a-zA-Z][a-zA-Z0-9]*>/gi);
      if (parentMatch && index >= 0 && index < parentMatch.length) {
        return [parentMatch[index]];
      }
    }

    // 处理 :first-child
    if (pseudo === 'first-child') {
      const match = html.match(/<[a-zA-Z][a-zA-Z0-9]*\b[^>]*>([\s\S]*?)<\/[a-zA-Z][a-zA-Z0-9]*>/i);
      return match ? [match[0]] : [];
    }

    // 处理 :last-child
    if (pseudo === 'last-child') {
      const matches = html.match(/<[a-zA-Z][a-zA-Z0-9]*\b[^>]*>([\s\S]*?)<\/[a-zA-Z][a-zA-Z0-9]*>/gi);
      return matches ? [matches[matches.length - 1]] : [];
    }

    return [];
  }

  /**
   * 匹配所有元素
   */
  private static matchAllElements(html: string): string[] {
    const regex = /<([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>[\s\S]*?<\/\1>/gi;
    return html.match(regex) || [];
  }
}
