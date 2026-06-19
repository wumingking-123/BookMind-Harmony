import { componentSnapshot, promptAction } from '@kit.ArkUI'
import router from '@ohos.router'
import { image } from '@kit.ImageKit'
import { emitter } from '@kit.BasicServicesKit'
import { ThemeColor, ThemeStorageKey } from '../../../common/constants/Theme'
import { ThemeColorItem, ThemeItem } from '../../../common/model/Theme'
import { themeManager } from '../../../common/utils/ThemeManager'
import { sleep } from '../../../common/utils/utils'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../common/constants/DesignTokens'

// 色彩辅助类型
interface RgbColor {
  r: number
  g: number
  b: number
}

interface HslColor {
  h: number
  s: number
  l: number
}

// HSL 色彩转换辅助函数
function hexToRgb(hex: string): RgbColor | null {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (result) {
    const color: RgbColor = {
      r: parseInt(result[1], 16),
      g: parseInt(result[2], 16),
      b: parseInt(result[3], 16)
    }
    return color
  }
  return null
}

function rgbToHsl(r: number, g: number, b: number): HslColor {
  r /= 255;
  g /= 255;
  b /= 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let h = 0;
  let s = 0;
  const l = (max + min) / 2;

  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: h = (g - b) / d + (g < b ? 6 : 0); break;
      case g: h = (b - r) / d + 2; break;
      case b: h = (r - g) / d + 4; break;
    }
    h /= 6;
  }
  const hslResult: HslColor = { h: h * 360, s: s * 100, l: l * 100 }
  return hslResult
}

function hslToRgb(h: number, s: number, l: number): RgbColor {
  h /= 360;
  s /= 100;
  l /= 100;
  let r = l;
  let g = l;
  let b = l;

  if (s !== 0) {
    const hue2rgb = (p: number, q: number, t: number): number => {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1/6) return p + (q - p) * 6 * t;
      if (t < 1/2) return q;
      if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
      return p;
    };
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    r = hue2rgb(p, q, h + 1/3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1/3);
  }
  const rgbResult: RgbColor = {
    r: Math.round(r * 255),
    g: Math.round(g * 255),
    b: Math.round(b * 255)
  }
  return rgbResult
}

function rgbToHex(r: number, g: number, b: number): string {
  const toHex = (c: number): string => {
    const hex = c.toString(16);
    return hex.length === 1 ? '0' + hex : hex;
  };
  return '#' + toHex(r) + toHex(g) + toHex(b);
}

function generateSecondColor(mainHex: string): string {
  const rgb = hexToRgb(mainHex);
  if (!rgb) return '#FAF7F0';
  const hsl = rgbToHsl(rgb.r, rgb.g, rgb.b);
  // 色相保持，设置极低饱和度 (12%) 和极高亮度 (95%)，推导契合纸张色彩的莫兰迪副色
  const newRgb = hslToRgb(hsl.h, 12, 95);
  return rgbToHex(newRgb.r, newRgb.g, newRgb.b);
}

@Entry
@Component
struct CreateCustomTheme {
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  // 莫兰迪色系
  colorList: ThemeColorItem[] = [
    ThemeColor.SMOKE_PINK,
    ThemeColor.MIST_BLUE,
    ThemeColor.WITHERED_LOTUS,
    ThemeColor.MOSS_GREEN,
    ThemeColor.LOTUS_PURPLE,
    ThemeColor.AMBER,
    ThemeColor.WHALE_BLUE,
    ThemeColor.PERSIMMON,
    ThemeColor.CELADON_GREY,
    ThemeColor.INK_BAMBOO,
  ]
  @StorageProp('screen_shot') previewIndexPage: PixelMap = {} as PixelMap
  @State activeIndex: number = -1
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem
  originTheme: ThemeItem = {} as ThemeItem
  selectTheme: ThemeItem = {} as ThemeItem
  @State themeName: string = '自定义主题'
  @State customHexInput: string = ''

  isValidColor(): boolean {
    return /^#([A-Fa-f0-9]{6})$/.test(this.selectTheme.mainColor)
  }

  async handleColorSelect(mainColor: string) {
    this.themeName = this.themeName || '自定义主题'
    const generatedSecond = generateSecondColor(mainColor)
    const themeItem: ThemeItem = {
      mainColor: mainColor,
      secondColor: generatedSecond,
      text: this.themeName
    }
    this.selectTheme = themeItem
    
    // 强制刷新主题预览
    let count = 3
    while (count--) {
      themeManager.setTheme(themeItem, AppStorage.get(ThemeStorageKey.THEMEINDEX) as number)
      emitter.emit('screen_shot') // 触发首页截图
      this.previewIndexPage = AppStorage.get('screen_shot') as PixelMap
      await sleep(80)
    }
  }

  aboutToAppear(): void {
    this.originTheme = this.theme // 暂存原主题配置信息
    this.selectTheme = this.theme
    this.customHexInput = this.theme.mainColor
  }

  aboutToDisappear() {
    themeManager.setTheme(this.originTheme, AppStorage.get(ThemeStorageKey.THEMEINDEX) as number)
  }

  build() {
    Column() {
      // 头部标题栏
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor(InkPalette.INK)
        }
        .width(InkLayout.MIN_TOUCH_TARGET)
        .height(InkLayout.MIN_TOUCH_TARGET)
        .borderRadius(InkRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          themeManager.setTheme(this.originTheme, AppStorage.get(ThemeStorageKey.THEMEINDEX) as number)
          router.back()
        })

        Row({ space: InkSpacing.SM }) {
          TextInput({ text: $$this.themeName })
            .height(24)
            .fontSize(InkTypography.TITLE_SMALL)
            .fontWeight(FontWeight.Medium)
            .fontColor(InkPalette.INK)
            .onSubmit(() => {
              this.selectTheme.text = this.themeName
            })
            .padding(0)
            .width(100)
            .backgroundColor(Color.Transparent)
          Image($r('app.media.writing'))
            .width(16)
            .height(16)
            .fillColor(InkPalette.INK_MIST)
        }
        .alignItems(VerticalAlign.Center)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        Text('保存')
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isValidColor() ? this.theme.mainColor : InkPalette.INK_MIST)
          .height(InkLayout.MIN_TOUCH_TARGET)
          .onClick(() => {
            if (!this.isValidColor()) {
              this.getUIContext().getPromptAction().showToast({ message: '请先输入或选择一个有效的主题色(十六进制如 #C4A4A0)' })
              return
            }
            themeManager.setTheme(this.originTheme, AppStorage.get(ThemeStorageKey.THEMEINDEX) as number)
            this.selectTheme.text = this.themeName
            themeManager.addTheme(this.selectTheme)
            router.back()
          })
      }
      .width('100%')
      .height(InkLayout.HEADER_HEIGHT)
      .padding({ left: InkSpacing.LG, right: InkSpacing.XL })
      .margin({ top: this.topRectHeight })

      // 截图预览区
      Column() {
        Image(this.previewIndexPage)
          .width(220)
          .borderRadius(InkRadius.MD)
          .shadow(InkShadow.MEDIUM)
          .objectFit(ImageFit.Cover)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 60, right: 60, top: 48, bottom: 48 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(InkPalette.PAPER_EMBEDDED)

      // 底部选色区
      Column() {
        Row()
          .width(32)
          .height(4)
          .borderRadius(2)
          .backgroundColor(InkPalette.INK_MIST)
          .margin({ bottom: InkSpacing.LG })

        Row({ space: InkSpacing.MD }) {
          Text('自定义色值')
            .fontSize(InkTypography.CAPTION)
            .fontColor(InkPalette.INK_GHOST)
            .layoutWeight(1)

          TextInput({ placeholder: '请输入 Hex 色值，如 #C4A4A0', text: this.customHexInput })
            .width(190)
            .height(36)
            .fontSize(InkTypography.BODY_SMALL)
            .borderRadius(InkRadius.SM)
            .backgroundColor(InkPalette.PAPER_WARM)
            .fontColor(InkPalette.INK)
            .onChange(async (val) => {
              this.customHexInput = val
              if (/^#([A-Fa-f0-9]{6})$/.test(val)) {
                this.activeIndex = -1 // 清空预设选中状态，采用自定义值
                this.handleColorSelect(val)
              }
            })
        }
        .width('100%')
        .margin({ bottom: InkSpacing.MD })
        .alignItems(VerticalAlign.Center)

        Text('常用推荐色相')
          .fontSize(InkTypography.MICRO)
          .fontColor(InkPalette.INK_MIST)
          .width('100%')
          .margin({ bottom: InkSpacing.SM })

        // 颜色网格
        Grid() {
          ForEach(this.colorList, (item: ThemeColorItem, index: number) => {
            GridItem() {
              Stack({ alignContent: Alignment.Center }) {
                Row()
                  .width(44)
                  .height(44)
                  .borderRadius(InkRadius.FULL)
                  .backgroundColor(item.mainColor)

                // 选中指示
                if (this.activeIndex === index) {
                  Image($r('app.media.ic_public_confirm'))
                    .width(20)
                    .height(20)
                    .fillColor(Color.White)
                }
              }
              .width(52)
              .height(52)
            }
            .onClick(() => {
              this.activeIndex = index
              this.customHexInput = item.mainColor
              this.handleColorSelect(item.mainColor)
            })
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .columnsGap(8)
        .rowsGap(12)
        .width('100%')
      }
      .width('100%')
      .padding({ left: InkSpacing.XL, right: InkSpacing.XL, top: InkSpacing.LG, bottom: InkSpacing.XL + this.bottomRectHeight })
      .backgroundColor(InkPalette.PAPER)
      .borderRadius({ topLeft: InkRadius.SHEET, topRight: InkRadius.SHEET })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(InkPalette.PAPER_EMBEDDED)
  }
}
