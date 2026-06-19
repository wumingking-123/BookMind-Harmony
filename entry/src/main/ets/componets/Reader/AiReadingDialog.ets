import { InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow } from '../../common/constants/DesignTokens'
import { MarkdownView } from './MarkdownView'
import aiReadingService, { StreamEvent, ToolExecutionContext, ChapterInfo, ChatBubble } from '../../common/utils/AiReadingService'
import aiConfigUtils from '../../common/utils/AiConfigUtils'

@Component
export struct AiReadingDialog {
  @Prop isShow: boolean = false
  @Prop isNightMode: boolean = false
  @Prop currentChapterIndex: number = 0
  @Prop currentPageIndex: number = 0
  @Prop bookUrl: string = ''
  chapterListProvider: () => ChapterInfo[] = () => new Array()
  onClose: () => void = () => {}

  @State messages: ChatBubble[] = new Array()
  @State inputText: string = ''
  @State isLoading: boolean = false
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    if (this.bookUrl.length > 0) {
      aiReadingService.initSession(this.bookUrl).then(() => {
        aiReadingService.registerListener(this.bookUrl, (bubbles: ChatBubble[], isLoading: boolean) => {
          this.messages = bubbles
          this.isLoading = isLoading
          this.scrollToBottom()
        })
      })
    }
  }

  aboutToDisappear(): void {
    if (this.bookUrl.length > 0) {
      aiReadingService.unregisterListener(this.bookUrl)
    }
  }

  getBgColor(): string {
    return this.isNightMode ? '#1A1A1C' : InkPalette.PAPER
  }
  getCardBg(): string {
    return this.isNightMode ? 'rgba(38,36,34,0.95)' : InkPalette.PAPER_PURE
  }
  getInputBorder(): string {
    return this.isNightMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)'
  }
  getTextColor(): string {
    return this.isNightMode ? '#EDE4D3' : InkPalette.INK
  }
  getSubTextColor(): string {
    return this.isNightMode ? '#A89B8C' : InkPalette.INK_LIGHT
  }
  getAssistBg(): string {
    return this.isNightMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)'
  }
  getUserBg(): string {
    return this.isNightMode ? InkPalette.CINNABAR : InkPalette.CINNABAR
  }

  buildContext(): ToolExecutionContext {
    const chapters = this.chapterListProvider()
    const ctx: ToolExecutionContext = {
      currentChapterIndex: this.currentChapterIndex,
      currentPageIndex: this.currentPageIndex,
      chapterList: chapters
    }
    return ctx
  }

  send(): void {
    const text = this.inputText.trim()
    if (text.length === 0 || this.isLoading) return
    this.inputText = ''
    const ctx = this.buildContext()
    aiReadingService.chat(this.bookUrl, text, ctx)
  }

  scrollToBottom(): void {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom)
    }, 50)
  }

  clearConversation(): void {
    aiReadingService.clearConversation(this.bookUrl)
  }

  @Builder
  AiIcon(size: number, color: ResourceColor) {
    Stack({ alignContent: Alignment.Center }) {
      Text('AI')
        .fontSize(size * 0.4)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
    }
    .width(size)
    .height(size)
    .backgroundColor(color)
    .borderRadius(size / 2)
  }

  @Builder
  Header() {
    Row({ space: 10 }) {
      Row() {
        this.AiIcon(28, InkPalette.CINNABAR)
      }

      Column({ space: 1 }) {
        Text('AI 阅读助手')
          .fontSize(InkTypography.BODY_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTextColor())
        if (this.isLoading) {
          Text('正在思考...')
            .fontSize(10)
            .fontColor(InkPalette.CELADON)
        } else {
          Text('就绪')
            .fontSize(10)
            .fontColor(this.getSubTextColor())
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.messages.length > 0) {
        Text('清空')
          .fontSize(InkTypography.CAPTION)
          .fontColor(this.getSubTextColor())
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.getAssistBg())
          .borderRadius(InkRadius.BUTTON_LARGE)
          .onClick(() => { this.clearConversation() })
      }

      Row() {
        Image($r('app.media.close'))
          .width(18).height(18)
          .fillColor(this.getSubTextColor())
      }
      .width(32).height(32)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onClose() })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 10 })
  }

  @Builder
  ToolBubble(bubble: ChatBubble) {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        if (bubble.isStreaming) {
          LoadingProgress().width(12).height(12).color(InkPalette.CELADON)
        } else {
          Row()
            .width(12).height(12)
            .borderRadius(3)
            .backgroundColor(InkPalette.CELADON)
        }
        Text(bubble.isStreaming ? '正在调用' : '已调用')
          .fontSize(10)
          .fontColor(InkPalette.CELADON)
          .fontWeight(FontWeight.Medium)
        Text(bubble.toolCallName || '')
          .fontSize(11)
          .fontColor(this.getTextColor())
          .fontWeight(FontWeight.Medium)
      }

      if (bubble.toolCallArgs && bubble.toolCallArgs.length > 2) {
        Text(bubble.toolCallArgs)
          .fontSize(9)
          .fontColor(this.getSubTextColor())
          .fontFamily('monospace')
          .wordBreak(WordBreak.BREAK_ALL)
          .width('100%')
          .padding({ left: 8, top: 4, bottom: 4, right: 8 })
          .backgroundColor(this.isNightMode ? 'rgba(0,0,0,0.25)' : 'rgba(0,0,0,0.025)')
          .borderRadius(InkRadius.XS)
      }

      if (bubble.toolResult && bubble.toolResult.length > 0) {
        Row({ space: 4 }) {
          Row()
            .width(5).height(5)
            .borderRadius(2.5)
            .backgroundColor(InkPalette.SUCCESS)
          Text('已获取内容')
            .fontSize(9)
            .fontColor(InkPalette.SUCCESS)
        }
      }
    }
    .width('100%')
    .padding({ left: 12, top: 8, bottom: 8, right: 12 })
    .backgroundColor(this.isNightMode ? 'rgba(91,140,122,0.06)' : 'rgba(91,140,122,0.05)')
    .borderRadius(InkRadius.SM)
    .border({ width: { left: 2 }, color: { left: InkPalette.CELADON } })
  }

  @Builder
  MessageBubble(bubble: ChatBubble, index: number) {
    if (bubble.role === 'tool') {
      Row() {
        this.ToolBubble(bubble)
      }.width('100%').padding({ left: 44, right: 16 })
    } else if (bubble.role === 'user') {
      Row() {
        Blank()
        Column() {
          Text(bubble.content)
            .fontSize(InkTypography.BODY)
            .fontColor(Color.White)
            .lineHeight(22)
            .wordBreak(WordBreak.BREAK_ALL)
        }
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor(this.getUserBg())
        .borderRadius({ topLeft: 18, topRight: 18, bottomLeft: 18, bottomRight: 4 })
        .constraintSize({ maxWidth: '78%' })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    } else {
      Row({ space: 8 }) {
        Column() {
          this.AiIcon(24, InkPalette.CINNABAR)
        }
        .margin({ top: 2 })

        Column() {
          if (bubble.content.length === 0 && bubble.isStreaming) {
            Row({ space: 6 }) {
              LoadingProgress()
                .width(14).height(14)
                .color(InkPalette.CINNABAR)
              Text('正在思考...')
                .fontSize(InkTypography.CAPTION)
                .fontColor(this.getSubTextColor())
            }
          } else {
            MarkdownView({ content: bubble.content, isNightMode: this.isNightMode })
              .width('100%')
          }
          if (bubble.isStreaming && bubble.content.length > 0) {
            Row({ space: 6 }) {
              LoadingProgress()
                .width(12).height(12)
                .color(InkPalette.CINNABAR)
              Text('正在生成回复...')
                .fontSize(10)
                .fontColor(this.getSubTextColor())
            }
            .margin({ top: 6 })
          }
          if (bubble.isError) {
            Text(bubble.content)
              .fontSize(InkTypography.CAPTION)
              .fontColor(InkPalette.ERROR)
              .padding({ top: 4 })
          }
        }
        .padding({ left: 14, right: 14, top: 12, bottom: 12 })
        .backgroundColor(this.getCardBg())
        .borderRadius({ topLeft: 4, topRight: 18, bottomLeft: 18, bottomRight: 18 })
        .constraintSize({ maxWidth: '78%' })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Top)
    }
  }

  @Builder
  EmptyState() {
    Column({ space: 20 }) {
      this.AiIcon(56, InkPalette.CINNABAR)

      Text('AI 阅读助手')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getTextColor())

      Text('我可以帮你总结剧情、解释概念、分析人物\n随时问我关于这本书的任何问题')
        .fontSize(InkTypography.CAPTION)
        .fontColor(this.getSubTextColor())
        .textAlign(TextAlign.Center)
        .lineHeight(20)

      Column({ space: 10 }) {
        this.SuggestionCard('概括本章', '帮我总结一下当前这一章的主要内容')
        this.SuggestionCard('解释含义', '帮我分析一下当前这段话的深层含义')
        this.SuggestionCard('人物背景', '这个角色之前出现过吗？有什么背景？')
        this.SuggestionCard('预测剧情', '根据前文内容，猜测接下来的发展')
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  SuggestionCard(title: string, prompt: string) {
    Row({ space: 10 }) {
      Column()
        .width(4).height(28)
        .backgroundColor(InkPalette.CINNABAR_LIGHT)
        .borderRadius(2)

      Column({ space: 2 }) {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextColor())
        Text(prompt)
          .fontSize(11)
          .fontColor(this.getSubTextColor())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(16)
        .fontColor(this.getSubTextColor())
        .opacity(0.5)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)')
    .borderRadius(InkRadius.MD)
    .border({ width: 0.5, color: this.getInputBorder() })
    .onClick(() => {
      this.inputText = prompt
      this.send()
    })
  }

  @Builder
  InputBar() {
    Row({ space: 10 }) {
      TextInput({ text: this.inputText, placeholder: '问点关于这本书的问题...' })
        .fontSize(InkTypography.BODY)
        .fontColor(this.getTextColor())
        .placeholderFont({ size: InkTypography.BODY })
        .placeholderColor(this.getSubTextColor())
        .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
        .borderRadius(24)
        .padding({ left: 18, right: 18, top: 11, bottom: 11 })
        .layoutWeight(1)
        .onSubmit(() => { this.send() })
        .onChange((value: string) => { this.inputText = value })

      if (this.isLoading) {
        Row() {
          Column()
            .width(10).height(10)
            .backgroundColor(Color.White)
            .borderRadius(2)
        }
        .width(44).height(44)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(this.isNightMode ? InkPalette.INK_LIGHT : '#5A5048')
        .borderRadius(22)
        .onClick(() => {
          aiReadingService.abort(this.bookUrl)
        })
      } else {
        Text('发送')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.inputText.trim().length > 0 ? Color.White : this.getSubTextColor())
          .width(44).height(44)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.inputText.trim().length > 0 ? InkPalette.CINNABAR : (this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)'))
          .borderRadius(22)
          .onClick(() => { this.send() })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(this.getBgColor())
    .border({ width: { top: 0.5 }, color: { top: this.getInputBorder() } })
  }

  build() {
    Column() {
      this.Header()
      Divider().color(this.getInputBorder())

      if (this.messages.length === 0) {
        this.EmptyState()
      } else {
        Scroll(this.scroller) {
          Column({ space: 16 }) {
            ForEach(this.messages, (bubble: ChatBubble, index: number) => {
              this.MessageBubble(bubble, index)
            }, (bubble: ChatBubble, idx: number) => bubble.timestamp + '_' + idx + '_' + bubble.isStreaming + '_' + bubble.content.length)
          }
          .width('100%')
          .padding({ top: 16, bottom: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }

      this.InputBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getBgColor())
  }
}
