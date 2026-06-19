import dataPreferences from '@ohos.data.preferences';
import http from '@ohos.net.http'

export interface AiConfig {
  baseUrl: string
  apiKey: string
  model: string
  maxTokens: number
  temperature: number
  systemPrompt: string
  enableTools: boolean
  disableThinking: boolean
}

export class TestResult {
  success: boolean = false
  message: string = ''
  constructor(success: boolean, message: string) {
    this.success = success
    this.message = message
  }
}

class TestMessage {
  role: string = ''
  content: string = ''
  constructor(role: string, content: string) {
    this.role = role
    this.content = content
  }
}

const PREF_NAME = 'ai_reading_config'
const KEY_BASE_URL = 'ai_base_url'
const KEY_API_KEY = 'ai_api_key'
const KEY_MODEL = 'ai_model'
const KEY_MAX_TOKENS = 'ai_max_tokens'
const KEY_TEMPERATURE = 'ai_temperature'
const KEY_SYSTEM_PROMPT = 'ai_system_prompt'
const KEY_ENABLE_TOOLS = 'ai_enable_tools'
const KEY_DISABLE_THINKING = 'ai_disable_thinking'

const DEFAULT_BASE_URL = 'https://api.openai.com/v1'
const DEFAULT_MODEL = 'gpt-4o-mini'
const DEFAULT_MAX_TOKENS = 4096
const DEFAULT_TEMPERATURE = 0.7
const DEFAULT_SYSTEM_PROMPT = '你是一个专业的阅读助手，帮助用户理解正在阅读的书籍内容。用户会提供当前阅读的上下文，你可以调用工具获取更多上下文。回答要简洁、准确、有条理，使用 Markdown 格式。'
const DEFAULT_ENABLE_TOOLS = true
const DEFAULT_DISABLE_THINKING = false

class AiConfigUtils {
  private preferences: dataPreferences.Preferences | null = null

  private init(): void {
    if (this.preferences === null) {
      this.preferences = dataPreferences.getPreferencesSync(getContext(), { name: PREF_NAME })
    }
  }

  getConfig(): AiConfig {
    this.init()
    const config: AiConfig = {
      baseUrl: (this.preferences!.getSync(KEY_BASE_URL, DEFAULT_BASE_URL) as string),
      apiKey: (this.preferences!.getSync(KEY_API_KEY, '') as string),
      model: (this.preferences!.getSync(KEY_MODEL, DEFAULT_MODEL) as string),
      maxTokens: (this.preferences!.getSync(KEY_MAX_TOKENS, DEFAULT_MAX_TOKENS) as number),
      temperature: (this.preferences!.getSync(KEY_TEMPERATURE, DEFAULT_TEMPERATURE) as number),
      systemPrompt: (this.preferences!.getSync(KEY_SYSTEM_PROMPT, DEFAULT_SYSTEM_PROMPT) as string),
      enableTools: (this.preferences!.getSync(KEY_ENABLE_TOOLS, DEFAULT_ENABLE_TOOLS) as boolean),
      disableThinking: (this.preferences!.getSync(KEY_DISABLE_THINKING, DEFAULT_DISABLE_THINKING) as boolean),
    }
    return config
  }

  saveConfig(config: AiConfig): void {
    this.init()
    this.preferences!.putSync(KEY_BASE_URL, config.baseUrl)
    this.preferences!.putSync(KEY_API_KEY, config.apiKey)
    this.preferences!.putSync(KEY_MODEL, config.model)
    this.preferences!.putSync(KEY_MAX_TOKENS, config.maxTokens)
    this.preferences!.putSync(KEY_TEMPERATURE, config.temperature)
    this.preferences!.putSync(KEY_SYSTEM_PROMPT, config.systemPrompt)
    this.preferences!.putSync(KEY_ENABLE_TOOLS, config.enableTools)
    this.preferences!.putSync(KEY_DISABLE_THINKING, config.disableThinking)
    this.preferences!.flush()
  }

  isConfigured(): boolean {
    const config = this.getConfig()
    return config.baseUrl.length > 0 && config.apiKey.length > 0 && config.model.length > 0
  }

  async testConnection(): Promise<TestResult> {
    const config = this.getConfig()
    if (config.apiKey.length === 0) {
      return new TestResult(false, 'API Key 不能为空')
    }
    if (config.baseUrl.length === 0) {
      return new TestResult(false, 'Base URL 不能为空')
    }
    try {
      const httpRequest = http.createHttp()
      const url = config.baseUrl.replace(/\/+$/, '') + '/chat/completions'

      const testMsg = new TestMessage('user', 'Hi')
      const messages: TestMessage[] = [testMsg]
      const requestBody: Record<string, Object> = {}
      requestBody['model'] = config.model
      requestBody['messages'] = messages
      requestBody['max_tokens'] = 5
      requestBody['stream'] = false
      const body = JSON.stringify(requestBody)

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + config.apiKey
        } as Record<string, string>,
        extraData: body,
        connectTimeout: 10000,
        readTimeout: 15000,
        expectDataType: http.HttpDataType.STRING
      })
      httpRequest.destroy()
      const code = response.responseCode
      if (code >= 200 && code < 300) {
        return new TestResult(true, '连接成功 (HTTP ' + code + ')')
      }
      let errMsg = 'HTTP ' + code
      try {
        const respStr = typeof response.result === 'string' ? response.result : ''
        if (respStr.length > 0) {
          const respObj = JSON.parse(respStr) as Record<string, Object>
          if (respObj.error) {
            const errObj = respObj.error as Record<string, string>
            if (errObj.message) {
              errMsg = errObj.message
            }
          }
        }
      } catch (e) {}
      return new TestResult(false, errMsg)
    } catch (e) {
      return new TestResult(false, '连接失败: ' + (e as Error).message)
    }
  }
}

const aiConfigUtils = new AiConfigUtils()
export default aiConfigUtils as AiConfigUtils

