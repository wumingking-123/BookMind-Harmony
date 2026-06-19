import { Books } from '../../database/entities/Books'

@Component
export struct NetworkInput {
  @Prop bookData: Books | undefined;

  build() {
    Row() {
      Row() {
        Image($r("app.media.ic_public_return_left"))
          .width(12)
        Text(this.bookData?.originName || this.bookData?.origin || "未知书源")
          .lineHeight(18)
          .font({
            size: 10,
            weight: 500
          })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .margin({
        left: 3
      })
      .borderRadius(40)
      .backgroundColor("white")
      .padding({
        top: 4,
        bottom: 4,
        left: 12,
        right: 12
      })

      Text(this.bookData?.bookUrl || "无链接")
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .layoutWeight(1)
        .margin({ left: 8, right: 8 })
    }
    .backgroundColor("rgba(0, 0, 0, 0.06)")
    .width("100%")
    .height(30)
    .borderRadius(40)
  }
}