import { ExploreRule } from '../../../../database/entities/rule';
import { router } from '@kit.ArkUI';
import clickUtil from '../../../../common/utils/ClickUtils';
import { ThemeStorageKey } from '../../../../common/constants/Theme';
import { ThemeItem } from '../../../../common/model/Theme';

@Component
export  struct CardItem {
  @Prop item: ExploreRule = {};
  currentIndex:number = 0

  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  build() {
    Row() {
      Image(this.item.coverUrl ?? $r('app.media.no_record'))
        .alt($r('app.media.find_empty'))
        .width(63)
        .height(84)
        .objectFit(ImageFit.Contain)
        .borderRadius(4)
        .margin({ right: 12 })

      Column() {
        Text(this.item.name)
          .fontSize(16)
          .height(24)
          .lineHeight(24)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.item.kind) {
          Text(this.item.kind)
            .fontSize(12)
            .fontColor('#73000000')
            .height(20)
            .lineHeight(20)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 40 })
    .onClick(() => {
      clickUtil.preventClick(()=>{
        router.pushUrl({
          url: 'pages/view/BookDetailPage',
          params: {
            bookName: this.item.name,
            coverUrl: this.item.coverUrl,
            author: this.item.author,
            intro: this.item.intro,
            bookUrl:this.item.bookUrl,
            wordCount:this.item.wordCount,
            bookType:this.currentIndex
          }
        })
      })
    })
  }
}