import { promptAction } from '@kit.ArkUI';
import { Constants } from '../common/constants/Constants';
import { ReaderChapterItem } from '../common/entity/ReaderChaptersItem';
import { Reader } from './Reader';
import { NovelChapterOperateHelper } from '../common/helper/NovelChapterOperateHelper';

@Component
export struct UpDownFlipView {
  @Consume('screenH') screenH: number;
  @Consume('screenW') screenW: number;
  @Consume('chapterList') @Watch('onChapterListChanged') chapterList: ReaderChapterItem[];
  @Consume('currentPageIndex') currentPageIndex: number;
  @Consume('currentChapterIndex') currentChapterIndex: number;
  @Consume('bgColor') bgColor: string;
  @State private offsetY: number = 0;
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
        // 下一页（底层）
        if (this.nextPageIndex !== null) {
          Reader({
            content: this.chapterList[this.nextPageIndex[0]]?.chapterPageList?.[this.nextPageIndex[1]]?.content || '',
            lineContentList: this.chapterList[this.nextPageIndex[0]]?.chapterPageList?.[this.nextPageIndex[1]]?.lineContentList || [],
            isCurrentPage: false
          })
            .width(this.screenW)
            .height('100%')
        }

        // 当前页（上下随手势偏移）
        Reader({
          content: this.chapterList[this.currentChapterIndex]?.chapterPageList?.[this.currentPageIndex]?.content || '',
          lineContentList: this.chapterList[this.currentChapterIndex]?.chapterPageList?.[this.currentPageIndex]?.lineContentList || [],
          isCurrentPage: true
        })
          .translate({ x: 0, y: this.offsetY <= 0 ? this.offsetY : 0, z: 0 })
          .width(this.screenW)
          .height('100%')

        // 上一页（从上方跟随）
        if (this.prePageIndex != null) {
          Reader({
            content: this.chapterList[this.prePageIndex[0]]?.chapterPageList?.[this.prePageIndex[1]]?.content || '',
            lineContentList: this.chapterList[this.prePageIndex[0]]?.chapterPageList?.[this.prePageIndex[1]]?.lineContentList || [],
            isCurrentPage: false
          })
            .translate({
              x: 0,
              y: this.offsetY > 0 ? this.offsetY - this.screenH : -this.screenH
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
      PanGesture({ direction: PanDirection.Vertical })
        .onActionStart(() => {
          this.isFirst = false;
        })
        .onActionUpdate((event?: GestureEvent) => {
          if (!event) return;
          const dy = event.offsetY;

          const prePageIndex = NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
          const nextPageIndex = NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);

          if (dy > 0 && prePageIndex === null) {
            this.isFirst = true;
            return;
          }
          if (dy < 0 && nextPageIndex === null) {
            return;
          }
          this.offsetY = dy;
          this.calPageIndex();
        })
        .onActionEnd((event?: GestureEvent) => {
          const velocity = event?.velocityY ?? 0;
          const threshold = this.screenH * 0.3;
          const shouldFlip = Math.abs(this.offsetY) > threshold || Math.abs(velocity) > 500;

          if (this.isFirst) {
            promptAction.showToast({ message: Constants.MSG_FLIP_OVER, duration: Constants.PROMPT_DURATION });
            this.isFirst = false;
            animateTo({ duration: Constants.SLIDE_DURATION, curve: Curve.EaseOut }, () => {
              this.offsetY = 0;
            });
            return;
          }

          if (shouldFlip && this.offsetY > 0) {
            const prevIdx = NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
            if (prevIdx !== null) {
              animateTo({
                duration: Constants.SLIDE_DURATION,
                curve: Curve.EaseOut,
                onFinish: () => {
                  this.currentChapterIndex = prevIdx[0];
                  this.currentPageIndex = prevIdx[1];
                  this.offsetY = 0;
                  this.calPageIndex();
                }
              }, () => {
                this.offsetY = this.screenH;
                this.calPageIndex();
              });
            } else {
              animateTo({ duration: Constants.SLIDE_DURATION, curve: Curve.EaseOut }, () => {
                this.offsetY = 0;
              });
            }
          } else if (shouldFlip && this.offsetY < 0) {
            const nextIdx = NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
            if (nextIdx !== null) {
              animateTo({
                duration: Constants.SLIDE_DURATION,
                curve: Curve.EaseOut,
                onFinish: () => {
                  this.currentChapterIndex = nextIdx[0];
                  this.currentPageIndex = nextIdx[1];
                  this.offsetY = 0;
                  this.calPageIndex();
                }
              }, () => {
                this.offsetY = -this.screenH;
                this.calPageIndex();
              });
            } else {
              animateTo({ duration: Constants.SLIDE_DURATION, curve: Curve.EaseOut }, () => {
                this.offsetY = 0;
              });
            }
          } else {
            animateTo({ duration: Constants.SLIDE_DURATION, curve: Curve.EaseOut }, () => {
              this.offsetY = 0;
            });
          }
        })
        .onActionCancel(() => {
          animateTo({ duration: Constants.SLIDE_DURATION, curve: Curve.EaseOut }, () => {
            this.offsetY = 0;
          });
        })
    )
  }
}