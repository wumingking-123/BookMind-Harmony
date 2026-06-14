import { router } from '@kit.ArkUI';
import taskSearchBooks from '../../common/model/taskSearchBook';
import { SearchBook } from '../../database/entities/SearchBook';
import { showMessage } from '../common/promptShow';
import { ThemeStorageKey } from '../../common/constants/Theme';
import { ThemeItem } from '../../common/model/Theme';
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow, InkLayout
} from '../../common/constants/DesignTokens';

@Component
export struct SearchHead {
  @Consume SearchValue: string
  @Consume SearchStatus: number
  @Consume('searchBookList') books: SearchBook[]
  @State lastSearch: string = ''
  @Consume('isSearch') isSearch: boolean
  
  @StorageProp('topRectHeight') topRectHeight: number = 0
  // 主题颜色
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  getMainColor(): string {
    return this.theme?.mainColor || InkPalette.CINNABAR;
  }

  build() {
    Row() {
      Row({ space: InkSpacing.MD }) {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor(InkPalette.INK)
        }
        .width(InkLayout.MIN_TOUCH_TARGET)
        .height(InkLayout.MIN_TOUCH_TARGET)
        .borderRadius(InkRadius.FULL)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          router.back()
          if (this.isSearch) {
            taskSearchBooks.cancelAllTasks()
          }
        })

        Search({ value: this.SearchValue, placeholder: '搜索书名或作者' })
          .layoutWeight(1)
          .height(36)
          .backgroundColor(InkPalette.PAPER_WARM)
          .placeholderColor(InkPalette.INK_GHOST)
          .borderRadius(InkRadius.SEARCH)
          .onChange(this.onChange)
          .onSubmit(this.onSubmit)

        Text(this.isSearch ? "取消" : "搜索")
          .fontSize(InkTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isSearch ? this.getMainColor() : InkPalette.INK_LIGHT)
          .height(InkLayout.MIN_TOUCH_TARGET)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.isSearch) {
              taskSearchBooks.cancelAllTasks()
              console.log(`取消搜索${this.books.length}`)
              this.isSearch = false
            } else {
              this.onSubmit(this.SearchValue)
            }
          })
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)
    }
    .padding({
      top: this.topRectHeight,
      left: InkSpacing.PAGE_HORIZONTAL,
      right: InkSpacing.PAGE_HORIZONTAL
    })
    .backgroundColor(InkPalette.PAPER)
    .shadow(InkShadow.SUBTLE)
    .height(InkLayout.HEADER_HEIGHT + this.topRectHeight)
    .width("100%")
  }

  onChange = (value: string) => {
    this.lastSearch = this.SearchValue
    this.SearchValue = value;
  }
  
  onSubmit = async (value: string) => {
    this.SearchValue = value;
    if (!this.SearchValue) {
      showMessage('搜索内容不能为空')
      return
    }
    if (this.books.length === 0 || this.SearchValue !== this.lastSearch) {
      this.SearchStatus = 1
    }
    this.isSearch = true
    this.books = []
    taskSearchBooks.search(this.SearchValue, (newUrls: SearchBook[]) => {
      this.setBookList(newUrls)
    }, () => {
      this.SearchStatus = 2
      this.isSearch = false
    })
  }

  setBookList(books: SearchBook[]) {
    if (books.length === 0) return
    books.forEach((book: SearchBook) => {
      let found = false;
      if (!book.name) return
      for (let item of this.books) {
        if (item.name === book.name && item.author === book.author) {
          item.belongCount++;
          if (item.source?.bookSourceUrl !== book.source?.bookSourceUrl && book.source) {
            if (!item.sourceList) {
              item.sourceList = [];
            }
            item.sourceList.push(book.source)
          }
          found = true;
          break;
        }
      }

      if (!found) {
        book.belongCount = 1
        this.books.push(book);
      }
    });
    this.sortBooksBySearchValue()
  }

  sortBooksBySearchValue() {
    this.books.sort((a: SearchBook, b: SearchBook) => {
      const aName = a.name || '';
      const bName = b.name || '';
      const searchValue = this.SearchValue || '';

      const aNameSimilarity = this.getSimilarity(aName.toLowerCase(), searchValue.toLowerCase());
      const bNameSimilarity = this.getSimilarity(bName.toLowerCase(), searchValue.toLowerCase());

      if (aNameSimilarity !== bNameSimilarity) {
        return bNameSimilarity - aNameSimilarity;
      }

      return b.belongCount - a.belongCount;
    });
  }

  getSimilarity(str1: string, str2: string) {
    const lengthDifference = Math.abs(str1.length - str2.length);
    const commonLength = Math.min(str1.length, str2.length);
    let similarity = 0;

    for (let i = 0; i < commonLength; i++) {
      if (str1[i] === str2[i]) {
        similarity++;
      }
    }

    return similarity - lengthDifference;
  }

  countMatchingChars(last: string, current: string) {
    const charsInA: Record<string, number> = {};
    for (const char of last) {
      charsInA[char] = (charsInA[char] || 0) + 1;
    }
    let count = 0;
    for (const char of current) {
      if (charsInA[char]) {
        count++;
      }
    }
    return count;
  }
  
  aboutToAppear(): void {
    console.log(this.SearchStatus.toString());
  }
}