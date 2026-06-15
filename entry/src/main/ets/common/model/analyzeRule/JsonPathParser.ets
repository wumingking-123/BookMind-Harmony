/**
 * JSON路径解析器
 * 解析 $. 表达式并从JSON对象中提取数据
 */
export class JsonPathParser {
  /**
   * 评估JSON路径表达式
   * @param obj JSON对象
   * @param path 路径表达式，如 $.data.list[0].name
   * @returns 匹配的结果数组
   */
  static evaluate(obj: object, path: string): string[] {
    if (!path || !obj) return [];

    // 移除 $ 前缀
    let cleanPath = path.startsWith('$.') ? path.substring(2) : path;
    if (cleanPath === '$') return [JSON.stringify(obj)];

    const segments = this.parsePath(cleanPath);
    let current: unknown[] = [obj];

    for (const segment of segments) {
      const next: unknown[] = [];

      for (const item of current) {
        if (item === null || item === undefined) continue;

        if (segment.type === 'property') {
          if (typeof item === 'object' && !Array.isArray(item)) {
            const obj = item as Record<string, unknown>;
            if (segment.name in obj) {
              next.push(obj[segment.name]);
            }
          }
        } else if (segment.type === 'index') {
          if (Array.isArray(item)) {
            if (segment.index >= 0 && segment.index < item.length) {
              next.push(item[segment.index]);
            }
          }
        } else if (segment.type === 'wildcard') {
          if (Array.isArray(item)) {
            next.push(...item);
          } else if (typeof item === 'object') {
            next.push(...Object.values(item as Record<string, unknown>));
          }
        } else if (segment.type === 'recursive') {
          // 递归搜索所有层级
          const found = this.recursiveSearch(item, segment.name);
          next.push(...found);
        }
      }

      current = next;
    }

    return current.map(item => {
      if (typeof item === 'string') return item;
      if (typeof item === 'number' || typeof item === 'boolean') return String(item);
      return JSON.stringify(item);
    });
  }

  /**
   * 解析路径为段落数组
   */
  private static parsePath(path: string): PathSegment[] {
    const segments: PathSegment[] = [];
    let i = 0;

    while (i < path.length) {
      if (path[i] === '.') {
        i++;
        // 检查是否是递归搜索 ..
        if (i < path.length && path[i] === '.') {
          i++;
          const name = this.readPropertyName(path, i);
          segments.push({ type: 'recursive', name });
          i += name.length;
        } else {
          const name = this.readPropertyName(path, i);
          segments.push({ type: 'property', name });
          i += name.length;
        }
      } else if (path[i] === '[') {
        i++;
        if (path[i] === '*' && path[i + 1] === ']') {
          segments.push({ type: 'wildcard' });
          i += 2;
        } else if (path[i] === '\'' || path[i] === '"') {
          // 字符串键 ['key'] or ["key"]
          const quote = path[i];
          i++;
          let key = '';
          while (i < path.length && path[i] !== quote) {
            key += path[i];
            i++;
          }
          segments.push({ type: 'property', name: key });
          i += 2; // skip quote and ]
        } else {
          // 数字索引 [n]
          let numStr = '';
          while (i < path.length && path[i] >= '0' && path[i] <= '9') {
            numStr += path[i];
            i++;
          }
          if (numStr) {
            segments.push({ type: 'index', index: parseInt(numStr) });
          }
          i++; // skip ]
        }
      } else {
        const name = this.readPropertyName(path, i);
        if (name) {
          segments.push({ type: 'property', name });
          i += name.length;
        } else {
          i++;
        }
      }
    }

    return segments;
  }

  /**
   * 读取属性名
   */
  private static readPropertyName(path: string, start: number): string {
    let name = '';
    let i = start;
    while (i < path.length && path[i] !== '.' && path[i] !== '[' && path[i] !== ']') {
      name += path[i];
      i++;
    }
    return name;
  }

  /**
   * 递归搜索
   */
  private static recursiveSearch(obj: unknown, propertyName: string): unknown[] {
    const results: unknown[] = [];

    const search = (current: unknown) => {
      if (current === null || current === undefined) return;

      if (Array.isArray(current)) {
        for (const item of current) {
          search(item);
        }
      } else if (typeof current === 'object') {
        const obj = current as Record<string, unknown>;
        if (propertyName in obj) {
          results.push(obj[propertyName]);
        }
        for (const value of Object.values(obj)) {
          search(value);
        }
      }
    };

    search(obj);
    return results;
  }
}

interface PathSegment {
  type: 'property' | 'index' | 'wildcard' | 'recursive';
  name?: string;
  index?: number;
}
