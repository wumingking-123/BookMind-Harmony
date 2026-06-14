import IndexFind from './IndexFind'
import { InkPalette } from '../../../common/constants/DesignTokens'

@ComponentV2
@Preview
export default struct Find {
  build() {
    Column() {
      IndexFind()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(InkPalette.PAPER)
  }
}
