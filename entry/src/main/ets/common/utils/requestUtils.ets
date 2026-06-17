/**
 * @author 2008
 * @datetime 2024/8/16 11:49
 * @className: requestUtils
 */
import axios, { AxiosRequestConfig, AxiosResponse } from '@ohos/axios';
import { http } from '@kit.NetworkKit';
import { SearchConfig } from '../model/SearchConfig';
import { util } from '@kit.ArkTS';

class requestUtils {

  private generateRandomCookie(): string {
    const randomValue = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15)
    return `random-cookie=${randomValue}`
  }

  private getHeaders(): Record<string, string> {
    return {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
      'Accept': 'text/html,*/*',
      'Accept-Encoding': 'gzip, deflate',
      'Accept-Language': 'zh-CN,zh;q=0.9'
    }
  }

  /**
   * 两步搜索：axios发POST获取响应，从中提取searchid，再GET获取结果
   */
  async requestPostWithRedirect(url: string, body: string, charset: string): Promise<string> {
    console.log('[requestPostWithRedirect] URL: ' + url)
    console.log('[requestPostWithRedirect] body: ' + body)

    // 第一步：用axios发POST获取响应
    let response: AxiosResponse<ArrayBuffer>
    const postHeaders: Record<string, string> = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': '*/*'
    }
    const postOptions: AxiosRequestConfig = {
      headers: postHeaders,
      responseType: 'array_buffer',
      timeout: 15000
    }
    try {
      response = await axios.post(url, body || '', postOptions)
    } catch (e) {
      let errMsg = (e as Error).message
      console.log('[requestPostWithRedirect] POST异常: ' + errMsg)
      throw new Error(errMsg)
    }
    let decoded = this.textDecoder(response.data, charset || 'UTF-8')
    console.log('[requestPostWithRedirect] POST状态码: ' + response.status + ', 响应长度: ' + decoded.length)
    if (decoded.length > 0) {
      console.log('[requestPostWithRedirect] POST响应前200字符: ' + decoded.substring(0, 200))
    }

    // 第二步：检查响应是否包含searchid（帝国CMS两步搜索模式）
    let searchidMatch: RegExpMatchArray | null = decoded.match(/searchid=(\d+)/)
    if (searchidMatch) {
      let searchid = searchidMatch[1]
      let baseUrl = url.substring(0, url.lastIndexOf('/') + 1)
      let resultUrl = baseUrl + 'result/?searchid=' + searchid
      console.log('[requestPostWithRedirect] 从响应体提取到searchid: ' + searchid + ', 请求: ' + resultUrl)
      const getOptions: AxiosRequestConfig = {
        responseType: 'array_buffer',
        timeout: 15000
      }
      let getResponse: AxiosResponse<ArrayBuffer> = await axios.get(resultUrl, getOptions)
      let getDecoded = this.textDecoder(getResponse.data, charset || 'UTF-8')
      console.log('[requestPostWithRedirect] 结果页响应长度: ' + getDecoded.length)
      if (getDecoded.length > 0) {
        console.log('[requestPostWithRedirect] 结果页前200字符: ' + getDecoded.substring(0, 200))
      }
      return getDecoded
    }

    return decoded
  }

  private addPostHeader(options: AxiosRequestConfig): void {
    if (options.headers) {
      options.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    }
  }

  async requestHtml(config: SearchConfig): Promise<string> {
    // 使用配置中的headers，如果没有则使用默认headers
    let headers: Record<string, string> = this.getHeaders()
    if (config.headers) {
      const keys = Object.keys(config.headers)
      for (let i = 0; i < keys.length; i++) {
        headers[keys[i]] = config.headers[keys[i]]
      }
    }
    // 从URL提取Referer
    try {
      const urlMatch = config.url.match(/^(https?:\/\/[^\/]+)/)
      if (urlMatch) {
        headers['Referer'] = urlMatch[1] + '/'
      }
    } catch (e) {
      // ignore
    }

    const requestMethod: string = config.method ? config.method.toUpperCase() : 'POST';

    if (requestMethod === 'GET') {
      const requestOptions: AxiosRequestConfig = {
        headers: headers,
        responseType: 'array_buffer',
        timeout: 15000
      };
      try {
        const response: AxiosResponse<ArrayBuffer> = await axios.get<ArrayBuffer>(config.url, requestOptions);
        console.log('[requestHtml] 响应状态码: ' + response.status)
        return this.textDecoder(response.data, config.charset ?? 'UTF-8')
      } catch (e) {
        let errMsg = (e as Error).message;
        console.log('[requestHtml] GET失败, 尝试POST: ' + errMsg)
        this.addPostHeader(requestOptions)
        const response: AxiosResponse<ArrayBuffer> = await axios.post<ArrayBuffer>(config.url, config.body || '', requestOptions);
        console.log('[requestHtml] 响应状态码: ' + response.status)
        return this.textDecoder(response.data, config.charset ?? 'UTF-8')
      }
    } else {
      // 使用原生HTTP API发送POST请求，保持body中的URL编码
      console.log('[requestHtml] 使用原生HTTP API POST')
      headers['Content-Type'] = 'application/x-www-form-urlencoded'
      return await this.requestPostNative(config.url, config.body || '', headers, config.charset ?? 'UTF-8')
    }
  }

  async requestUrlHtml(url: string, charset?: string): Promise<string> {
    console.log('[requestUrlHtml] 请求URL: ' + url)
    const requestOptions: AxiosRequestConfig = {
      headers: this.getHeaders(),
      responseType: 'array_buffer',
      timeout: 15000
    }
    let response: AxiosResponse<ArrayBuffer>
    try {
      response = await axios.get<ArrayBuffer>(url, requestOptions)
    } catch (e) {
      let errMsg = (e as Error).message;
      console.log('[requestUrlHtml] GET失败, 尝试POST: ' + errMsg)
      this.addPostHeader(requestOptions)
      response = await axios.post<ArrayBuffer>(url, requestOptions)
    }
    const encoding = charset || this.detectCharset(response) || 'UTF-8'
    console.log('[requestUrlHtml] 检测到编码: ' + encoding)
    return this.textDecoder(response.data, encoding)
  }

  private detectCharset(response: AxiosResponse<ArrayBuffer>): string {
    // 从Content-Type头检测编码
    const contentType: string = (response.headers?.['content-type'] as string) || ''
    const charsetMatch: RegExpMatchArray | null = contentType.match(/charset=([^\s;]+)/i)
    if (charsetMatch) {
      return charsetMatch[1].toUpperCase()
    }
    // 用多种编码尝试从HTML meta标签检测
    const encodings = ['UTF-8', 'GBK', 'GB2312', 'GB18030']
    for (const enc of encodings) {
      try {
        const raw = this.textDecoder(response.data, enc)
        const metaMatch = raw.match(/charset=["']?([^"'\s;>]+)/i)
        if (metaMatch) {
          return metaMatch[1].toUpperCase()
        }
      } catch (e) {
        // 该编码不支持，继续尝试下一个
      }
    }
    return ''
  }

  /**
   * 使用原生HTTP API发送POST请求
   * 保持body中的URL编码不被解码
   */
  async requestPostNative(url: string, body: string, headers: Record<string, string>, charset: string): Promise<string> {
    console.log('[requestPostNative] URL: ' + url)
    console.log('[requestPostNative] body: ' + body)

    const httpRequest = http.createHttp()
    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: body,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 15000,
        readTimeout: 15000
      }

      const response = await httpRequest.request(url, options)
      console.log('[requestPostNative] 响应状态码: ' + response.responseCode)

      // 获取响应体
      const result = response.result as ArrayBuffer
      if (result) {
        const decoded = this.textDecoder(result, charset || 'UTF-8')
        console.log('[requestPostNative] 解码后响应长度: ' + decoded.length)
        return decoded
      }

      throw new Error('响应体为空')
    } catch (e) {
      const errMsg = (e as Error).message
      console.log('[requestPostNative] 请求失败: ' + errMsg)
      throw new Error(errMsg)
    } finally {
      httpRequest.destroy()
    }
  }

  private textDecoder(data: ArrayBuffer, encoding: string = 'UTF-8'): string {
    let textDecoder = util.TextDecoder.create(encoding, { ignoreBOM: true });
    const result = new Uint8Array(data);
    let decodedText = textDecoder.decodeWithStream(result);
    return decodedText
  }
}

const requestUtil = new requestUtils();
export default requestUtil as requestUtils;
