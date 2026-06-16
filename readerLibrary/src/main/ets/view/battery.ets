import batteryInfo from '@ohos.batteryInfo';

@Component
export default struct battery {
  // 表示当前设备剩余电池电量百分比。
  @State batterySOCInfo: number = batteryInfo.batterySOC;
  // 表示当前设备电池的充电状态。 0 放电; 1 充电; 2 停止充电; 3 充满
  @State chargingStatusInfo: number = batteryInfo.chargingStatus;
  @Prop color: string = 'rgba(0, 0, 0, 0.88)';


  build() {
    Flex() {
      Stack() {
        Flex()
          .height(7)
          .width(this.batterySOCInfo / 100 * 20)
          .backgroundColor(this.batterySOCInfo < 20 ? "red" : this.color)
          .zIndex(2)
          .borderRadius(1.5)
          .margin({
            left: 2
          })

        Image($r("app.media.Union"))
          .width(26)
          .fillColor(this.color)
      }
      .alignContent(Alignment.Start)

      if (this.chargingStatusInfo !== 0) {
        Image($r("app.media.Vector"))
          .height(12)
          .fillColor(this.color)
          .margin({
            left: 3
          })
          .opacity(0.88)
      }
    }
    .width(38)
  }
}