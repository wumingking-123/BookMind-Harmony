import { router, promptAction } from '@kit.ArkUI';
import { ThemeItem } from '../../../common/model/Theme';
import { ThemeStorageKey } from '../../../common/constants/Theme';
import downloadManager from '../../../common/utils/DownloadManager';
import { DownloadTask, DownloadStatus } from '../../../common/model/DownloadTask';

PersistentStorage.persistProp('ExportSettingList', [false, false, false, false, false]);

@Entry
@Component
struct DownloadManagementPage {
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @State currentTabIndex: number = 0
  @State currentScrollCardIndex: number = 0
  @State SearchValue: string = ""
  @State IsEdit: boolean = false
  @State isShowExportSetting: boolean = false
  @StorageLink('ExportSettingList') ExportSettingList: Array<boolean> = [false, false, false, false, false]
  @State questionsList: Array<string> = ["全部", "小说", "漫画", "有声书", "有声书", "有声书"]
  @State downloadingTasks: DownloadTask[] = []
  @State completedTasks: DownloadTask[] = []
  @State exportingTaskId: string = ''

  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  aboutToAppear(): void {
    this.refreshTasks();
    downloadManager.onProgress(() => {
      this.refreshTasks();
    });
  }

  aboutToDisappear(): void {
    downloadManager.offProgress(() => {
      this.refreshTasks();
    });
  }

  private refreshTasks(): void {
    this.downloadingTasks = downloadManager.getDownloadingTasks();
    this.completedTasks = downloadManager.getCompletedTasks();
  }

  private async exportSingleTask(task: DownloadTask): Promise<void> {
    if (this.exportingTaskId) {
      promptAction.showToast({ message: '请等待当前导出完成', duration: 1500 })
      return
    }
    if (!task.savedFilePath) {
      promptAction.showToast({ message: '文件未保存，无法导出', duration: 1500 })
      return
    }

    this.exportingTaskId = task.id
    const success = await downloadManager.exportTask(task.id)
    this.exportingTaskId = ''

    if (success) {
      promptAction.showToast({ message: '导出成功，请在 Download 目录查看', duration: 2000 })
    } else {
      promptAction.showToast({ message: '导出失败', duration: 1500 })
    }
  }

  private async exportAllTasks(): Promise<void> {
    if (this.exportingTaskId) {
      promptAction.showToast({ message: '请等待当前导出完成', duration: 1500 })
      return
    }

    const exportable = this.completedTasks.filter(t => t.savedFilePath)
    if (exportable.length === 0) {
      promptAction.showToast({ message: '暂无可导出的任务', duration: 1500 })
      return
    }

    let successCount = 0
    for (const task of exportable) {
      this.exportingTaskId = task.id
      const ok = await downloadManager.exportTask(task.id)
      if (ok) successCount++
    }
    this.exportingTaskId = ''

    promptAction.showToast({
      message: successCount > 0 ? `成功导出 ${successCount} 个文件到 Download 目录` : '导出已取消',
      duration: 2000
    })
  }

  build() {
    Stack() {
      if (this.IsEdit === false) {
        Row({ space: 12 }) {
          Scroll() {
            Row({ space: 12 }) {
              ForEach(this.questionsList, (item: string, index) => {
                Column() {
                  Text(item)
                    .fontColor(this.currentScrollCardIndex === index ? this.theme.mainColor : 'rgba(0, 0, 0, 0.88)')
                    .fontSize(12)
                    .fontWeight(700)
                }
                .borderRadius(8)
                .padding(8)
                .backgroundColor(this.currentScrollCardIndex === index ? this.theme.secondColor : 'rgb(240,240,240)')
                .onClick(() => {
                  this.currentScrollCardIndex = index
                })
              })
            }
          }
          .align(Alignment.Start)
          .width("80%")
          .scrollBar(BarState.Off)
          .scrollable(ScrollDirection.Horizontal)

          Blank(1)
          Image($r('app.media.more_search'))
            .width(24)
            .onClick(() => {
              this.IsEdit = true
            })
        }
        .width("100%")
        .margin({
          top: 55
        })
        .height(40)
        .padding({
          left: 20,
          right: 20
        })
        .zIndex(2)
      }


      Tabs({
        barPosition: BarPosition.Start
      }) {
        TabContent() {
          Column() {
            // 下载-下载中
            if (this.downloadingTasks.length > 0) {
              Row() {
                Text(`下载中 (${this.downloadingTasks.length})`)
                  .opacity(0.45)
                  .lineHeight(20)
                  .font({
                    size: 12,
                    weight: 500
                  })
                Blank(1)
                if (this.IsEdit) {
                  CheckboxGroup({ group: 'downloadingTasks' })
                } else {
                  Text("全部暂停")
                    .lineHeight(20)
                    .fontColor(this.theme.mainColor)
                    .font({
                      size: 12,
                      weight: 500
                    })
                    .onClick(() => {
                      downloadManager.pauseAll();
                      this.refreshTasks();
                    })
                }
              }
              .width("100%")
              .padding({
                top: 12,
                bottom: 12
              })

              ForEach(this.downloadingTasks, (task: DownloadTask) => {
                this.ShowTaskItem(task, "Downloading")
              })
            }
            // 下载-已下载
            if (this.completedTasks.length > 0) {
              Row() {
                Text(`已下载 (${this.completedTasks.length})`)
                  .opacity(0.45)
                  .lineHeight(20)
                  .font({
                    size: 12,
                    weight: 500
                  })
                Blank(1)
                if (this.IsEdit) {
                  CheckboxGroup({ group: 'completedTasks' })
                }
              }
              .width("100%")
              .padding({
                top: 12,
                bottom: 12
              })

              ForEach(this.completedTasks, (task: DownloadTask) => {
                this.ShowTaskItem(task, "DownloadFinish")
              })
              Blank(1)
              Divider()
            }

            // 空状态
            if (this.downloadingTasks.length === 0 && this.completedTasks.length === 0) {
              Column() {
                Text('暂无下载任务')
                  .fontSize(14)
                  .fontColor('#999999')
              }
              .width('100%')
              .height(200)
              .justifyContent(FlexAlign.Center)
            }
          }
          .margin({
            top: this.IsEdit ? 0 : 40
          })
          .width('100%')
          .height("100%")
        }
        .padding({
          left: 20,
          right: 20
        })
        .tabBar(this.TabBuilder(0, "下载"))

        TabContent() {
          Column() {
            // 导出-已下载
            if (this.completedTasks.length > 0 && !this.IsEdit) {
              Row() {
                Text(`已下载 (${this.completedTasks.length})`)
                  .opacity(0.45)
                  .lineHeight(20)
                  .font({
                    size: 12,
                    weight: 500
                  })
                Blank(1)

                Text("全部导出")
                  .lineHeight(20)
                  .fontColor(this.theme.mainColor)
                  .font({
                    size: 12,
                    weight: 500
                  })
                  .onClick(() => {
                    this.exportAllTasks()
                  })
              }
              .width("100%")
              .padding({
                top: 12,
                bottom: 12
              })

              ForEach(this.completedTasks, (task: DownloadTask) => {
                this.ShowTaskItem(task, "ExportReady")
              })
            }

            // 空状态
            if (this.completedTasks.length === 0) {
              Column() {
                Text('暂无可导出的任务')
                  .fontSize(14)
                  .fontColor('#999999')
              }
              .width('100%')
              .height(200)
              .justifyContent(FlexAlign.Center)
            }

          }
          .margin({
            top: this.IsEdit ? 0 : 40
          })
          .width('100%')
          .height("100%")
        }
        .padding({
          left: 20,
          right: 20
        })
        .tabBar(this.TabBuilder(1, "导出"))
      }
      .onChange((index: number) => {
        this.currentTabIndex = index
      })
    }
    .alignContent(Alignment.TopStart)
    .padding({
      top: this.topRectHeight,
      bottom: this.bottomRectHeight
    })
  }

  @Builder
  ShowTaskItem(task: DownloadTask, itemType: string) {
    Row({ space: 12 }) {
      Flex({
        direction: FlexDirection.Row,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center
      }) {
        Text(task.bookSource?.bookSourceType === 0 ? 'TXT' : task.bookSource?.bookSourceType === 1 ? 'MP3' : 'IMG')
          .fontColor("#188BFF")
          .font({
            size: 10,
            weight: 700,
          })
      }
      .backgroundColor("#D8ECFF")
      .width(32)
      .height(32)
      .padding({
        top: 10,
        bottom: 10
      })
      .margin(4)

      Column() {
        Row() {
          Text(task.bookName)
            .lineHeight(22)
            .font({
              size: 14,
              weight: 500,
            })
        }
        .width("100%")

        Row() {
          if (itemType === "Downloading") {
            Text(`${task.downloadedChapters}/${task.totalChapters}`)
              .lineHeight(18)
              .opacity(0.45)
              .font({
                size: 10,
                weight: 500,
              })
          } else if (itemType === "DownloadFinish") {
            Text(`全书已下载`)
              .lineHeight(18)
              .opacity(0.45)
              .font({
                size: 10,
                weight: 500,
              })
          } else {
            Text(`可导出`)
              .lineHeight(18)
              .opacity(0.45)
              .font({
                size: 10,
                weight: 500,
              })
          }
        }
        .width("100%")
      }
      .width("55%")

      Blank(1)
      if (!this.IsEdit && itemType === "Downloading") {
        Progress({
          value: task.totalChapters > 0 ? task.downloadedChapters / task.totalChapters * 100 : 0,
          type: ProgressType.Ring
        })
          .width(32)
      } else if (this.IsEdit && itemType === "Downloading") {
        Checkbox({ name: task.id, group: 'downloadingTasks' })
      } else if (this.IsEdit && itemType === "DownloadFinish") {
        Checkbox({ name: task.id, group: 'completedTasks' })
      } else if (itemType === "ExportReady") {
        Progress({
          value: 0,
          total: 100,
          type: ProgressType.Capsule
        })
          .color(this.theme.mainColor)
          .backgroundColor("#FFAF7A")
          .value(0)
          .width(68)
          .height(28)
          .style({ content: this.exportingTaskId === task.id ? '导出中...' : '导出', font: { size: 12, weight: 500 }, fontColor: "#FFFFFF" })
      }
    }
    .padding({
      top: 10,
      bottom: 10
    })
    .width("100%")
    .onClick(() => {
      if (itemType === "Downloading" && !this.IsEdit) {
        // 暂停/恢复
        if (task.status === DownloadStatus.DOWNLOADING) {
          downloadManager.pauseTask(task.id);
        } else if (task.status === DownloadStatus.PAUSED) {
          downloadManager.resumeTask(task.id);
        }
        this.refreshTasks();
      } else if (itemType === "ExportReady") {
        this.exportSingleTask(task)
      }
    })
  }

  @Builder
  ExportSettingDialog() {
    Column() {
      Row() {
        Text("导出设置")
          .lineHeight(24)
          .font({
            size: 16,
            weight: 500
          })
      }
      .padding({
        top: 12,
        bottom: 12
      })

      this.ExportSettingSwitchItem(0, "替换净化")
      this.ExportSettingSwitchItem(1, "TXT不导出章节名")
      this.ExportSettingSwitchItem(2, "TXT导出图片")
      this.ExportSettingSwitchItem(3, "多线程导出TXT")

      this.ExportSettingClickItem(5, "导出格式", "TXT")
      this.ExportSettingClickItem(6, "导出路径", "/storage/emulated/阅读")
      this.ExportSettingClickItem(7, "文件命名", "")

      Blank(1)
      Divider()
      Row() {
        Text("取消")
      }
      .justifyContent(FlexAlign.Center)
      .width("100%")
      .onClick(() => {
        this.isShowExportSetting = false
      })
      .padding({
        top: 16,
        bottom: 16
      })
    }
    .padding({
      left: 20,
      right: 20
    })
  }

  @Builder
  ExportSettingSwitchItem(index: number, title: string) {
    Row() {
      Text(title)
        .lineHeight(22)
        .font({
          size: 14,
          weight: 400
        })
      Blank(1)
      Toggle({ type: ToggleType.Switch, isOn: this.ExportSettingList[index] })
        .onChange((value) => {
          this.ExportSettingList[index] = value // 按钮状态同步到数组对应元素
        })
      Text(this.ExportSettingList[index].toString()) // 验证按钮是否双向同步
    }
    .padding({
      top: 12,
      bottom: 12
    })
    .width("100%")
  }

  @Builder
  ExportSettingClickItem(index: number, title: string, rightString: string) {
    Row() {
      Text(title)
        .lineHeight(22)
        .font({
          size: 14,
          weight: 400
        })
      Blank(1)
      if (rightString) {
        Text(rightString)
          .lineHeight(20)
          .font({
            size: 12,
            weight: 400
          })
          .opacity(0.45)
      }
      Image($r('app.media.right'))
        .width(24)
        .onClick(() => {
          switch (index) {
            case 5:
              break
            case 6:
              break
            case 7:
              break
          }
        })
    }
    .padding({
      top: 12,
      bottom: 12
    })
    .width("100%")
  }

  @Builder
  TabBuilder(index = 0, name: string) {
    Column() {
      Flex({
        direction: index === 0 ? FlexDirection.Row : FlexDirection.RowReverse,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Start
      }) {
        Column() {
          if (index) {
            if (this.IsEdit === true) {
              // 下面的flex是扩宽完成按钮的点击区域
              Flex({
                justifyContent: FlexAlign.End
              }) {
                Text("完成")
                  .lineHeight(22)
                  .font({
                    size: 14,
                    weight: 400
                  })
              }
              .width(50)
              .onClick(() => {
                this.IsEdit = false
              })
            } else {
              Image($r('app.media.Column_More'))
                .width(24)
                .bindSheet($$this.isShowExportSetting, this.ExportSettingDialog(), {
                  height: 520,
                  showClose: false,
                  dragBar: false,
                  blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
                  onDisappear: () => {
                    // this.clickBookType = ''
                  }
                })
                .onClick(() => {
                  this.isShowExportSetting = true
                })
            }
          } else {
            if (this.IsEdit === true) {
              Text("全选")
                .lineHeight(22)
                .font({
                  size: 14,
                  weight: 400
                })
                .onClick(() => {

                })
            } else {
              Image($r('app.media.return_left'))
                .width(24)
                .onClick(() => {
                  router.back()
                })
            }
          }

        }
        .padding({
          left: index === 0 ? 20 : null,
          right: index === 1 ? 20 : null
        })
        .width("70%")
        .alignItems(index === 0 ? HorizontalAlign.Start : HorizontalAlign.End)

        Column() {
          Text(name)
            .lineHeight(24)
            .font({
              size: 16,
              weight: 500
            })
            .fontColor(this.currentTabIndex === index ? this.theme.mainColor : '#000000')
            .opacity(this.currentTabIndex === index ? null : 0.45)
        }
      }
      .height("100%")
    }
    .width('100%')
    .height("100%")
  }
}
