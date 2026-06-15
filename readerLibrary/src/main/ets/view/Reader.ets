import { Constants, FlipPageType } from '../common/constants/Constants'
import battery from './battery';
import { common2D, drawing } from '@kit.ArkGraphics2D';
import { ReaderChapterItem } from '../common/entity/ReaderChaptersItem';
import { componentSnapshot, MeasureText } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { NovelChapterOperateHelper } from '../common/helper/NovelChapterOperateHelper';

@Component
export struct Reader {
  @Consume('bgColor') bgColor: string;
  @Consume('fontSize') fontSize: number;
  @Consume('lineHeightRatio') lineHeightRatio: number;
  @Consume('turnStyle') turnStyle: FlipPageType;
  @Consume('displaySize') displaySize: number[];
  @Consume('readerPadding') readerPadding: number;
  @Consume('fontWeight') fontWeight: number;
  @Consume('fontType') fontType: string;
  @Consume('isFirstLineIndent') isFirstLineIndent: boolean;
  @Consume('letterSpacing') letterSpacing: number;
  @Consume('currentPageIndex') currentPageIndex: number;
  @Consume('currentChapterIndex') currentChapterIndex: number;
  @Consume('chapterList') chapterList: ReaderChapterItem[];
  @Consume('paragraphSpacing') paragraphSpacing: number;
  @Prop content: string = '';
  @Prop lineContentList: string[] = [];
  @Prop isCurrentPage: boolean = true;

  build() {
    Column() {
      Column() {
        ForEach(this.lineContentList && this.lineContentList.length > 0 ? this.lineContentList : [this.content], (line: string) => {
          if (line.trim().startsWith('[img:') && line.trim().endsWith(']')) {
            Image(line.trim().substring(5, line.trim().length - 1))
              .objectFit(ImageFit.Contain)
              .width('100%')
              .height(180)
              .margin({ top: 8, bottom: 8 })
          } else if (line !== '' && line !== '\n') {
            Text(line.endsWith('\n') ? line.slice(0, -1) : line)
              .textOverflow({ overflow: TextOverflow.Clip })
              .align(Alignment.TopStart)
              .font({
                size: this.fontSize,
              })
              .fontWeight(this.fontWeight)
              .letterSpacing(this.letterSpacing)
              .fontColor($r('sys.color.black'))
              .lineHeight(this.fontSize * this.lineHeightRatio)
              .width("100%")
              .margin({ bottom: line.endsWith('\n') ? this.paragraphSpacing : 0 })
          }
        })
      }
      .alignItems(HorizontalAlign.Start)
      .width("100%")
      .layoutWeight(1)
      .clip(true)
      .onSizeChange((oldSize, newSize) => {
        if (typeof newSize.width === 'number' && typeof newSize.height === 'number') {
          let width = vp2px(newSize.width as number)
          let height = vp2px(newSize.height as number)
          if (this.displaySize[0] !== width || this.displaySize[1] !== height) {
            this.displaySize = [width, height];
          }
        }
        console.info(`display size, width : ${vp2px(newSize.width as number)} , height : ${vp2px(newSize.height as number)}`)
      })
    }
    .backgroundColor(this.bgColor)
    .width(Constants.FULL_PERCENT)
    .height(Constants.FULL_PERCENT)
    .padding({
      top: Constants.SCREEN_MARGIN_LEFT,
      bottom: Constants.SCREEN_MARGIN_LEFT,
      left: this.readerPadding,
      right: this.readerPadding,
    })
  }
}

@Component
export struct ReaderForCurlView {
  @Consume('bgColor') bgColor: string;
  @Consume('fontSize') fontSize: number;
  @Consume('lineHeightRatio') lineHeightRatio: number;
  @Consume('turnStyle') turnStyle: FlipPageType;
  @Consume('displaySize') displaySize: number[];
  @Consume('readerPadding') readerPadding: number;
  @Consume('fontWeight') fontWeight: number;
  @Consume('fontType') fontType: string;
  @Consume('isFirstLineIndent') isFirstLineIndent: boolean;
  @Consume('letterSpacing') letterSpacing: number;
  @Consume('currentPageIndex') currentPageIndex: number;
  @Consume('currentChapterIndex') currentChapterIndex: number;
  @Consume('chapterList') chapterList: ReaderChapterItem[];
  @Consume('paragraphSpacing') paragraphSpacing: number;
  @Prop content: string = '';
  @Prop lineContentList: string[] = [];

  build() {
    Column() {
      Column() {
        ForEach(this.lineContentList && this.lineContentList.length > 0 ? this.lineContentList : [this.content], (line: string) => {
          if (line.trim().startsWith('[img:') && line.trim().endsWith(']')) {
            Image(line.trim().substring(5, line.trim().length - 1))
              .objectFit(ImageFit.Contain)
              .width('100%')
              .height(180)
              .margin({ top: 8, bottom: 8 })
          } else if (line !== '' && line !== '\n') {
            Text(line.endsWith('\n') ? line.slice(0, -1) : line)
              .textOverflow({ overflow: TextOverflow.Clip })
              .align(Alignment.TopStart)
              .font({
                size: this.fontSize,
              })
              .fontWeight(this.fontWeight)
              .letterSpacing(this.letterSpacing)
              .fontColor($r('sys.color.black'))
              .lineHeight(this.fontSize * this.lineHeightRatio)
              .width("100%")
              .margin({ bottom: line.endsWith('\n') ? this.paragraphSpacing : 0 })
          }
        })
      }
      .alignItems(HorizontalAlign.Start)
      .width("100%")
      .layoutWeight(1)
      .clip(true)
      .onSizeChange((oldSize, newSize) => {
        if (typeof newSize.width === 'number' && typeof newSize.height === 'number') {
          let width = vp2px(newSize.width as number)
          let height = vp2px(newSize.height as number)
          if (this.displaySize[0] !== width || this.displaySize[1] !== height) {
            this.displaySize = [width, height];
          }
        }
        console.info(`display size, width : ${vp2px(newSize.width as number)} , height : ${vp2px(newSize.height as number)}`)
      })
    }
    .backgroundColor(this.bgColor)
    .width(Constants.FULL_PERCENT)
    .height(Constants.FULL_PERCENT)
    .padding({
      top: Constants.SCREEN_MARGIN_LEFT,
      bottom: Constants.SCREEN_MARGIN_LEFT,
      left: this.readerPadding,
      right: this.readerPadding,
    })
  }
}

@Component
export struct ReaderBottom {
  private containerId = 'root'; // 组件NodeContainer的id
  @Consume('fontSize') fontSize: number;
  @Consume('currentPageIndex') currentPageIndex: number;
  @Consume('currentChapterIndex') currentChapterIndex: number;
  @Consume('chapterList') chapterList: ReaderChapterItem[];

  build() {
    Row({ space: 4 }) {
      TextClock({ timeZoneOffset: -8 })
        .format('hh:mm')
        .fontSize(12)
        .onDateChange((value) => {
          /// todo: 更新到SimulateDrawManager
        })
        .fontWeight(400)
      /// todo:电池状态监听与更新到SimulateDrawManager
      battery()
      Blank(0)
      Text(`${this.currentPageIndex + 1}/${this.chapterList[this.currentChapterIndex]?.chapterPageList?.length ?? 1}` + "\u3000" + `${(this.chapterList.length > 0 ? (this.currentChapterIndex + ((this.chapterList[this.currentChapterIndex]?.chapterPageList?.length ?? 1) > 0 ? this.currentPageIndex / (this.chapterList[this.currentChapterIndex]?.chapterPageList?.length ?? 1) : 0)) / this.chapterList.length * 100 : 0).toFixed(1)}%`)
        .fontSize(12)
        .fontColor($r('sys.color.black'))
    }.padding({
      top: 16,
    }).id(this.containerId)
    .width("100%").height(36)
  }
}

export class SimulateDrawManager {
  currentDrawHelper: SimulationDrawHelper | null = null;
  // 当前画布大小
  canvasSize: Size = Size.zero();
  // 起始触摸点
  startTouch: TouchEvent = TouchEvent.zero();
  // 当前触摸点
  touch: TouchEvent = TouchEvent.zero();
  // 上一次触摸点
  lastTouch: TouchEvent | null = null;
  private context: DrawingRenderingContext;
  private fontSize: number;
  private lineHeight: number;
  private chapterList: ReaderChapterItem[];
  private currentChapterIndex: number;
  private currentPageIndex: number;
  private bgColor: string;
  paragraphSpacing: number;
  batteryPixelMap: image.PixelMap | null = null;
  textDisplaySize: number[] = [0, 0];
  private isTurnNext: boolean | null = null;
  public readerPadding: number = 24;

  constructor(context: DrawingRenderingContext, fontSize: number, lineHeight: number,
    chapterList: ReaderChapterItem[], currentChapterIndex: number, currentPageIndex: number, bgColor: string, paragraphSpacing: number) {
    this.context = context;
    this.fontSize = fontSize;
    this.lineHeight = lineHeight;
    this.chapterList = chapterList;
    this.currentChapterIndex = currentChapterIndex;
    this.currentPageIndex = currentPageIndex;
    this.bgColor = bgColor;
    this.paragraphSpacing = paragraphSpacing;
  }

  setReaderPadding(padding: number) {
    this.readerPadding = padding;
  }

  setCanvasSizeFromDimensions(width: number, height: number) {
    this.canvasSize = new Size(width, height);
  }

  setCanvasSize(size: Size) {
    this.canvasSize = size;
  }

  updatePageIndex(pageIndex: number, chapterIndex: number) {
    this.currentPageIndex = pageIndex;
    this.currentChapterIndex = chapterIndex;
  }

  updateChapterIndex(index: number) {
    this.currentChapterIndex = index;
  }

  applyAnimationProgressToTouch(process: number) {
    this.currentDrawHelper?.applyAnimationProgressToTouch(process);
  }

  setTextDisplaySize(size: number[]) {
    this.textDisplaySize = size;
  }

  setBatteryPixelMap(image: image.PixelMap) {
    this.batteryPixelMap = image;
  }

  dispatchPointerStart(pointerEvent: GestureEvent) {
    let currentTouch =
      new TouchEvent(vp2px(pointerEvent.fingerList[0].localX), vp2px(pointerEvent.fingerList[0].localY),
        pointerEvent.velocityX, pointerEvent.velocityY, pointerEvent.velocity);

    this.lastTouch = new TouchEvent(currentTouch.x, currentTouch.y,
      currentTouch.velocityX, currentTouch.velocityY, currentTouch.velocity);

    this.startTouch = new TouchEvent(currentTouch.x, currentTouch.y,
      currentTouch.velocityX, currentTouch.velocityY, currentTouch.velocity);

    this.touch = new TouchEvent(currentTouch.x, currentTouch.y,
      currentTouch.velocityX, currentTouch.velocityY, currentTouch.velocity);

    if (this.canvasSize.equal(Size.zero())) {
      this.setCanvasSize(new Size(vp2px(this.context.size.width), vp2px(this.context.size.height)));
    }
  }

  /**
   * 分发move事件的手势信息
   *
   * @return {boolean|null} true表示向下翻页，false是向上翻页，null表示无操作
   */
  dispatchPointerMoveEvent(
    pointerEvent: GestureEvent): boolean | null {
    let currentTouch =
      new TouchEvent(vp2px(pointerEvent.fingerList[0].localX), vp2px(pointerEvent.fingerList[0].localY),
        pointerEvent.velocityX, pointerEvent.velocityY, pointerEvent.velocity);

    this.lastTouch = new TouchEvent(currentTouch.x, currentTouch.y,
      currentTouch.velocityX, currentTouch.velocityY, currentTouch.velocity);

    this.touch = new TouchEvent(currentTouch.x, currentTouch.y,
      currentTouch.velocityX, currentTouch.velocityY, currentTouch.velocity);

    if (this.canvasSize.equal(Size.zero())) {
      this.setCanvasSize(new Size(vp2px(this.context.size.width), vp2px(this.context.size.height)));
    }

    if (this.currentDrawHelper === null) {
      let isTurnNextByHorizontal: boolean = (this.lastTouch.x - this.startTouch.x) < 0 ||
        (this.lastTouch.x === this.startTouch.x && this.lastTouch.velocityX < 0);
      let isTurnNextByVertical: boolean =
        (this.startTouch.y <= this.canvasSize.height / 2) ? (this.lastTouch.y > this.startTouch.y) :
          (this.startTouch.y > this.lastTouch.y);

      this.isTurnNext = isTurnNextByHorizontal || isTurnNextByVertical

      let nextPageIndex =
        NovelChapterOperateHelper.nextPageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);
      let prePageIndex =
        NovelChapterOperateHelper.prePageIndex(this.chapterList, this.currentChapterIndex, this.currentPageIndex);

      // todo: 这部分的限制逻辑不该放在这里，需要等到章节缓存处理模块做完再移走
      if (this.isTurnNext &&
        nextPageIndex === null) {
        return null;
      }

      if ((!this.isTurnNext) && prePageIndex === null) {
        return null;
      }
      if (this.startTouch.y <= this.canvasSize.height / 3 || this.startTouch.y >= this.canvasSize.height / 3 * 2) {
        this.currentDrawHelper =
          new SimulationCornerTurnDrawHelper(this, this.context, this.fontSize, this.lineHeight, this.chapterList,
            this.isTurnNext ? this.currentChapterIndex : prePageIndex![0],
            this.isTurnNext ? this.currentPageIndex : prePageIndex![1],
            this.bgColor, this.paragraphSpacing);
      } else {
        this.currentDrawHelper =
          new SimulationPageTurnDrawHelper(this, this.context, this.fontSize, this.lineHeight, this.chapterList,
            this.isTurnNext ? this.currentChapterIndex : prePageIndex![0],
            this.isTurnNext ? this.currentPageIndex : prePageIndex![1],
            this.bgColor, this.paragraphSpacing);
      }
    }

    this.currentDrawHelper?.onMove();

    return this.isTurnNext;
  }

  dispatchPointerUPEvent() {
    this.touch = TouchEvent.zero();
    this.lastTouch = null;
    this.currentDrawHelper?.reset();
    this.currentDrawHelper = null;
    this.isTurnNext = null;
  }

  draw() {
    this.context.invalidate();
    this.currentDrawHelper?.draw(this.context.canvas);
  }
}

// 仿真翻页绘制辅助器
abstract class SimulationDrawHelper {
  // 底部页面区域Path
  nextPagePath = new drawing.Path();
  // 顶部翻起页区域Path
  turningPagePath = new drawing.Path();
  hostManager: SimulateDrawManager;
  protected fontSize: number;
  protected lineHeight: number;
  protected chapterList: ReaderChapterItem[];
  protected currentChapterIndex: number;
  protected currentPageIndex: number;
  protected bgColor: string;
  protected paragraphSpacing: number;
  protected context: DrawingRenderingContext;

  constructor(hostManager: SimulateDrawManager, context: DrawingRenderingContext, fontSize: number, lineHeight: number,
    chapterList: ReaderChapterItem[], currentChapterIndex: number, currentPageIndex: number, bgColor: string, paragraphSpacing: number) {
    this.hostManager = hostManager;
    this.context = context;
    this.fontSize = fontSize;
    this.lineHeight = lineHeight;
    this.chapterList = chapterList;
    this.currentChapterIndex = currentChapterIndex;
    this.currentPageIndex = currentPageIndex;
    this.bgColor = bgColor;
    this.paragraphSpacing = paragraphSpacing;
  }

  get canvasSize(): Size {
    return this.hostManager.canvasSize;
  }

  get touch(): TouchEvent {
    return this.hostManager.touch;
  }

  get lastTouch(): TouchEvent | null {
    return this.hostManager.lastTouch;
  }

  get touchOffset(): Offset {
    return this.hostManager.touch.offset;
  }

  get lastTouchOffset(): Offset | null {
    return this.hostManager.lastTouch?.offset ?? null;
  }

  abstract draw(canvas: drawing.Canvas,)

  move(): boolean {
    this.onMove();
    return true;
  }

  abstract onMove();

  abstract calPath()

  abstract applyAnimationProgressToTouch(process: number);

  reset() {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      this.nextPagePath.reset();
      this.turningPagePath.reset();
    }
  }

  protected hexToRgb(hex: string): Array<number> | null {
    const hexRegex = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i;
    const result = hexRegex.exec(hex);
    if (result) {
      return [parseInt(result[1], 16), parseInt(result[2], 16), parseInt(result[3], 16)];
    }
    return null;
  }

  protected drawCurrentPage(canvas: drawing.Canvas,): void {
    let bgColorRGB = this.hexToRgb(this.bgColor);
    let preColor: common2D.Color = {
      alpha: 255,
      red: (bgColorRGB?.[0] ?? 0),
      green: (bgColorRGB?.[1] ?? 0),
      blue: (bgColorRGB?.[2] ?? 0)
    }

    if (canIUse('SystemCapability.Graphics.Drawing')) {
      canvas.drawColor(preColor)
      const brush = new drawing.Brush();
      brush.setColor({
        alpha: 255,
        red: 0,
        green: 0,
        blue: 0
      });
      const font = new drawing.Font();
      font.setSize(fp2px(this.fontSize));
      canvas.attachBrush(brush);
      let fontMetrics = font.getMetrics();
      let lineHeight = Math.round(fp2px(this.lineHeight))
      // 文本绘制位置：水平用 readerPadding，垂直从顶部开始（与 ReaderForCurlView 一致）
      let horizontalMargin = vp2px(this.hostManager.readerPadding)
      let startY =
        Math.round(lineHeight * (Math.abs(fontMetrics.ascent) / (fontMetrics.descent - fontMetrics.ascent))) +
        vp2px(Constants.SCREEN_MARGIN_LEFT)

      let currentY = startY;

      let currentPageLineList =
        this.chapterList?.[this.currentChapterIndex]?.chapterPageList?.[this.currentPageIndex]?.lineContentList || [];
      let accumulatedY = startY;
      for (let index = 0; index < currentPageLineList.length; index++) {
        let line = currentPageLineList[index];
        let drawLine = line.endsWith('\n') ? line.slice(0, -1) : line;
        const textBlob =
          drawing.TextBlob.makeFromString(drawLine,
            font, drawing.TextEncoding.TEXT_ENCODING_UTF8);
        canvas.drawTextBlob(textBlob, horizontalMargin, accumulatedY);
        accumulatedY += lineHeight;
        if (line.endsWith('\n')) {
          accumulatedY += vp2px(this.paragraphSpacing);
        }
      }
      canvas.detachBrush();
    }
  }

  protected drawNextPage(canvas: drawing.Canvas): void {
    let bgColorRGB = this.hexToRgb(this.bgColor);
    let preColor: common2D.Color = {
      alpha: 255,
      red: (bgColorRGB?.[0] ?? 0),
      green: (bgColorRGB?.[1] ?? 0),
      blue: (bgColorRGB?.[2] ?? 0)
    }

    if (canIUse('SystemCapability.Graphics.Drawing')) {
      canvas.drawColor(preColor)
      const brush = new drawing.Brush();
      brush.setColor({
        alpha: 255,
        red: 0,
        green: 0,
        blue: 0
      });
      const font = new drawing.Font();
      font.setSize(fp2px(this.fontSize));
      canvas.attachBrush(brush);
      let fontMetrics = font.getMetrics();
      let lineHeight = Math.round(fp2px(this.lineHeight))
      let horizontalMargin = vp2px(this.hostManager.readerPadding)
      let startY =
        Math.round(lineHeight * (Math.abs(fontMetrics.ascent) / (fontMetrics.descent - fontMetrics.ascent))) +
        vp2px(Constants.SCREEN_MARGIN_LEFT)

      let currentY = startY;

      // 安全获取下一页索引，避免越界
      let nextPageIndex = this.currentPageIndex + 1;
      let nextPageLineList: string[] = [];
      if (nextPageIndex < (this.chapterList?.[this.currentChapterIndex]?.chapterPageList?.length ?? 0)) {
        nextPageLineList = this.chapterList?.[this.currentChapterIndex]?.chapterPageList?.[nextPageIndex]?.lineContentList || [];
      } else if (this.currentChapterIndex + 1 < (this.chapterList?.length ?? 0)) {
        nextPageLineList = this.chapterList?.[this.currentChapterIndex + 1]?.chapterPageList?.[0]?.lineContentList || [];
      }

      let accumulatedY = startY;
      for (let index = 0; index < nextPageLineList.length; index++) {
        let line = nextPageLineList[index];
        let drawLine = line.endsWith('\n') ? line.slice(0, -1) : line;
        const textBlob =
          drawing.TextBlob.makeFromString(drawLine,
            font, drawing.TextEncoding.TEXT_ENCODING_UTF8);
        canvas.drawTextBlob(textBlob, horizontalMargin, accumulatedY);
        accumulatedY += lineHeight;
        if (line.endsWith('\n')) {
          accumulatedY += vp2px(this.paragraphSpacing);
        }
      }
      canvas.detachBrush();
    }
  }

}

// 从角落开始的仿真翻页
class SimulationCornerTurnDrawHelper extends SimulationDrawHelper {
  bezierStart1 = Offset.zero(); // 贝塞尔曲线起始点
  bezierControl1 = Offset.zero(); // 贝塞尔曲线控制点
  bezierVertex1 = Offset.zero(); // 贝塞尔曲线顶点
  bezierEnd1 = Offset.zero(); // 贝塞尔曲线结束点
  bezierStart2 = Offset.zero(); // 另一条贝塞尔曲线
  bezierControl2 = Offset.zero();
  bezierVertex2 = Offset.zero();
  bezierEnd2 = Offset.zero();
  cornerX = 1; // 拖拽点对应的基准角落点X坐标
  cornerY = 1; // 拖拽点对应的基准角落点Y坐标
  middleX = 0.0; // 辅助点，当前触摸点与基准角落点的平分点的X坐标
  middleY = 0.0; // 辅助点，当前触摸点与基准角落点的平分点的Y坐标
  isNeedCalCorner = true; // 是否需要计算基准角落点
  isTurnNext = false; // 是否是翻下一页的状态

  // 计算各个关键点坐标
  private calBezierPoint() {
    this.middleX = (this.touchOffset.dx + this.cornerX) / 2;
    this.middleY = (this.touchOffset.dy + this.cornerY) / 2;

    this.bezierControl1 = new Offset(
      this.middleX -
        (this.cornerY - this.middleY) *
          (this.cornerY - this.middleY) /
          (this.cornerX - this.middleX),
      this.cornerY);

    let f4 = this.cornerY - this.middleY;
    if (f4 === 0) {
      this.bezierControl2 = new Offset(this.cornerX,
        this.middleY - (this.cornerX - this.middleX) * (this.cornerX - this.middleX) / 0.1);
    } else {
      this.bezierControl2 = new Offset(
        this.cornerX,
        this.middleY -
          (this.cornerX - this.middleX) *
            (this.cornerX - this.middleX) /
            (this.cornerY - this.middleY));
    }

    this.bezierStart1 = new Offset(
      this.bezierControl1.dx - (this.cornerX - this.bezierControl1.dx) / 2,
      this.cornerY);

    // 当mBezierStart1.x < 0或者mBezierStart1.x > 480时
    // 如果继续翻页，会出现BUG故在此限制
    if (this.touchOffset.dx > 0 && this.touchOffset.dx < this.canvasSize.width) {
      if (this.bezierStart1.dx < 0 || this.bezierStart1.dx > this.canvasSize.width) {
        if (this.bezierStart1.dx < 0) {
          this.bezierStart1 =
            new Offset(this.canvasSize.width - this.bezierStart1.dx, this.bezierStart1.dy);
        }

        let f1 = Math.abs(this.cornerX - this.touchOffset.dx);
        let f2 = this.canvasSize.width * f1 / this.bezierStart1.dx;
        this.touch.x = Math.abs(this.cornerX - f2);

        let f3 =
          Math.abs(this.cornerX - this.touchOffset.dx) * Math.floor(this.cornerY - this.touchOffset.dy) / f1;
        this.touch.x = Math.abs(this.cornerX - f2);
        this.touch.y = Math.abs(this.cornerY - f3);

        this.middleX = (this.touchOffset.dx + this.cornerX) / 2;
        this.middleY = (this.touchOffset.dy + this.cornerY) / 2;

        this.bezierControl1 = new Offset(
          this.middleX -
            (this.cornerY - this.middleY) *
              (this.cornerY - this.middleY) /
              (this.cornerX - this.middleX),
          this.cornerY);

        let f5 = this.cornerY - this.middleY;
        if (f5 === 0) {
          this.bezierControl2 = new Offset(this.cornerX,
            this.middleY - (this.cornerX - this.middleX) * (this.cornerX - this.middleX) / 0.1);
        } else {
          this.bezierControl2 = new Offset(
            this.cornerX,
            this.middleY -
              (this.cornerX - this.middleX) *
                (this.cornerX - this.middleX) /
                (this.cornerY - this.middleY));
        }

        this.bezierStart1 = new Offset(
          this.bezierControl1.dx - (this.cornerX - this.bezierControl1.dx) / 2,
          this.bezierStart1.dy);
      }
    }

    this.bezierStart2 = new Offset(this.cornerX,
      this.bezierControl2.dy - (this.cornerY - this.bezierControl2.dy) / 2);

    this.bezierEnd1 =
      this.getCrossByPoint(this.touchOffset, this.bezierControl1, this.bezierStart1, this.bezierStart2);
    this.bezierEnd2 =
      this.getCrossByPoint(this.touchOffset, this.bezierControl2, this.bezierStart1, this.bezierStart2);

    this.bezierVertex1 = new Offset(
      (this.bezierStart1.dx + 2 * this.bezierControl1.dx + this.bezierEnd1.dx) / 4,
      (2 * this.bezierControl1.dy + this.bezierStart1.dy + this.bezierEnd1.dy) / 4);

    this.bezierVertex2 = new Offset(
      (this.bezierStart2.dx + 2 * this.bezierControl2.dx + this.bezierEnd2.dx) / 4,
      (2 * this.bezierControl2.dy + this.bezierStart2.dy + this.bezierEnd2.dy) / 4);
  }

  // 获取交点(根据四点) //
  private getCrossByPoint(p1: Offset, p2: Offset, p3: Offset, p4: Offset): Offset {
    let line1Info = this.getLineInfo(p1, p2);
    let line2Info = this.getLineInfo(p3, p4);

    return this.getCrossByLine(
      line1Info.dx, line1Info.dy, line2Info.dx, line2Info.dy);
  }

  // 根据两点获取直线的k、b；
  // return : dx = k，dy = b
  private getLineInfo(p1: Offset, p2: Offset): Offset {
    let k1 = (p2.dy - p1.dy) / (p2.dx - p1.dx);
    let b1 = ((p1.dx * p2.dy) - (p2.dx * p1.dy)) / (p1.dx - p2.dx);
    return new Offset(k1, b1);
  }

  // 根据k和b
  private getCrossByLine(k1: number, b1: number, k2: number, b2: number): Offset {
    return new Offset((b2 - b1) / (k1 - k2), k1 * ((b2 - b1) / (k1 - k2)) + b1);
  }

  /// 计算拖拽点对应的拖拽脚 ///
  private calcCornerXY(y: number) {
    this.cornerX = this.canvasSize.width;
    if (y <= this.canvasSize.height / 2) {
      this.cornerY = 0;
    } else {
      this.cornerY = this.canvasSize.height;
    }
  }

  reset(): void {
    super.reset();
    this.bezierStart1 = Offset.zero();
    this.bezierControl1 = Offset.zero();
    this.bezierVertex1 = Offset.zero();
    this.bezierEnd1 = Offset.zero();

    this.bezierStart2 = Offset.zero();
    this.bezierControl2 = Offset.zero();
    this.bezierVertex2 = Offset.zero();
    this.bezierEnd2 = Offset.zero();

    this.cornerX = 1;
    this.cornerY = 1;

    this.middleX = 0.0;
    this.middleY = 0.0;

    this.isNeedCalCorner = true;
    this.isTurnNext = true;
  }

  onMove(): void {
    if (this.isNeedCalCorner) {
      this.calcCornerXY(this.touch.dy);
      this.isNeedCalCorner = false;
      this.isTurnNext = this.touch.velocityX <= 0;
    }

    this.calBezierPoint();
  }

  calPath(): void {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      this.nextPagePath.reset();
      this.nextPagePath.moveTo(this.cornerX, this.cornerY);
      this.nextPagePath.lineTo(this.bezierStart1.dx, this.bezierStart1.dy);
      this.nextPagePath.quadTo(this.bezierControl1.x, this.bezierControl1.y, this.bezierEnd1.x,
        this.bezierEnd1.y)

      this.nextPagePath.lineTo(this.touch.dx, this.touch.dy);
      this.nextPagePath.lineTo(this.bezierEnd2.dx, this.bezierEnd2.dy);
      this.nextPagePath.quadTo(this.bezierControl2.x, this.bezierControl2.y, this.bezierStart2.x,
        this.bezierStart2.y)

      this.nextPagePath.close();
    }
  }

  applyAnimationProgressToTouch(process: number): void {
    let isRecover = process <= 0

    this.touch.x = Math.min((this.lastTouchOffset?.x ?? 0) +
      ((isRecover ? this.cornerX : -this.cornerX) - (this.lastTouchOffset?.x ?? 0)) * Math.abs(process),
      this.cornerX);

    this.touch.y = (this.lastTouchOffset?.y ?? 0) + this.cornerY - (this.lastTouchOffset?.y ?? 0) * Math.abs(process);

    console.info(`animation: mTouch is x:${this.touch.x},y:${this.touch.y}, process is ${process}`)

    this.calBezierPoint();
  }

  draw(canvas: drawing.Canvas): void {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      try {
        this.calPath();
        let color: common2D.Color = {
          alpha: 255,
          red: 0,
          green: 0,
          blue: 0
        }
        canvas.drawColor(color, drawing.BlendMode.CLEAR);
        this.drawCurrentPageArea(canvas);
        this.drawNextPageArea(canvas);
        this.drawCurrentTurningPage(canvas)

        // 页面边缘阴影
        let shadowBrush = new drawing.Brush();
        let maskFilter = drawing.MaskFilter.createBlurMaskFilter(drawing.BlurType.OUTER, 40);
        shadowBrush.setMaskFilter(maskFilter)
        canvas.attachBrush(shadowBrush)
        canvas.drawPath(this.nextPagePath);
        canvas.detachBrush()
      } catch (e) {
        console.error(`绘制出错：${e}`)
      }
    }
  }

  private drawCurrentPageArea(canvas: drawing.Canvas): void {
    this.drawCurrentPage(canvas)
  }

  private drawNextPageArea(canvas: drawing.Canvas): void {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      canvas.save()
      canvas.clipPath(this.nextPagePath, drawing.ClipOp.INTERSECT, true)
      this.drawNextPage(canvas)
      this.drawNextPageShadow(canvas)
      canvas.restore()
    }
  }

  private drawNextPageShadow(canvas: drawing.Canvas) {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      let k1 = (this.bezierVertex1.y - this.bezierVertex2.y) / (this.bezierVertex1.x - this.bezierVertex2.x);
      let b1 = this.bezierVertex1.y - this.bezierVertex1.x * k1;

      let shadowWidth =
        (Math.abs(k1 * this.bezierStart1.x - this.bezierStart1.y + b1)) / (Math.sqrt(Math.pow(k1, 2) + 1)) * 4
      let shadowMaskFilter = drawing.MaskFilter.createBlurMaskFilter(drawing.BlurType.NORMAL, shadowWidth)

      const shadowPen = new drawing.Pen();
      shadowPen.setStrokeWidth(shadowWidth)
      shadowPen.setMaskFilter(shadowMaskFilter)

      canvas.attachPen(shadowPen)
      canvas.drawLine(this.bezierStart1.x, this.bezierStart1.y, this.bezierStart2.x, this.bezierStart2.y)
      canvas.detachPen()
    }
  }

  private drawCurrentTurningPage(canvas: drawing.Canvas): void {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      canvas.save()
      canvas.clipPath(this.nextPagePath, drawing.ClipOp.INTERSECT)
      let backAreaPath = new drawing.Path()
      backAreaPath.moveTo(this.touchOffset.x, this.touchOffset.y)
      backAreaPath.lineTo(this.bezierVertex1.x, this.bezierVertex1.y)
      backAreaPath.lineTo(this.bezierVertex2.x, this.bezierVertex2.y)
      backAreaPath.close()
      canvas.clipPath(backAreaPath, drawing.ClipOp.INTERSECT)
      canvas.save();

      let bgColorRGB = this.hexToRgb(this.bgColor);
      let preColor: common2D.Color = {
        alpha: 255,
        red: (bgColorRGB?.[0] ?? 0),
        green: (bgColorRGB?.[1] ?? 0),
        blue: (bgColorRGB?.[2] ?? 0)
      }

      // 绘制翻起页背面（略暗的背景色）
      canvas.drawColor({
        alpha: 255,
        red: Math.max(0, (bgColorRGB?.[0] ?? 255) - 20),
        green: Math.max(0, (bgColorRGB?.[1] ?? 255) - 20),
        blue: Math.max(0, (bgColorRGB?.[2] ?? 255) - 20)
      })
      canvas.restore();

      // 半透明白色蒙版 — 模拟纸张背面
      const maskBrush = new drawing.Brush();
      maskBrush.setColor({
        alpha: 40,
        red: 255,
        green: 255,
        blue: 255
      });
      canvas.attachBrush(maskBrush);
      canvas.drawPath(backAreaPath);
      canvas.detachBrush();

      // 折痕阴影 — 多层渐变效果
      let shadowDistance = Math.sqrt(
        Math.pow(this.touchOffset.x - this.bezierVertex1.x, 2) +
        Math.pow(this.touchOffset.y - this.bezierVertex1.y, 2)
      );
      let shadowWidth = Math.min(shadowDistance * 0.15, 80);

      // 外层柔阴影
      let outerFilter = drawing.MaskFilter.createBlurMaskFilter(drawing.BlurType.NORMAL, shadowWidth);
      const outerPen = new drawing.Pen();
      outerPen.setStrokeWidth(shadowWidth * 0.6);
      outerPen.setColor({ alpha: 60, red: 0, green: 0, blue: 0 });
      outerPen.setMaskFilter(outerFilter);
      canvas.attachPen(outerPen);
      canvas.drawLine(this.bezierVertex1.x, this.bezierVertex1.y, this.bezierVertex2.x, this.bezierVertex2.y);
      canvas.detachPen();

      // 内层硬阴影（折痕线）
      let innerFilter = drawing.MaskFilter.createBlurMaskFilter(drawing.BlurType.NORMAL, shadowWidth * 0.3);
      const innerPen = new drawing.Pen();
      innerPen.setStrokeWidth(shadowWidth * 0.25);
      innerPen.setColor({ alpha: 100, red: 0, green: 0, blue: 0 });
      innerPen.setMaskFilter(innerFilter);
      canvas.attachPen(innerPen);
      canvas.drawLine(this.bezierVertex1.x, this.bezierVertex1.y, this.bezierVertex2.x, this.bezierVertex2.y);
      canvas.detachPen();

      canvas.restore()
    }
  }
}

// 整页一起翻的仿真翻页
class SimulationPageTurnDrawHelper extends SimulationDrawHelper {
  calPath(): void {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      let splitLineX = (this.canvasSize.width - this.touch.dx) / 2 + this.touch.dx;
      this.nextPagePath.reset();
      this.nextPagePath.moveTo(this.canvasSize.width, 0);
      this.nextPagePath.lineTo(this.canvasSize.width, this.canvasSize.height);
      this.nextPagePath.lineTo(splitLineX, this.canvasSize.height)
      this.nextPagePath.lineTo(splitLineX, 0);
      this.nextPagePath.close();

      this.turningPagePath.reset();
      this.turningPagePath.moveTo(this.touch.dx, 0)
      this.turningPagePath.lineTo(splitLineX, 0);
      this.turningPagePath.lineTo(splitLineX, this.canvasSize.height);
      this.turningPagePath.lineTo(this.touch.dx, this.canvasSize.height);
      this.turningPagePath.close();
    }
  }

  draw(canvas: drawing.Canvas): void {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      this.calPath();
      let color: common2D.Color = {
        alpha: 255,
        red: 0,
        green: 0,
        blue: 0
      }
      canvas.drawColor(color, drawing.BlendMode.CLEAR);
      this.drawCurrentPage(canvas)
      this.drawCurrentPageShadow(canvas)
      this.drawNextPageArea(canvas)
      this.drawCurrentTurningPage(canvas);
    }
  }

  private drawNextPageArea(canvas: drawing.Canvas): void {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      canvas.save()
      canvas.clipPath(this.nextPagePath, drawing.ClipOp.INTERSECT, true)
      this.drawNextPage(canvas);
      this.drawNextPageShadow(canvas);
      canvas.restore()
    }
  }

  private drawCurrentTurningPageShadow(canvas: drawing.Canvas): void {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      let splitLineX = (this.canvasSize.width - this.touch.dx) / 2 + this.touch.dx;
      let shadowWidth = 70
      let maskFilter = drawing.MaskFilter.createBlurMaskFilter(drawing.BlurType.NORMAL, 70);
      const pen = new drawing.Pen();
      pen.setStrokeWidth(shadowWidth / 2);
      pen.setColor({
        alpha: 255,
        red: 0,
        green: 0,
        blue: 0
      });
      pen.setMaskFilter(maskFilter);
      canvas.attachPen(pen);
      canvas.drawLine(splitLineX, -shadowWidth, splitLineX, this.canvasSize.height + shadowWidth);
      canvas.detachPen();
    }
  }

  private drawCurrentPageShadow(canvas: drawing.Canvas): void {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      let shadowWidth = (this.canvasSize.width - this.touch.dx) / 4
      if (shadowWidth <= 0) {
        return
      }
      let maskFilter = drawing.MaskFilter.createBlurMaskFilter(drawing.BlurType.NORMAL, shadowWidth / 2);
      const pen = new drawing.Pen();
      pen.setStrokeWidth(shadowWidth / 2);
      pen.setColor({
        alpha: 255,
        red: 0,
        green: 0,
        blue: 0
      });
      pen.setMaskFilter(maskFilter);
      canvas.attachPen(pen);
      canvas.drawLine(this.touch.dx, -shadowWidth, this.touch.dx, this.canvasSize.height + shadowWidth);
      canvas.detachPen();
    }
  }

  private drawNextPageShadow(canvas: drawing.Canvas): void {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      let splitLineX = (this.canvasSize.width - this.touch.dx) / 2 + this.touch.dx;

      let shadowWidth = (Math.max(0, Math.min(this.canvasSize.width - splitLineX, splitLineX))) / 2
      if (shadowWidth <= 0) {
        return
      }
      let shadowMaskFilter = drawing.MaskFilter.createBlurMaskFilter(drawing.BlurType.NORMAL, shadowWidth)

      const shadowPen = new drawing.Pen();
      shadowPen.setStrokeWidth(shadowWidth)
      shadowPen.setMaskFilter(shadowMaskFilter)

      canvas.attachPen(shadowPen)
      canvas.drawLine(splitLineX, -shadowWidth, splitLineX, this.canvasSize.height + shadowWidth)
      canvas.detachPen()
    }
  }

  private drawCurrentTurningPage(canvas: drawing.Canvas): void {
    if (canIUse('SystemCapability.Graphics.Drawing')) {
      canvas.save()
      canvas.clipPath(this.turningPagePath, drawing.ClipOp.INTERSECT)
      canvas.save();

      canvas.translate(this.canvasSize.width, 0)
      canvas.scale(-1.0, 1.0)
      canvas.translate(-this.touchOffset.x, 0)
      this.drawCurrentPage(canvas,)
      canvas.restore();

      const maskBrush = new drawing.Brush();
      maskBrush.setColor({
        alpha: 125,
        red: 255,
        green: 255,
        blue: 255
      });

      canvas.attachBrush(maskBrush);
      canvas.drawPath(this.turningPagePath);
      canvas.detachBrush();

      this.drawCurrentTurningPageShadow(canvas);

      canvas.restore()
    }
  }

  onMove(): void {
  }

  applyAnimationProgressToTouch(process: number): void {
    let isRecover = process <= 0

    this.touch.x = Math.min((this.lastTouchOffset?.x ?? 0) +
      ((isRecover ? this.canvasSize.width : -this.canvasSize.width) - (this.lastTouchOffset?.x ?? 0)) *
      Math.abs(process),
      this.canvasSize.width);

    console.info(`animation: mTouch is x:${this.touch.x},y:${this.touch.y}, process is ${process}`)
  }

  reset(): void {
    super.reset();
  }
}

class TouchEvent {
  x: number;
  y: number;
  velocityX: number;
  velocityY: number;
  velocity: number;

  constructor(x: number, y: number, velocityX: number, velocityY: number, velocity: number) {
    this.x = x;
    this.y = y;
    this.velocityX = velocityX;
    this.velocityY = velocityY;
    this.velocity = velocity;
  }

  static zero(): TouchEvent {
    return new TouchEvent(0, 0, 0, 0, 0,);
  }

  get dx(): number {
    return this.x;
  }

  get dy(): number {
    return this.y;
  }

  get offset(): Offset {
    return new Offset(this.x, this.y);
  }
}

class Offset {
  x: number;
  y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }

  static zero(): Offset {
    return new Offset(0, 0);
  }

  get dx(): number {
    return this.x;
  }

  get dy(): number {
    return this.y;
  }

  equal(other: Offset): boolean {
    return this.x === other.x && this.y === other.y;
  }

  isEmpty(): boolean {
    return this.x === 0 && this.y === 0;
  }
}

export class Size {
  width: number;
  height: number;

  constructor(width: number, height: number) {
    this.width = width;
    this.height = height;
  }

  static zero(): Size {
    return new Size(0, 0);
  }

  equal(other: Size): boolean {
    return this.width === other.width && this.height === other.height;
  }

  isEmpty(): boolean {
    return this.width === 0 && this.height === 0;
  }
}