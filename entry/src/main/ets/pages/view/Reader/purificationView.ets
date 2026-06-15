/**
 * @author 2008
 * @datetime 2024/6/12 21:48
 * @className: purificationView
 * 净化设置界面
 */
import ruleView from './ruleView';
import { promptAction } from '@kit.ArkUI';

@Component
export default struct purificationView {
  @Link isShowPurification: boolean;
  @State isRule: boolean = false;
  @State enableReplace: boolean = false
  @State enableRemoveDuplicate: boolean = false
  @State enableReParagraph: boolean = false
  @State enableReverse: boolean = false
  
  ruleViewDialog: CustomDialogController | null = new CustomDialogController({
    builder: ruleView(),
    cancel: this.clickExitDialog,
    autoCancel: true,
    alignment: DialogAlignment.Top,
    customStyle: true
  })

  clickExitDialog() {
    this.ruleViewDialog?.close()
  }

  build() {
    Column({ space: 0 }) {
      // 标题
      Row() {
        Text('内容净化')
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#1F2329')
      }
      .width('100%')
      .padding({ top: 20, left: 20, right: 20, bottom: 16 })

      // 功能选项
      Column({ space: 0 }) {
        this.titleContent('替换净化', 0, this.enableReplace, (isOn: boolean) => {
          this.enableReplace = isOn
          promptAction.showToast({
            message: isOn ? '替换净化已开启' : '替换净化已关闭',
            duration: 1500
          })
        })
        
        Divider().color('#F0F0F0').margin({ left: 20, right: 20 })
        
        this.titleContent('移除重复标题', 0, this.enableRemoveDuplicate, (isOn: boolean) => {
          this.enableRemoveDuplicate = isOn
          promptAction.showToast({
            message: isOn ? '移除重复标题已开启' : '移除重复标题已关闭',
            duration: 1500
          })
        })
        
        Divider().color('#F0F0F0').margin({ left: 20, right: 20 })
        
        this.titleContent('重新分段', 0, this.enableReParagraph, (isOn: boolean) => {
          this.enableReParagraph = isOn
          promptAction.showToast({
            message: isOn ? '重新分段已开启' : '重新分段已关闭',
            duration: 1500
          })
        })
        
        Divider().color('#F0F0F0').margin({ left: 20, right: 20 })
        
        this.titleContent('反转内容', 0, this.enableReverse, (isOn: boolean) => {
          this.enableReverse = isOn
          promptAction.showToast({
            message: isOn ? '反转内容已开启' : '反转内容已关闭',
            duration: 1500
          })
        })
        
        Divider().color('#F0F0F0').margin({ left: 20, right: 20 })
        
        this.titleContent('编辑内容', 1)
        
        Divider().color('#F0F0F0').margin({ left: 20, right: 20 })
        
        Column() {
          this.titleContent('净化规则管理', 1)
        }
        .onClick(() => {
          this.ruleViewDialog?.open()
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)

      Divider().height(12).color('#F7F8FA')

      // 取消按钮
      Column() {
        Text('取消')
          .fontSize(16)
          .fontWeight(500)
          .fontColor('#1F2329')
      }
      .width('100%')
      .height(52)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .onClick(() => {
        this.isShowPurification = false
      })
    }
    .padding({ left: 16, right: 16, bottom: 24 })
    .backgroundColor('#F7F8FA')
  }

  @Builder
  titleContent(title: string, type: number, isOn?: boolean, onChange?: (isOn: boolean) => void) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#1F2329')
        .fontWeight(400)
        .layoutWeight(1)
      
      if (type === 0) {
        // 开关类型
        Toggle({ type: ToggleType.Switch, isOn: isOn ?? false })
          .selectedColor('#A89B7E')
          .onChange((value: boolean) => {
            if (onChange) {
              onChange(value)
            }
          })
      } else {
        // 箭头类型
        Image($r('app.media.right'))
          .width(16)
          .height(16)
          .fillColor('#C4C4C4')
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 20, right: 20 })
  }
}