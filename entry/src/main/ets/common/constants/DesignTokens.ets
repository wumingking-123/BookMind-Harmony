/**
 * 墨韵 2.0 Design System
 * 东方文人美学 × HarmonyOS 6.0 圆润设计语言
 * 打造"书香沉浸"阅读体验
 */

// ==================== 色彩系统 ====================
// 灵感来源：宣纸、墨迹、朱砂、青瓷、檀木

export class InkPalette {
  // 基底色 — 纸张质感
  static readonly PAPER: string = '#FAF7F0'              // 宣纸白 (更温暖)
  static readonly PAPER_PURE: string = '#FFFFFF'          // 纯白 (用于卡片)
  static readonly PAPER_WARM: string = '#F5EFE0'          // 暖纸
  static readonly PAPER_DEEP: string = '#EDE4D3'          // 深纸
  static readonly PAPER_EMBEDDED: string = '#E8DFD0'      // 嵌入纸
  static readonly PAPER_SAND: string = '#D9CEBD'          // 沙纸

  // 墨色层次 — 从浓到淡的7级灰阶
  static readonly INK: string = '#1A1612'                 // 浓墨 (主文字)
  static readonly INK_DARK: string = '#2D2821'            // 深墨 (次标题)
  static readonly INK_MEDIUM: string = '#4A4039'          // 中墨 (正文)
  static readonly INK_FAINT: string = '#4A4039'           // 薄墨 (图标/辅助)
  static readonly INK_LIGHT: string = '#6B5E52'           // 淡墨 (辅助文字)
  static readonly INK_GHOST: string = '#8A7D71'           // 幽墨 (占位文字)
  static readonly INK_MIST: string = '#A89B8C'            // 雾墨 (禁用状态)
  static readonly INK_WHISPER: string = '#C5BAB0'         // 轻墨 (分割线)

  // 朱砂红 — 点睛之笔
  static readonly CINNABAR: string = '#C23B22'            // 朱砂
  static readonly CINNABAR_LIGHT: string = '#D4654A'      // 浅朱
  static readonly CINNABAR_GLOW: string = '#F2D4CC'       // 朱光

  // 青瓷绿 — 自然之韵
  static readonly CELADON: string = '#5B8C7A'             // 青瓷
  static readonly CELADON_LIGHT: string = '#7BAA98'       // 浅青
  static readonly CELADON_MIST: string = '#D4E8DF'        // 青雾

  // 琥珀金 — 暖意
  static readonly AMBER: string = '#C4883A'               // 琥珀
  static readonly AMBER_LIGHT: string = '#E0A856'         // 浅琥珀
  static readonly AMBER_GLOW: string = '#F5E6C8'          // 琥珀光

  // 靛蓝 — 沉静
  static readonly INDIGO: string = '#3D5A80'              // 靛蓝
  static readonly INDIGO_LIGHT: string = '#5B7FA8'        // 浅靛
  static readonly INDIGO_MIST: string = '#D0DCE8'         // 靛雾

  // 檀木棕 — 书架底色
  static readonly SANDALWOOD: string = '#8B6F47'          // 檀木
  static readonly SANDALWOOD_LIGHT: string = '#A68B5B'    // 浅檀
  static readonly SANDALWOOD_MIST: string = '#E8DCC8'     // 檀雾

  // 功能色
  static readonly SUCCESS: string = '#5B8C7A'
  static readonly WARNING: string = '#C4883A'
  static readonly ERROR: string = '#C23B22'
  static readonly INFO: string = '#3D5A80'

  // 透明度层次
  static readonly OVERLAY_LIGHT: string = '#0A1A1612'     // 4% 墨色
  static readonly OVERLAY_MEDIUM: string = '#1A1A1612'    // 10% 墨色
  static readonly OVERLAY_HEAVY: string = '#331A1612'     // 20% 墨色
  static readonly OVERLAY_INTENSE: string = '#661A1612'   // 40% 墨色
}

// ==================== 排版系统 ====================
// HarmonyOS 6.0 字体规范 + 东方美学

export class InkTypography {
  // 字号 — 10级递进
  static readonly DISPLAY: number = 36        // 展示标题 (启动页)
  static readonly HEADLINE: number = 28       // 大标题
  static readonly TITLE_LARGE: number = 22    // 标题大
  static readonly TITLE: number = 18          // 标题
  static readonly TITLE_SMALL: number = 16    // 小标题
  static readonly BODY_LARGE: number = 16     // 正文大
  static readonly BODY: number = 14           // 正文 (默认)
  static readonly BODY_SMALL: number = 13     // 正文小
  static readonly CAPTION: number = 12        // 注释
  static readonly MICRO: number = 10          // 微字

  // 字重
  static readonly WEIGHT_LIGHT: FontWeight = FontWeight.Lighter
  static readonly WEIGHT_REGULAR: FontWeight = FontWeight.Normal
  static readonly WEIGHT_MEDIUM: FontWeight = FontWeight.Medium
  static readonly WEIGHT_SEMIBOLD: FontWeight = FontWeight.Bold
  static readonly WEIGHT_BOLD: FontWeight = FontWeight.Bolder

  // 行高倍数
  static readonly LINE_HEIGHT_TIGHT: number = 1.3
  static readonly LINE_HEIGHT_NORMAL: number = 1.5
  static readonly LINE_HEIGHT_RELAXED: number = 1.8
  static readonly LINE_HEIGHT_LOOSE: number = 2.0

  // 字间距
  static readonly LETTER_TIGHT: number = -0.5
  static readonly LETTER_NORMAL: number = 0
  static readonly LETTER_WIDE: number = 1.5
  static readonly LETTER_DISPLAY: number = 3
}

// ==================== 间距系统 ====================
// 4px 基准网格

export class InkSpacing {
  static readonly XXS: number = 2
  static readonly XS: number = 4
  static readonly SM: number = 8
  static readonly MD: number = 12
  static readonly LG: number = 16
  static readonly XL: number = 20
  static readonly XXL: number = 24
  static readonly XXXL: number = 32
  static readonly HUGE: number = 48
  static readonly MASSIVE: number = 64

  // 页面安全边距
  static readonly PAGE_HORIZONTAL: number = 20
  static readonly PAGE_TOP: number = 12
  static readonly PAGE_BOTTOM: number = 16

  // 卡片内边距
  static readonly CARD_PADDING: number = 16
  static readonly CARD_COMPACT: number = 12

  // 列表项间距
  static readonly LIST_GAP: number = 1
}

// ==================== 圆角系统 ====================
// HarmonyOS 6.0 大圆角风格

export class InkRadius {
  static readonly NONE: number = 0
  static readonly XS: number = 4
  static readonly SM: number = 8
  static readonly MD: number = 12
  static readonly LG: number = 16
  static readonly XL: number = 20
  static readonly XXL: number = 24
  static readonly FULL: number = 999

  // 语义化圆角
  static readonly BOOK_COVER: number = 8       // 书籍封面
  static readonly CARD: number = 16            // 卡片
  static readonly SHEET: number = 24           // 底部面板
  static readonly BUTTON: number = 12          // 按钮
  static readonly BUTTON_LARGE: number = 24    // 大按钮
  static readonly TAG: number = 6              // 标签
  static readonly SEARCH: number = 20          // 搜索栏
  static readonly DIALOG: number = 20          // 对话框
  static readonly TAB_INDICATOR: number = 10   // Tab指示器
}

// ==================== 阴影系统 ====================
// 暖色调阴影，模拟纸面浮起效果

export class InkShadow {
  // 微阴影 — 几乎不可见的层次
  static readonly SUBTLE: ShadowOptions = {
    radius: 4,
    color: '#081A1612',
    offsetX: 0,
    offsetY: 1
  }

  // 柔和阴影 — 浮于纸面
  static readonly SOFT: ShadowOptions = {
    radius: 8,
    color: '#0D1A1612',
    offsetX: 0,
    offsetY: 2
  }

  // 中等阴影 — 立体感
  static readonly MEDIUM: ShadowOptions = {
    radius: 16,
    color: '#1A1A1612',
    offsetX: 0,
    offsetY: 4
  }

  // 深阴影 — 悬浮
  static readonly DEEP: ShadowOptions = {
    radius: 24,
    color: '#261A1612',
    offsetX: 0,
    offsetY: 8
  }

  // 浮层阴影
  static readonly FLOATING: ShadowOptions = {
    radius: 32,
    color: '#331A1612',
    offsetX: 0,
    offsetY: 12
  }
}

// ==================== 动画系统 ====================
// HarmonyOS 6.0 弹性动画曲线

export class InkMotion {
  // 时长
  static readonly INSTANT: number = 100
  static readonly FAST: number = 200
  static readonly NORMAL: number = 300
  static readonly SLOW: number = 500
  static readonly CINEMATIC: number = 800

  // 缓动曲线
  static readonly EASE_OUT: Curve = Curve.EaseOut
  static readonly EASE_IN_OUT: Curve = Curve.EaseInOut
  static readonly FRICTION: Curve = Curve.Friction
  static readonly SHARP: Curve = Curve.Sharp

  // 弹簧参数
  static readonly SPRING_RESPONSE: number = 0.55
  static readonly SPRING_DAMPING: number = 0.82
}

// ==================== 布局常量 ====================

export class InkLayout {
  // Tab 栏高度
  static readonly TAB_BAR_HEIGHT: number = 56

  // 标题栏高度
  static readonly HEADER_HEIGHT: number = 48

  // 卡片最小高度
  static readonly CARD_MIN_HEIGHT: number = 80

  // 书籍封面比例 (宽:高 = 3:4)
  static readonly COVER_RATIO: number = 0.75

  // 封面尺寸
  static readonly COVER_SM_W: number = 56
  static readonly COVER_SM_H: number = 75
  static readonly COVER_MD_W: number = 76
  static readonly COVER_MD_H: number = 102
  static readonly COVER_LG_W: number = 100
  static readonly COVER_LG_H: number = 133

  // 断点
  static readonly BREAKPOINT_SM: number = 320
  static readonly BREAKPOINT_MD: number = 600
  static readonly BREAKPOINT_LG: number = 840

  // 网格列数
  static readonly GRID_COLUMNS_PHONE: number = 3
  static readonly GRID_COLUMNS_TABLET: number = 5

  // 最小触控区域 (HarmonyOS 6.0 规范)
  static readonly MIN_TOUCH_TARGET: number = 48
}
