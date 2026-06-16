/**
 * JSON路径解析器
 * 解析 $. 表达式并从JSON对象中提取数据
 */
export class JsonPathParser {
  /**
   * 将JSON对象转换为Map（ArkTS兼容方式）
   * 使用JSON.stringify replacer收集键值对
   */
  private static convertToMap(obj: Object): Map<string, Object> {
    const result = new Map<string, Object>();
    const jsonStr = JSON.stringify(obj);
    if (!jsonStr || jsonStr.charAt(0) !== '{') return result;

    // 使用replacer收集所有键
    const collectedKeys: string[] = [];
    JSON.stringify(obj, (key: string, value: Object) => {
      if (key !== '') {
        collectedKeys.push(key);
      }
      return value;
    });

    // 对每个键，通过构造子JSON提取值
    for (let i = 0; i < collectedKeys.length; i++) {
      const k = collectedKeys[i];
      const subJson = JSON.stringify(obj, (key: string, value: Object) => {
        if (key === '' || key === k) {
          return value;
        }
        return undefined;
      });
      if (subJson && subJson !== '{}') {
        // 从子JSON中提取值
        const parsed = JSON.parse(subJson) as Map<string, Object>;
        if (parsed.has(k)) {
          result.set(k, parsed.get(k)!);
        }
      }
    }
    return result;
  }

  /**
   * 将JSON数组转换为Map（索引为键）
   */
  private static convertArrayToMap(arr: Object[]): Map<string, Object> {
    const result = new Map<string, Object>();
    for (let i = 0; i < arr.length; i++) {
      result.set(String(i), arr[i]);
    }
    return result;
  }

  /**
   * 评估JSON路径表达式
   * @param obj JSON对象
   * @param path 路径表达式，如 $.data.list[0].name
   * @returns 匹配的结果数组
   */
  static evaluate(obj: Object, path: string): string[] {
    if (!path || !obj) return [];

    // 移除 $ 前缀
    let cleanPath = path.startsWith('$.') ? path.substring(2) : path;
    if (cleanPath === '$') return [JSON.stringify(obj)];

    const segments = JsonPathParser.parsePath(cleanPath);

    // 使用Map存储当前层级数据
    let currentMaps: Map<string, Object>[] = [JsonPathParser.convertToMap(obj)];

    for (const segment of segments) {
      const nextMaps: Map<string, Object>[] = [];

      for (let ci = 0; ci < currentMaps.length; ci++) {
        const itemMap = currentMaps[ci];

        if (segment.type === 'property') {
          const name = segment.name!;
          if (itemMap.has(name)) {
            const val = itemMap.get(name)!;
            if (Array.isArray(val)) {
              nextMaps.push(JsonPathParser.convertArrayToMap(val));
            } else if (typeof val === 'object' && val !== null) {
              nextMaps.push(JsonPathParser.convertToMap(val));
            }
          }
        } else if (segment.type === 'index') {
          const idx = segment.index!;
          const key = String(idx);
          if (itemMap.has(key)) {
            const val = itemMap.get(key)!;
            if (Array.isArray(val)) {
              nextMaps.push(JsonPathParser.convertArrayToMap(val));
            } else if (typeof val === 'object' && val !== null) {
              nextMaps.push(JsonPathParser.convertToMap(val));
            }
          }
        } else if (segment.type === 'wildcard') {
          const keys: string[] = [];
          itemMap.forEach((_value: Object, key: string) => {
            keys.push(key);
          });
          for (let ki = 0; ki < keys.length; ki++) {
            const val = itemMap.get(keys[ki])!;
            if (Array.isArray(val)) {
              nextMaps.push(JsonPathParser.convertArrayToMap(val));
            } else if (typeof val === 'object' && val !== null) {
              nextMaps.push(JsonPathParser.convertToMap(val));
            }
          }
        } else if (segment.type === 'recursive') {
          const found = JsonPathParser.recursiveSearch(itemMap, segment.name!);
          for (let ri = 0; ri < found.length; ri++) {
            const val = found[ri];
            if (Array.isArray(val)) {
              nextMaps.push(JsonPathParser.convertArrayToMap(val));
            } else if (typeof val === 'object' && val !== null) {
              nextMaps.push(JsonPathParser.convertToMap(val));
            }
          }
        }
      }

      currentMaps = nextMaps;
    }

    // 从最终的Map中提取字符串结果
    const result: string[] = [];
    for (let mi = 0; mi < currentMaps.length; mi++) {
      const m = currentMaps[mi];
      m.forEach((val: Object, _key: string) => {
        if (typeof val === 'string') {
          result.push(val);
        } else if (typeof val === 'number' || typeof val === 'boolean') {
          result.push(String(val));
        } else {
          result.push(JSON.stringify(val));
        }
      });
    }
    return result;
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
          const name = JsonPathParser.readPropertyName(path, i);
          segments.push({ type: 'recursive', name });
          i += name.length;
        } else {
          const name = JsonPathParser.readPropertyName(path, i);
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
        const name = JsonPathParser.readPropertyName(path, i);
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
  private static recursiveSearch(objMap: Map<string, Object>, propertyName: string): Object[] {
    const results: Object[] = [];

    const search = (currentMap: Map<string, Object>) => {
      currentMap.forEach((val: Object, key: string) => {
        if (key === propertyName) {
          results.push(val);
        }

        if (Array.isArray(val)) {
          const arrMap = JsonPathParser.convertArrayToMap(val);
          search(arrMap);
        } else if (typeof val === 'object' && val !== null) {
          const childMap = JsonPathParser.convertToMap(val);
          search(childMap);
        }
      });
    };

    search(objMap);
    return results;
  }
}

interface PathSegment {
  type: 'property' | 'index' | 'wildcard' | 'recursive';
  name?: string;
  index?: number;
}
