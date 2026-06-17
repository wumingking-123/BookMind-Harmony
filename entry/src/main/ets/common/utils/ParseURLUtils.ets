import { BookSource } from '../../database/entities/BookSource';
import AppPattern from '../constants/AppPattern';
import { parseSearchString, SearchConfig } from '../model/SearchConfig';
import networkUtil from './NetworkUtils';
import { encodeToGbk } from './GbkEncoder';

export interface IParseURL {
  baseUrl: string
  searchUrl: string
  page: number
  keyword: string
  removeCookie?: boolean
  bookSource:BookSource
  speakText?:string
  speakSpeed?:number
}

export class ParseURL {
  baseUrl: string = '';
  searchUrl: string = '';
  page: number = 1;
  keyword: string = '';
  removeCookie?: boolean = false;
  speakText?:string
  speakSpeed?:number
  bookSource?:BookSource;
  constructor(parseUrl?: IParseURL) {
    this.baseUrl = parseUrl?.baseUrl || '';
    this.searchUrl = parseUrl?.searchUrl || '';
    this.page = parseUrl?.page || 1;
    this.keyword = parseUrl?.keyword || '';
    this.removeCookie = parseUrl?.removeCookie;
    this.bookSource = parseUrl?.bookSource;
    this.speakText = parseUrl?.speakText
    this.speakSpeed = parseUrl?.speakSpeed
  }
}
export class ParseURLUtils {
  parseURL: ParseURL = new ParseURL();
  ruleUrl:string = ''
  url:string = ''
  private init(){
    let urlMatcher = this.parseURL.baseUrl.match(AppPattern.pattern)
    if (urlMatcher && urlMatcher.length > 0) {
      this.parseURL.baseUrl = this.parseURL.baseUrl.substring(0, urlMatcher.index);
    }
    this.ruleUrl = networkUtil.cleanUrl(this.parseURL.searchUrl);
    this.url =  networkUtil.cleanUrl(this.parseURL.baseUrl);
  }

  setParseURL(value: ParseURL) {
    this.parseURL = value;
  }

  extractAndReplace(ruleUrl: string): string {
    if (ruleUrl.startsWith("{{")) {
      const end = ruleUrl.indexOf("}}");
      if (end !== -1) {
        const result = ruleUrl.replace(/{{[^}]*}}/, '');
        return result ?? '';
      }
    }
    return ruleUrl;
  }

  replacePlaceholders(str: string, placeholder: string, replacement: string): string {
    const regex = new RegExp(placeholder, 'g');
    return str.replace(regex, replacement);
  }

  buildBaseUrl(baseUrl: string, path: string, body: string): string {
    const ensureNoLeadingSlash = (str: string) => str.replace(/^\/+/, '');
    const ensureNoTrailingSlash = (str: string) => str.replace(/\/+$/, '');

    if (path) {
      if (!path.startsWith('http://') && !path.startsWith('https://')) {
        path = ensureNoTrailingSlash(baseUrl) + '/' + ensureNoLeadingSlash(path);
      } else {
        path = ensureNoTrailingSlash(path);
      }
    } else {
      path = ensureNoTrailingSlash(baseUrl);
    }

    if (path && body) {
      if (!path.endsWith('/') && !body.startsWith('/')) {
        //需要校验path如果结尾是/就替换为? 如果没有/就添加?
        if (path.endsWith('/')) {
          path = path.slice(0, -1);
        }
        path += '?';
      } else if (path.endsWith('/') && body.startsWith('/')) {
        body = ensureNoLeadingSlash(body);
      }
    }
    return ensureNoTrailingSlash(path + body);
  }

  processRuleUrl(): SearchConfig|string {
    this.init()
    let baseUrl = ''
    let searchUrl = this.ruleUrl
    searchUrl = this.extractAndReplace(searchUrl)
    try {
      let parseSearch = parseSearchString(searchUrl)
      console.log('[ParseURLUtils] parseSearchString body: ' + parseSearch.body)
      // 使用书源的charset覆盖默认值
      if (this.parseURL.bookSource?.charset) {
        parseSearch.charset = this.parseURL.bookSource.charset
      }
      // 使用书源的header配置
      if (this.parseURL.bookSource?.header) {
        try {
          // 解析header配置（可能是JSON字符串或JS表达式）
          const headerStr = this.parseURL.bookSource.header
          if (headerStr.startsWith('{') || headerStr.startsWith('@js:')) {
            // 简单处理：如果是@js:开头，跳过；如果是JSON，直接解析
            if (headerStr.startsWith('{')) {
              parseSearch.headers = JSON.parse(headerStr)
            }
          }
        } catch (e) {
          console.log('[ParseURLUtils] 解析header失败: ' + (e as Error).message)
        }
      }
      baseUrl = this.buildBaseUrl(this.url, parseSearch.path, parseSearch.method === 'POST' ? '' : parseSearch.body);
      // 根据charset编码keyword（GBK需要特殊编码）
      const isGbk = parseSearch.charset.toUpperCase() === 'GBK'
      const encodedKeyword = isGbk ? encodeToGbk(this.parseURL.keyword) : encodeURIComponent(this.parseURL.keyword)
      baseUrl = this.replacePlaceholders(baseUrl, '{{key}}', encodedKeyword);
      baseUrl = this.replacePlaceholders(baseUrl, '{{page}}', this.parseURL.page.toString());
      baseUrl = networkUtil.getAbsoluteURL(this.url, baseUrl)
      parseSearch.url = baseUrl
      parseSearch.body = this.replacePlaceholders(parseSearch.body, '{{key}}', encodedKeyword);
      parseSearch.body = this.replacePlaceholders(parseSearch.body, '{{page}}', this.parseURL.page.toString());
      console.log('[ParseURLUtils] 最终body: ' + parseSearch.body)
      return parseSearch;
    } catch (e){
      const charset = this.parseURL.bookSource?.charset?.toUpperCase() || 'UTF-8'
      const isGbk = charset === 'GBK'
      const encodedKeyword = isGbk ? encodeToGbk(this.parseURL.keyword) : encodeURIComponent(this.parseURL.keyword)
      baseUrl = this.buildBaseUrl(this.url, searchUrl, '')
      baseUrl = this.replacePlaceholders(baseUrl, '{{key}}', encodedKeyword);
      baseUrl = this.replacePlaceholders(baseUrl, '{{page}}', this.parseURL.page.toString());
      return baseUrl
    }
  }
}