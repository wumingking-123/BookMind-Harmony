import router from '@ohos.router'
import { dataItem } from '../../../componets/dataList/dataItem'
import { ThemeStorageKey } from '../../../common/constants/Theme'
import { ThemeItem } from '../../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../common/constants/DesignTokens'
import bookMarkUtils from '../../../common/utils/BookMarkUtils'
import readRecordDao from '../../../database/dao/ReadRecordDao'
import booksDao from '../../../database/dao/BooksDao'

@Entry
@Component
export default struct MyCenter {
  @State reading_time: number = 0
  // 顶部统计数据
  @State head_list: dataItem[] = [
    new dataItem('读过', 128),
    new dataItem('读完', 42),
    new dataItem('书签', 16),
    new dataItem('勋章', 5),
  ]
  // 中部功能快捷入口
  @State center_list: dataItem[] = [
    new dataItem('主题', 1, $r('app.media.my_center_book_icon')),
    new dataItem('书源', 2, $r('app.media.my_center_theme_icon')),
    new dataItem('净化', 3, $r('app.media.my_center_purify_icon')),
  ]
  // 底部设置列表
  @State end_list: dataItem[] = [
    new dataItem('帮助中心', 1, $r('app.media.my_center_help_icon')),
    new dataItem('关于我们', 2, $r('app.media.my_center_about_icon')),
    new dataItem('清理缓存', 3, $r('app.media.my_center_clean_icon')),
    new dataItem('文件管理', 4, $r('app.media.my_center_file_icon')),
    new dataItem('阅读统计', 5, $r('app.media.my_center_book_icon')),
  ]

  @StorageLink('topRectHeight') topRectHeight: number = 0
  // 主题颜色
  @StorageLink(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  @StorageLink(ThemeStorageKey.USER_NICKNAME) nickname: string = '夏目友人'
  @StorageLink(ThemeStorageKey.USER_AVATAR) avatarUri: string = ''

  getMainColor(): string {
    return this.theme?.mainColor || '#A89B7E';
  }

  getSecondColor(): string {
    return this.theme?.secondColor || '#EDE8DF';
  }

  async aboutToAppear() {
    // 加载真实统计数据
    try {
      let allBooks = await booksDao.search();
      let records = await readRecordDao.getAllRecords();
      let bookmarkCount = await bookMarkUtils.getTotalBookmarkCount();

      let readCount = records.length;
      let finishedCount = 0;
      for (let r of records) {
        let book = allBooks.find(b => b.bookName === r.bookName);
        if (book && book.totalChapterNum > 0 && book.durChapterIndex >= book.totalChapterNum - 1) {
          finishedCount++;
        }
      }

      this.head_list = [
        new dataItem('读过', readCount),
        new dataItem('读完', finishedCount),
        new dataItem('书签', bookmarkCount),
        new dataItem('勋章', 5),
      ];
    } catch (e) {
      console.error('Failed to load MyCenter stats:', e);
    }
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: InkSpacing.LG }) {
          // ===== 顶部操作栏 =====
          Row() {
            Blank()
            Row({ space: InkSpacing.LG }) {
              // 夜间模式图标
              Image($r('app.media.night_icon'))
                .width(22)
                .height(22)
                .fillColor(InkPalette.INK_FAINT)

              // 设置图标
              Image($r('app.media.my_center_set_icon'))
                .width(22)
                .height(22)
                .fillColor(InkPalette.INK_FAINT)
                .onClick(() => {
                  this.toMySetPage()
                })
            }
          }
          .width('100%')
          .padding({ right: InkSpacing.XL })

          // ===== 用户信息卡片 =====
          Column() {
            Column({ space: InkSpacing.LG }) {
              // 头像 + 昵称
              Row({ space: InkSpacing.LG }) {
                // 头像 — 点击编辑个人资料
                Stack() {
                  Image(this.avatarUri ? this.avatarUri : $r('app.media.user_avatar'))
                    .width(60)
                    .height(60)
                    .borderRadius(InkRadius.FULL)

                  // 编辑指示
                  Row() {
                    Image($r('app.media.writing'))
                      .width(12)
                      .height(12)
                      .fillColor(Color.White)
                  }
                  .width(22)
                  .height(22)
                  .borderRadius(InkRadius.FULL)
                  .backgroundColor(this.theme?.mainColor || '#A89B7E')
                  .border({ width: 1.5, color: InkPalette.PAPER })
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                  .position({ right: -2, bottom: -2 })
                  .shadow(InkShadow.SOFT)
                }
                .width(60)
                .height(60)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/view/myCenter/ProfileEditPage' })
                })

                // 昵称及阅读时长
                Column({ space: InkSpacing.XS }) {
                  Text(this.nickname)
                    .fontSize(InkTypography.TITLE)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(InkPalette.INK)

                  Row({ space: InkSpacing.XS }) {
                    Text('今日阅读')
                      .fontSize(InkTypography.CAPTION)
                      .fontColor(InkPalette.INK_MIST)
                    Text(`${this.reading_time}`)
                      .fontSize(InkTypography.CAPTION)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.theme?.mainColor || '#A89B7E')
                    Text('分钟')
                      .fontSize(InkTypography.CAPTION)
                      .fontColor(InkPalette.INK_MIST)
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/view/myCenter/ProfileEditPage' })
                })
              }
              .width('100%')

              // 统计数据
              Row() {
                ForEach(this.head_list, (item: dataItem, index: number) => {
                  Column({ space: InkSpacing.XS }) {
                    Text(item.value.toString())
                      .fontSize(InkTypography.TITLE)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(InkPalette.INK)

                    Text(item.title)
                      .fontSize(InkTypography.MICRO)
                      .fontColor(InkPalette.INK_MIST)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Center)
                  .onClick(() => {
                    this.head_onclick(index)
                  })
                })
              }
              .width('100%')
              .padding({ top: InkSpacing.MD })
              .border({ width: { top: 1 }, color: InkPalette.PAPER_DEEP })
            }
            .padding(InkSpacing.XL)
          }
          .width('100%')
          .backgroundColor(InkPalette.PAPER)
          .borderRadius(InkRadius.CARD)
          .shadow(InkShadow.SOFT)

          // ===== 功能快捷入口 — 主题/书源/净化 =====
          Column() {
            Row() {
              ForEach(this.center_list, (item: dataItem) => {
                Column({ space: InkSpacing.SM }) {
                  Row() {
                    Image(item.icon)
                      .width(24)
                      .height(24)
                      .fillColor(this.theme?.mainColor || '#A89B7E')
                  }
                  .width(48)
                  .height(48)
                  .borderRadius(InkRadius.MD)
                  .backgroundColor(this.theme?.secondColor || '#EDE8DF')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)

                  Text(item.title)
                    .fontSize(InkTypography.CAPTION)
                    .fontColor(InkPalette.INK_LIGHT)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
                .onClick(() => this.centerOnclick(item.value))
              })
            }
            .width('100%')
            .padding(InkSpacing.LG)
          }
          .width('100%')
          .backgroundColor(InkPalette.PAPER)
          .borderRadius(InkRadius.CARD)
          .shadow(InkShadow.SOFT)

          // ===== 功能快捷入口 — 主题/书源/净化 =====
          Column() {
            Column() {
              ForEach(this.end_list, (item: dataItem, index: number) => {
                Column() {
                  Row() {
                    Image(item.icon)
                      .width(20)
                      .height(20)
                      .fillColor(InkPalette.INK_FAINT)

                    Text(item.title)
                      .fontSize(InkTypography.BODY)
                      .fontColor(InkPalette.INK)
                      .layoutWeight(1)
                      .margin({ left: InkSpacing.MD })

                    Image($r('app.media.ic_public_right'))
                      .width(16)
                      .height(16)
                      .fillColor(InkPalette.INK_WHISPER)
                  }
                  .width('100%')
                  .height(InkLayout.MIN_TOUCH_TARGET)
                  .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
                  .onClick(() => this.endOnclick(item.value))

                  if (index < this.end_list.length - 1) {
                    Divider()
                      .color(InkPalette.PAPER_DEEP)
                      .margin({ left: 52 })
                  }
                }
              })
            }
            .padding({ top: InkSpacing.SM, bottom: InkSpacing.SM })
          }
          .width('100%')
          .backgroundColor(InkPalette.PAPER)
          .borderRadius(InkRadius.CARD)
          .shadow(InkShadow.SOFT)

          // 底部留白
          Blank(InkSpacing.XXL)
        }
        .padding({
          left: InkSpacing.PAGE_HORIZONTAL,
          right: InkSpacing.PAGE_HORIZONTAL,
          top: this.topRectHeight + InkSpacing.LG,
          bottom: InkSpacing.XXL
        })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom, // 渐变方向
      colors: [[this.theme?.mainColor || '#A89B7E', 0], [this.theme?.secondColor || '#EDE8DF', 0.08], [InkPalette.PAPER, 0.28]]
    })
  }

  // 读过点击事件
  head_onclick(value: number) {
    console.log('点击了' + value)
    if (value == 3) {
      // 勋章
    } else {
      router.pushUrl({
        url: 'pages/view/myCenter/readStatistics',
        params: { value: value }
      })
    }
  }

  // 书源,主题,净化点击事件
  centerOnclick(value: number | string) {
    switch (value) {
      // 点击主题
      case 1:
        router.pushUrl({
          url: '/pages/view/myCenter/MyThemeConfig'.slice(1)
        })
        break
      case 2:
        break
      case 3:
        break
    }
  }

  // 帮助中心,关于阅读,清理缓存,我的设置点击事件
  endOnclick(value: number | string) {
    switch (value) {
      case 1:
        // 帮助中心
        router.pushUrl({ url: 'pages/view/myCenter/helpCenterPage' })
        break
      case 2:
        // 关于我们
        router.pushUrl({ url: 'pages/view/myCenter/aboutUs/aboutUsPage' })
        break
      case 3:
        // 清理缓存
        router.pushUrl({ url: 'pages/view/myCenter/clearCache' })
        break
      case 4:
        // 文件管理
        router.pushUrl({ url: 'pages/view/myCenter/FileManagement' })
        break
      case 5:
        // 阅读统计
        router.pushUrl({ url: 'pages/view/myCenter/readStatistics' })
        break
    }
  }

  toMySetPage() {
    router.pushUrl({ url: 'pages/view/myCenter/MySetPage' })
  }
}
