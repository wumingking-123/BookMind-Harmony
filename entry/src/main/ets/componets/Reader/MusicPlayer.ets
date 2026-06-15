import { BusinessError } from '@ohos.base';
import media from '@ohos.multimedia.media';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import { Books } from '../../database/entities/Books';

let avPlayer: media.AVPlayer;
let seekTime: number = 15000

@Component
export struct MusicPlayer {
  @Prop bookData: Books | undefined
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0
  @StorageLink('topRectHeight') topRectHeight: number = 0
  @StorageLink('WindowWidth') WindowWidth: number = 0
  @Prop WidthMinus: number = 0
  @Link isShowListen: boolean
  @State hasInit: boolean = false;
  @State isMusicPlaying: boolean = false; // 音乐播放状态
  @State MusicPlayingTime: number = 0 // 音乐目前播放时间
  @State MusicDuration: number = 100 // 音乐总时长
  @State isShowSpeed: boolean = false;

  // 格式化时间
  formatMilliseconds(milliseconds: number): string {
    const totalSeconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;

    // 格式化秒数为两位数字
    const formattedSeconds = seconds < 10 ? `0${seconds}` : `${seconds}`;

    return `${minutes}:${formattedSeconds}`;
  }

  async selectFromPicker() {
    try {
      let audioSelectOptions = new picker.AudioSelectOptions();
      let audioPicker = new picker.AudioViewPicker();
      let audioSelectResult: Array<string> = await audioPicker.select(audioSelectOptions);
      if (audioSelectResult && audioSelectResult.length > 0) {
        console.info('AudioViewPicker.select successfully, audioSelectResult uri: ' + JSON.stringify(audioSelectResult));
        avPlayer.url = 'fd://' + fs.openSync(audioSelectResult[0]).fd.toString();
      }
    } catch (err) {
      console.error('AudioViewPicker select failed: ' + JSON.stringify(err));
    }
  }

  async aboutToAppear() {
    try {
      let video: media.AVPlayer = await media.createAVPlayer();
      if (video != null) {
        avPlayer = video;
        console.info('createAVPlayer success');
        
        await this.setCallback(avPlayer);
        this.timeDurationUpdateCallback(avPlayer);
        
        // Load the audiobook URL directly or via picker fallback
        if (this.bookData && this.bookData.bookUrl) {
          try {
            let file = fs.openSync(this.bookData.bookUrl, fs.OpenMode.READ_ONLY);
            avPlayer.url = 'fd://' + file.fd.toString();
            console.info('MusicPlayer loaded url from bookData.bookUrl: ' + this.bookData.bookUrl);
          } catch (err) {
            console.error('MusicPlayer failed to open bookData.bookUrl: ' + JSON.stringify(err));
            await this.selectFromPicker();
          }
        } else {
          await this.selectFromPicker();
        }
      } else {
        console.error('createAVPlayer returned null');
      }
    } catch (error) {
      console.error(`AVPlayer initialization error: ${(error as BusinessError).message}`);
    }
  }

  build() {
    Column() {
      Row() {
        Image($r("app.media.direction_down")).width(24)
          .onClick(() => {
            this.isShowListen = false
          })
        Blank(1)
        Text(this.bookData?.bookName || '有声书')
          .lineHeight(24)
          .fontColor("#FFFFFF")
          .font({
            size: 16,
            weight: 500
          })
        Blank(1)
        Image($r("app.media.more")).width(24)
      }
      .height(48)
      .width("100%")


      Blank(1)
      Column() {
        Row() {
          Text(this.bookData?.durChapterTitle || '有声书章节已载入')
        }

        Row() {
          Text(this.bookData?.author || '本地导入')
          Button("搜作者")
        }

        Row() {
          Text("音频播放中，请戴上耳机，享受精彩内容。")
        }
      }

      Column({ space: 24 }) {
        Row() {
          Stack() {
            Flex() {
              Text(`${this.formatMilliseconds(this.MusicPlayingTime)}/${this.formatMilliseconds(this.MusicDuration)}`)
                .font({
                  size: 10,
                  weight: 400
                })
            }
            .margin({
              // 需要在模拟器查看
              left: (this.WindowWidth - this.WidthMinus) * this.MusicPlayingTime / this.MusicDuration
            })
            .borderRadius(33)
            .width(70)
            .zIndex(2)
            .backgroundColor('#FFFFFF')
            .padding({
              top: 4,
              bottom: 4,
              left: 8,
              right: 8
            })

            Line().width("100%").height(2).backgroundColor('#FFFFFF')
          }
          .alignContent(Alignment.Start)
          .width("100%")
        }

        Flex({
          direction: FlexDirection.Row,
          justifyContent: FlexAlign.SpaceBetween,
          alignItems: ItemAlign.Center
        }) {
          Image($r("app.media.Backward"))
            .width(24)
            .onClick(() => {
              avPlayer.seek(this.MusicPlayingTime - seekTime < 0 ? 0 : this.MusicPlayingTime - seekTime,
                media.SeekMode.SEEK_PREV_SYNC)
            })
          Image($r("app.media.Previous"))
            .width(24)
            .onClick(() => {
            })
          Image($r(this.isMusicPlaying ? "app.media.stop" : "app.media.music_play"))
            .fillColor(Color.White)
            .width(80)
            .onClick(async () => {
              if (this.isMusicPlaying) {
                avPlayer.pause()
                avPlayer.off('timeUpdate')
              } else {
                avPlayer.play()
                this.timeUpdateCallback()
              }
            })

          Image($r("app.media.next"))
            .width(24)
            .onClick(() => {
            })
          Image($r("app.media.forward"))
            .width(24)
            .onClick(() => {
              avPlayer.seek(this.MusicPlayingTime + seekTime, media.SeekMode.SEEK_NEXT_SYNC)
            })
        }
        .width("100%")

        Flex({
          direction: FlexDirection.Row,
          justifyContent: FlexAlign.SpaceBetween,
          alignItems: ItemAlign.Center
        }) {
          Column() {
            Image($r("app.media.appointment_time"))
              .width(24)
              .onClick(() => {
              })
            Text("定时")
          }

          Column() {
            Image($r("app.media.speed"))
              .width(24)
              .onClick(() => {

              })
            Text("语速")
          }.bindSheet($$this.isShowSpeed, this.SpeedDialog(), {
            height: 326,
            showClose: false,
            dragBar: false,
            blurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
          })

          Column() {
            Image($r("app.media.add_bookshelf"))
              .fillColor(Color.White)
              .width(80)
              .onClick(() => {

              })
            Text("加书架")
          }

          Column() {
            Image($r("app.media.directory"))
              .width(24)
              .onClick(() => {
              })
            Text("目录")
          }
        }
        .width("100%")

        Row() {

        }
      }
    }
    .height("100%")
    .padding({
      top: this.topRectHeight,
      bottom: this.bottomRectHeight,
      left: 24,
      right: 24
    })
  }

  setCallback(avPlayer: media.AVPlayer) {
    avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      console.info('reason:' + reason) // reason:1 USER; 2 BACKGROUND;
      switch (state) {
        case 'idle':
          console.info('state idle called');
          break;
        case 'initialized':
          console.info('initialized prepared called')
          this.hasInit = true;
          avPlayer.prepare()
          break;
        case 'playing':
          console.info('audio play success')
          this.isMusicPlaying = true
          break;
        case 'paused':
          console.info('audio paused success')
          this.isMusicPlaying = false
          break;
        case 'error':
          console.error('state error called');
          break;
        default:
          console.info('unkown state :' + state);
          break;
      }
    })
  }

  // 用于获取音频目前播放时间
  timeUpdateCallback() {
    avPlayer.on('timeUpdate', (time: number) => {
      console.info('timeUpdate success,and new time is :' + time)
      this.MusicPlayingTime = time
    })
  }

  // 用于获取音频的总时间长度
  timeDurationUpdateCallback(avPlayer: media.AVPlayer) {
    avPlayer.on('durationUpdate', (duration: number) => {
      console.info('durationUpdate success,new duration is :' + duration)
      this.MusicDuration = duration
    })
  }

  @Builder
  SpeedDialog() {
    Column() {
      Row() {
        Text("语速设置")
        Blank(1)
        Text("仅用于当前")
        Toggle({ type: ToggleType.Switch, isOn: false })
      }

      Row() {

      }
    }
  }
}