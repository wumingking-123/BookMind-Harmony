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
      Image(this.item.coverUrl && this.item.coverUrl.length > 0 ? this.item.coverUrl : $r('app.media.no_record'))
        .alt($r('app.media.find_empty'))
        .width(63)
        .height(84)
        .objectFit(ImageFit.Contain)
        .borderRadius(4)
        .margin({ right: 12 })

      Column({ space: 4 }) {
        Text(this.item.name)
          .fontSize(16)
          .lineHeight(24)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.item.kind) {
          Text(this.item.kind)
            .fontSize(12)
            .fontColor('#73000000')
            .lineHeight(20)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        if (this.item.lastChapter) {
          Text(this.item.lastChapter)
            .fontSize(12)
            .fontColor('#4D000000')
            .lineHeight(18)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .height(100)
    .padding({ left: 16, right: 16 })
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