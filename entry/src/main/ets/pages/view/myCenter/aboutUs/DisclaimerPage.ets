import { router } from '@kit.ArkUI';
import { ThemeStorageKey } from '../../../../common/constants/Theme';
import { ThemeItem } from '../../../../common/model/Theme';
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../../../common/constants/DesignTokens';

@Entry
@Component
struct DisclaimerPage {
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @State rowsData: Array<string> = [
    '免责声明（Disclaimer）',
    '阅读是一款解析指定规则并获取内容的工具，为广大网络文学爱好者提供一种方便、快捷舒适的试读体验。',
    '当您搜索一本书的时，阅读会您所使用的规则将该书的书名以关键词的形式提交到各个第三方网络文学网站。 各第三方网站返回的内容与阅读无关，阅读对其概不负责，亦不承担任何法律责任。 任何通过使用阅读而链接到的第三方网页均系他人制作或提供，您可能从第三方网页上获得其他服务，阅读对其合法性概不负责，亦不承担任何法律责任。 第三方搜索引擎结果根据您提交的书名自动搜索获得并提供试读，不代表阅读赞成或被搜索链接到的第三方网页上的内容或立场。 您应该对使用搜索引擎的结果自行承担风险。',
    '阅读不做任何形式的保证：不保证第三方搜索引擎的搜索结果满足您的要求，不保证搜索服务不中断，不保证搜索结果的安全性、正确性、及时性、合法性。 因网络状况、通讯线路、第三方网站等任何原因而导致您不能正常使用阅读，阅读不承担任何法律责任。 阅读尊重并保护所有使用阅读用户的个人隐私权，您注册的用户名、电子邮件地址等个人资料，非经您亲自许可或根据相关法律、法规的强制性规定，阅读不会主动地泄露给第三方。',
    '阅读致力于最大程度地减少网络文学阅读者在自行搜寻过程中的无意义的时间浪费，通过专业搜索展示不同网站中网络文学的最新章节。 阅读在为广大小说爱好者提供方便、快捷舒适的试读体验的同时，也使优秀网络文学得以迅速、更广泛的传播，从而达到了在一定程度促进网络文学充分繁荣发展之目的。 阅读鼓励广大小说爱好者通过阅读发现优秀网络小说及其提供商，并建议阅读正版图书。 任何单位或个人认为通过阅读搜索链接到的第三方网页内容可能涉嫌侵犯其信息网络传播权，应该及时向阅读提出书面权力通知，并提供身份证明、权属证明及详细侵权情况证明。 阅读在收到上述法律文件后，将会依法尽快断开相关链接内容。'
  ]
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  build() {
    Column() {
      // 头部标题栏
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor(InkPalette.INK)
        }
        .width(InkLayout.MIN_TOUCH_TARGET)
        .height(InkLayout.MIN_TOUCH_TARGET)
        .borderRadius(InkRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { router.back() })

        Text('免责声明')
          .fontSize(InkTypography.TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)
          .position({ left: '50%' })
          .translate({ x: '-50%' })
      }
      .padding({ left: InkSpacing.LG, right: InkSpacing.LG })
      .width('100%')
      .height(InkLayout.HEADER_HEIGHT)
      .margin({ top: this.topRectHeight })

      // 可滚动的内容区域
      Scroll() {
        Column({ space: InkSpacing.LG }) {
          Column({ space: InkSpacing.MD }) {
            ForEach(this.rowsData, (item: string, index: number) => {
              Row() {
                Text(item)
                  .fontSize(index === 0 ? InkTypography.TITLE_SMALL : InkTypography.BODY)
                  .fontWeight(index === 0 ? FontWeight.Medium : FontWeight.Normal)
                  .fontColor(index === 0 ? InkPalette.INK : InkPalette.INK_LIGHT)
                  .lineHeight(24)
              }
              .width("100%")
            })
          }
          .borderRadius(InkRadius.CARD)
          .backgroundColor(Color.White)
          .padding(InkSpacing.LG)
          .width("100%")
          .shadow(InkShadow.SUBTLE)

          Blank(InkSpacing.XXL)
        }
        .padding({
          left: InkSpacing.PAGE_HORIZONTAL,
          right: InkSpacing.PAGE_HORIZONTAL,
          top: InkSpacing.LG,
          bottom: this.bottomRectHeight + InkSpacing.XXL
        })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
    .height("100%")
    .width("100%")
    .backgroundColor(InkPalette.PAPER_EMBEDDED)
  }
}