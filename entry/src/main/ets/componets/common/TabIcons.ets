/**
 * 底部导航栏矢量图标组件
 * 纯 ArkTS 原语，根据选中状态动态切换 Outline 和 Filled 样式
 */

// 书架图标
@Component
export struct IconBookShelf {
  @Prop color: string = '#A89B8C'
  @Prop iconSize: number = 22
  @Prop isSelected: boolean = false

  build() {
    Image(this.isSelected ? $r("app.media.tab_bookshelf_filled") : $r("app.media.tab_bookshelf_outline"))
      .width(this.iconSize)
      .height(this.iconSize)
      .fillColor(this.color)
      .opacity(this.isSelected ? 1.0 : 0.6)
  }
}

// 发现图标
@Component
export struct IconFind {
  @Prop color: string = '#A89B8C'
  @Prop iconSize: number = 22
  @Prop isSelected: boolean = false

  build() {
    Image(this.isSelected ? $r("app.media.tab_find_filled") : $r("app.media.tab_find_outline"))
      .width(this.iconSize)
      .height(this.iconSize)
      .fillColor(this.color)
      .opacity(this.isSelected ? 1.0 : 0.6)
  }
}

// 订阅图标
@Component
export struct IconSubscribe {
  @Prop color: string = '#A89B8C'
  @Prop iconSize: number = 22
  @Prop isSelected: boolean = false

  build() {
    Image(this.isSelected ? $r("app.media.tab_subscribe_filled") : $r("app.media.tab_subscribe_outline"))
      .width(this.iconSize)
      .height(this.iconSize)
      .fillColor(this.color)
      .opacity(this.isSelected ? 1.0 : 0.6)
  }
}

// 我的图标
@Component
export struct IconMine {
  @Prop color: string = '#A89B8C'
  @Prop iconSize: number = 22
  @Prop isSelected: boolean = false

  build() {
    Image(this.isSelected ? $r("app.media.tab_mine_filled") : $r("app.media.tab_mine_outline"))
      .width(this.iconSize)
      .height(this.iconSize)
      .fillColor(this.color)
      .opacity(this.isSelected ? 1.0 : 0.6)
  }
}
