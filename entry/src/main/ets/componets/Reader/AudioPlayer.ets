/**
 * 有声书播放器组件
 * 使用 @ohos.multimedia.media 实现音频播放
 * 支持: 播放/暂停/进度拖动/速度调节
 */
import { media } from '@kit.MediaKit';
import fs from '@ohos.file.fs';
import { Books } from '../../database/entities/Books';
import {
  InkPalette, InkTypography, InkSpacing, InkRadius, InkShadow
} from '../../common/constants/DesignTokens'
import { ThemeStorageKey } from '../../common/constants/Theme'
import { ThemeItem } from '../../common/model/Theme'

@Component
export struct AudioPlayer {
  @Prop bookData: Books | undefined
  @State isPlaying: boolean = false
  @State currentTime: number = 0
  @State duration: number = 0
  @State playbackSpeed: number = 1.0
  @State audioTitle: string = ''
  @State isReady: boolean = false
  @State errorMsg: string = ''
  @StorageProp(ThemeStorageKey.THEME) theme: ThemeItem = {} as ThemeItem

  private avPlayer: media.AVPlayer | null = null
  private progressTimer: number = -1

  async aboutToAppear() {
    if (this.bookData?.bookUrl) {
      this.audioTitle = this.bookData.bookName || '未知音频';
      await this.initPlayer(this.bookData.bookUrl);
    }
  }

  aboutToDisappear() {
    this.stopProgressTimer();
    this.releasePlayer();
  }

  async initPlayer(url: string) {
    try {
      this.avPlayer = await media.createAVPlayer();

      // 监听状态变化
      this.avPlayer.on('stateChange', (state: string) => {
        console.info('AudioPlayer state: ' + state);
        switch (state) {
          case 'initialized':
            this.avPlayer?.prepare();
            break;
          case 'prepared':
            this.isReady = true;
            this.duration = (this.avPlayer?.duration || 0) / 1000;
            break;
          case 'playing':
            this.isPlaying = true;
            this.startProgressTimer();
            break;
          case 'paused':
            this.isPlaying = false;
            this.stopProgressTimer();
            break;
          case 'stopped':
          case 'completed':
            this.isPlaying = false;
            this.stopProgressTimer();
            break;
          case 'error':
            this.errorMsg = '音频加载失败';
            this.isPlaying = false;
            this.stopProgressTimer();
            break;
        }
      });

      // 监听错误
      this.avPlayer.on('error', (err) => {
        console.error('AudioPlayer error: ' + JSON.stringify(err));
        this.errorMsg = '播放出错';
        this.isPlaying = false;
      });

      // 设置音频源
      this.avPlayer.url = url;
    } catch (err) {
      console.error('初始化播放器失败: ' + JSON.stringify(err));
      this.errorMsg = '初始化播放器失败';
    }
  }

  async releasePlayer() {
    if (this.avPlayer) {
      try {
        await this.avPlayer.release();
      } catch (e) {
        // 忽略
      }
      this.avPlayer = null;
    }
  }

  startProgressTimer() {
    this.stopProgressTimer();
    this.progressTimer = setInterval(() => {
      if (this.avPlayer && this.isPlaying) {
        this.currentTime = (this.avPlayer.currentTime || 0) / 1000;
      }
    }, 500);
  }

  stopProgressTimer() {
    if (this.progressTimer >= 0) {
      clearInterval(this.progressTimer);
      this.progressTimer = -1;
    }
  }

  togglePlay() {
    if (!this.avPlayer || !this.isReady) return;

    if (this.isPlaying) {
      this.avPlayer.pause();
    } else {
      this.avPlayer.play();
    }
  }

  seekTo(value: number) {
    if (!this.avPlayer || !this.isReady) return;
    const seekTime = value * 1000; // 转为毫秒
    this.avPlayer.seek(seekTime);
    this.currentTime = value;
  }

  setSpeed(speed: number) {
    if (!this.avPlayer) return;
    this.playbackSpeed = speed;
    try {
      this.avPlayer.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_00_X);
      // 根据 speed 值映射到 HarmonyOS 的 PlaybackSpeed 枚举
      if (speed === 0.5) {
        this.avPlayer.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_0_50_X);
      } else if (speed === 0.75) {
        this.avPlayer.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_0_75_X);
      } else if (speed === 1.0) {
        this.avPlayer.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_00_X);
      } else if (speed === 1.25) {
        this.avPlayer.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_25_X);
      } else if (speed === 1.5) {
        this.avPlayer.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_50_X);
      } else if (speed === 2.0) {
        this.avPlayer.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_2_00_X);
      }
    } catch (err) {
      console.error('设置播放速度失败: ' + JSON.stringify(err));
    }
  }

  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  build() {
    Column({ space: InkSpacing.XL }) {
      // 音频信息
      Column({ space: InkSpacing.SM }) {
        // 音频图标
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(160)
            .height(160)
            .borderRadius(InkRadius.XL)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [[this.theme.mainColor, 0], [this.theme.secondColor, 1]]
            })

          Text('卷')
            .fontSize(64)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Lighter)
        }
        .width(160)
        .height(160)

        Text(this.audioTitle)
          .fontSize(InkTypography.TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(InkPalette.INK)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: InkSpacing.MD })
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')

      // 进度条
      Column({ space: InkSpacing.XS }) {
        Slider({
          value: this.currentTime,
          max: this.duration > 0 ? this.duration : 100,
          min: 0,
          step: 1,
          style: SliderStyle.OutSet
        })
          .blockColor(this.theme.mainColor)
          .selectedColor(this.theme.mainColor)
          .trackColor(InkPalette.PAPER_DEEP)
          .onChange((value: number) => {
            this.seekTo(value);
          })

        Row() {
          Text(this.formatTime(this.currentTime))
            .fontSize(InkTypography.CAPTION)
            .fontColor(InkPalette.INK_MIST)

          Text(this.formatTime(this.duration))
            .fontSize(InkTypography.CAPTION)
            .fontColor(InkPalette.INK_MIST)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .padding({ left: InkSpacing.XL, right: InkSpacing.XL })

      // 控制按钮
      Row({ space: InkSpacing.XXL }) {
        // 后退15秒
        Column() {
          Text('15')
            .fontSize(InkTypography.CAPTION)
            .fontColor(InkPalette.INK_FAINT)
          Text('后退')
            .fontSize(InkTypography.MICRO)
            .fontColor(InkPalette.INK_MIST)
        }
        .onClick(() => {
          this.seekTo(Math.max(0, this.currentTime - 15));
        })

        // 播放/暂停
        Row() {
          Text(this.isPlaying ? '⏸' : '▶')
            .fontSize(32)
            .fontColor(Color.White)
        }
        .width(64)
        .height(64)
        .borderRadius(InkRadius.FULL)
        .backgroundColor(this.theme.mainColor)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .shadow(InkShadow.MEDIUM)
        .onClick(() => {
          this.togglePlay();
        })

        // 前进15秒
        Column() {
          Text('15')
            .fontSize(InkTypography.CAPTION)
            .fontColor(InkPalette.INK_FAINT)
          Text('前进')
            .fontSize(InkTypography.MICRO)
            .fontColor(InkPalette.INK_MIST)
        }
        .onClick(() => {
          this.seekTo(Math.min(this.duration, this.currentTime + 15));
        })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .width('100%')

      // 播放速度
      Row({ space: InkSpacing.MD }) {
        ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], (speed: number) => {
          Text(speed + 'x')
            .fontSize(InkTypography.CAPTION)
            .fontColor(this.playbackSpeed === speed ? this.theme.mainColor : InkPalette.INK_MIST)
            .fontWeight(this.playbackSpeed === speed ? FontWeight.Medium : FontWeight.Normal)
            .padding({ left: InkSpacing.SM, right: InkSpacing.SM, top: InkSpacing.XS, bottom: InkSpacing.XS })
            .borderRadius(InkRadius.FULL)
            .backgroundColor(this.playbackSpeed === speed ? this.theme.secondColor : Color.Transparent)
            .onClick(() => {
              this.setSpeed(speed);
            })
        })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')

      // 错误提示
      if (this.errorMsg) {
        Text(this.errorMsg)
          .fontSize(InkTypography.CAPTION)
          .fontColor(InkPalette.ERROR)
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: InkSpacing.XXL, bottom: InkSpacing.XXL })
    .backgroundColor(InkPalette.PAPER)
  }
}
