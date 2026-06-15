import { promptAction } from '@kit.ArkUI';
import { Constants } from '../common/constants/Constants';
import { ReaderChapterItem } from '../common/entity/ReaderChaptersItem';
import { Reader } from './Reader';
import { NovelChapterOperateHelper } from '../common/helper/NovelChapterOperateHelper';

@Component
export struct SlideFlipView {
  @Consume('screenW') screenW: number;
  @Consume('chapterList') @Watch('onChapterListChanged') chapterList: ReaderChapterItem[];
  @Consume('currentPageIndex') currentPageIndex: number;
  @Consume('currentChapterIndex') currentChapterIndex: number;
  @State private offsetX: number = 0;
  private isFirst: boolean = false;

  @State nextPageIndex: number[] | null = null;
  @State prePageIndex: number[] | null = null;

  aboutToAppear(): void {
    this.calPageIndex();
  }

  onChapterListChanged() {
    this.calPageIndex();
  }

  calPageIndex() {
    this.nextPageIndex =
      NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
    this.prePageIndex =
      NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
  }

  build() {
    Stack() {
      if (this.chapterList.length === 0 || !this.chapterList[this.currentChapterIndex] || !this.chapterList[this.currentChapterIndex].chapterPageList || this.chapterList[this.currentChapterIndex].chapterPageList.length === 0) {
        Reader({ content: '', lineContentList: [], isCurrentPage: true })
          .width(this.screenW)
          .height('100%')
      } else {
        // 下一页（随手势平移进入）
        if (this.nextPageIndex !== null) {
          Reader({
            content: this.chapterList[this.nextPageIndex[0]]?.chapterPageList?.[this.nextPageIndex[1]]?.content || '',
            lineContentList: this.chapterList[this.nextPageIndex[0]]?.chapterPageList?.[this.nextPageIndex[1]]?.lineContentList || [],
            isCurrentPage: false
          })
            .translate({ x: this.offsetX < 0 ? this.screenW + this.offsetX : this.screenW, y: 0, z: 0 })
            .width(this.screenW)
            .height('100%')
        }

        // 当前页（随手势同步平移）
        Reader({
          content: this.chapterList[this.currentChapterIndex]?.chapterPageList?.[this.currentPageIndex]?.content || '',
          lineContentList: this.chapterList[this.currentChapterIndex]?.chapterPageList?.[this.currentPageIndex]?.lineContentList || [],
          isCurrentPage: true
        })
          .translate({ x: this.offsetX, y: 0, z: 0 })
          .width(this.screenW)
          .height('100%')

        // 上一页（从左侧同步平移进入）
        if (this.prePageIndex != null) {
          Reader({
            content: this.chapterList[this.prePageIndex[0]]?.chapterPageList?.[this.prePageIndex[1]]?.content || '',
            lineContentList: this.chapterList[this.prePageIndex[0]]?.chapterPageList?.[this.prePageIndex[1]]?.lineContentList || [],
            isCurrentPage: false
          })
            .translate({ x: this.offsetX > 0 ? this.offsetX - this.screenW : -this.screenW, y: 0, z: 0 })
            .width(this.screenW)
            .height('100%')
        }
      }
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .gesture(
      PanGesture({ direction: PanDirection.Horizontal })
        .onActionStart(() => {
          this.isFirst = false;
        })
        .onActionUpdate((event?: GestureEvent) => {
          if (!event) return;
          const dx = event.offsetX;

          const prePageIndex = NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
          const nextPageIndex = NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);

          if (dx > 0 && prePageIndex === null) {
            this.isFirst = true;
            return;
          }
          if (dx < 0 && nextPageIndex === null) {
            return;
          }
          this.offsetX = dx;
          this.calPageIndex();
        })
        .onActionEnd((event?: GestureEvent) => {
          const velocity = event?.velocityX ?? 0;
          const threshold = this.screenW * 0.3;
          const shouldFlip = Math.abs(this.offsetX) > threshold || Math.abs(velocity) > 500;

          if (this.isFirst) {
            promptAction.showToast({ message: Constants.MSG_FLIP_OVER, duration: Constants.PROMPT_DURATION });
            this.isFirst = false;
            animateTo({ duration: Constants.SLIDE_DURATION, curve: Curve.EaseOut }, () => {
              this.offsetX = 0;
            });
            return;
          }

          if (shouldFlip && this.offsetX > 0) {
            const prevIdx = NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
            if (prevIdx !== null) {
              animateTo({
                duration: Constants.SLIDE_DURATION,
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
              animateTo({ duration: Constants.SLIDE_DURATION, curve: Curve.EaseOut }, () => {
                this.offsetX = 0;
              });
            }
          } else if (shouldFlip && this.offsetX < 0) {
            const nextIdx = NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
            if (nextIdx !== null) {
              animateTo({
                duration: Constants.SLIDE_DURATION,
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
              animateTo({ duration: Constants.SLIDE_DURATION, curve: Curve.EaseOut }, () => {
                this.offsetX = 0;
              });
            }
          } else {
            animateTo({ duration: Constants.SLIDE_DURATION, curve: Curve.EaseOut }, () => {
              this.offsetX = 0;
            });
          }
        })
        .onActionCancel(() => {
          animateTo({ duration: Constants.SLIDE_DURATION, curve: Curve.EaseOut }, () => {
            this.offsetX = 0;
          });
        })
    )
  }
}