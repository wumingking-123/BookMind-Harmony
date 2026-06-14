import SubscriptionIndex from './Subscription/SubscriptionIndex'
import { InkPalette } from '../../common/constants/DesignTokens'

@Component
export default struct Subscription {
  @Prop currentTabIndex: number

  build() {
    Column() {
      SubscriptionIndex({ currentTabIndex: this.currentTabIndex })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(InkPalette.PAPER)
  }
}
