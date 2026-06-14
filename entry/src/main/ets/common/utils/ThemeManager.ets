import { ThemeColor, ThemeStorageKey } from "../constants/Theme";
import { ThemeItem } from "../model/Theme";
import MySetConstants from "../constants/MySetConstants";

export class ThemeManager {
  // 莫兰迪色系 — 10种默认主题
  themeList: ThemeItem[] = [
    { text: '烟粉', mainColor: ThemeColor.SMOKE_PINK.mainColor, secondColor: ThemeColor.SMOKE_PINK.secondColor },
    { text: '雾蓝', mainColor: ThemeColor.MIST_BLUE.mainColor, secondColor: ThemeColor.MIST_BLUE.secondColor },
    { text: '枯荷', mainColor: ThemeColor.WITHERED_LOTUS.mainColor, secondColor: ThemeColor.WITHERED_LOTUS.secondColor },
    { text: '松绿', mainColor: ThemeColor.MOSS_GREEN.mainColor, secondColor: ThemeColor.MOSS_GREEN.secondColor },
    { text: '藕紫', mainColor: ThemeColor.LOTUS_PURPLE.mainColor, secondColor: ThemeColor.LOTUS_PURPLE.secondColor },
    { text: '琥珀', mainColor: ThemeColor.AMBER.mainColor, secondColor: ThemeColor.AMBER.secondColor },
    { text: '灰蓝', mainColor: ThemeColor.WHALE_BLUE.mainColor, secondColor: ThemeColor.WHALE_BLUE.secondColor },
    { text: '柿红', mainColor: ThemeColor.PERSIMMON.mainColor, secondColor: ThemeColor.PERSIMMON.secondColor },
    { text: '青灰', mainColor: ThemeColor.CELADON_GREY.mainColor, secondColor: ThemeColor.CELADON_GREY.secondColor },
    { text: '墨竹', mainColor: ThemeColor.INK_BAMBOO.mainColor, secondColor: ThemeColor.INK_BAMBOO.secondColor },
  ]

  init() {
    PersistentStorage.persistProp<ThemeItem>(ThemeStorageKey.THEME, this.themeList[2])
    PersistentStorage.persistProp<string>(ThemeStorageKey.THEMELISTSTR, JSON.stringify(this.themeList))

    // 解析主题数组字符串 加载主题
    const str = AppStorage.get<string>(ThemeStorageKey.THEMELISTSTR)
    const themeList = JSON.parse(str as string) as ThemeItem[]
    AppStorage.setOrCreate<ThemeItem[]>(ThemeStorageKey.THEMELIST, themeList)

    PersistentStorage.persistProp<number>(ThemeStorageKey.THEMEINDEX, 2) // 被选中主题的索引默认为枯荷(2)
    PersistentStorage.persistProp<number>(ThemeStorageKey.SPLASH_INDEX, 0) // 启动页样式默认为0(默认)
    
    // 如果当前存储的索引为0（旧默认值烟粉），则自动迁移/升级到新的默认主题枯荷（索引为2）
    if (AppStorage.get<number>(ThemeStorageKey.THEMEINDEX) === 0) {
      AppStorage.setOrCreate<number>(ThemeStorageKey.THEMEINDEX, 2)
      AppStorage.setOrCreate<ThemeItem>(ThemeStorageKey.THEME, this.themeList[2])
    }

    // 确保当前启动页索引也是默认值
    if (AppStorage.get<number>(ThemeStorageKey.SPLASH_INDEX) === undefined) {
      AppStorage.setOrCreate<number>(ThemeStorageKey.SPLASH_INDEX, 0)
    }

    PersistentStorage.persistProp<number>(ThemeStorageKey.ICON_INDEX, 0) // 桌面图标
    PersistentStorage.persistProp<string>(ThemeStorageKey.SPLASH_CUSTOM_IMAGE, '') // 自定义启动图片
    PersistentStorage.persistProp<string>(ThemeStorageKey.USER_NICKNAME, '夏目友人') // 用户昵称
    PersistentStorage.persistProp<string>(ThemeStorageKey.USER_SIGNATURE, '以书为伴，以墨为友') // 用户签名
    PersistentStorage.persistProp<string>(ThemeStorageKey.USER_GENDER, '保密') // 用户性别
    PersistentStorage.persistProp<string>(ThemeStorageKey.USER_AVATAR, '') // 用户头像URI

    // 个人设置持久化注册
    PersistentStorage.persistProp<boolean>(MySetConstants.SET_REFRESH, true)
    PersistentStorage.persistProp<boolean>(MySetConstants.SET_JUMP, true)
    PersistentStorage.persistProp<boolean>(MySetConstants.SET_REPLACE, true)
    PersistentStorage.persistProp<boolean>(MySetConstants.SET_TIP, true)
    PersistentStorage.persistProp<boolean>(MySetConstants.SET_IMG_ANTI, true)
    PersistentStorage.persistProp<boolean>(MySetConstants.SET_HEAD, true)
    PersistentStorage.persistProp<boolean>(MySetConstants.SET_SEARCH, true)
    PersistentStorage.persistProp<number>(MySetConstants.SET_PRE_DOWNLOAD, 10)
    PersistentStorage.persistProp<string>(MySetConstants.SET_LANGUAGE, '跟随系统')
  }

  setTheme(newTheme: ThemeItem, index: number) {
    AppStorage.setOrCreate<ThemeItem>(ThemeStorageKey.THEME, newTheme)
    AppStorage.setOrCreate<number>(ThemeStorageKey.THEMEINDEX, index)
  }

  addTheme(newTheme: ThemeItem) {
    const str = AppStorage.get<string>(ThemeStorageKey.THEMELISTSTR)
    const themeList = JSON.parse(str as string) as ThemeItem[]
    themeList.push(newTheme)
    AppStorage.setOrCreate(ThemeStorageKey.THEMELISTSTR, JSON.stringify(themeList))
    AppStorage.setOrCreate<ThemeItem[]>(ThemeStorageKey.THEMELIST, themeList)
  }

  deleteTheme(index: number) {
    const str = AppStorage.get<string>(ThemeStorageKey.THEMELISTSTR)
    let themeList = JSON.parse(str as string) as ThemeItem[]
    let activeIndex: number = AppStorage.get<number>(ThemeStorageKey.THEMEINDEX) as number
    if (activeIndex > index) {
        --activeIndex
    } else if (activeIndex == index) {
      activeIndex = 0
    }
    themeList = themeList.filter((item, i) => i != index)
    this.setTheme(themeList[activeIndex], activeIndex)
    AppStorage.setOrCreate(ThemeStorageKey.THEMELISTSTR, JSON.stringify(themeList))
    AppStorage.setOrCreate<ThemeItem[]>(ThemeStorageKey.THEMELIST, themeList)
  }
}

// 单例模式
export const themeManager = new ThemeManager()
