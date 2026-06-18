import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import { BusinessError } from '@kit.BasicServicesKit';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import display from '@ohos.display';
import DbUtil from '../common/utils/DbUtil';
import DataBase from '../database'
import { webview } from '@kit.ArkWeb';
import { themeManager, ThemeManager } from '../common/utils/ThemeManager';
import bookSourceDao from '../database/dao/BookSourceDao';
import { BookSource } from '../database/entities/BookSource';
import { getDefaultBookSources } from '../common/constants/DefaultBookSources';
import downloadManager from '../common/utils/DownloadManager';

export default class EntryAbility extends UIAbility {

  private curBp: string = ''

  // 根据当前窗口尺寸更新断点
  private updateBreakpoint(windowWidth: number) :void{
    // 将长度的单位由px换算为vp
    let windowWidthVp = windowWidth / display.getDefaultDisplaySync().densityPixels
    let newBp: string = ''
    if (windowWidthVp < 320) {
      newBp = 'xs'
    } else if (windowWidthVp < 600) {
      newBp = 'sm'
    } else if (windowWidthVp < 840) {
      newBp = 'md'
    } else {
      newBp = 'lg'
    }
    if (this.curBp !== newBp) {
      this.curBp = newBp
      // 使用状态变量记录当前断点值
      AppStorage.setOrCreate('currentBreakpoint', this.curBp)
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    webview.WebviewController.initializeWebEngine()//初始化web控件
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    // 初始化db数据库/创建相关数据表
    DbUtil.initDB(this.context).then(async () => {
      DataBase.initAllTable()
      // 自动加载默认书源（补充缺失的默认书源）
      try {
        const defaultSources = getDefaultBookSources()
        const toInsert: BookSource[] = []
        for (const ds of defaultSources) {
          const exist = await bookSourceDao.getBookSource(ds.bookSourceUrl)
          if (!exist) {
            toInsert.push(ds)
            hilog.info(0x0000, 'testTag', '待添加默认书源: %{public}s', ds.bookSourceName)
          } else {
            // 检查是否需要更新（exploreUrl格式不对、内容不同、或缺少规则）
            const needUpdateRule = ds.ruleToc || ds.ruleExplore || ds.ruleContent
            const needUpdateUrl = ds.exploreUrl && (!exist.exploreUrl || !exist.exploreUrl.startsWith('[') || exist.exploreUrl !== ds.exploreUrl)
            const needUpdateSearch = ds.searchUrl && exist.searchUrl !== ds.searchUrl
            if (needUpdateRule || needUpdateUrl || needUpdateSearch) {
              exist.ruleExplore = ds.ruleExplore || exist.ruleExplore
              exist.ruleToc = ds.ruleToc || exist.ruleToc
              exist.ruleContent = ds.ruleContent || exist.ruleContent
              exist.ruleSearch = ds.ruleSearch || exist.ruleSearch
              exist.ruleBookInfo = ds.ruleBookInfo || exist.ruleBookInfo
              exist.charset = ds.charset || exist.charset
              exist.exploreUrl = ds.exploreUrl || exist.exploreUrl
              exist.searchUrl = ds.searchUrl || exist.searchUrl
              exist.searchResultUrl = ds.searchResultUrl || exist.searchResultUrl
              exist.enabledExplore = ds.enabledExplore
              await bookSourceDao.update(exist)
              hilog.info(0x0000, 'testTag', '已更新书源: %{public}s', ds.bookSourceName)
            }
          }
        }
        if (toInsert.length > 0) {
          await bookSourceDao.batchInsert(toInsert)
          hilog.info(0x0000, 'testTag', '已补充 %{public}d 个默认书源', toInsert.length)
        }
      } catch (e) {
        hilog.error(0x0000, 'testTag', '加载默认书源失败: %{public}s', JSON.stringify(e) ?? '')
      }
    })
    // 获取本地文件存储路径
    const pathDir = this.context.filesDir;
    AppStorage.setOrCreate('pathDir', pathDir);
    downloadManager.setPathDir(pathDir);
    // 书源存入的地址
    AppStorage.setOrCreate('pathBookSource', pathDir + '/bookSource.json');
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    // 全屏
    windowStage.getMainWindow((err, windowClass) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return
      }
      //全屏
      windowClass.setWindowLayoutFullScreen(true)
        .then(() => {
          console.info('Succeeded in setting the window layout to full-screen mode.');
        })
        .catch((err: BusinessError) => {
          console.error('Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(err));
        });
      //获取上下遮挡区域
      let type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR; //导航栏
      let avoidArea = windowClass.getWindowAvoidArea(type);
      let bottomRectHeight = avoidArea.bottomRect.height;
      AppStorage.setOrCreate('bottomRectHeight', px2vp(bottomRectHeight));

      // 2. 获取导航栏避让遮挡的区域
      type = window.AvoidAreaType.TYPE_SYSTEM; // 状态栏
      avoidArea = windowClass.getWindowAvoidArea(type);
      let topRectHeight = avoidArea.topRect.height;
      AppStorage.setOrCreate('topRectHeight', px2vp(topRectHeight));

      //手机屏幕高度和宽度
      let defaultDisplay = display.getDefaultDisplaySync()
      let WindowHeight = defaultDisplay.height
      let WindowWidth = defaultDisplay.width


      AppStorage.setOrCreate('WindowHeight', px2vp(WindowHeight));
      AppStorage.setOrCreate('WindowWidth', px2vp(WindowWidth));

      let avoidAreaSys = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      let navi = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      let total = avoidAreaSys.topRect.height + navi.bottomRect.height;
      AppStorage.setOrCreate('avoidHeight', total);
      AppStorage.setOrCreate('stateHeight', px2vp(avoidAreaSys.topRect.height));

    })

    windowStage.loadContent('/pages/welcomePage'.slice(1), (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      // 主题初始化
      themeManager.init()
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground() {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground() {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
