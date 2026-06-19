import { PublicConstants } from '../../../common/constants/PublicConstants'
import { ColumnModifier } from '../../../common/utils/ComponetModifier'
import { dataItem } from '../../../componets/dataList/dataItem'
import { MyCenterTitle } from '../../../componets/myCenter/MyCenterTitle'
import { ThemeStorageKey } from '../../../common/constants/Theme'
import { ThemeItem } from '../../../common/model/Theme'
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../common/constants/DesignTokens'
import fs from '@ohos.file.fs';
import { common } from '@kit.AbilityKit';
import { showMessage } from '../../../componets/common/promptShow';

function getFileSize(path: string): number {
  try {
    let stat = fs.statSync(path);
    return stat.size;
  } catch(e) {
    return 0;
  }
}

function getDirSize(path: string): number {
  let size = 0;
  try {
    let stat = fs.statSync(path);
    if (stat.isDirectory()) {
      let files = fs.listFileSync(path);
      for (let i = 0; i < files.length; i++) {
        size += getDirSize(path + '/' + files[i]);
      }
    } else {
      size += stat.size;
    }
  } catch(e) {}
  return size;
}

function deleteDirContent(path: string) {
  try {
    let stat = fs.statSync(path);
    if (stat.isDirectory()) {
      let files = fs.listFileSync(path);
      for (let i = 0; i < files.length; i++) {
        let filePath = path + '/' + files[i];
        let fStat = fs.statSync(filePath);
        if (fStat.isDirectory()) {
          deleteDirContent(filePath);
          fs.rmdirSync(filePath);
        } else {
          fs.unlinkSync(filePath);
        }
      }
    } else {
      fs.unlinkSync(path);
    }
  } catch(e) {}
}

@Entry
@Component
struct clearCache {
  @State clearList: dataItem[] = [
    new dataItem("网络小说缓存", 0),
    new dataItem("系统临时缓存", 0),
  ]
  @State @Watch("ClearChange") clearDialogStatus: boolean = false
  @State index: number = 0
  
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  getMainColor(): string {
    return this.theme?.mainColor || InkPalette.CINNABAR;
  }

  getSecondColor(): string {
    return this.theme?.secondColor || InkPalette.PAPER_WARM;
  }

  aboutToAppear() {
    this.calculateCache();
  }

  calculateCache() {
    let context = getContext(this) as common.UIAbilityContext;
    let cacheDir = context.cacheDir;
    
    // 网络小说缓存 (temp_online_book.txt)
    let onlineNovelSize = getFileSize(cacheDir + '/temp_online_book.txt');
    
    // 系统缓存 (整个 cacheDir 减去明确的网络小说缓存)
    let totalCacheSize = getDirSize(cacheDir);
    let systemCacheSize = totalCacheSize - onlineNovelSize;
    if (systemCacheSize < 0) systemCacheSize = 0;

    this.clearList[0].value = parseFloat((onlineNovelSize / 1024 / 1024).toFixed(2));
    this.clearList[1].value = parseFloat((systemCacheSize / 1024 / 1024).toFixed(2));
    this.clearList = [...this.clearList];
  }

  build() {
    Column() {
      // 标题栏
      MyCenterTitle({ title: "清理缓存" })

      Scroll() {
        Column({ space: InkSpacing.LG }) {
          Column() {
            ForEach(this.clearList, (item: dataItem, index: number) => {
              Column() {
                Row() {
                  Text(item.title)
                    .fontSize(InkTypography.BODY)
                    .fontColor(InkPalette.INK)
                    .layoutWeight(1)
                  
                  Text(item.value + " MB")
                    .fontSize(InkTypography.BODY_SMALL)
                    .fontColor(InkPalette.INK_MIST)
                    .margin({ right: InkSpacing.SM })

                  Image($r("app.media.ic_public_right"))
                    .size({ width: 18, height: 18 })
                    .fillColor(InkPalette.INK_WHISPER)
                }
                .width("100%")
                .height(InkLayout.MIN_TOUCH_TARGET)
                .onClick(() => {
                  this.index = index
                  this.clearDialogStatus = true
                })

                if (index < this.clearList.length - 1) {
                  Divider()
                    .color(InkPalette.PAPER_WARM)
                    .strokeWidth(0.5)
                }
              }
            })
          }
          .backgroundColor(Color.White)
          .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
          .borderRadius(InkRadius.CARD)
          .shadow(InkShadow.SUBTLE)
          .width("100%")
        }
        .padding({
          left: InkSpacing.PAGE_HORIZONTAL,
          right: InkSpacing.PAGE_HORIZONTAL,
          top: InkSpacing.LG,
          bottom: InkSpacing.XXL
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width("100%")
    .height("100%")
    .backgroundColor(InkPalette.PAPER_EMBEDDED)
  }

  // 弹窗关闭
  exitApp() {
    this.clearDialogStatus = false
  }
  onCancel() {
    this.clearDialogStatus = false
  }

  onAccept(index: number) {
    console.log(index.toString());
    this.clear(index)
    this.clearDialogStatus = false
  }
  
  ClearChange() {
    if (this.clearDialogStatus) {
      this.clearInfoDel?.open()
    }
  }

  @Builder
  confirmDialogBuilder() {
    Column({ space: InkSpacing.XL }) {
      Text('确认清除缓存吗？')
        .fontSize(InkTypography.TITLE_SMALL)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK)

      Text('清除缓存后可能需要重新加载部分内容。')
        .fontSize(InkTypography.BODY)
        .fontColor(InkPalette.INK_GHOST)

      Row({ space: InkSpacing.MD }) {
        Button('取消')
          .fontSize(InkTypography.BODY)
          .fontColor(this.getMainColor())
          .backgroundColor(this.getSecondColor())
          .onClick(() => { this.onCancel() })
          .width(112)
          .height(40)
          .borderRadius(InkRadius.BUTTON_LARGE)

        Button('确认')
          .fontSize(InkTypography.BODY)
          .fontColor(Color.White)
          .backgroundColor(this.getMainColor())
          .onClick(() => { this.onAccept(this.index) })
          .width(112)
          .height(40)
          .borderRadius(InkRadius.BUTTON_LARGE)
      }
      .justifyContent(FlexAlign.Center)
    }
    .padding(InkSpacing.XXL)
    .width(280)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(InkPalette.PAPER)
    .borderRadius(InkRadius.DIALOG)
    .shadow(InkShadow.FLOATING)
  }

  clearInfoDel: CustomDialogController | null = new CustomDialogController({
    builder: this.confirmDialogBuilder(),
    cancel: this.exitApp,
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  })

  // 清除方法
  clear(index: number) {
    let context = getContext(this) as common.UIAbilityContext;
    let cacheDir = context.cacheDir;
    
    try {
      if (index === 0) {
        // 网络小说缓存
        let filePath = cacheDir + '/temp_online_book.txt';
        if (fs.accessSync(filePath)) {
          fs.unlinkSync(filePath);
        }
        showMessage('网络小说缓存已清理');
      } else if (index === 1) {
        // 系统临时缓存
        deleteDirContent(cacheDir);
        showMessage('系统临时缓存已清理');
      }
    } catch(e) {
      console.error("Clear cache failed: " + e);
      showMessage('清理失败');
    }
    
    // 重新计算
    this.calculateCache();
  }
}