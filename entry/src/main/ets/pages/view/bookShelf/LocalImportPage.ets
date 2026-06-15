import { router } from '@kit.ArkUI';
import fs from '@ohos.file.fs';
import { ThemeStorageKey } from '../../../common/constants/Theme';
import { ThemeItem } from '../../../common/model/Theme';
import { showMessage } from '../../../componets/common/promptShow';
import { FileHandler } from '../../../common/utils/FileHandler';
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkMotion, InkLayout
} from '../../../common/constants/DesignTokens';

class SmartScanItem {
  bookName: string
  Type: string
  CreateTime: Date
  size: string
  rawSize: number
  uri: string
  checked: boolean = false

  constructor(
    bookName: string,
    size: string,
    rawSize: number,
    uri: string,
    Type: string = 'EPUB',
    CreateTime: Date = new Date()
  ) {
    this.bookName = bookName
    this.size = size
    this.rawSize = rawSize
    this.uri = uri
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

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
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
  @State isAllSelected: boolean = false
  
  menuList: string[] = [
    '按时间排序',
    '按名称排序',
    '按大小排序',
    '系统文件夹',
  ]
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  // 触发文档选择器
  async selectFiles() {
    try {
      const selectedUris = await FileHandler.documentPickerFile(20, [
        '.txt', '.epub', '.pdf', '.mobi', '.azw', '.azw3', '.chm',
        '.cbz', '.cbr', '.cb7',
        '.m4b', '.mp3', '.wav', '.flac', '.m4a', '.ogg', '.opus'
      ]);
      
      if (!selectedUris || selectedUris.length === 0) {
        return;
      }
      
      const newItems: SmartScanItem[] = [];
      for (let i = 0; i < selectedUris.length; i++) {
        const uri = selectedUris[i];
        try {
          const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
          const stat = fs.statSync(file.fd);
          const ext = file.name.substring(file.name.lastIndexOf('.')).toUpperCase().replace('.', '');
          const createDate = stat.mtime ? new Date(stat.mtime * 1000) : new Date();
          
          newItems.push(new SmartScanItem(
            file.name,
            formatBytes(stat.size),
            stat.size,
            uri,
            ext,
            createDate
          ));
          fs.closeSync(file);
        } catch (e) {
          console.error(`读取选择文件详情失败: ${e.message}`);
        }
      }
      
      // 合并到已扫描列表，并默认选中
      if (newItems.length > 0) {
        newItems.forEach(item => item.checked = true);
        this.SmartScanItemList = [...this.SmartScanItemList, ...newItems];
        this.updateSelectAllState();
      }
    } catch (err) {
      console.error(`选择文件失败: ${err.message}`);
      showMessage('选择文件失败');
    }
  }

  // 排序逻辑
  sortList(index: number) {
    if (index === 0) {
      // 按时间
      this.SmartScanItemList.sort((a, b) => b.CreateTime.getTime() - a.CreateTime.getTime());
    } else if (index === 1) {
      // 按名称
      this.SmartScanItemList.sort((a, b) => a.bookName.localeCompare(b.bookName));
    } else if (index === 2) {
      // 按大小
      this.SmartScanItemList.sort((a, b) => b.rawSize - a.rawSize);
    }
    // 强制触发更新
    this.SmartScanItemList = [...this.SmartScanItemList];
  }

  // 全选/取消全选
  toggleSelectAll(checked: boolean) {
    this.isAllSelected = checked;
    this.SmartScanItemList.forEach(item => {
      item.checked = checked;
    });
    this.SmartScanItemList = [...this.SmartScanItemList];
  }

  // 更新全选框状态
  updateSelectAllState() {
    if (this.SmartScanItemList.length === 0) {
      this.isAllSelected = false;
      return;
    }
    this.isAllSelected = this.SmartScanItemList.every(item => item.checked);
  }

  // 执行批量导入
  async doImport() {
    const selectedItems = this.SmartScanItemList.filter(item => item.checked);
    if (selectedItems.length === 0) {
      showMessage('请选择要导入的文件');
      return;
    }
    
    let successCount = 0;
    for (let i = 0; i < selectedItems.length; i++) {
      const item = selectedItems[i];
      const success = await FileHandler.importLocalFile(item.uri, this.currentTabIndex);
      if (success) {
        successCount++;
      }
    }
    
    showMessage(`成功导入 ${successCount} 本书籍`);
    // 触发书架刷新
    AppStorage.setOrCreate<number>('BOOK_IS_BOOK_REFRESHING', (AppStorage.get<number>('BOOK_IS_BOOK_REFRESHING') || 0) + 1);
    
    setTimeout(() => {
      router.back();
    }, 800);
  }

  // 获取类型对应的背景色
  getTypeBgColor(type: string): string {
    const audioExts = ['MP3', 'WAV', 'FLAC', 'M4A', 'M4B', 'OGG', 'OPUS'];
    const mangaExts = ['CBZ', 'CBR', 'CB7'];
    if (audioExts.includes(type)) {
      return InkPalette.INDIGO_MIST;
    }
    if (mangaExts.includes(type)) {
      return InkPalette.CELADON_MIST;
    }
    if (type === 'PDF') {
      return InkPalette.CINNABAR_GLOW;
    }
    return InkPalette.AMBER_GLOW;
  }

  // 获取类型对应的字体颜色
  getTypeTextColor(type: string): string {
    const audioExts = ['MP3', 'WAV', 'FLAC', 'M4A', 'M4B', 'OGG', 'OPUS'];
    const mangaExts = ['CBZ', 'CBR', 'CB7'];
    if (audioExts.includes(type)) {
      return InkPalette.INDIGO;
    }
    if (mangaExts.includes(type)) {
      return InkPalette.CELADON;
    }
    if (type === 'PDF') {
      return InkPalette.CINNABAR;
    }
    return InkPalette.AMBER;
  }

  @Builder
  MenuBuilder() {
    Column() {
      ForEach(this.menuList, (item: string, index: number) => {
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
          if (index === 3) {
            this.selectFiles();
          } else {
            this.sortList(index);
          }
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
        Checkbox({ name: 'all', group: 'allSelectGroup' })
          .select(this.isAllSelected)
          .selectedColor(this.theme.mainColor || InkPalette.CINNABAR)
          .onChange((checked: boolean) => {
            this.toggleSelectAll(checked);
          })
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
          this.doImport();
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
          .fontColor(this.getTypeTextColor(item.Type))
          .fontSize(InkTypography.MICRO)
          .fontWeight(FontWeight.Bold)
      }
      .backgroundColor(this.getTypeBgColor(item.Type))
      .width(44)
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

      Checkbox({ name: `${item.bookName}`, group: 'fileSelectGroup' })
        .select(item.checked)
        .selectedColor(this.theme.mainColor || InkPalette.CINNABAR)
        .size({ width: 18, height: 18 })
        .onChange((checked: boolean) => {
          item.checked = checked;
          this.updateSelectAllState();
        })
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

  // 过滤出符合搜索条件的内容
  getFilteredList(): SmartScanItem[] {
    if (!this.SearchValue) {
      return this.SmartScanItemList;
    }
    return this.SmartScanItemList.filter(item => 
      item.bookName.toLowerCase().includes(this.SearchValue.toLowerCase())
    );
  }

  @Builder
  FileListPanel() {
    Column() {
      if (this.SmartScanItemList.length > 0) {
        List() {
          ForEach(this.getFilteredList(), (item: SmartScanItem) => {
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
          Stack({ alignContent: Alignment.Center }) {
            Column()
              .width(100)
              .height(100)
              .borderRadius(50)
              .backgroundColor(InkPalette.PAPER_WARM)
            Image($r('app.media.icon_no_source_find'))
              .width(64)
              .height(64)
              .opacity(0.7)
          }
          .width(100)
          .height(100)
          
          Text('暂未选择本地文件')
            .fontSize(InkTypography.BODY_SMALL)
            .fontColor(InkPalette.INK_MIST)
            .textAlign(TextAlign.Center)
            
          Button('选择并扫描本地文件')
            .fontSize(InkTypography.BODY_SMALL)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .backgroundColor(this.theme.mainColor || InkPalette.CELADON)
            .width(180)
            .height(36)
            .borderRadius(InkRadius.BUTTON)
            .onClick(() => {
              this.selectFiles();
            })
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
      // 头部操作栏
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
          .onChange((value: string) => {
            this.SearchValue = value;
          })
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