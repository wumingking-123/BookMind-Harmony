import { Constants } from '../common/constants/Constants';
import { Reader } from './Reader';
import { promptAction } from '@kit.ArkUI';
import { ReaderChapterItem } from '../common/entity/ReaderChaptersItem';
import { NovelChapterOperateHelper } from '../common/helper/NovelChapterOperateHelper';

@Component
export struct CoverFlipView {
  @State private offsetX: number = 0
  @Consume('screenW') screenW: number;
  @Consume('currentPageIndex') currentPageIndex: number;
  @Consume('currentChapterIndex') currentChapterIndex: number;
  @Consume('chapterList') @Watch('onChapterListChanged') chapterList: ReaderChapterItem[];
  @Consume('bgColor') bgColor: string;
  private isFirst: boolean = false;
  // 记录手势开始时的翻页方向，防止 animateTo 结束时取值错误
  private pendingDirection: number = 0; // -1 = 向前, 1 = 向后, 0 = 无

  @State nextPageIndex: number[] | null = null;
  @State prePageIndex: number[] | null = null;

  aboutToAppear(): void {
    console.log('[CoverFlipView] aboutToAppear, chapterList.length: ' + this.chapterList.length + ', currentChapterIndex: ' + this.currentChapterIndex)
    this.calPageIndex();
  }

  onChapterListChanged() {
    let hasPages = this.chapterList.length > 0 && !!this.chapterList[this.currentChapterIndex]?.chapterPageList?.length
    console.log('[CoverFlipView] onChapterListChanged, chapterList.length: ' + this.chapterList.length + ', hasPages: ' + hasPages)
    if (hasPages) {
      console.log('[CoverFlipView] chapterPageList.length: ' + this.chapterList[this.currentChapterIndex].chapterPageList.length)
    }
    this.calPageIndex();
  }

  calPageIndex() {
    this.nextPageIndex =
      NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
    this.prePageIndex =
      NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
  }

  // 程序化翻页（点击区域或外部调用）
  flipToNext() {
    const next = NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
    if (next === null) {
      promptAction.showToast({ message: Constants.MSG_FLIP_OVER, duration: Constants.PROMPT_DURATION });
      return;
    }
    this.pendingDirection = 1;
    animateTo({
      duration: Constants.COVER_DURATION,
      curve: Curve.EaseOut,
      onFinish: () => {
        const nextIdx = NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
        if (nextIdx !== null) {
          this.currentChapterIndex = nextIdx[0];
          this.currentPageIndex = nextIdx[1];
        }
        this.offsetX = 0;
        this.pendingDirection = 0;
        this.calPageIndex();
      }
    }, () => {
      this.offsetX = -this.screenW;
      this.calPageIndex();
    });
  }

  flipToPrev() {
    const prev = NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
    if (prev === null) {
      promptAction.showToast({ message: Constants.MSG_FLIP_OVER, duration: Constants.PROMPT_DURATION });
      return;
    }
    this.pendingDirection = -1;
    animateTo({
      duration: Constants.COVER_DURATION,
      curve: Curve.EaseOut,
      onFinish: () => {
        const prevIdx = NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
        if (prevIdx !== null) {
          this.currentChapterIndex = prevIdx[0];
          this.currentPageIndex = prevIdx[1];
        }
        this.offsetX = 0;
        this.pendingDirection = 0;
        this.calPageIndex();
      }
    }, () => {
      this.offsetX = this.screenW;
      this.calPageIndex();
    });
  }

  build() {
    Stack() {
      if (this.chapterList.length === 0 || !this.chapterList[this.currentChapterIndex] || !this.chapterList[this.currentChapterIndex].chapterPageList || this.chapterList[this.currentChapterIndex].chapterPageList.length === 0) {
        Reader({ content: '', lineContentList: [], isCurrentPage: true })
          .width(this.screenW)
          .height('100%')
      } else {
        // 下一页（放在最底层，向左滑时漏出）
        if (this.nextPageIndex !== null) {
          Reader({
            content: this.chapterList[this.nextPageIndex[0]]?.chapterPageList?.[this.nextPageIndex[1]]?.content || '',
            lineContentList: this.chapterList[this.nextPageIndex[0]]?.chapterPageList?.[this.nextPageIndex[1]]?.lineContentList || [],
            isCurrentPage: false
          })
            .width(this.screenW)
            .height('100%')
        }

        // 当前页（随手势平移）
        Reader({
          content: this.chapterList[this.currentChapterIndex]?.chapterPageList?.[this.currentPageIndex]?.content || '',
          lineContentList: this.chapterList[this.currentChapterIndex]?.chapterPageList?.[this.currentPageIndex]?.lineContentList || [],
          isCurrentPage: true
        })
          .translate({ x: this.offsetX <= 0 ? this.offsetX : 0, y: 0, z: 0 })
          .width(this.screenW)
          .height('100%')

        // 上一页（向右拖时从左侧滑入）
        if (this.prePageIndex != null) {
          Reader({
            content: this.chapterList[this.prePageIndex[0]]?.chapterPageList?.[this.prePageIndex[1]]?.content || '',
            lineContentList: this.chapterList[this.prePageIndex[0]]?.chapterPageList?.[this.prePageIndex[1]]?.lineContentList || [],
            isCurrentPage: false
          })
            .translate({
              x: this.offsetX > 0 ? this.offsetX - this.screenW : -this.screenW
            })
            .width(this.screenW)
            .height('100%')
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bgColor)
    .clip(true)
    .gesture(
      PanGesture({ direction: PanDirection.Horizontal })
        .onActionStart((event?: GestureEvent) => {
          this.isFirst = false;
        })
        .onActionUpdate((event?: GestureEvent) => {
          if (!event) return;
          const dx = event.offsetX;

          const prePageIndex = NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
          const nextPageIndex = NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);

          // 向右拖（翻前页），但没有前页时阻止
          if (dx > 0 && prePageIndex === null) {
            this.isFirst = true;
            return;
          }
          // 向左拖（翻后页），但没有后页时阻止
          if (dx < 0 && nextPageIndex === null) {
            return;
          }
          this.offsetX = dx;
          this.calPageIndex();
        })
        .onActionEnd((event?: GestureEvent) => {
          const velocity = event?.velocityX ?? 0;
          const threshold = this.screenW * 0.3; // 超过30%屏宽或速度足够则翻页
          const shouldFlip = Math.abs(this.offsetX) > threshold || Math.abs(velocity) > 500;

          if (this.isFirst) {
            promptAction.showToast({ message: Constants.MSG_FLIP_OVER, duration: Constants.PROMPT_DURATION });
            this.isFirst = false;
            animateTo({ duration: Constants.COVER_DURATION, curve: Curve.EaseOut }, () => {
              this.offsetX = 0;
            });
            return;
          }

          if (shouldFlip && this.offsetX > 0) {
            // 翻向上一页：当前页滑到右侧，上一页进入
            const prevIdx = NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
            if (prevIdx !== null) {
              animateTo({
                duration: Constants.COVER_DURATION,
                curve: Curve.EaseOut,
                onFinish: () => {
                  this.currentChapterIndex = prevIdx[0];
                  this.currentPageIndex = prevIdx[1];
                  this.offsetX = 0;
                  this.calPageIndex();
                }
              }, () => {
                this.offsetX = this.screenW;
                this.calPageIndex();
              });
            } else {
              animateTo({ duration: Constants.COVER_DURATION, curve: Curve.EaseOut }, () => {
                this.offsetX = 0;
              });
            }
          } else if (shouldFlip && this.offsetX < 0) {
            // 翻向下一页
            const nextIdx = NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
            if (nextIdx !== null) {
              animateTo({
                duration: Constants.COVER_DURATION,
                curve: Curve.EaseOut,
                onFinish: () => {
                  this.currentChapterIndex = nextIdx[0];
                  this.currentPageIndex = nextIdx[1];
                  this.offsetX = 0;
                  this.calPageIndex();
                }
              }, () => {
                this.offsetX = -this.screenW;
                this.calPageIndex();
              });
            } else {
              animateTo({ duration: Constants.COVER_DURATION, curve: Curve.EaseOut }, () => {
                this.offsetX = 0;
              });
            }
          } else {
            // 未达到阈值，弹回
            animateTo({ duration: Constants.COVER_DURATION, curve: Curve.EaseOut }, () => {
              this.offsetX = 0;
            });
          }
        })
        .onActionCancel(() => {
          animateTo({ duration: Constants.COVER_DURATION, curve: Curve.EaseOut }, () => {
            this.offsetX = 0;
          });
        })
    )
  }
}