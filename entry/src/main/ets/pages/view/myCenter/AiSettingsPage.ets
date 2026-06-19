import { router } from '@kit.ArkUI'
import { InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow } from '../../../common/constants/DesignTokens'
import aiConfigUtils, { AiConfig, TestResult } from '../../../common/utils/AiConfigUtils'
import { promptAction } from '@kit.ArkUI'
import { ThemeStorageKey } from '../../../common/constants/Theme'
import { ThemeItem } from '../../../common/model/Theme'

@Entry
@Component
struct AiSettingsPage {
  @State baseUrl: string = ''
  @State apiKey: string = ''
  @State model: string = ''
  @State maxTokens: string = '4096'
  @State temperature: string = '0.7'
  @State systemPrompt: string = ''
  @State enableTools: boolean = true
  @State disableThinking: boolean = false
  @State isTesting: boolean = false
  @State testResult: string = ''
  @State testSuccess: boolean = false
  @State showKey: boolean = false
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0

  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  getMainColor(): string {
    return this.theme?.mainColor || InkPalette.CINNABAR;
  }
  getSecondColor(): string {
    return this.theme?.secondColor || InkPalette.PAPER_WARM;
  }

  aboutToAppear(): void {
    const config: AiConfig = aiConfigUtils.getConfig()
    this.baseUrl = config.baseUrl
    this.apiKey = config.apiKey
    this.model = config.model
    this.maxTokens = config.maxTokens.toString()
    this.temperature = config.temperature.toString()
    this.systemPrompt = config.systemPrompt
    this.enableTools = config.enableTools
    this.disableThinking = config.disableThinking
  }

  save(): void {
    const config: AiConfig = {
      baseUrl: this.baseUrl.trim(),
      apiKey: this.apiKey.trim(),
      model: this.model.trim(),
      maxTokens: Number(this.maxTokens) || 4096,
      temperature: Number(this.temperature) || 0.7,
      systemPrompt: this.systemPrompt,
      enableTools: this.enableTools,
      disableThinking: this.disableThinking
    }
    aiConfigUtils.saveConfig(config)
    promptAction.showToast({ message: '保存成功', duration: 1500 })
  }

  async testConnection(): Promise<void> {
    this.save()
    this.isTesting = true
    this.testResult = ''
    const result: TestResult = await aiConfigUtils.testConnection()
    this.isTesting = false
    this.testSuccess = result.success
    this.testResult = result.message
  }

  @Builder
  Header() {
    Row() {
      Image($r('app.media.ic_public_return_left'))
        .width(24).height(24)
        .fillColor(InkPalette.INK)
        .onClick(() => { router.back() })
      Text('AI 阅读助手设置')
        .fontSize(InkTypography.TITLE_SMALL)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('保存')
        .fontSize(InkTypography.BODY)
        .fontColor(this.theme?.mainColor || InkPalette.CINNABAR)
        .fontWeight(FontWeight.Medium)
        .onClick(() => { this.save() })
    }
    .width('100%')
    .height(56)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16, right: 16, top: this.topRectHeight })
  }

  @Builder
  FieldLabel(label: string, hint: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(InkTypography.BODY_SMALL)
        .fontColor(InkPalette.INK_LIGHT)
        .fontWeight(FontWeight.Medium)
      Text(hint)
        .fontSize(InkTypography.MICRO)
        .fontColor(InkPalette.INK_MIST)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  InputField(value: string, placeholder: string, isPassword: boolean, onChange: (v: string) => void) {
    Row({ space: 8 }) {
      TextInput({ text: value, placeholder: placeholder })
        .fontSize(InkTypography.BODY)
        .fontColor(InkPalette.INK)
        .placeholderFont({ size: InkTypography.BODY })
        .placeholderColor(InkPalette.INK_MIST)
        .backgroundColor('transparent')
        .layoutWeight(1)
        .type(isPassword && !this.showKey ? InputType.Password : InputType.Normal)
        .onChange((v: string) => { onChange(v) })

      if (isPassword) {
        Text(this.showKey ? '隐藏' : '显示')
          .fontSize(InkTypography.CAPTION)
          .fontColor(InkPalette.INK_LIGHT)
          .onClick(() => { this.showKey = !this.showKey })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(InkPalette.PAPER_WARM)
    .borderRadius(InkRadius.SM)
  }

  build() {
    Column() {
      this.Header()
      Divider().color(InkPalette.INK_WHISPER)

      Scroll() {
        Column({ space: 16 }) {
          // 说明卡片
          Column({ space: 8 }) {
            Row({ space: 8 }) {
              Text('配置说明')
                .fontSize(InkTypography.CAPTION)
                .fontWeight(FontWeight.Medium)
                .fontColor(InkPalette.CELADON)
              Text('配置 OpenAI 兼容的大模型 API，即可在阅读时使用 AI 助手')
                .fontSize(InkTypography.CAPTION)
                .fontColor(InkPalette.INK_LIGHT)
                .lineHeight(18)
                .layoutWeight(1)
            }
            .width('100%')
          }
          .width('100%')
          .padding(12)
          .backgroundColor(InkPalette.CELADON_MIST)
          .borderRadius(InkRadius.MD)

          // Base URL
          Column({ space: 6 }) {
            this.FieldLabel('Base URL', 'API 基础地址，如 https://api.openai.com/v1')
            this.InputField(this.baseUrl, 'https://api.openai.com/v1', false, (v: string) => { this.baseUrl = v })
          }.width('100%')

          // API Key
          Column({ space: 6 }) {
            this.FieldLabel('API Key', '你的密钥，仅保存在本地')
            this.InputField(this.apiKey, 'sk-...', true, (v: string) => { this.apiKey = v })
          }.width('100%')

          // Model
          Column({ space: 6 }) {
            this.FieldLabel('模型名称', '如 gpt-4o-mini, deepseek-chat 等')
            this.InputField(this.model, 'gpt-4o-mini', false, (v: string) => { this.model = v })
          }.width('100%')

          // Max Tokens & Temperature
          Row({ space: 12 }) {
            Column({ space: 6 }) {
              this.FieldLabel('最大 Token', '限制输出长度')
              this.InputField(this.maxTokens, '4096', false, (v: string) => { this.maxTokens = v })
            }.layoutWeight(1)

            Column({ space: 6 }) {
              this.FieldLabel('温度', '0-2，越高越随机')
              this.InputField(this.temperature, '0.7', false, (v: string) => { this.temperature = v })
            }.layoutWeight(1)
          }.width('100%')

          // System Prompt
          Column({ space: 6 }) {
            this.FieldLabel('系统提示词', '自定义 AI 助手的角色和行为')
            TextArea({ text: this.systemPrompt, placeholder: '系统提示词...' })
              .fontSize(InkTypography.BODY_SMALL)
              .fontColor(InkPalette.INK)
              .placeholderColor(InkPalette.INK_MIST)
              .backgroundColor(InkPalette.PAPER_WARM)
              .border({ width: 1, color: InkPalette.PAPER_DEEP, radius: InkRadius.SM })
              .caretColor(this.theme?.mainColor || InkPalette.CINNABAR)
              .selectedBackgroundColor(this.theme?.secondColor || InkPalette.PAPER_WARM)
              .borderRadius(InkRadius.SM)
              .padding(12)
              .height(100)
              .onChange((v: string) => { this.systemPrompt = v })
          }.width('100%')

          // 启用智能工具开关
          Row() {
            Column({ space: 2 }) {
              Text('启用智能工具')
                .fontSize(InkTypography.BODY)
                .fontColor(InkPalette.INK)
                .fontWeight(FontWeight.Medium)
              Text('允许 AI 助手根据需要获取前后文、章节目录等内容')
                .fontSize(InkTypography.MICRO)
                .fontColor(InkPalette.INK_LIGHT)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.enableTools })
              .selectedColor(this.theme?.mainColor || InkPalette.CINNABAR)
              .onChange((isOn: boolean) => {
                this.enableTools = isOn
              })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 12 })
          .backgroundColor(InkPalette.PAPER_WARM)
          .borderRadius(InkRadius.SM)

          // 关闭思考模式开关
          Row() {
            Column({ space: 2 }) {
              Text('关闭思考模式')
                .fontSize(InkTypography.BODY)
                .fontColor(InkPalette.INK)
                .fontWeight(FontWeight.Medium)
              Text('针对 DeepSeek R1 等模型，强制关闭自带的思考过程以加快响应')
                .fontSize(InkTypography.MICRO)
                .fontColor(InkPalette.INK_LIGHT)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.disableThinking })
              .selectedColor(this.theme?.mainColor || InkPalette.CINNABAR)
              .onChange((isOn: boolean) => {
                this.disableThinking = isOn
              })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 12 })
          .backgroundColor(InkPalette.PAPER_WARM)
          .borderRadius(InkRadius.SM)

          // 测试连接按钮
          Button(this.isTesting ? '正在测试...' : '测试连接', { type: ButtonType.Normal })
            .width('100%')
            .height(44)
            .fontSize(InkTypography.BODY)
            .fontColor(Color.White)
            .backgroundColor(this.isTesting ? InkPalette.INK_MIST : (this.theme?.mainColor || InkPalette.CINNABAR))
            .borderRadius(InkRadius.BUTTON)
            .enabled(!this.isTesting)
            .onClick(() => { this.testConnection() })

          // 测试结果
          if (this.testResult.length > 0) {
            Row({ space: 6 }) {
              Row()
                .width(8).height(8)
                .borderRadius(4)
                .backgroundColor(this.testSuccess ? InkPalette.SUCCESS : InkPalette.ERROR)
              Text(this.testResult)
                .fontSize(InkTypography.CAPTION)
                .fontColor(this.testSuccess ? InkPalette.SUCCESS : InkPalette.ERROR)
                .layoutWeight(1)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(this.testSuccess ? InkPalette.CELADON_MIST : InkPalette.CINNABAR_GLOW)
            .borderRadius(InkRadius.SM)
          }

          // 功能说明
          Column({ space: 8 }) {
            Text('功能说明')
              .fontSize(InkTypography.CAPTION)
              .fontColor(InkPalette.INK_GHOST)
              .fontWeight(FontWeight.Medium)
            Text('• 自动传入当前页上下文（约2000字）\n• 支持 ReAct 多轮推理（最多15轮）\n• 工具：获取前文/后文/本章全文/指定章节/章节目录\n• 流式输出，实时展示思考与工具调用过程\n• 支持 Markdown 格式回复')
              .fontSize(InkTypography.MICRO)
              .fontColor(InkPalette.INK_MIST)
              .lineHeight(18)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(InkPalette.PAPER_WARM)
          .borderRadius(InkRadius.MD)

          Blank().height(20)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(InkPalette.PAPER)
  }
}
