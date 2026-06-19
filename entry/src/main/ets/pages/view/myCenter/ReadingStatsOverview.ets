import { router } from '@kit.ArkUI'
import { InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow } from '../../../common/constants/DesignTokens'
import readRecordDao from '../../../database/dao/ReadRecordDao'
import booksDao from '../../../database/dao/BooksDao'
import bookMarkUtils from '../../../common/utils/BookMarkUtils'
import { ReadRecord } from '../../../database/entities/ReadRecord'
import { Books } from '../../../database/entities/Books'
import { ThemeStorageKey } from '../../../common/constants/Theme'
import { ThemeItem } from '../../../common/model/Theme'

interface BookStat {
  bookName: string
  author: string
  coverUrl: ResourceStr
  readTime: number
  readDays: number
  readCount: number
  schedule: number
  lastRead: number
  bookType: number
}

interface TypeDistribution {
  label: string
  count: number
  color: string
}

@Entry
@Component
struct ReadingStatsOverview {
  @State totalReadTime: number = 0
  @State totalReadDays: number = 0
  @State totalReadCount: number = 0
  @State totalFinishedCount: number = 0
  @State totalBookmarkCount: number = 0
  @State bookStats: BookStat[] = new Array()
  @State typeDistribution: TypeDistribution[] = new Array()
  @State topBooks: BookStat[] = new Array()
  @State recentBooks: BookStat[] = new Array()
  @State weekActivity: number[] = [0, 0, 0, 0, 0, 0, 0]
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0

  @StorageLink(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  getMainColor(): string {
    return this.theme?.mainColor || InkPalette.CINNABAR;
  }
  getSecondColor(): string {
    return this.theme?.secondColor || InkPalette.PAPER_WARM;
  }

  aboutToAppear(): void {
    this.loadData()
  }

  async loadData(): Promise<void> {
    try {
      const allBooks: Books[] = await booksDao.search()
      const records: ReadRecord[] = await readRecordDao.getAllRecords()
      const bookmarkCount: number = await bookMarkUtils.getTotalBookmarkCount()

      let totalTime = 0
      let totalDays = 0
      let finishedCount = 0
      const stats: BookStat[] = new Array()

      for (let r of records) {
        const book: Books | undefined = allBooks.find((b: Books) => b.bookName === r.bookName)
        if (!book) continue

        totalTime += r.readTime
        totalDays += r.readDays

        let schedule = 0
        if (book.totalChapterNum > 0 && book.durChapterIndex !== undefined) {
          schedule = Math.floor((book.durChapterIndex / book.totalChapterNum) * 100)
        }
        if (schedule >= 100) {
          finishedCount++
        }

        const coverStr: string | undefined = book.coverUrl
        const cover: ResourceStr = (coverStr && coverStr !== 'null' && coverStr !== 'undefined' && coverStr.trim() !== '')
          ? coverStr : $r('app.media.icon_book_default_cover_one')

        const stat: BookStat = {
          bookName: r.bookName,
          author: book.author || '未知',
          coverUrl: cover,
          readTime: r.readTime,
          readDays: r.readDays,
          readCount: r.readCount,
          schedule: schedule,
          lastRead: r.lastRead,
          bookType: book.bookType
        }
        stats.push(stat)
      }

      this.totalReadTime = totalTime
      this.totalReadDays = totalDays
      this.totalReadCount = records.length
      this.totalFinishedCount = finishedCount
      this.totalBookmarkCount = bookmarkCount
      this.bookStats = stats

      const novelCount = stats.filter(s => s.bookType === 0).length
      const mangaCount = stats.filter(s => s.bookType === 1).length
      const audioCount = stats.filter(s => s.bookType === 2).length
      const dist: TypeDistribution[] = new Array()
      if (novelCount > 0) {
        const item: TypeDistribution = { label: '小说', count: novelCount, color: this.theme?.mainColor || InkPalette.CINNABAR }
        dist.push(item)
      }
      if (mangaCount > 0) {
        const item: TypeDistribution = { label: '漫画', count: mangaCount, color: this.theme?.secondColor || InkPalette.PAPER_WARM }
        dist.push(item)
      }
      if (audioCount > 0) {
        const item: TypeDistribution = { label: '有声书', count: audioCount, color: InkPalette.CELADON }
        dist.push(item)
      }
      this.typeDistribution = dist

      const sorted = stats.slice().sort((a: BookStat, b: BookStat) => b.readTime - a.readTime)
      this.topBooks = sorted.slice(0, 5)

      const byRecent = stats.slice().sort((a: BookStat, b: BookStat) => b.lastRead - a.lastRead)
      this.recentBooks = byRecent.slice(0, 5)

      this.weekActivity = this.calcWeekActivity(records)
    } catch (e) {
      console.error('ReadingStatsOverview loadData error: ' + JSON.stringify(e))
    }
  }

  calcWeekActivity(records: ReadRecord[]): number[] {
    const result: number[] = [0, 0, 0, 0, 0, 0, 0]
    const now = new Date()
    const dayOfWeek = now.getDay() === 0 ? 6 : now.getDay() - 1
    const weekStart = new Date(now)
    weekStart.setDate(now.getDate() - dayOfWeek)
    weekStart.setHours(0, 0, 0, 0)

    for (let r of records) {
      const lastDate = new Date(r.lastRead)
      const diffDays = Math.floor((lastDate.getTime() - weekStart.getTime()) / 86400000)
      if (diffDays >= 0 && diffDays < 7) {
        result[diffDays] += Math.round(r.readTime / 60)
      }
    }
    return result
  }

  formatReadTime(seconds: number): string {
    if (seconds < 60) return seconds + '秒'
    const mins = Math.floor(seconds / 60)
    if (mins < 60) return mins + '分钟'
    const hrs = Math.floor(mins / 60)
    const remainMins = mins % 60
    if (hrs < 24) return hrs + '小时' + (remainMins > 0 ? remainMins + '分' : '')
    const days = Math.floor(hrs / 24)
    const remainHrs = hrs % 24
    return days + '天' + (remainHrs > 0 ? remainHrs + '小时' : '')
  }

  formatRelativeTime(timestamp: number): string {
    const diff = Date.now() - timestamp
    if (diff < 60000) return '刚刚'
    if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前'
    if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前'
    if (diff < 604800000) return Math.floor(diff / 86400000) + '天前'
    const d = new Date(timestamp)
    return d.getFullYear() + '/' + (d.getMonth() + 1) + '/' + d.getDate()
  }

  @Builder
  Header() {
    Row() {
      Image($r('app.media.ic_public_return_left'))
        .width(24).height(24)
        .fillColor(InkPalette.INK)
        .onClick(() => { router.back() })
      Text('阅读统计')
        .fontSize(InkTypography.TITLE_SMALL)
        .fontWeight(FontWeight.Medium)
        .fontColor(InkPalette.INK)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Row().width(24)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: this.topRectHeight + 12, bottom: 12 })
  }

  @Builder
  OverviewCard() {
    Column({ space: 0 }) {
      Text('阅读概览')
        .fontSize(InkTypography.CAPTION)
        .fontColor(InkPalette.INK_GHOST)
        .fontWeight(FontWeight.Medium)
        .width('100%')

      Row() {
        Column({ space: 4 }) {
          Text(this.formatReadTime(this.totalReadTime))
            .fontSize(InkTypography.TITLE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.mainColor || InkPalette.CINNABAR)
          Text('累计时长')
            .fontSize(InkTypography.MICRO)
            .fontColor(InkPalette.INK_MIST)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Text(this.totalReadDays.toString())
            .fontSize(InkTypography.TITLE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.secondColor || InkPalette.PAPER_WARM)
          Text('阅读天数')
            .fontSize(InkTypography.MICRO)
            .fontColor(InkPalette.INK_MIST)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Text(this.totalReadCount.toString())
            .fontSize(InkTypography.TITLE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(InkPalette.CELADON)
          Text('读过')
            .fontSize(InkTypography.MICRO)
            .fontColor(InkPalette.INK_MIST)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Text(this.totalFinishedCount.toString())
            .fontSize(InkTypography.TITLE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.mainColor || InkPalette.CINNABAR)
          Text('读完')
            .fontSize(InkTypography.MICRO)
            .fontColor(InkPalette.INK_MIST)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({ top: 16, bottom: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(InkPalette.PAPER_PURE)
    .borderRadius(InkRadius.CARD)
    .shadow(InkShadow.SOFT)
  }

  @Builder
  TypeDistCard() {
    if (this.typeDistribution.length > 0) {
      Column({ space: 12 }) {
        Text('类型分布')
          .fontSize(InkTypography.CAPTION)
          .fontColor(InkPalette.INK_GHOST)
          .fontWeight(FontWeight.Medium)
          .width('100%')

        Row() {
          ForEach(this.typeDistribution, (item: TypeDistribution) => {
            Column({ space: 6 }) {
              Text(item.count.toString())
                .fontSize(InkTypography.TITLE_SMALL)
                .fontWeight(FontWeight.Bold)
                .fontColor(item.color)
              Text(item.label)
                .fontSize(InkTypography.MICRO)
                .fontColor(InkPalette.INK_MIST)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          })
        }
        .width('100%')

        Stack() {
          Row() {
            ForEach(this.typeDistribution, (item: TypeDistribution) => {
              Row()
                .layoutWeight(item.count)
                .height(6)
                .backgroundColor(item.color)
            })
          }
          .width('100%')
          .height(6)
          .borderRadius(3)
          .clip(true)
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor(InkPalette.PAPER_PURE)
      .borderRadius(InkRadius.CARD)
      .shadow(InkShadow.SOFT)
    }
  }

  @Builder
  WeekHeatmapCard() {
    Column({ space: 12 }) {
      Text('本周阅读')
        .fontSize(InkTypography.CAPTION)
        .fontColor(InkPalette.INK_GHOST)
        .fontWeight(FontWeight.Medium)
        .width('100%')

      Row() {
        ForEach(this.weekActivity, (minutes: number, idx: number) => {
          Column({ space: 4 }) {
            Column() {
              if (minutes > 0) {
                Text(minutes >= 60 ? Math.floor(minutes / 60) + 'h' : minutes + 'm')
                  .fontSize(9)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Medium)
              }
            }
            .width('100%')
            .height(this.getBarHeight(minutes))
            .backgroundColor(this.getBarColor(minutes))
            .borderRadius(4)

            Text(this.getWeekDay(idx))
              .fontSize(9)
              .fontColor(InkPalette.INK_MIST)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .height(80)
          .justifyContent(FlexAlign.End)
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(InkPalette.PAPER_PURE)
    .borderRadius(InkRadius.CARD)
    .shadow(InkShadow.SOFT)
  }

  getBarHeight(minutes: number): number {
    if (minutes === 0) return 8
    const maxVal = Math.max(...this.weekActivity, 1)
    const ratio = minutes / maxVal
    return 12 + Math.round(ratio * 52)
  }

  getBarColor(minutes: number): string {
    if (minutes === 0) return InkPalette.PAPER_SAND
    if (minutes < 30) return InkPalette.CELADON_LIGHT
    if (minutes < 60) return InkPalette.CELADON
    return InkPalette.INDIGO
  }

  getWeekDay(idx: number): string {
    const days: string[] = ['一', '二', '三', '四', '五', '六', '日']
    return days[idx]
  }

  @Builder
  TopBooksCard() {
    if (this.topBooks.length > 0) {
      Column({ space: 12 }) {
        Text('阅读排行')
          .fontSize(InkTypography.CAPTION)
          .fontColor(InkPalette.INK_GHOST)
          .fontWeight(FontWeight.Medium)
          .width('100%')

        ForEach(this.topBooks, (book: BookStat, idx: number) => {
          Row({ space: 12 }) {
            Text((idx + 1).toString())
              .fontSize(InkTypography.TITLE_SMALL)
              .fontWeight(FontWeight.Bold)
              .fontColor(idx < 3 ? InkPalette.CINNABAR : InkPalette.INK_MIST)
              .width(20)
              .textAlign(TextAlign.Center)

            Image(book.coverUrl)
              .width(36)
              .height(48)
              .borderRadius(InkRadius.XS)
              .objectFit(ImageFit.Cover)
              .alt($r('app.media.icon_book_default_cover_one'))

            Column({ space: 2 }) {
              Text(book.bookName)
                .fontSize(InkTypography.BODY_SMALL)
                .fontWeight(FontWeight.Medium)
                .fontColor(InkPalette.INK)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.formatReadTime(book.readTime) + ' · ' + book.readDays + '天')
                .fontSize(InkTypography.MICRO)
                .fontColor(InkPalette.INK_MIST)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(book.schedule + '%')
              .fontSize(InkTypography.CAPTION)
              .fontColor(book.schedule >= 100 ? InkPalette.SUCCESS : InkPalette.INK_LIGHT)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })

          if (idx < this.topBooks.length - 1) {
            Divider().color(InkPalette.PAPER_DEEP).margin({ left: 32 })
          }
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(InkPalette.PAPER_PURE)
      .borderRadius(InkRadius.CARD)
      .shadow(InkShadow.SOFT)
    }
  }

  @Builder
  RecentBooksCard() {
    if (this.recentBooks.length > 0) {
      Column({ space: 12 }) {
        Row() {
          Text('最近阅读')
            .fontSize(InkTypography.CAPTION)
            .fontColor(InkPalette.INK_GHOST)
            .fontWeight(FontWeight.Medium)
          Blank()
          Text('查看全部 >')
            .fontSize(InkTypography.MICRO)
            .fontColor(InkPalette.INK_MIST)
            .onClick(() => {
              router.pushUrl({ url: 'pages/view/myCenter/readStatistics', params: { value: 0 } })
            })
        }
        .width('100%')

        ForEach(this.recentBooks, (book: BookStat, idx: number) => {
          Row({ space: 12 }) {
            Image(book.coverUrl)
              .width(40)
              .height(54)
              .borderRadius(InkRadius.XS)
              .objectFit(ImageFit.Cover)
              .alt($r('app.media.icon_book_default_cover_one'))

            Column({ space: 2 }) {
              Text(book.bookName)
                .fontSize(InkTypography.BODY_SMALL)
                .fontWeight(FontWeight.Medium)
                .fontColor(InkPalette.INK)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Row({ space: 6 }) {
                Text(this.formatRelativeTime(book.lastRead))
                  .fontSize(InkTypography.MICRO)
                  .fontColor(InkPalette.INK_MIST)
                Text('·')
                  .fontSize(InkTypography.MICRO)
                  .fontColor(InkPalette.INK_MIST)
                Text(book.schedule + '%')
                  .fontSize(InkTypography.MICRO)
                  .fontColor(book.schedule >= 100 ? InkPalette.SUCCESS : InkPalette.INK_MIST)
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 2 }) {
              Text(this.formatReadTime(book.readTime))
                .fontSize(InkTypography.CAPTION)
                .fontColor(InkPalette.INDIGO)
                .fontWeight(FontWeight.Medium)
              Text('时长')
                .fontSize(9)
                .fontColor(InkPalette.INK_MIST)
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })

          if (idx < this.recentBooks.length - 1) {
            Divider().color(InkPalette.PAPER_DEEP).margin({ left: 52 })
          }
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(InkPalette.PAPER_PURE)
      .borderRadius(InkRadius.CARD)
      .shadow(InkShadow.SOFT)
    }
  }

  @Builder
  EmptyState() {
    Column({ space: 12 }) {
      Image($r('app.media.find_empty'))
        .width(80).height(80)
        .opacity(0.5)
      Text('暂无阅读记录')
        .fontSize(InkTypography.BODY)
        .fontColor(InkPalette.INK_MIST)
      Text('开始阅读后这里会展示你的阅读统计')
        .fontSize(InkTypography.CAPTION)
        .fontColor(InkPalette.INK_WHISPER)
    }
    .width('100%')
    .padding(48)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      this.Header()
      Divider().color(InkPalette.INK_WHISPER)

      if (this.totalReadCount === 0 && this.bookStats.length === 0) {
        Scroll() {
          this.EmptyState()
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else {
        Scroll() {
          Column({ space: InkSpacing.MD }) {
            this.OverviewCard()
            this.WeekHeatmapCard()
            this.TypeDistCard()
            this.TopBooksCard()
            this.RecentBooksCard()
            Blank().height(this.bottomRectHeight + 16)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(InkPalette.PAPER)
  }
}
