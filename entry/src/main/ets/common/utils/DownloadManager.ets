/**
 * 下载管理器
 * 管理书籍下载任务队列
 */
import { DownloadTask, DownloadChapter, DownloadStatus } from '../model/DownloadTask';
import { BookSource } from '../../database/entities/BookSource';
import { TocAnalysis, TocAnalysisData } from '../model/TocAnalysis';
import { ContentAnalysis, ContentAnalysisData } from '../model/ContentAnalysis';
import { BookChapter } from '../model/BookChapter';
import chaptersDao from '../../database/dao/ChaptersDao';
import requestUtil from './requestUtils';
import fs from '@ohos.file.fs';

export type DownloadProgressCallback = (task: DownloadTask) => void;

class DownloadManager {
  private tasks: Map<string, DownloadTask> = new Map();
  private activeTasks: Set<string> = new Set();
  private maxConcurrent: number = 3;
  private progressCallbacks: DownloadProgressCallback[] = [];
  private pathDir: string = '';

  /**
   * 添加下载任务
   */
  addTask(
    bookUrl: string,
    bookName: string,
    bookAuthor: string,
    bookSource: BookSource,
    tocUrl: string,
    startChapter: number,
    endChapter: number
  ): DownloadTask {
    const task = new DownloadTask();
    task.bookUrl = bookUrl;
    task.bookName = bookName;
    task.bookAuthor = bookAuthor;
    task.bookSource = bookSource;
    task.tocUrl = tocUrl;
    task.startChapter = startChapter;
    task.endChapter = endChapter;
    task.startTime = Date.now();

    this.tasks.set(task.id, task);
    this.startNextTask();

    return task;
  }

  /**
   * 设置存储路径
   */
  setPathDir(path: string): void {
    this.pathDir = path;
  }

  /**
   * 注册进度回调
   */
  onProgress(callback: DownloadProgressCallback): void {
    this.progressCallbacks.push(callback);
  }

  /**
   * 移除进度回调
   */
  offProgress(callback: DownloadProgressCallback): void {
    const index = this.progressCallbacks.indexOf(callback);
    if (index >= 0) {
      this.progressCallbacks.splice(index, 1);
    }
  }

  /**
   * 通知进度更新
   */
  private notifyProgress(task: DownloadTask): void {
    for (const callback of this.progressCallbacks) {
      callback(task);
    }
  }

  /**
   * 开始下一个任务
   */
  private startNextTask(): void {
    if (this.activeTasks.size >= this.maxConcurrent) return;

    let found = false;
    this.tasks.forEach((task: DownloadTask, id: string) => {
      if (!found && task.status === DownloadStatus.PENDING && !this.activeTasks.has(id)) {
        found = true;
        this.executeTask(task);
      }
    });
  }

  /**
   * 执行下载任务
   */
  private async executeTask(task: DownloadTask): Promise<void> {
    this.activeTasks.add(task.id);
    task.status = DownloadStatus.DOWNLOADING;
    this.notifyProgress(task);

    try {
      // 1. 获取目录
      const tocBody = await requestUtil.requestUrlHtml(task.tocUrl, task.bookSource?.charset);
      const tocAnalysis = new TocAnalysis();
      tocAnalysis.init(new TocAnalysisData({
        body: tocBody,
        bookSource: task.bookSource!,
        bookUrl: task.bookUrl
      }));

      const allChapters = await tocAnalysis.getChapterList();

      // 2. 筛选章节范围
      let selectedChapters: BookChapter[];
      if (task.endChapter === -1) {
        // 全部章节
        selectedChapters = allChapters;
      } else {
        selectedChapters = allChapters.slice(
          task.startChapter,
          task.endChapter + 1
        );
      }

      task.totalChapters = selectedChapters.length;

      // 3. 初始化章节状态
      task.chapters = selectedChapters.map((ch, i) => {
        const dc = new DownloadChapter();
        dc.index = ch.index;
        dc.title = ch.title;
        dc.url = ch.url;
        return dc;
      });

      // 4. 先保存章节目录到数据库
      await chaptersDao.deleteChaptersByBookUrl(task.bookUrl);
      await chaptersDao.insertChapters(selectedChapters);

      // 5. 逐章下载内容
      for (let i = 0; i < task.chapters.length; i++) {
        if ((task.status as DownloadStatus) === DownloadStatus.PAUSED) {
          break;
        }

        const chapter = task.chapters[i];
        chapter.status = DownloadStatus.DOWNLOADING;
        this.notifyProgress(task);

        try {
          const chapterBody = await requestUtil.requestUrlHtml(chapter.url, task.bookSource?.charset);
          const contentAnalysis = new ContentAnalysis();
          contentAnalysis.init(new ContentAnalysisData({
            body: chapterBody,
            bookSource: task.bookSource!,
            chapterUrl: chapter.url
          }));

          const result = await contentAnalysis.getContent();
          chapter.content = result.content;
          chapter.status = DownloadStatus.COMPLETED;
          task.downloadedChapters++;
        } catch (e) {
          chapter.status = DownloadStatus.ERROR;
          chapter.error = (e as Error).message;
          console.error(`下载章节失败: ${chapter.title}`, e);
        }

        this.notifyProgress(task);
      }

      // 6. 完成
      if ((task.status as DownloadStatus) !== DownloadStatus.PAUSED) {
        task.status = DownloadStatus.COMPLETED;
        // 保存为TXT文件
        this.saveAsTxtFile(task);
      }
    } catch (e) {
      task.status = DownloadStatus.ERROR;
      task.error = (e as Error).message;
      console.error(`下载任务失败: ${task.bookName}`, e);
    }

    this.activeTasks.delete(task.id);
    this.notifyProgress(task);
    this.startNextTask();
  }

  /**
   * 暂停任务
   */
  pauseTask(taskId: string): void {
    const task = this.tasks.get(taskId);
    if (task && task.status === DownloadStatus.DOWNLOADING) {
      task.status = DownloadStatus.PAUSED;
      this.activeTasks.delete(taskId);
      this.notifyProgress(task);
      this.startNextTask();
    }
  }

  /**
   * 恢复任务
   */
  resumeTask(taskId: string): void {
    const task = this.tasks.get(taskId);
    if (task && task.status === DownloadStatus.PAUSED) {
      task.status = DownloadStatus.PENDING;
      this.notifyProgress(task);
      this.startNextTask();
    }
  }

  /**
   * 取消任务
   */
  cancelTask(taskId: string): void {
    const task = this.tasks.get(taskId);
    if (task) {
      task.status = DownloadStatus.ERROR;
      task.error = '已取消';
      this.activeTasks.delete(taskId);
      this.tasks.delete(taskId);
      this.notifyProgress(task);
      this.startNextTask();
    }
  }

  /**
   * 暂停所有任务
   */
  pauseAll(): void {
    this.tasks.forEach((task: DownloadTask, id: string) => {
      if (task.status === DownloadStatus.DOWNLOADING) {
        task.status = DownloadStatus.PAUSED;
        this.activeTasks.delete(id);
        this.notifyProgress(task);
      }
    });
  }

  /**
   * 获取所有任务
   */
  getAllTasks(): DownloadTask[] {
    return Array.from(this.tasks.values());
  }

  /**
   * 获取下载中的任务
   */
  getDownloadingTasks(): DownloadTask[] {
    return Array.from(this.tasks.values()).filter(
      t => t.status === DownloadStatus.DOWNLOADING || t.status === DownloadStatus.PENDING
    );
  }

  /**
   * 获取已完成的任务
   */
  getCompletedTasks(): DownloadTask[] {
    return Array.from(this.tasks.values()).filter(
      t => t.status === DownloadStatus.COMPLETED
    );
  }

  /**
   * 获取任务
   */
  getTask(taskId: string): DownloadTask | undefined {
    return this.tasks.get(taskId);
  }

  /**
   * 删除任务
   */
  removeTask(taskId: string): void {
    this.cancelTask(taskId);
  }

  /**
   * 导出任务为TXT文件（复制到公共下载目录）
   */
  async exportTask(taskId: string): Promise<boolean> {
    const task = this.tasks.get(taskId);
    if (!task || !task.savedFilePath) {
      console.error('[DownloadManager] 导出失败: 任务不存在或文件未保存');
      return false;
    }

    try {
      // 尝试多个可能的公共下载目录
      const safeName = task.bookName.replace(/[\\/:*?"<>|]/g, '_') + '.txt';
      const candidates: string[] = [
        '/storage/Users/currentUser/Download',
        '/storage/emulated/0/Download',
        this.pathDir + '/Download'
      ];

      let destPath = '';
      for (const dir of candidates) {
        try {
          if (!fs.accessSync(dir)) {
            fs.mkdirSync(dir);
          }
          destPath = dir + '/' + safeName;
          break;
        } catch (_) {
          continue;
        }
      }

      if (!destPath) {
        // 回退：导出到应用 Download 目录
        const fallbackDir = this.pathDir + '/downloads/export';
        if (!fs.accessSync(fallbackDir)) {
          fs.mkdirSync(fallbackDir);
        }
        destPath = fallbackDir + '/' + safeName;
      }

      fs.copyFileSync(task.savedFilePath, destPath);

      console.log('[DownloadManager] 导出成功: ' + destPath);
      return true;
    } catch (e) {
      console.error('[DownloadManager] 导出失败: ' + (e as Error).message);
      return false;
    }
  }

  /**
   * 将下载完成的章节保存为TXT文件
   */
  private saveAsTxtFile(task: DownloadTask): void {
    try {
      if (!this.pathDir) {
        console.error('[DownloadManager] pathDir not available');
        return;
      }
      const pathDir = this.pathDir;

      const downloadDir = pathDir + '/downloads';
      // 确保目录存在
      if (!fs.accessSync(downloadDir)) {
        fs.mkdirSync(downloadDir);
      }

      // 文件名: 书名.txt
      const safeName = task.bookName.replace(/[\\/:*?"<>|]/g, '_');
      const filePath = downloadDir + '/' + safeName + '.txt';

      // 拼接所有章节内容
      let content = task.bookName + '\n作者：' + task.bookAuthor + '\n\n';
      for (const chapter of task.chapters) {
        if (chapter.status === DownloadStatus.COMPLETED && chapter.content) {
          content += '\n\n' + chapter.title + '\n\n' + chapter.content;
        }
      }

      // 写入文件
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, content);
      fs.close(file);

      task.savedFilePath = filePath;
      console.log('[DownloadManager] TXT文件已保存: ' + filePath);
      this.notifyProgress(task);
    } catch (e) {
      console.error('[DownloadManager] 保存TXT文件失败: ' + (e as Error).message);
    }
  }
}

const downloadManager = new DownloadManager();
export default downloadManager as DownloadManager;
