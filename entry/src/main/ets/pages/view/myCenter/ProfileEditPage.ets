import router from '@ohos.router'
import { ThemeStorageKey } from '../../../common/constants/Theme'
import { ThemeItem } from '../../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout, InkMotion
} from '../../../common/constants/DesignTokens'
import { pickerAvatar, PhotoSelectResultClean } from '../../../common/utils/photoViewPicker'
import picker from '@ohos.file.picker'

// ===== 昵称编辑组件 =====
@Component
struct NicknameEditSheet {
  @Link nickname: string
  @State tempValue: string = ''
  onConfirm: () => void = () => {}
  onCancel: () => void = () => {}
  themeColor: string = InkPalette.CINNABAR

  private readonly MAX_LENGTH: number = 12

  aboutToAppear() {
    this.tempValue = this.nickname
  }

  build() {
    Column() {
      // 拖拽指示条
      Row()
        .width(36)
        .height(4)
        .borderRadius(2)
        .backgroundColor(InkPalette.INK_WHISPER)
        .margin({ top: InkSpacing.MD, bottom: InkSpacing.SM })

      // 标题栏
      Row() {
        Text('取消')
          .fontSize(InkTypography.BODY)
          .fontColor(InkPalette.INK_GHOST)
          .padding({ left: InkSpacing.XS, right: InkSpacing.XS, top: InkSpacing.XS, bottom: InkSpacing.XS })
          .onClick(() => { this.onCancel() })

        Text('修改昵称')
          .fontSize(InkTypography.TITLE_SMALL)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)

        Text('保存')
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tempValue.length > 0 ? this.themeColor : InkPalette.INK_MIST)
          .padding({ left: InkSpacing.XS, right: InkSpacing.XS, top: InkSpacing.XS, bottom: InkSpacing.XS })
          .onClick(() => {
            if (this.tempValue.length > 0) {
              this.nickname = this.tempValue
              this.onConfirm()
            }
          })
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .padding({ left: InkSpacing.XL, right: InkSpacing.XL })

      // 输入区域
      Column({ space: InkSpacing.SM }) {
        TextInput({ text: this.tempValue, placeholder: '请输入昵称' })
          .height(48)
          .backgroundColor(InkPalette.PAPER_WARM)
          .borderRadius(InkRadius.MD)
          .fontSize(InkTypography.BODY)
          .placeholderColor(InkPalette.INK_MIST)
          .maxLength(this.MAX_LENGTH)
          .onChange((value: string) => {
            this.tempValue = value
          })

        // 字数提示
        Text(`${this.tempValue.length}/${this.MAX_LENGTH}`)
          .fontSize(InkTypography.CAPTION)
          .fontColor(InkPalette.INK_MIST)
          .width('100%')
          .textAlign(TextAlign.End)
      }
      .padding({ left: InkSpacing.XL, right: InkSpacing.XL })
    }
    .width('100%')
    .backgroundColor(InkPalette.PAPER)
    .borderRadius({ topLeft: InkRadius.SHEET, topRight: InkRadius.SHEET })
  }
}

// ===== 签名编辑组件 =====
@Component
struct SignatureEditSheet {
  @Link signature: string
  @State tempValue: string = ''
  onConfirm: () => void = () => {}
  onCancel: () => void = () => {}
  themeColor: string = InkPalette.CINNABAR

  private readonly MAX_LENGTH: number = 30

  aboutToAppear() {
    this.tempValue = this.signature
  }

  build() {
    Column() {
      // 拖拽指示条
      Row()
        .width(36)
        .height(4)
        .borderRadius(2)
        .backgroundColor(InkPalette.INK_WHISPER)
        .margin({ top: InkSpacing.MD, bottom: InkSpacing.SM })

      // 标题栏
      Row() {
        Text('取消')
          .fontSize(InkTypography.BODY)
          .fontColor(InkPalette.INK_GHOST)
          .padding({ left: InkSpacing.XS, right: InkSpacing.XS, top: InkSpacing.XS, bottom: InkSpacing.XS })
          .onClick(() => { this.onCancel() })

        Text('修改签名')
          .fontSize(InkTypography.TITLE_SMALL)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)

        Text('保存')
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tempValue.length > 0 ? this.themeColor : InkPalette.INK_MIST)
          .padding({ left: InkSpacing.XS, right: InkSpacing.XS, top: InkSpacing.XS, bottom: InkSpacing.XS })
          .onClick(() => {
            if (this.tempValue.length > 0) {
              this.signature = this.tempValue
              this.onConfirm()
            }
          })
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .padding({ left: InkSpacing.XL, right: InkSpacing.XL })

      // 输入区域
      Column({ space: InkSpacing.SM }) {
        TextArea({ text: this.tempValue, placeholder: '写下你的座右铭…' })
          .height(80)
          .backgroundColor(InkPalette.PAPER_WARM)
          .borderRadius(InkRadius.MD)
          .fontSize(InkTypography.BODY)
          .placeholderColor(InkPalette.INK_MIST)
          .maxLength(this.MAX_LENGTH)
          .onChange((value: string) => {
            this.tempValue = value
          })

        // 字数提示
        Text(`${this.tempValue.length}/${this.MAX_LENGTH}`)
          .fontSize(InkTypography.CAPTION)
          .fontColor(InkPalette.INK_MIST)
          .width('100%')
          .textAlign(TextAlign.End)
      }
      .padding({ left: InkSpacing.XL, right: InkSpacing.XL })
    }
    .width('100%')
    .backgroundColor(InkPalette.PAPER)
    .borderRadius({ topLeft: InkRadius.SHEET, topRight: InkRadius.SHEET })
  }
}

// ===== 性别选择组件 =====
@Component
struct GenderSelectSheet {
  @Link gender: string
  onConfirm: () => void = () => {}
  themeColor: string = InkPalette.CINNABAR

  @State private genderList: GenderOption[] = [
    { label: '男', icon: '♂' },
    { label: '女', icon: '♀' },
    { label: '保密', icon: '✦' }
  ]

  build() {
    Column() {
      // 拖拽指示条
      Row()
        .width(36)
        .height(4)
        .borderRadius(2)
        .backgroundColor(InkPalette.INK_WHISPER)
        .margin({ top: InkSpacing.MD, bottom: InkSpacing.SM })

      // 标题
      Text('选择性别')
        .fontSize(InkTypography.TITLE_SMALL)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: InkSpacing.SM, bottom: InkSpacing.LG })

      // 选项列表
      Column({ space: InkSpacing.SM }) {
        ForEach(this.genderList, (item: GenderOption) => {
          Row() {
            // 图标
            Text(item.icon)
              .fontSize(InkTypography.TITLE)
              .fontColor(this.gender === item.label ? this.themeColor : InkPalette.INK_GHOST)
              .width(32)
              .textAlign(TextAlign.Center)

            Text(item.label)
              .fontSize(InkTypography.BODY)
              .fontWeight(this.gender === item.label ? FontWeight.Medium : FontWeight.Normal)
              .fontColor(this.gender === item.label ? this.themeColor : InkPalette.INK)
              .margin({ left: InkSpacing.MD })

            Blank()

            if (this.gender === item.label) {
              Image($r('app.media.ic_public_confirm'))
                .width(18)
                .height(18)
                .fillColor(this.themeColor)
            }
          }
          .width('100%')
          .height(52)
          .padding({ left: InkSpacing.XL, right: InkSpacing.XL })
          .borderRadius(InkRadius.MD)
          .backgroundColor(this.gender === item.label ? InkPalette.PAPER_WARM : Color.Transparent)
          .onClick(() => {
            this.gender = item.label
            this.onConfirm()
          })
        })
      }
      .padding({ left: InkSpacing.MD, right: InkSpacing.MD })
    }
    .width('100%')
    .backgroundColor(InkPalette.PAPER)
    .borderRadius({ topLeft: InkRadius.SHEET, topRight: InkRadius.SHEET })
  }
}

interface GenderOption {
  label: string
  icon: string
}

// ===== 设置行组件 =====
@Component
struct ProfileRow {
  label: string = ''
  @Prop value: string = ''
  themeColor: string = InkPalette.CINNABAR
  @Prop showDivider: boolean = true
  onTap: () => void = () => {}

  build() {
    Column() {
      Row() {
        Text(this.label)
          .fontSize(InkTypography.BODY)
          .fontColor(InkPalette.INK)
          .fontWeight(FontWeight.Normal)

        Blank()

        Text(this.value)
          .fontSize(InkTypography.BODY)
          .fontColor(InkPalette.INK_GHOST)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: '60%' })

        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .width(16)
          .height(16)
          .fillColor(InkPalette.INK_WHISPER)
          .margin({ left: InkSpacing.XS })
      }
      .width('100%')
      .height(56)
      .padding({ left: InkSpacing.XL, right: InkSpacing.LG })
      .onClick(() => { this.onTap() })

      if (this.showDivider) {
        Divider()
          .color(InkPalette.PAPER_DEEP)
          .margin({ left: InkSpacing.XL })
      }
    }
  }
}

// ===== 主页面 =====
@Entry
@Component
struct ProfileEditPage {
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @StorageLink(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  @StorageLink(ThemeStorageKey.USER_NICKNAME) nickname: string = '夏目友人'
  @StorageLink(ThemeStorageKey.USER_SIGNATURE) signature: string = '以书为伴，以墨为友'
  @StorageLink(ThemeStorageKey.USER_GENDER) gender: string = '保密'
  @StorageLink(ThemeStorageKey.USER_AVATAR) avatarUri: string = ''

  @State showSheet: boolean = false
  @State sheetType: string = ''
  @State sheetHeight: number = 280
  @State avatarScale: number = 1

  private getThemeColor(): string {
    return this.theme?.mainColor || InkPalette.CINNABAR
  }

  build() {
    Column() {
      // ===== 标题栏 =====
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(22)
            .height(22)
            .fillColor(InkPalette.INK)
        }
        .width(InkLayout.MIN_TOUCH_TARGET)
        .height(InkLayout.MIN_TOUCH_TARGET)
        .borderRadius(InkRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { router.back() })

        Text('个人资料')
          .fontSize(InkTypography.TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位保持标题居中
        Row().width(InkLayout.MIN_TOUCH_TARGET).height(InkLayout.MIN_TOUCH_TARGET)
      }
      .padding({ left: InkSpacing.SM, right: InkSpacing.SM })
      .width('100%')
      .height(InkLayout.HEADER_HEIGHT)
      .margin({ top: this.topRectHeight })

      Scroll() {
        Column({ space: InkSpacing.LG }) {

          // ===== 头像区域 — 视觉焦点 =====
          Column() {
            // 装饰性背景
            Stack() {
              // 装饰圆
              Row()
                .width(120)
                .height(120)
                .borderRadius(InkRadius.FULL)
                .backgroundColor(InkPalette.PAPER_DEEP)
                .opacity(0.5)

              // 头像
              Stack() {
                Image(this.avatarUri ? this.avatarUri : $r('app.media.user_avatar'))
                  .width(88)
                  .height(88)
                  .borderRadius(InkRadius.FULL)
                  .border({ width: 3, color: InkPalette.PAPER })
                  .shadow(InkShadow.MEDIUM)
                  .scale({ x: this.avatarScale, y: this.avatarScale })
                  .animation({
                    duration: InkMotion.FAST,
                    curve: Curve.EaseOut
                  })

                // 相机编辑图标
                Row() {
                  Image($r('app.media.my_center_set_icon'))
                    .width(16)
                    .height(16)
                    .fillColor(Color.White)
                }
                .width(28)
                .height(28)
                .borderRadius(InkRadius.FULL)
                .backgroundColor(this.theme?.mainColor || InkPalette.CINNABAR)
                .border({ width: 2, color: InkPalette.PAPER })
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)
                .position({ right: 0, bottom: 0 })
                .shadow(InkShadow.SOFT)
              }
              .width(88)
              .height(88)
            }
            .margin({ top: InkSpacing.XXL, bottom: InkSpacing.LG })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.avatarScale = 0.92
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.avatarScale = 1
              }
            })
            .onClick(async () => {
              try {
                let res: picker.PhotoSelectResult | undefined = await pickerAvatar()
                if (res) {
                  let cleanRes = res as PhotoSelectResultClean
                  if (cleanRes.photoUris && cleanRes.photoUris.length > 0) {
                    this.avatarUri = cleanRes.photoUris[0]
                  }
                }
              } catch (e) {
                // 用户取消选择或发生错误
              }
            })

            // 提示文字
            Text('点击更换头像')
              .fontSize(InkTypography.CAPTION)
              .fontColor(InkPalette.INK_MIST)
              .margin({ bottom: InkSpacing.XL })
          }
          .width('100%')
          .backgroundColor(InkPalette.PAPER)
          .borderRadius(InkRadius.CARD)
          .shadow(InkShadow.SOFT)
          .alignItems(HorizontalAlign.Center)

          // ===== 基本信息卡片 =====
          Column() {
            // 分组标题
            Text('基本信息')
              .fontSize(InkTypography.CAPTION)
              .fontColor(InkPalette.INK_GHOST)
              .fontWeight(FontWeight.Medium)
              .letterSpacing(0.5)
              .width('100%')
              .padding({
                left: InkSpacing.XL,
                top: InkSpacing.LG,
                bottom: InkSpacing.SM
              })

            ProfileRow({
              label: '昵称',
              value: this.nickname,
              themeColor: this.theme?.mainColor || InkPalette.CINNABAR,
              showDivider: true,
              onTap: () => { this.openSheet('nickname', 220) }
            })

            ProfileRow({
              label: '个性签名',
              value: this.signature,
              themeColor: this.theme?.mainColor || InkPalette.CINNABAR,
              showDivider: true,
              onTap: () => { this.openSheet('signature', 280) }
            })

            ProfileRow({
              label: '性别',
              value: this.gender,
              themeColor: this.theme?.mainColor || InkPalette.CINNABAR,
              showDivider: false,
              onTap: () => { this.openSheet('gender', 280) }
            })
          }
          .width('100%')
          .backgroundColor(InkPalette.PAPER)
          .borderRadius(InkRadius.CARD)
          .shadow(InkShadow.SOFT)

          // ===== 阅读偏好卡片 =====
          Column() {
            // 分组标题
            Text('阅读偏好')
              .fontSize(InkTypography.CAPTION)
              .fontColor(InkPalette.INK_GHOST)
              .fontWeight(FontWeight.Medium)
              .letterSpacing(0.5)
              .width('100%')
              .padding({
                left: InkSpacing.XL,
                top: InkSpacing.LG,
                bottom: InkSpacing.SM
              })

            ProfileRow({
              label: '阅读偏好',
              value: '未设置',
              themeColor: this.theme?.mainColor || InkPalette.CINNABAR,
              showDivider: true,
              onTap: () => {}
            })

            ProfileRow({
              label: '书架展示',
              value: '列表模式',
              themeColor: this.theme?.mainColor || InkPalette.CINNABAR,
              showDivider: false,
              onTap: () => {}
            })
          }
          .width('100%')
          .backgroundColor(InkPalette.PAPER)
          .borderRadius(InkRadius.CARD)
          .shadow(InkShadow.SOFT)

          // 底部留白
          Blank()
            .height(InkSpacing.MASSIVE)
        }
        .padding({
          left: InkSpacing.PAGE_HORIZONTAL,
          right: InkSpacing.PAGE_HORIZONTAL,
          top: InkSpacing.MD,
          bottom: InkSpacing.XXL
        })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(InkPalette.PAPER_EMBEDDED)
    // 统一半模态面板
    .bindSheet($$this.showSheet, this.unifiedSheetBuilder(), {
      height: this.sheetHeight,
      dragBar: false,
      showClose: false,
      backgroundColor: InkPalette.PAPER,
      preferType: SheetType.BOTTOM
    })
  }

  private openSheet(type: string, height: number): void {
    this.sheetType = type
    this.sheetHeight = height
    this.showSheet = true
  }

  private closeSheet(): void {
    this.showSheet = false
  }

  @Builder
  unifiedSheetBuilder() {
    if (this.sheetType === 'nickname') {
      NicknameEditSheet({
        nickname: $nickname,
        themeColor: this.theme?.mainColor || InkPalette.CINNABAR,
        onConfirm: () => { this.closeSheet() },
        onCancel: () => { this.closeSheet() }
      })
    } else if (this.sheetType === 'signature') {
      SignatureEditSheet({
        signature: $signature,
        themeColor: this.theme?.mainColor || InkPalette.CINNABAR,
        onConfirm: () => { this.closeSheet() },
        onCancel: () => { this.closeSheet() }
      })
    } else if (this.sheetType === 'gender') {
      GenderSelectSheet({
        gender: $gender,
        themeColor: this.theme?.mainColor || InkPalette.CINNABAR,
        onConfirm: () => { this.closeSheet() }
      })
    }
  }
}
