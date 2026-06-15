/**
 * 底部导航栏矢量图标组件
 * 纯 ArkTS 原语，无 border+Transparent 组合
 */

// 书架图标 — 两本书叠加
@Component
export struct IconBookShelf {
  @Prop color: string = '#A89B8C'
  @Prop iconSize: number = 22

  build() {
    Row({ space: this.iconSize * 0.1 }) {
      Column()
        .width(this.iconSize * 0.3)
        .height(this.iconSize * 0.73)
        .borderRadius(this.iconSize * 0.04)
        .backgroundColor(this.color)

      Column()
        .width(this.iconSize * 0.3)
        .height(this.iconSize * 0.58)
        .borderRadius(this.iconSize * 0.04)
        .backgroundColor(this.color)
        .opacity(0.6)
    }
    .height(this.iconSize)
    .alignItems(VerticalAlign.Bottom)
  }
}

// 发现图标 — 放大镜 (圆 + 斜柄)
@Component
export struct IconFind {
  @Prop color: string = '#A89B8C'
  @Prop iconSize: number = 22

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 镜片 (实心圆 + 内部白色圆 = 圆环)
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(this.iconSize * 0.6)
          .height(this.iconSize * 0.6)
          .borderRadius(this.iconSize * 0.3)
          .backgroundColor(this.color)

        Column()
          .width(this.iconSize * 0.38)
          .height(this.iconSize * 0.38)
          .borderRadius(this.iconSize * 0.19)
          .backgroundColor(Color.White)
      }
      .width(this.iconSize * 0.6)
      .height(this.iconSize * 0.6)
      .position({ x: 0, y: this.iconSize * 0.05 })

      // 镜柄 (斜条)
      Column()
        .width(this.iconSize * 0.08)
        .height(this.iconSize * 0.28)
        .borderRadius(this.iconSize * 0.04)
        .backgroundColor(this.color)
        .rotate({ angle: -45 })
        .position({ x: this.iconSize * 0.55, y: this.iconSize * 0.6 })
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }
}

// 订阅图标 — RSS (横线 + 圆点)
@Component
export struct IconSubscribe {
  @Prop color: string = '#A89B8C'
  @Prop iconSize: number = 22

  build() {
    Row({ space: this.iconSize * 0.12 }) {
      // 左侧圆点
      Column()
        .width(this.iconSize * 0.2)
        .height(this.iconSize * 0.2)
        .borderRadius(this.iconSize * 0.1)
        .backgroundColor(this.color)

      // 右侧三条横线
      Column({ space: this.iconSize * 0.14 }) {
        // 长线
        Row()
          .width(this.iconSize * 0.55)
          .height(this.iconSize * 0.1)
          .borderRadius(this.iconSize * 0.05)
          .backgroundColor(this.color)

        // 中线
        Row()
          .width(this.iconSize * 0.4)
          .height(this.iconSize * 0.1)
          .borderRadius(this.iconSize * 0.05)
          .backgroundColor(this.color)

        // 短线
        Row()
          .width(this.iconSize * 0.25)
          .height(this.iconSize * 0.1)
          .borderRadius(this.iconSize * 0.05)
          .backgroundColor(this.color)
      }
      .justifyContent(FlexAlign.End)
    }
    .height(this.iconSize)
    .alignItems(VerticalAlign.Center)
  }
}

// 我的图标 — 人物轮廓
@Component
export struct IconMine {
  @Prop color: string = '#A89B8C'
  @Prop iconSize: number = 22

  build() {
    Column({ space: this.iconSize * 0.08 }) {
      // 头部
      Column()
        .width(this.iconSize * 0.36)
        .height(this.iconSize * 0.36)
        .borderRadius(this.iconSize * 0.18)
        .backgroundColor(this.color)

      // 身体
      Column()
        .width(this.iconSize * 0.56)
        .height(this.iconSize * 0.4)
        .borderRadius({ topLeft: this.iconSize * 0.18, topRight: this.iconSize * 0.18, bottomLeft: 0, bottomRight: 0 })
        .backgroundColor(this.color)
    }
    .height(this.iconSize)
    .alignItems(HorizontalAlign.Center)
  }
}
