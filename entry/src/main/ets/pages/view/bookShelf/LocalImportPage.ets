import { router } from '@kit.ArkUI';
import fs from '@ohos.file.fs';
import { ThemeStorageKey } from '../../../common/constants/Theme';
import { ThemeItem } from '../../../common/model/Theme';
import { showMessage } from '../../../componets/common/promptShow';
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkMotion, InkLayout
} from '../../../common/constants/DesignTokens';

class SmartScanItem {
  bookName: string
  Type: string
  CreateTime: Date
  size: string

  constructor(
    bookName: string,
    size: string,
    Type: string = 'EPUB',
    CreateTime: Date = new Date()
  ) {
    this.bookName = bookName
    this.size = size
    this.Type = Type
    this.CreateTime = CreateTime
  }
}

function formatDate(date: Date): string {
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  return `${year}/${month}/${day}`;
}

@Entry
@Component
struct LocalImportPage {
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @State currentTabIndex: number = 0
  @State SearchValue: string = ""
  SearchController: SearchController = new SearchController()
  @State SmartScanItemList: SmartScanItem[] = []
  menuList: string[] = [
    '按时间排序',
    '按名称排序',
    '按大小排序',
    '系统文件夹',
  ]
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  // 加载测试数据
  onPageShow(): void {
    setTimeout(() => {
      this.SmartScanItemList = [
        new SmartScanItem("大主宰.txt", "14.2MB", "TXT", new Date()),
        new SmartScanItem("完美世界.epub", "8.5MB", "EPUB", new Date()),
        new SmartScanItem("遮天.pdf", "24.1MB", "PDF", new Date()),
        new SmartScanItem("宇宙职业选手.epub", "6.2MB", "EPUB", new Date()),
      ]
    }, 600)
  }

  @Builder
  MenuBuilder() {
    Column() {
      ForEach(this.menuList, (item: string, index) => {
        Row({ space: InkSpacing.SM }) {
          if (index === this.menuList.length - 1) {
            Image($r("app.media.my_center_file_icon"))
              .width(16)
              .height(16)
              .fillColor(InkPalette.INK)
          }
          Text(item)
            .fontSize(InkTypography.BODY_SMALL)
            .fontColor(InkPalette.INK)
        }
        .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
        .width("100%")
        .height(44)
        .onClick(() => {
          // 菜单项点击
        })

        if (index !== this.menuList.length - 1) {
          Divider().color(InkPalette.PAPER_WARM).strokeWidth(0.5)
        }
      })
    }
    .width(140)
    .backgroundColor(InkPalette.PAPER)
    .borderRadius(InkRadius.MD)
    .shadow(InkShadow.MEDIUM)
  }

  @Builder
  BottomBar() {
    Row() {
      Row({ space: InkSpacing.XS }) {
        CheckboxGroup({ group: 'checkboxGroup' })
          .selectedColor(this.theme.mainColor || InkPalette.CINNABAR)
        Text("全选")
          .fontSize(InkTypography.BODY)
          .fontColor(InkPalette.INK)
      }
      .alignItems(VerticalAlign.Center)

      Button("导入书架")
        .fontSize(InkTypography.BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor(this.theme.mainColor || InkPalette.CELADON)
        .width(120)
        .height(36)
        .borderRadius(InkRadius.BUTTON)
        .onClick(() => {
          showMessage("导入书架成功")
          router.back()
        })
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: InkSpacing.PAGE_HORIZONTAL, right: InkSpacing.PAGE_HORIZONTAL })
    .width("100%")
    .height(60)
    .backgroundColor(InkPalette.PAPER)
  }

  @Builder
  ScanShowItem(item: SmartScanItem) {
    Row() {
      // 格式小标签
      Row() {
        Text(item.Type)
          .fontColor(item.Type === 'EPUB' ? InkPalette.CELADON : (
            item.Type === 'TXT' ? InkPalette.AMBER : (
              item.Type === 'PDF' ? InkPalette.CINNABAR : InkPalette.INDIGO
            )
          ))
          .fontSize(InkTypography.MICRO)
          .fontWeight(FontWeight.Bold)
      }
      .backgroundColor(item.Type === 'EPUB' ? InkPalette.CELADON_MIST : (
        item.Type === 'TXT' ? InkPalette.AMBER_GLOW : (
          item.Type === 'PDF' ? InkPalette.CINNABAR_GLOW : InkPalette.INDIGO_MIST
        )
      ))
      .width(36)
      .height(36)
      .borderRadius(InkRadius.SM)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 文件详细信息
      Column({ space: InkSpacing.XXS }) {
        Text(item.bookName)
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${item.size} · ${formatDate(item.CreateTime)}`)
          .fontSize(InkTypography.CAPTION)
          .fontColor(InkPalette.INK_GHOST)
      }
      .margin({ left: InkSpacing.MD })
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Checkbox({ name: `${item.bookName}`, group: 'checkboxGroup' })
        .selectedColor(this.theme.mainColor || InkPalette.CINNABAR)
        .size({ width: 18, height: 18 })
    }
    .width("100%")
    .padding(InkSpacing.MD)
    .backgroundColor(Color.White)
    .borderRadius(InkRadius.CARD)
    .shadow(InkShadow.SUBTLE)
    .margin({ bottom: InkSpacing.SM })
  }

  @Builder
  TabHeaderBuilder(index: number, name: string) {
    Column({ space: InkSpacing.XXS }) {
      Text(name)
        .fontSize(InkTypography.BODY_SMALL)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? this.theme.mainColor || InkPalette.INK : InkPalette.INK_MIST)
      
      Row()
        .width(this.currentTabIndex === index ? 16 : 0)
        .height(2)
        .borderRadius(1)
        .backgroundColor(this.theme.mainColor || InkPalette.CELADON)
        .animation({ duration: InkMotion.NORMAL, curve: Curve.EaseOut })
    }
    .padding({ top: InkSpacing.SM, bottom: InkSpacing.SM, left: InkSpacing.LG, right: InkSpacing.LG })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  FileListPanel() {
    Column() {
      if (this.SmartScanItemList.length > 0) {
        List() {
          ForEach(this.SmartScanItemList, (item: SmartScanItem) => {
            ListItem() {
              this.ScanShowItem(item)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: InkSpacing.PAGE_HORIZONTAL, right: InkSpacing.PAGE_HORIZONTAL, top: InkSpacing.SM })

        Divider().color(InkPalette.PAPER_DEEP)
        this.BottomBar()
      } else {
        Column({ space: InkSpacing.LG }) {
          Image($r('app.media.no_record'))
            .width(160)
            .height(160)
            .opacity(0.6)
          Text('暂未扫描到可用书籍')
            .fontSize(InkTypography.BODY_SMALL)
            .fontColor(InkPalette.INK_MIST)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Column() {
      // 头部操作栏 — 统一且标准的导航顶栏
      Row() {
        Row() {
          Image($r('app.media.ic_public_return_left'))
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

        Text('导入书籍')
          .fontSize(InkTypography.TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)
          .margin({ left: InkSpacing.SM })

        Blank()

        Row() {
          Image($r('app.media.Column_More'))
            .width(22)
            .height(22)
            .fillColor(InkPalette.INK)
        }
        .width(InkLayout.MIN_TOUCH_TARGET)
        .height(InkLayout.MIN_TOUCH_TARGET)
        .borderRadius(InkRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .bindMenu(this.MenuBuilder())
      }
      .width('100%')
      .height(InkLayout.HEADER_HEIGHT)
      .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
      .margin({ top: this.topRectHeight })

      // 搜索栏
      Row() {
        Search({
          value: this.SearchValue,
          placeholder: '输入书名搜索',
          controller: this.SearchController
        })
          .backgroundColor(InkPalette.PAPER_WARM)
          .borderRadius(InkRadius.SEARCH)
          .width('100%')
      }
      .padding({ left: InkSpacing.PAGE_HORIZONTAL, right: InkSpacing.PAGE_HORIZONTAL, bottom: InkSpacing.SM })

      // 本地导入 Tab 分类导航
      Tabs({ barPosition: BarPosition.Start }) {
        TabContent() {
          this.FileListPanel()
        }
        .tabBar(this.TabHeaderBuilder(0, "智能扫描"))

        TabContent() {
          this.FileListPanel()
        }
        .tabBar(this.TabHeaderBuilder(1, "本地目录"))
      }
      .layoutWeight(1)
      .onChange((index) => {
        this.currentTabIndex = index
      })
      .barHeight(44)
    }
    .width("100%")
    .height("100%")
    .backgroundColor(InkPalette.PAPER_EMBEDDED)
    .padding({ bottom: this.bottomRectHeight })
  }
}