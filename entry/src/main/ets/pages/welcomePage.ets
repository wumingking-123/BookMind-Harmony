import router from '@ohos.router' // 引入路由管理器
import { initAppData } from '../storage/appData'
import { InkPalette, InkTypography, InkSpacing } from '../common/constants/DesignTokens'
import { ThemeStorageKey, SplashStyle } from '../common/constants/Theme'
import { ThemeItem } from '../common/model/Theme'

interface QuoteItem {
  line1: string
  line2: string
}

// 预设文人雅致的读书诗句
const READING_QUOTES: QuoteItem[] = [
  { line1: "书卷多情似故人", line2: "晨昏忧乐每相亲" },
  { line1: "腹有诗书气自华", line2: "最是书香能致远" },
  { line1: "万卷古今消永日", line2: "一窗晴日送流年" },
  { line1: "一屏引古今", line2: "半日水墨香" },
  { line1: "松风吹解带", line2: "山月照弹琴" },
  { line1: "清风书香近", line2: "明月字句清" }
]

@Entry
@Component
struct WelcomePage {
  @State bgScale: number = 1.06
  @State line1Opacity: number = 0
  @State line1OffsetY: number = 15
  @State line2Opacity: number = 0
  @State line2OffsetY: number = 15
  @State brandOpacity: number = 0
  @State brandOffsetY: number = 10
  @State progressWidth: number = 0
  @State decorOpacity: number = 0
  @State selectedQuoteLine1: string = "书卷多情似故人"
  @State selectedQuoteLine2: string = "晨昏忧乐每相亲"

  @StorageProp(ThemeStorageKey.SPLASH_INDEX) splashIndex: number = 0
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem
  @StorageProp(ThemeStorageKey.SPLASH_CUSTOM_IMAGE) splashCustomImage: string = ''

  aboutToAppear() {
    // 随机选择一段读书诗句
    const idx = Math.floor(Math.random() * READING_QUOTES.length);
    const item = READING_QUOTES[idx];
    this.selectedQuoteLine1 = item.line1;
    this.selectedQuoteLine2 = item.line2;
  }

  // 根据启动页样式获取背景渐变色
  getBgColors(): [ResourceColor, number][] {
    const mainColor: ResourceColor = this.theme?.mainColor || '#C4A4A0';
    const secondColor: ResourceColor = this.theme?.secondColor || '#F2E8E6';
    switch (this.splashIndex) {
      case SplashStyle.INK: // 水墨 — 深色风格
        return [
          [InkPalette.INK, 0],
          [InkPalette.INK_DARK, 0.4],
          [InkPalette.INK_MEDIUM, 1]
        ]
      case SplashStyle.PAPER: // 素笺 — 纯白纸感
        return [
          [InkPalette.PAPER_WARM, 0],
          [InkPalette.PAPER, 0.5],
          [InkPalette.PAPER, 1]
        ]
      case SplashStyle.PAINTING: // 丹青 — 主题色渐变
        return [
          [mainColor, 0],
          [secondColor, 0.6],
          [InkPalette.PAPER, 1]
        ]
      case SplashStyle.CELADON: // 青瓷 — 淡雅青瓷色渐变
        return [
          [InkPalette.CELADON_MIST, 0],
          [InkPalette.PAPER_WARM, 0.5],
          [InkPalette.PAPER, 1]
        ]
      default: // 默认 — 琥珀暖光
        return [
          [InkPalette.AMBER_GLOW, 0],
          [InkPalette.PAPER, 0.5],
          [InkPalette.PAPER, 1]
        ]
    }
  }

  getTextColor(): string {
    return this.splashIndex === SplashStyle.INK ? InkPalette.PAPER : InkPalette.INK
  }

  getSubTextColor(): string {
    return this.splashIndex === SplashStyle.INK ? InkPalette.PAPER_SAND : InkPalette.INK_GHOST
  }

  getAccentColor(): string {
    return this.splashIndex === SplashStyle.INK ? InkPalette.AMBER_LIGHT : InkPalette.CINNABAR
  }

  onPageShow() {
    initAppData()
    
    // 1. 背景缩放动画
    animateTo({ duration: 2400, curve: Curve.EaseOut }, () => {
      this.bgScale = 1.0
    })

    // 2. 装饰细线渐显
    animateTo({ duration: 1000, delay: 100, curve: Curve.EaseOut }, () => {
      this.decorOpacity = 0.6
    })

    // 3. 第一行诗句渐显并从下方划入
    animateTo({ duration: 1000, delay: 300, curve: Curve.EaseOut }, () => {
      this.line1Opacity = 1.0
      this.line1OffsetY = 0
    })

    // 4. 第二行诗句渐显并从下方划入
    animateTo({ duration: 1000, delay: 900, curve: Curve.EaseOut }, () => {
      this.line2Opacity = 1.0
      this.line2OffsetY = 0
    })

    // 5. 底部品牌渐显
    animateTo({ duration: 800, delay: 1500, curve: Curve.EaseOut }, () => {
      this.brandOpacity = 1.0
      this.brandOffsetY = 0
    })

    // 6. 极细进度条动画
    animateTo({ duration: 1800, delay: 400, curve: Curve.EaseInOut }, () => {
      this.progressWidth = 100
    })

    // 2.5秒后自动跳转
    setTimeout(() => {
      router.pushUrl({ url: 'pages/Index' })
    }, 2500)
  }

  onPageHide() {
    router.clear()
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景层 — 根据选择的样式显示不同渐变或图片
      Column() {
        if (this.splashIndex === SplashStyle.CUSTOM && this.splashCustomImage) {
          Stack() {
            Image(this.splashCustomImage)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
            
            // 半透明宣纸磨砂叠加层
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor(this.splashIndex === SplashStyle.INK ? '#CC1A1612' : '#E6FAF7F0')
              .backgroundBlurStyle(BlurStyle.Thin)
          }
          .width('100%')
          .height('100%')
        } else {
          Column()
            .width('100%')
            .height('100%')
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: this.getBgColors()
            })
        }
      }
      .width('100%')
      .height('100%')
      .scale({ x: this.bgScale, y: this.bgScale })

      // 书香笺纸主体 (诗句展示区)
      Row() {
        // 第二行 (左侧，中文传统竖排习惯：自右向左阅读)
        Column() {
          ForEach(this.selectedQuoteLine2.split(''), (char: string) => {
            Text(char)
              .fontSize(InkTypography.TITLE_LARGE - 2)
              .fontColor(this.getTextColor())
              .fontWeight(FontWeight.Lighter)
              .height(32)
              .letterSpacing(0)
          })
        }
        .opacity(this.line2Opacity)
        .offset({ y: this.line2OffsetY })
        .alignItems(HorizontalAlign.Center)

        // 居中朱砂竖线
        Row()
          .width(0.8)
          .height(200)
          .backgroundColor(this.getAccentColor())
          .opacity(this.decorOpacity)
          .margin({ left: InkSpacing.XXL, right: InkSpacing.XXL })

        // 第一行 (右侧)
        Column() {
          ForEach(this.selectedQuoteLine1.split(''), (char: string) => {
            Text(char)
              .fontSize(InkTypography.TITLE_LARGE - 2)
              .fontColor(this.getTextColor())
              .fontWeight(FontWeight.Lighter)
              .height(32)
              .letterSpacing(0)
          })
        }
        .opacity(this.line1Opacity)
        .offset({ y: this.line1OffsetY })
        .alignItems(HorizontalAlign.Center)
      }
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: '15%' }) // 整体位置向上偏置，给底部留白

      // 底部品牌展示区
      Column({ space: InkSpacing.SM }) {
        Text('鸿 蒙 阅 读')
          .fontSize(InkTypography.BODY_LARGE)
          .fontColor(this.getTextColor())
          .fontWeight(FontWeight.Lighter)
          .letterSpacing(6)

        Text('书香致远  阅见未来')
          .fontSize(InkTypography.MICRO + 1)
          .fontColor(this.getSubTextColor())
          .fontWeight(FontWeight.Lighter)
          .letterSpacing(2)

        Blank(16)

        // 极细进度指示条
        Row() {
          Row()
            .width(`${this.progressWidth}%`)
            .height(1.5)
            .backgroundColor(this.getAccentColor())
            .borderRadius(0.75)
        }
        .width(80)
        .height(1.5)
        .borderRadius(0.75)
        .backgroundColor(this.splashIndex === SplashStyle.INK ? InkPalette.INK_GHOST : InkPalette.INK_WHISPER)
        .clip(true)
      }
      .width('100%')
      .opacity(this.brandOpacity)
      .offset({ y: this.brandOffsetY })
      .alignItems(HorizontalAlign.Center)
      .position({ bottom: '8%' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.splashIndex === SplashStyle.INK ? InkPalette.INK : InkPalette.PAPER)
  }
}
