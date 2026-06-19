/**
 * CSS选择器解析器
 * 将CSS选择器字符串解析为匹配操作链
 */
import { HtmlParser } from './HtmlParser';

export interface SelectorPart {
  type: 'tag' | 'class' | 'id' | 'attribute' | 'pseudo' | 'universal';
  value: string;
  combinator?: 'descendant' | 'child' | 'sibling' | 'adjacent';
  pseudoValue?: string;  // 用于contains等需要额外参数的伪类
}

export class CssSelectorParser {
  /**
   * 解析CSS选择器字符串
   */
  static parseSelector(selector: string): SelectorPart[] {
    const parts: SelectorPart[] = [];
    selector = selector.trim();

    const tokens = CssSelectorParser.tokenize(selector);

    for (let i = 0; i < tokens.length; i++) {
      const token = tokens[i];
      if (token === '>' || token === '+' || token === '~') {
        continue;
      }

      const parsedParts = CssSelectorParser.parseToken(token);
      for (const part of parsedParts) {
        if (i > 0 && tokens[i - 1] === '>') {
          part.combinator = 'child';
        } else if (i > 0 && tokens[i - 1] === '+') {
          part.combinator = 'adjacent';
        } else if (i > 0 && tokens[i - 1] === '~') {
          part.combinator = 'sibling';
        } else if (i > 0 && parts.length > 0) {
          part.combinator = 'descendant';
        }
        parts.push(part);
      }
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
   * 解析单个token，支持复合选择器
   * 例如: div.class, h3.title, span:contains(文本)
   */
  private static parseToken(token: string): SelectorPart[] {
    const parts: SelectorPart[] = [];

    // 通配符 *
    if (token === '*') {
      parts.push({ type: 'universal', value: '*' });
      return parts;
    }

    // 处理伪类 :contains(文本)
    const containsMatch = token.match(/^(.*):contains\((.+?)\)$/);
    if (containsMatch) {
      const baseToken = containsMatch[1];
      const containsText = containsMatch[2];
      // 先解析基础部分
      if (baseToken) {
        parts.push(...CssSelectorParser.parseSimpleToken(baseToken));
      }
      // 添加contains伪类
      parts.push({ type: 'pseudo', value: 'contains', pseudoValue: containsText });
      return parts;
    }

    // 处理其他伪类 :nth-child(n), :first-child 等
    const pseudoMatch = token.match(/^(.*):(nth-child\(\d+\)|first-child|last-child|nth-of-type\(\d+\))$/);
    if (pseudoMatch) {
      const baseToken = pseudoMatch[1];
      const pseudo = pseudoMatch[2];
      if (baseToken) {
        parts.push(...CssSelectorParser.parseSimpleToken(baseToken));
      }
      parts.push({ type: 'pseudo', value: pseudo });
      return parts;
    }

    return CssSelectorParser.parseSimpleToken(token);
  }

  /**
   * 解析简单token（不含伪类）
   * 支持: div, .class, #id, div.class, div#id, [attr=value]
   */
  private static parseSimpleToken(token: string): SelectorPart[] {
    const parts: SelectorPart[] = [];

    // ID选择器 #id
    if (token.startsWith('#')) {
      parts.push({ type: 'id', value: token.substring(1) });
      return parts;
    }

    // 类选择器 .class 或复合类选择器 .class1.class2
    if (token.startsWith('.')) {
      const classStr = token.substring(1);
      const subParts = classStr.split('.');
      for (const sub of subParts) {
        if (sub) {
          parts.push({ type: 'class', value: sub });
        }
      }
      return parts;
    }

    // 属性选择器 [attr=value]
    if (token.startsWith('[')) {
      parts.push({ type: 'attribute', value: token });
      return parts;
    }

    // 复合选择器: div.class, div#id, div[attr], div.class[attr]
    const bracketIndex = token.indexOf('[');
    const dotIndex = token.indexOf('.');
    const hashIndex = token.indexOf('#');

    if (dotIndex > 0 || hashIndex > 0 || bracketIndex > 0) {
      // 找到第一个.、#或[的位置作为标签名结束位置
      let tagEnd = token.length;
      if (dotIndex > 0) tagEnd = Math.min(tagEnd, dotIndex);
      if (hashIndex > 0) tagEnd = Math.min(tagEnd, hashIndex);
      if (bracketIndex > 0) tagEnd = Math.min(tagEnd, bracketIndex);

      const tagName = token.substring(0, tagEnd);
      parts.push({ type: 'tag', value: tagName });

      // 解析剩余的.class、#id和[attr]部分
      let remaining = token.substring(tagEnd);
      while (remaining.length > 0) {
        if (remaining.startsWith('[')) {
          const closeBracket = remaining.indexOf(']');
          if (closeBracket > 0) {
            parts.push({ type: 'attribute', value: remaining.substring(0, closeBracket + 1) });
            remaining = remaining.substring(closeBracket + 1);
          } else {
            break;
          }
        } else if (remaining.startsWith('.')) {
          const nextDot = remaining.indexOf('.', 1);
          const nextHash = remaining.indexOf('#', 1);
          const nextBracket = remaining.indexOf('[', 1);
          let classEnd = remaining.length;
          if (nextDot > 0) classEnd = Math.min(classEnd, nextDot);
          if (nextHash > 0) classEnd = Math.min(classEnd, nextHash);
          if (nextBracket > 0) classEnd = Math.min(classEnd, nextBracket);
          parts.push({ type: 'class', value: remaining.substring(1, classEnd) });
          remaining = remaining.substring(classEnd);
        } else if (remaining.startsWith('#')) {
          const nextDot = remaining.indexOf('.', 1);
          const nextHash = remaining.indexOf('#', 1);
          const nextBracket = remaining.indexOf('[', 1);
          let idEnd = remaining.length;
          if (nextDot > 0) idEnd = Math.min(idEnd, nextDot);
          if (nextHash > 0) idEnd = Math.min(idEnd, nextHash);
          if (nextBracket > 0) idEnd = Math.min(idEnd, nextBracket);
          parts.push({ type: 'id', value: remaining.substring(1, idEnd) });
          remaining = remaining.substring(idEnd);
        } else {
          break;
        }
      }

      return parts;
    }

    // 纯标签选择器
    parts.push({ type: 'tag', value: token });
    return parts;
  }

  /**
   * 应用选择器匹配HTML
   * 支持复合选择器（如 ul.row, li.col-md-3）在同一元素上匹配
   */
  static applySelector(html: string, selector: string): string[] {
    const parts = CssSelectorParser.parseSelector(selector);
    if (parts.length === 0) return [];

    let results: string[] = [html];
    let i = 0;

    while (i < parts.length) {
      const part = parts[i];

      // 合并同一层级的复合选择器（如 ul + .row → ul.row）
      const compoundParts: SelectorPart[] = [part];
      let j = i + 1;
      while (j < parts.length && parts[j].combinator === 'descendant' &&
        CssSelectorParser.isCompoundWithPrevious(part, parts[j])) {
        compoundParts.push(parts[j]);
        j++;
      }

      const newResults: string[] = [];
      for (const htmlFragment of results) {
        const matched = CssSelectorParser.matchCompound(htmlFragment, compoundParts);
        newResults.push(...matched);
      }

      results = newResults;
      if (results.length === 0) {
        console.log('CSS选择器匹配失败: ' + selector + ', 在步骤: ' + part.type + '=' + part.value)
        break;
      }

      i = j;
    }

    if (results.length > 0) {
      console.log('CSS选择器匹配成功: ' + selector + ', 找到 ' + results.length + ' 个元素')
    }

    return results;
  }

  /**
   * 判断两个连续的选择器部分是否构成复合选择器（匹配同一元素）
   * 例如: tag + class (ul.row), tag + id (div#main)
   */
  private static isCompoundWithPrevious(prev: SelectorPart, current: SelectorPart): boolean {
    // tag + class/id/attribute 构成复合选择器
    if (prev.type === 'tag' && (current.type === 'class' || current.type === 'id' || current.type === 'attribute')) {
      return true;
    }
    // class + class 构成复合选择器（如 .foo.bar）
    if (prev.type === 'class' && current.type === 'class') {
      return true;
    }
    return false;
  }

  /**
   * 匹配复合选择器（同一元素上需要同时满足多个条件）
   */
  private static matchCompound(html: string, parts: SelectorPart[]): string[] {
    if (parts.length === 1) {
      return CssSelectorParser.matchPart(html, parts[0]);
    }

    // 复合选择器：先按第一个部分匹配，再过滤后续条件
    let results = CssSelectorParser.matchPart(html, parts[0]);

    for (let k = 1; k < parts.length; k++) {
      const filterPart = parts[k];
      const filtered: string[] = [];
      for (const el of results) {
        const tagEnd = el.indexOf('>');
        const openTag = tagEnd >= 0 ? el.substring(0, tagEnd + 1) : el;
        if (CssSelectorParser.matchesFilter(openTag, filterPart)) {
          filtered.push(el);
        }
      }
      results = filtered;
    }

    return results;
  }

  /**
   * 检查开标签是否满足过滤条件（class/id/attribute）
   */
  private static matchesFilter(openTag: string, part: SelectorPart): boolean {
    if (part.type === 'class') {
      const classRegex = new RegExp(`\\bclass\\s*=\\s*["'][^"']*\\b${HtmlParser.escapeRegex(part.value)}\\b`, 'i');
      return classRegex.test(openTag);
    }
    if (part.type === 'id') {
      const idRegex = new RegExp(`\\bid\\s*=\\s*["']${HtmlParser.escapeRegex(part.value)}["']`, 'i');
      return idRegex.test(openTag);
    }
    if (part.type === 'attribute') {
      const match = part.value.match(/^\[([a-zA-Z]+)([~|^$*]?=)(["']?)(.+?)\3\]$/);
      if (!match) return false;
      const attrRegex = new RegExp(`\\b${match[1]}\\s*=\\s*["']${HtmlParser.escapeRegex(match[4])}["']`, 'i');
      return attrRegex.test(openTag);
    }
    return false;
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
        return CssSelectorParser.matchPseudo(html, part.value, part.pseudoValue);

      case 'universal':
        return CssSelectorParser.matchAllElements(html);

      default:
        return [];
    }
  }

  /**
   * 匹配伪类选择器
   */
  private static matchPseudo(html: string, pseudo: string, pseudoValue?: string): string[] {
    // 处理 :contains(文本)
    if (pseudo === 'contains' && pseudoValue) {
      return CssSelectorParser.matchContains(html, pseudoValue);
    }

    // 处理 :nth-child(n)
    const nthMatch = pseudo.match(/^nth-child\((\d+)\)$/);
    if (nthMatch) {
      const index = parseInt(nthMatch[1]) - 1;
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
   * 匹配:contains(文本) - 返回包含指定文本的元素
   */
  private static matchContains(html: string, text: string): string[] {
    const results: string[] = [];
    // 匹配所有元素
    const regex = /<([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>[\s\S]*?<\/\1>/gi;
    let match: RegExpExecArray | null;
    while ((match = regex.exec(html)) !== null) {
      const element = match[0];
      // 检查元素的文本内容是否包含指定文本
      const textContent = HtmlParser.stripTags(element);
      if (textContent.includes(text)) {
        results.push(element);
      }
    }
    return results;
  }

  /**
   * 匹配所有元素
   */
  private static matchAllElements(html: string): string[] {
    const regex = /<([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>[\s\S]*?<\/\1>/gi;
    return html.match(regex) || [];
  }
}
