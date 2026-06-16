import { common2D, drawing } from '@kit.ArkGraphics2D';
import animator, { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import { Constants } from '../common/constants/Constants';
import { ReaderChapterItem } from '../common/entity/ReaderChaptersItem';
import { Reader, ReaderForCurlView, SimulateDrawManager } from './Reader';
import { image } from '@kit.ImageKit';
import { NovelChapterOperateHelper } from '../common/helper/NovelChapterOperateHelper';

const NODE_CONTAINER_ID = 'root';

@Component
export struct SimulateCurlView {
  private context: DrawingRenderingContext = new DrawingRenderingContext()
  @State
  private isOnGesture: boolean = false;
  @State
  private isOnAnimation: boolean = false;
  private isReady: boolean = false
  private lastTime: number | null = null
  private animatorResult: AnimatorResult | undefined | null
  @Consume('screenW') screenW: number;
  @Consume('currentPageIndex') currentPageIndex: number;
  @Consume('chapterList') @Watch('onChapterListChanged') chapterList: ReaderChapterItem[];
  @Consume('currentChapterIndex') currentChapterIndex: number;
  @Consume('renderFontSize') @Watch('onFontSizeChanged') fontSize: number;
  @Consume('renderLineHeightRatio') @Watch('onLineHeightRatioChanged') lineHeightRatio: number;
  @Consume('bgColor') @Watch('onBgColorChanged') bgColor: string;
  @Consume('renderReaderPadding') @Watch('onReaderPaddingChanged') readerPadding: number;
  @Provide('batteryPixelMap') @Watch('setBatteryPixelMap') batteryPixelMap: image.PixelMap | null = null;
  @Consume('displaySize') @Watch('onTextDisplaySizeChanged') displaySize: number[];
  @Consume('renderParagraphSpacing') @Watch('onParagraphSpacingChanged') paragraphSpacing: number;
  drawManager: SimulateDrawManager | null = null;
  isTurnNext: boolean | null = null;
  animationEndValue: number | null = null;
  @State nextPageIndex: number[] | null = null;
  @State prePageIndex: number[] | null = null;

  calPageIndex() {
    this.nextPageIndex =
      NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
    this.prePageIndex =
      NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
  }

  onChapterListChanged() {
    this.calPageIndex();
    if (this.drawManager !== null) {
      this.drawManager.chapterList = this.chapterList;
      this.drawManager.draw();
    }
  }

  aboutToDisappear(): void {
    this.animatorResult?.cancel();
    this.animatorResult = undefined;
  }

  aboutToAppear(): void {
    this.drawManager =
      new SimulateDrawManager(this.context, this.fontSize, this.fontSize * this.lineHeightRatio, this.chapterList,
        this.currentChapterIndex, this.currentPageIndex, this.bgColor, this.paragraphSpacing);
    this.drawManager.setReaderPadding(this.readerPadding)
    this.drawManager.setTextDisplaySize(this.displaySize)

    let options: AnimatorOptions = {
      duration: 350,
      easing: "ease-out",
      delay: 0,
      fill: "none",
      direction: "normal",
      iterations: 1,
      begin: 0.0,
      end: 1.0
    };
    this.animatorResult = animator.create(options)
    this.animatorResult.onFinish = () => {
      this.isOnAnimation = false;
      if (this.drawManager !== null) {
        this.drawManager.dispatchPointerUPEvent();
      }
      if (this.isTurnNext && this.animationEndValue === 1.0) {
        let nextPageIndex =
          NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
        if (nextPageIndex != null) {
          this.currentChapterIndex = nextPageIndex![0];
          this.currentPageIndex = nextPageIndex![1];
          this.drawManager?.updatePageIndex(this.currentPageIndex, this.currentChapterIndex)
        }
      } else if (!this.isTurnNext && this.animationEndValue === -1.0) {
        let prePageIndex =
          NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
        if (prePageIndex != null) {
          this.currentChapterIndex = prePageIndex![0];
          this.currentPageIndex = prePageIndex![1];
          this.drawManager?.updatePageIndex(this.currentPageIndex, this.currentChapterIndex)
        }
      }
      this.isTurnNext = null;
      this.animationEndValue = null;
      this.calPageIndex();
    }
    this.animatorResult.onFrame = (progress) => {
      if (this.drawManager !== null) {
        this.drawManager.applyAnimationProgressToTouch(progress);
        this.drawManager.draw()
      }
    };
    this.calPageIndex();
  }

  setBatteryPixelMap() {
    if (this.drawManager !== null && this.batteryPixelMap !== null) {
      this.drawManager.setBatteryPixelMap(this.batteryPixelMap)
    }
  }

  onTextDisplaySizeChanged() {
    if (this.drawManager !== null) {
      this.drawManager.setTextDisplaySize(this.displaySize)
    }
  }

  onBgColorChanged() {
    if (this.drawManager !== null) {
      this.drawManager.updateBgColor(this.bgColor);
    }
  }

  onFontSizeChanged() {
    if (this.drawManager !== null) {
      this.drawManager.updateFontSizeAndLineHeight(this.fontSize, this.fontSize * this.lineHeightRatio);
    }
  }

  onLineHeightRatioChanged() {
    if (this.drawManager !== null) {
      this.drawManager.updateFontSizeAndLineHeight(this.fontSize, this.fontSize * this.lineHeightRatio);
    }
  }

  onReaderPaddingChanged() {
    if (this.drawManager !== null) {
      this.drawManager.setReaderPadding(this.readerPadding);
    }
  }

  onParagraphSpacingChanged() {
    if (this.drawManager !== null) {
      this.drawManager.updateParagraphSpacing(this.paragraphSpacing);
    }
  }

  startAnimation(isRecover: boolean, isTurnNext: boolean) {
    this.animationEndValue = (isTurnNext !== isRecover) ? 1.0 : -1.0;
    let options: AnimatorOptions = {
      duration: isRecover ? 250 : 350,
      easing: isRecover ? "ease-in-out" : "ease-out",
      delay: 0,
      fill: "forwards",
      direction: "normal",
      iterations: 1,
      begin: 0.0,
      end: this.animationEndValue
    };
    this.animatorResult?.cancel();
    this.animatorResult?.reset(options);
    this.animatorResult?.play();
    this.isOnAnimation = true;
  }

  build() {
    Stack() {
      if (this.chapterList.length === 0 || !this.chapterList[this.currentChapterIndex] ||
          !this.chapterList[this.currentChapterIndex].chapterPageList ||
          this.chapterList[this.currentChapterIndex].chapterPageList.length === 0) {
        Reader({ content: '', lineContentList: [] })
      } else {
        Canvas(this.context)
          .width(Constants.FULL_PERCENT)
          .height(Constants.FULL_PERCENT)
          .id(NODE_CONTAINER_ID)
          .onReady(() => {
            this.isReady = true;
            if (this.drawManager !== null) {
              this.drawManager.setCanvasSizeFromDimensions(vp2px(this.context.size.width), vp2px(this.context.size.height))
              if (!this.drawManager.canvasSize.isEmpty() && !this.drawManager.touch.offset.isEmpty()) {
                this.drawManager.draw()
              }
            }
          })

        ReaderForCurlView({
          content: this.chapterList[this.currentChapterIndex]?.chapterPageList?.[this.currentPageIndex]?.content || '',
          lineContentList: this.chapterList[this.currentChapterIndex]?.chapterPageList?.[this.currentPageIndex]?.lineContentList || []
        })
          .width(Constants.FULL_PERCENT)
          .height(Constants.FULL_PERCENT)
          .visibility(this.isOnGesture || this.isOnAnimation ? Visibility.None : Visibility.Visible)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bgColor)
    .align(Alignment.Center)
    .gesture(
      PanGesture()
        .onActionStart((event) => {
          if (this.drawManager !== null) {
            this.drawManager.dispatchPointerStart(event)
          }
        })
        .onActionUpdate((event) => {
          try {
            if (this.drawManager !== null) {
              this.isTurnNext = this.drawManager.dispatchPointerMoveEvent(event)
              if (this.isTurnNext != null) {
                this.isOnGesture = true;
              }
              if (this.isReady) {
                this.drawManager.draw();
              }
            }
          } catch (e) {
            console.error(e)
          }
        })
        .onActionEnd((event) => {
          if (this.isTurnNext != null) {
            let velocity = event.velocityX;
            this.isOnGesture = false;
            // 速度阈值判断：快速滑动时自动翻页，慢速滑动时回弹
            let shouldTurn = this.isTurnNext ? velocity <= -20 : velocity >= 20;
            this.startAnimation(!shouldTurn, this.isTurnNext);
          }
        })
        .onActionCancel(() => {
          if (this.drawManager !== null) {
            this.drawManager.dispatchPointerUPEvent();
          }
          this.isOnGesture = false;
          this.isTurnNext = null;
        })
    )
  }
}
