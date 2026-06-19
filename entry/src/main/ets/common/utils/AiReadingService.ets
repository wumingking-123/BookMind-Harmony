import { AiConfig } from './AiConfigUtils'
import aiConfigUtils from './AiConfigUtils'
import http from '@ohos.net.http'
import dataPreferences from '@ohos.data.preferences'
import { util } from '@kit.ArkTS'

export interface ChatMessage {
  role: string
  content: string
  tool_calls?: ToolCall[]
  tool_call_id?: string
  name?: string
}

export interface ToolCall {
  id: string
  type: string
  function: ToolFunctionCall
}

export interface ToolFunctionCall {
  name: string
  arguments: string
}

export interface ToolDefinition {
  type: string
  function: ToolFunctionDef
}

export interface ToolFunctionDef {
  name: string
  description: string
  parameters: object
}

export interface ToolExecutionContext {
  currentChapterIndex: number
  currentPageIndex: number
  chapterList: ChapterInfo[]
}

export interface ChapterInfo {
  index: number
  title: string
  content: string
  pageList: string[][]
}

export interface StreamEvent {
  type: string
  content?: string
  toolCallName?: string
  toolCallArgs?: string
  toolResult?: string
  done?: boolean
  error?: string
  thinking?: string
}

type StreamCallback = (event: StreamEvent) => void

export class ParseResult {
  fullContent: string = ''
  toolCalls: ToolCall[] = []
}

const MAX_HISTORY_ROUNDS = 15

export interface ChatBubble {
  role: string
  content: string
  isStreaming: boolean
  toolCallName?: string
  toolCallArgs?: string
  toolResult?: string
  isError: boolean
  timestamp: number
}

export class SessionState {
  conversationHistory: ChatMessage[] = new Array()
  uiBubbles: ChatBubble[] = new Array()
  abortFlag: boolean = false
  isLoading: boolean = false
  streamingContent: string = ''
  streamBubbleIndex: number = -1
}

export interface PersistedSessionData {
  conversationHistory: ChatMessage[]
  uiBubbles: ChatBubble[]
}

const PREF_NAME_HISTORY = 'ai_reading_history_v3'

export type UiStateListener = (bubbles: ChatBubble[], isLoading: boolean) => void

class AiReadingService {
  private sessions: Map<string, SessionState> = new Map()
  private listeners: Map<string, UiStateListener> = new Map()

  private getSession(bookUrl: string): SessionState {
    if (!this.sessions.has(bookUrl)) {
      this.sessions.set(bookUrl, new SessionState())
    }
    return this.sessions.get(bookUrl)!
  }

  async initSession(bookUrl: string): Promise<void> {
    if (!bookUrl) return;
    try {
      const pref = dataPreferences.getPreferencesSync(getContext(), { name: PREF_NAME_HISTORY })
      const dataStr = pref.getSync(bookUrl, '') as string
      if (dataStr && dataStr.length > 0) {
        const data = JSON.parse(dataStr) as Record<string, Object>
        const session = this.getSession(bookUrl)
        if (data.conversationHistory) {
          session.conversationHistory = data.conversationHistory as ChatMessage[]
        }
        if (data.uiBubbles) {
          session.uiBubbles = data.uiBubbles as ChatBubble[]
          // Reset streaming states on load
          for (let bubble of session.uiBubbles) {
            bubble.isStreaming = false
          }
        }
        session.isLoading = false
        session.abortFlag = false
      }
    } catch (e) {
      console.error('Failed to init session for ' + bookUrl, e)
    }
  }

  saveSession(bookUrl: string): void {
    if (!bookUrl) return;
    try {
      const session = this.getSession(bookUrl)
      // Only persist clean user/assistant messages (no tool/tool_calls)
      // to avoid 400 errors when replaying incomplete tool call sequences
      const cleanHistory: ChatMessage[] = new Array()
      for (let i = 0; i < session.conversationHistory.length; i++) {
        const msg = session.conversationHistory[i]
        if (msg.role === 'user') {
          cleanHistory.push(msg)
        } else if (msg.role === 'assistant' && !msg.tool_calls) {
          cleanHistory.push(msg)
        }
        // Skip 'tool' role messages and assistant messages with tool_calls
        // They cannot be replayed without matching tool definitions
      }
      const data: PersistedSessionData = {
        conversationHistory: cleanHistory,
        uiBubbles: session.uiBubbles
      }
      const pref = dataPreferences.getPreferencesSync(getContext(), { name: PREF_NAME_HISTORY })
      pref.putSync(bookUrl, JSON.stringify(data))
      pref.flush()
    } catch (e) {
      console.error('Failed to save session for ' + bookUrl, e)
    }
  }

  getBubbles(bookUrl: string): ChatBubble[] {
    return this.getSession(bookUrl).uiBubbles
  }

  isLoading(bookUrl: string): boolean {
    return this.getSession(bookUrl).isLoading
  }

  registerListener(bookUrl: string, listener: UiStateListener): void {
    this.listeners.set(bookUrl, listener)
    listener(this.getSession(bookUrl).uiBubbles, this.getSession(bookUrl).isLoading)
  }

  unregisterListener(bookUrl: string): void {
    this.listeners.delete(bookUrl)
  }

  notifyListener(bookUrl: string): void {
    const listener = this.listeners.get(bookUrl)
    if (listener) {
      const session = this.getSession(bookUrl)
      // Pass a new array reference to trigger UI update
      listener([...session.uiBubbles], session.isLoading)
    }
  }

  abort(bookUrl: string): void {
    const session = this.getSession(bookUrl)
    session.abortFlag = true
    session.isLoading = false
    if (session.streamBubbleIndex >= 0 && session.uiBubbles[session.streamBubbleIndex]) {
      session.uiBubbles[session.streamBubbleIndex].isStreaming = false
    }
    this.notifyListener(bookUrl)
  }

  clearConversation(bookUrl: string): void {
    const session = this.getSession(bookUrl)
    session.conversationHistory = new Array()
    session.uiBubbles = new Array()
    session.isLoading = false
    session.abortFlag = false
    this.saveSession(bookUrl)
    this.notifyListener(bookUrl)
  }

  private getToolDefinitions(): ToolDefinition[] {
    const tools: ToolDefinition[] = new Array()

    tools.push({
      type: 'function',
      function: {
        name: 'get_previous_context',
        description: '获取当前阅读位置之前约2000字的内容，用于理解前文剧情或背景',
        parameters: {
          "type": "object",
          "properties": {} as Record<string, Object>,
          "required": new Array<string>()
        } as Record<string, Object>
      } as ToolFunctionDef
    } as ToolDefinition)

    tools.push({
      type: 'function',
      function: {
        name: 'get_next_context',
        description: '获取当前阅读位置之后约2000字的内容，用于了解后续发展',
        parameters: {
          "type": "object",
          "properties": {} as Record<string, Object>,
          "required": new Array<string>()
        } as Record<string, Object>
      } as ToolFunctionDef
    } as ToolDefinition)

    tools.push({
      type: 'function',
      function: {
        name: 'get_full_chapter',
        description: '获取当前正在阅读的章节的完整内容',
        parameters: {
          "type": "object",
          "properties": {} as Record<string, Object>,
          "required": new Array<string>()
        } as Record<string, Object>
      } as ToolFunctionDef
    } as ToolDefinition)

    const indexProps: Record<string, Object> = {}
    indexProps["chapter_index"] = {
      "type": "number",
      "description": "章节索引（从0开始）"
    } as Record<string, Object>

    tools.push({
      type: 'function',
      function: {
        name: 'get_chapter_by_index',
        description: '根据章节索引获取指定章节的完整内容',
        parameters: {
          "type": "object",
          "properties": indexProps,
          "required": ["chapter_index"]
        } as Record<string, Object>
      } as ToolFunctionDef
    } as ToolDefinition)

    tools.push({
      type: 'function',
      function: {
        name: 'get_chapter_list',
        description: '获取当前书籍的章节目录列表（标题和索引）',
        parameters: {
          "type": "object",
          "properties": {} as Record<string, Object>,
          "required": new Array<string>()
        } as Record<string, Object>
      } as ToolFunctionDef
    } as ToolDefinition)

    return tools
  }

  private executeTool(toolName: string, args: string, ctx: ToolExecutionContext): string {
    let parsedArgs: Record<string, Object> = {}
    try {
      parsedArgs = JSON.parse(args)
    } catch (e) {
      return '参数解析失败'
    }

    if (toolName === 'get_previous_context') {
      return this.getPreviousContext(ctx)
    }
    if (toolName === 'get_next_context') {
      return this.getNextContext(ctx)
    }
    if (toolName === 'get_full_chapter') {
      return this.getFullChapter(ctx)
    }
    if (toolName === 'get_chapter_by_index') {
      const idx = Number(parsedArgs.chapter_index)
      return this.getChapterByIndex(ctx, idx)
    }
    if (toolName === 'get_chapter_list') {
      return this.getChapterList(ctx)
    }
    return '未知工具: ' + toolName
  }

  private getPreviousContext(ctx: ToolExecutionContext): string {
    const chapter = ctx.chapterList.find(c => c.index === ctx.currentChapterIndex)
    if (!chapter) return '无法获取当前章节'
    const allPages = chapter.pageList
    let text = ''
    for (let i = 0; i < ctx.currentPageIndex && i < allPages.length; i++) {
      if (allPages[i]) {
        text += allPages[i].join('\n') + '\n'
      }
    }
    if (ctx.currentChapterIndex > 0) {
      const prevChapter = ctx.chapterList.find(c => c.index === ctx.currentChapterIndex - 1)
      if (prevChapter && prevChapter.content.length > 0) {
        const prevText = prevChapter.content
        const remain = 2000 - text.length
        if (remain > 0) {
          text = prevText.substring(Math.max(0, prevText.length - remain)) + text
        }
      }
    }
    if (text.length > 2000) {
      text = text.substring(text.length - 2000)
    }
    return text.length > 0 ? text : '已经是开头的最前面了，没有更多前文内容'
  }

  private getNextContext(ctx: ToolExecutionContext): string {
    const chapter = ctx.chapterList.find(c => c.index === ctx.currentChapterIndex)
    if (!chapter) return '无法获取当前章节'
    const allPages = chapter.pageList
    let text = ''
    for (let i = ctx.currentPageIndex + 1; i < allPages.length; i++) {
      if (allPages[i]) {
        text += allPages[i].join('\n') + '\n'
        if (text.length >= 2000) break
      }
    }
    if (text.length < 2000 && ctx.currentChapterIndex < ctx.chapterList.length - 1) {
      const nextChapter = ctx.chapterList.find(c => c.index === ctx.currentChapterIndex + 1)
      if (nextChapter && nextChapter.content.length > 0) {
        const remain = 2000 - text.length
        if (remain > 0) {
          text += nextChapter.content.substring(0, remain)
        }
      }
    }
    if (text.length > 2000) {
      text = text.substring(0, 2000)
    }
    return text.length > 0 ? text : '已经是最后一页了，没有更多后续内容'
  }

  private getFullChapter(ctx: ToolExecutionContext): string {
    const chapter = ctx.chapterList.find(c => c.index === ctx.currentChapterIndex)
    if (!chapter) return '无法获取当前章节'
    let text = ''
    for (let i = 0; i < chapter.pageList.length; i++) {
      if (chapter.pageList[i]) {
        text += chapter.pageList[i].join('\n') + '\n'
      }
    }
    return text.length > 0 ? text : '当前章节无内容'
  }

  private getChapterByIndex(ctx: ToolExecutionContext, index: number): string {
    if (index < 0 || index >= ctx.chapterList.length) {
      return '章节索引超出范围，有效范围: 0-' + (ctx.chapterList.length - 1)
    }
    const chapter = ctx.chapterList.find(c => c.index === index)
    if (!chapter) return '未找到章节 ' + index
    let text = '【' + chapter.title + '】\n\n'
    for (let i = 0; i < chapter.pageList.length; i++) {
      if (chapter.pageList[i]) {
        text += chapter.pageList[i].join('\n') + '\n'
      }
    }
    return text
  }

  private getChapterList(ctx: ToolExecutionContext): string {
    let text = '章节目录（共' + ctx.chapterList.length + '章）:\n'
    for (let i = 0; i < ctx.chapterList.length; i++) {
      const ch = ctx.chapterList[i]
      text += '[' + ch.index + '] ' + ch.title + '\n'
    }
    return text
  }

  private buildInitialContext(ctx: ToolExecutionContext): string {
    const chapter = ctx.chapterList.find(c => c.index === ctx.currentChapterIndex)
    if (!chapter) return '无法获取阅读内容'
    const allPages = chapter.pageList
    let prevText = ''
    for (let i = 0; i < ctx.currentPageIndex && i < allPages.length; i++) {
      if (allPages[i]) {
        prevText += allPages[i].join('\n') + '\n'
      }
    }
    if (prevText.length > 1000) {
      prevText = prevText.substring(prevText.length - 1000)
    }
    let currentText = ''
    if (allPages[ctx.currentPageIndex]) {
      currentText = allPages[ctx.currentPageIndex].join('\n')
    }
    let nextText = ''
    if (ctx.currentPageIndex + 1 < allPages.length && allPages[ctx.currentPageIndex + 1]) {
      nextText = allPages[ctx.currentPageIndex + 1].join('\n')
    }
    if (nextText.length > 1000) {
      nextText = nextText.substring(0, 1000)
    }
    let context = '当前阅读: 《' + (chapter.title || '未知') + '》\n\n'
    if (prevText.length > 0) {
      context += '【前文】\n' + prevText + '\n\n'
    }
    context += '【当前页】\n' + currentText + '\n\n'
    if (nextText.length > 0) {
      context += '【后文】\n' + nextText
    }
    return context
  }

  async chat(
    bookUrl: string,
    userInput: string,
    ctx: ToolExecutionContext
  ): Promise<void> {
    const session = this.getSession(bookUrl)
    session.abortFlag = false
    const config = aiConfigUtils.getConfig()

    if (!aiConfigUtils.isConfigured()) {
      const errBubble: ChatBubble = {
        role: 'assistant', content: '请先在设置中配置 AI 阅读助手的 API 参数',
        isStreaming: false, isError: true, timestamp: Date.now()
      }
      session.uiBubbles.push(errBubble)
      this.notifyListener(bookUrl)
      return
    }

    const userBubble: ChatBubble = {
      role: 'user', content: userInput, isStreaming: false, isError: false, timestamp: Date.now()
    }
    session.uiBubbles.push(userBubble)

    const assistantBubble: ChatBubble = {
      role: 'assistant', content: '正在思考...', isStreaming: true, isError: false, timestamp: Date.now()
    }
    session.uiBubbles.push(assistantBubble)
    session.streamBubbleIndex = session.uiBubbles.length - 1

    session.isLoading = true
    session.streamingContent = ''
    this.notifyListener(bookUrl)

    const initialContext = this.buildInitialContext(ctx)
    const contextMessage: ChatMessage = {
      role: 'system',
      content: config.systemPrompt + '\n\n以下是用户当前阅读的最新上下文（约上下2000字）：\n\n' + initialContext
    }

    const userMsg: ChatMessage = { role: 'user', content: userInput }
    session.conversationHistory.push(userMsg)

    while (session.conversationHistory.length > MAX_HISTORY_ROUNDS * 2) {
      session.conversationHistory.shift()
    }

    const messages: ChatMessage[] = new Array()
    messages.push(contextMessage)
    for (let i = 0; i < session.conversationHistory.length; i++) {
      messages.push(session.conversationHistory[i])
    }

    const tools = this.getToolDefinitions()

    await this.callApiWithTools(config, messages, tools, ctx, bookUrl, 0)
  }

  private async callApiWithTools(
    config: AiConfig,
    messages: ChatMessage[],
    tools: ToolDefinition[],
    ctx: ToolExecutionContext,
    bookUrl: string,
    depth: number
  ): Promise<void> {
    const session = this.getSession(bookUrl)

    if (session.abortFlag) {
      if (session.streamBubbleIndex >= 0) {
        session.uiBubbles[session.streamBubbleIndex].isStreaming = false
        session.uiBubbles[session.streamBubbleIndex].isError = true
        session.uiBubbles[session.streamBubbleIndex].content = '已取消'
      }
      session.isLoading = false
      this.notifyListener(bookUrl)
      return
    }
    if (depth > 5) {
      if (session.streamBubbleIndex >= 0) {
        session.uiBubbles[session.streamBubbleIndex].isStreaming = false
        session.uiBubbles[session.streamBubbleIndex].isError = true
        session.uiBubbles[session.streamBubbleIndex].content = '工具调用嵌套过深'
      }
      session.isLoading = false
      this.notifyListener(bookUrl)
      return
    }

    const url = config.baseUrl.replace(/\/+$/, '') + '/chat/completions'
    const requestBody: Record<string, Object> = {}
    requestBody['model'] = config.model
    requestBody['messages'] = messages
    requestBody['stream'] = true
    requestBody['temperature'] = config.temperature
    requestBody['max_tokens'] = config.maxTokens
    
    if (config.enableTools) {
      requestBody['tools'] = tools
      requestBody['tool_choice'] = 'auto'
    }
    if (config.disableThinking) {
      const thinkingOptions: Record<string, string> = {}
      thinkingOptions['type'] = 'disabled'
      requestBody['thinking'] = thinkingOptions
    }

    const bodyStr = JSON.stringify(requestBody)
    console.info('[AiReadingService] Calling API: ' + url + ', model: ' + config.model + ', depth: ' + depth)

    try {
      const httpRequest = http.createHttp()
      const textDecoder = util.TextDecoder.create('UTF-8', { ignoreBOM: true })
      let bufferStr = ''
      let toolCallsArray: ToolCall[] = new Array()
      let streamError = ''
      let resolved = false
      await new Promise<void>((resolve, reject) => {
        httpRequest.on('headersReceive', (header: Object) => {
          console.info('[AiReadingService] Headers received')
        })

        httpRequest.on('dataReceive', (data: ArrayBuffer) => {
          if (session.abortFlag) {
            httpRequest.destroy()
            if (!resolved) { resolved = true; resolve() }
            return
          }
          const chunk = textDecoder.decodeWithStream(new Uint8Array(data))
          bufferStr += chunk
          const lines = bufferStr.split('\n')
          bufferStr = lines.pop() || ''

          for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim()
            if (line.length === 0) continue
            if (line.startsWith('data: ')) {
              const dataStr = line.substring(6)
              if (dataStr === '[DONE]') continue
              try {
                const obj = JSON.parse(dataStr) as Record<string, Object>
                const choices = obj.choices as object[]
                if (choices && choices.length > 0) {
                  const choiceObj = choices[0] as Record<string, Object>
                  const delta = choiceObj.delta as Record<string, Object>
                  if (!delta) continue

                  // 跳过思考内容，不显示给用户
                  if (delta.reasoning_content) {
                    continue
                  }

                  if (delta.content) {
                    let content = delta.content as string
                    // 移除可能残留的 <think> 标签
                    content = content.replace(/<think>[\s\S]*?<\/think>/g, '')
                    content = content.replace(/<think>[\s\S]*$/g, '')
                    if (content.length === 0) continue
                    session.streamingContent += content
                    if (session.streamBubbleIndex >= 0) {
                      session.uiBubbles[session.streamBubbleIndex].content = session.streamingContent
                      this.notifyListener(bookUrl)
                    }
                  }

                  if (delta.tool_calls) {
                    const tcs = delta.tool_calls as object[]
                    for (let tc of tcs) {
                      const tcObj = tc as Record<string, Object>
                      let idx = tcObj.index as number
                      if (!toolCallsArray[idx]) {
                        const tcId = tcObj.id ? tcObj.id as string : ''
                        const fnObj = tcObj.function ? tcObj.function as Record<string, string> : null
                        const fnName = fnObj && fnObj.name ? fnObj.name : ''
                        const fnArgs = fnObj && fnObj.arguments ? fnObj.arguments : ''
                        const fnCall: ToolFunctionCall = { name: fnName, arguments: fnArgs }
                        const newTc: ToolCall = { id: tcId, type: 'function', function: fnCall }
                        toolCallsArray[idx] = newTc
                      }
                      const fnObj = tcObj.function as Record<string, string> | undefined
                      if (fnObj && fnObj.arguments) {
                        toolCallsArray[idx].function.arguments += fnObj.arguments
                      }
                    }
                  }
                }
              } catch (e) {}
            } else if (line.startsWith('{"error":')) {
              streamError = line
            }
          }
        })
        
        httpRequest.on('dataEnd', () => {
           console.info('[AiReadingService] Stream ended')
           if (!resolved) { resolved = true; resolve() }
        })

        httpRequest.requestInStream(url, {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + config.apiKey,
            'Accept': 'text/event-stream'
          } as Record<string, string>,
          extraData: bodyStr,
          connectTimeout: 15000,
          readTimeout: 120000,
          expectDataType: http.HttpDataType.STRING
        }).then((responseCode: number) => {
           if (responseCode !== 200) {
             streamError = 'HTTP Error: ' + responseCode
             if (!resolved) { resolved = true; resolve() }
           }
        }).catch((err: Error) => {
           streamError = 'Request failed: ' + err.message
           if (!resolved) { resolved = true; resolve() }
        })
      })

      httpRequest.destroy()

      if (session.abortFlag) {
        if (session.streamBubbleIndex >= 0) {
          session.uiBubbles[session.streamBubbleIndex].isStreaming = false
          session.uiBubbles[session.streamBubbleIndex].isError = true
          session.uiBubbles[session.streamBubbleIndex].content = '已取消'
        }
        session.isLoading = false
        this.notifyListener(bookUrl)
        return
      }

      if (streamError.length > 0) {
         if (session.streamBubbleIndex >= 0) {
            session.uiBubbles[session.streamBubbleIndex].isStreaming = false
            session.uiBubbles[session.streamBubbleIndex].isError = true
            
            let displayError = streamError
            try {
              const errObj = JSON.parse(streamError) as Record<string, Object>
              if (errObj.error) {
                const errNested = errObj.error as Record<string, string>
                if (errNested.message) displayError = errNested.message
              }
            } catch(e) {}
            session.uiBubbles[session.streamBubbleIndex].content = displayError
         }
         session.isLoading = false
         this.saveSession(bookUrl)
         this.notifyListener(bookUrl)
         return
      }

      const validToolCalls: ToolCall[] = toolCallsArray.filter((t: ToolCall | undefined) => t !== undefined && t !== null)
      if (validToolCalls.length > 0) {
        const assistantMsg: ChatMessage = {
          role: 'assistant',
          content: session.streamingContent,
          tool_calls: validToolCalls
        }
        session.conversationHistory.push(assistantMsg)

        if (session.streamBubbleIndex >= 0) {
           session.uiBubbles[session.streamBubbleIndex].isStreaming = false
        }

        for (let i = 0; i < validToolCalls.length; i++) {
          if (session.abortFlag) break
          const tc = validToolCalls[i]
          const toolBubble: ChatBubble = {
            role: 'tool', content: '', isStreaming: false, isError: false,
            toolCallName: tc.function.name, toolCallArgs: tc.function.arguments,
            timestamp: Date.now()
          }
          session.uiBubbles.push(toolBubble)
          this.notifyListener(bookUrl)

          const toolResult = this.executeTool(tc.function.name, tc.function.arguments, ctx)
          toolBubble.toolResult = toolResult.length > 200 ? toolResult.substring(0, 200) + '...' : toolResult

          const toolMsg: ChatMessage = {
            role: 'tool',
            content: toolResult,
            tool_call_id: tc.id,
            name: tc.function.name
          }
          session.conversationHistory.push(toolMsg)
        }

        if (!session.abortFlag) {
          const resumeBubble: ChatBubble = {
            role: 'assistant', content: '正在整合结果...', isStreaming: true, isError: false, timestamp: Date.now()
          }
          session.uiBubbles.push(resumeBubble)
          session.streamBubbleIndex = session.uiBubbles.length - 1
          session.streamingContent = ''
          this.notifyListener(bookUrl)

          const nextMessages: ChatMessage[] = new Array()
          nextMessages.push(messages[0])
          for (let i = 0; i < session.conversationHistory.length; i++) {
            nextMessages.push(session.conversationHistory[i])
          }
          await this.callApiWithTools(config, nextMessages, tools, ctx, bookUrl, depth + 1)
        }
      } else {
        if (session.streamingContent.length > 0) {
          // 最终清理：移除残留的思考内容
          let finalContent = session.streamingContent
          finalContent = finalContent.replace(/<think>[\s\S]*?<\/think>/g, '')
          finalContent = finalContent.replace(/<think>[\s\S]*$/g, '')
          finalContent = finalContent.replace(/^>\s*_思考过程[\s\S]*?\n---\n\n?/, '')
          finalContent = finalContent.trim()
          if (finalContent.length > 0) {
            const assistantMsg: ChatMessage = { role: 'assistant', content: finalContent }
            session.conversationHistory.push(assistantMsg)
            if (session.streamBubbleIndex >= 0) {
              session.uiBubbles[session.streamBubbleIndex].content = finalContent
            }
          }
        }
        if (session.streamBubbleIndex >= 0) {
          session.uiBubbles[session.streamBubbleIndex].isStreaming = false
        }
        session.isLoading = false
        this.saveSession(bookUrl)
        this.notifyListener(bookUrl)
      }
    } catch (e) {
      console.error('[AiReadingService] Request failed', e)
      if (session.streamBubbleIndex >= 0) {
        session.uiBubbles[session.streamBubbleIndex].isStreaming = false
        session.uiBubbles[session.streamBubbleIndex].isError = true
        session.uiBubbles[session.streamBubbleIndex].content = '请求失败: ' + (e as Error).message
      }
      session.isLoading = false
      this.saveSession(bookUrl)
      this.notifyListener(bookUrl)
    }
  }
}

const aiReadingService = new AiReadingService()
export default aiReadingService as AiReadingService
