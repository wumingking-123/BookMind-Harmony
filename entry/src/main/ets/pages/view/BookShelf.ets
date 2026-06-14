import IndexShelf from './bookShelf/IndexShelf'
import { InkPalette } from '../../common/constants/DesignTokens'

@Component
export default struct BookShelf {
  build() {
    Column() {
      IndexShelf()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(InkPalette.PAPER)
  }
}
