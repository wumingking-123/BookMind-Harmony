/**
 * 下载任务状态模型
 */
import { BookSource } from '../../database/entities/BookSource';

export enum DownloadStatus {
  PENDING = 'pending',
  DOWNLOADING = 'downloading',
  PAUSED = 'paused',
  COMPLETED = 'completed',
  ERROR = 'error'
}

export class DownloadTask {
  id: string = '';
  bookUrl: string = '';
  bookName: string = '';
  bookAuthor: string = '';
  bookSource?: BookSource;
  tocUrl: string = '';
  startChapter: number = 0;
  endChapter: number = 0;
  totalChapters: number = 0;
  downloadedChapters: number = 0;
  status: DownloadStatus = DownloadStatus.PENDING;
  startTime: number = 0;
  error?: string;
  savedFilePath: string = '';
  chapters: DownloadChapter[] = [];

  constructor() {
    this.id = Date.now().toString() + Math.random().toString(36).substring(2, 9);
  }
}

export class DownloadChapter {
  index: number = 0;
  title: string = '';
  url: string = '';
  status: DownloadStatus = DownloadStatus.PENDING;
  content?: string;
  error?: string;
}
