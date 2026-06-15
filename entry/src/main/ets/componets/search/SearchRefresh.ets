import { ThemeStorageKey } from "../../common/constants/Theme";
import { ThemeItem } from "../../common/model/Theme";
import {
  InkPalette, InkTypography, InkSpacing
} from "../../common/constants/DesignTokens";

@Component
export struct SearchRefresh {
  @State color: string = InkPalette.INK_MIST
  @Consume SearchStatus: number;

  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  @Builder
  refresh() {
    Stack() {
      Row({ space: InkSpacing.MD }) {
        LoadingProgress()
          .color(this.theme.mainColor)
          .width(20)
          .height(20)
        Text("加载中...")
          .fontSize(InkTypography.BODY)
          .fontColor(InkPalette.INK_MIST)
      }
      .alignItems(VerticalAlign.Center)
    }
    .width("100%")
    .height("100%")
    .align(Alignment.Center)
  }

  build() {
    Column() {
      Refresh({ refreshing: true, builder: this.refresh() }) {

      }
      .height("10%")
      .onStateChange((refreshStatus: RefreshStatus) => {
        console.info('Refresh onStatueChange state is ' + refreshStatus)
      })
      .onRefreshing(() => {
        setTimeout(() => {
          this.SearchStatus = 2
        }, 3000)
        console.log('onRefreshing test')
      })
    }
    .height("80%")
    .width("100%")
    .justifyContent(FlexAlign.Center)
  }
}
