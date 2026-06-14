import { ThemeColorItem } from "../model/Theme"

// 莫兰迪色系主题 — 低饱和度、灰调、高级感
export class ThemeColor {
  // 烟粉 — 温柔如晨雾中的桃花
  static readonly SMOKE_PINK: ThemeColorItem = {
    mainColor: '#C4A4A0',
    secondColor: '#F2E8E6'
  }

  // 雾蓝 — 雨后天空的宁静
  static readonly MIST_BLUE: ThemeColorItem = {
    mainColor: '#7E9BB5',
    secondColor: '#E3EBF2'
  }

  // 枯荷 — 秋日残荷的侘寂
  static readonly WITHERED_LOTUS: ThemeColorItem = {
    mainColor: '#A89B7E',
    secondColor: '#EDE8DF'
  }

  // 松绿 — 苔藓覆石的沉稳
  static readonly MOSS_GREEN: ThemeColorItem = {
    mainColor: '#7A9A8B',
    secondColor: '#E2EDE7'
  }

  // 藕紫 — 暮色薰衣草的优雅
  static readonly LOTUS_PURPLE: ThemeColorItem = {
    mainColor: '#9B8EA8',
    secondColor: '#EBE6F0'
  }

  // 琥珀 — 老茶汤色的温厚
  static readonly AMBER: ThemeColorItem = {
    mainColor: '#B8976E',
    secondColor: '#F0E8DB'
  }

  // 灰蓝 — 深海鲸落的幽远
  static readonly WHALE_BLUE: ThemeColorItem = {
    mainColor: '#6E8A9E',
    secondColor: '#DDE7EE'
  }

  // 柿红 — 霜后柿子的暖意
  static readonly PERSIMMON: ThemeColorItem = {
    mainColor: '#C07858',
    secondColor: '#F2E2D8'
  }

  // 青灰 — 宋瓷天青的内敛
  static readonly CELADON_GREY: ThemeColorItem = {
    mainColor: '#8A9B8E',
    secondColor: '#E5EBE6'
  }

  // 墨竹 — 文人画竹的风骨
  static readonly INK_BAMBOO: ThemeColorItem = {
    mainColor: '#5C6B5E',
    secondColor: '#DDE2DE'
  }
}

// AppStorage key 标识
export class ThemeStorageKey {
  static readonly THEME: string = 'theme' // 主题key
  static readonly THEMELIST: string = 'themelist'
  static readonly THEMELISTSTR: string = 'themeliststr'
  static readonly THEMEINDEX: string = 'themeindex' // 被选中主题索引key
  static readonly SPLASH_INDEX: string = 'splashIndex' // 启动页样式索引
  static readonly ICON_INDEX: string = 'iconIndex' // 桌面图标索引
  static readonly SPLASH_CUSTOM_IMAGE: string = 'splashCustomImage' // 自定义启动图片
  static readonly USER_NICKNAME: string = 'userNickname' // 用户昵称
  static readonly USER_SIGNATURE: string = 'userSignature' // 用户签名
  static readonly USER_GENDER: string = 'userGender' // 用户性别
  static readonly USER_AVATAR: string = 'userAvatar' // 用户头像URI
}

// 启动页样式定义
export class SplashStyle {
  static readonly DEFAULT: number = 0    // 默认
  static readonly INK: number = 1        // 水墨
  static readonly PAPER: number = 2      // 素笺
  static readonly PAINTING: number = 3   // 丹青
  static readonly CELADON: number = 4    // 青瓷
  static readonly CUSTOM: number = 5     // 自定义
}
