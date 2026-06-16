import measure from '@ohos.measure'
import I18n from '@ohos.i18n';

// 小说内容解析辅助工具
export class NovelContentParseHelper {
  /**
   * 根据给定的页面大小对章节内容进行分页计算
   * Paginate the chapter content according to the given page size.
   *
   * @param {string[]} paragraphList 章节的段落列表 the list of paragraph in the chapter
   * @param {number} fontSize 展示内容的文字大小 the text size of display config
   * @param {number} lineHeight 展示内容的行高 the line height of display config
   * @param {number} measureContentWidth 展示区域的宽度 the width of display area
   * @param {number} measureContentHeight 展示区域的高度 the height of display area
   * @return {Promise<string>} 章节中每页的内容列表 The list of content for each page in chapter
   */
  static async calculateChapterContent(paragraphList: string[], fontSize: number, lineHeight: number,
    measureContentWidth: number, measureContentHeight: number, paragraphSpacing: number = 0,
    letterSpacing: number = 0): Promise<string[][]> {
    let tempParagraphList = paragraphList.slice()
    let wordSize = measure.measureTextSize({
      textContent: '测', // 随便找的测试文字，用来测试一个字有多大。
      fontSize: fontSize,
      lineHeight: lineHeight,
      letterSpacing: `${letterSpacing}px`
    });
    let pageIndex = 0;
    let pageContent: string[][] = [];
    let lastLength = tempParagraphList.length;
    while (tempParagraphList.length != 0) {
      try {
        let pageParagraphList =
          await NovelContentParseHelper.calculateParagraphForPage(tempParagraphList, measureContentHeight,
            measureContentWidth, wordSize, fontSize, lineHeight, paragraphSpacing, letterSpacing)

        pageContent[pageIndex] = pageParagraphList
        pageIndex++;

        // 安全检查，如果一次计算没有消耗任何段落，强制消耗一个，防止死循环
        if (tempParagraphList.length === lastLength) {
          tempParagraphList.splice(0, 1);
        }
        lastLength = tempParagraphList.length;
      } catch (e) {
        console.error(e)
        // 发生错误时，强制消耗一个以确保进度
        tempParagraphList.splice(0, 1);
        lastLength = tempParagraphList.length;
      }
    }

    return pageContent
  }

  /**
   * 根据给定的段落，计算一页的内容
   * 会自动移除已经计算过的段落
   * Calculate the content of each page line by line
   *
   * @param {string[]} paragraphs 目标段落列表 the target paragraph list
   * @param {number} targetHeight 展示内容的文字大小 the text size of display config
   * @param {number} targetWidth 展示内容的行高 the line height of display config
   * @param {SizeOptions} wordSize 展示区域的宽度 the width of display area
   * @param {number} fontSize 展示内容的文字大小 the text size of display config
   * @param {number} lineHeight 展示内容的行高 the line height of display config
   * @return {Promise<string>} 每页的段落列表 The list of content for each page in chapter
   */
  static calculateParagraphForPage(paragraphs: string[], targetHeight: number, targetWidth: number,
    wordSize: SizeOptions, fontSize: number, lineHeight: number, paragraphSpacing: number = 0,
    letterSpacing: number = 0): Promise<string[]> {
    return new Promise((resolve, reject) => {
      let constraintWidth = targetWidth;

      let wordWidth: number = typeof wordSize.width === 'number' ? (wordSize.width ?? 0) : 0
      let wordHeight: number = typeof wordSize.height === 'number' ? (wordSize.height ?? 0) : 0
      if (wordWidth <= 0) {
        wordWidth = fontSize;
      }
      if (wordHeight <= 0) {
        wordHeight = lineHeight || (fontSize * 1.5);
      }

      let guessLineWordCount = Math.floor(constraintWidth / wordWidth)
      if (guessLineWordCount <= 0) {
        guessLineWordCount = 1;
      }
      let constraintHeight = targetHeight - vp2px(6);
      if (constraintHeight <= 0) {
        constraintHeight = targetHeight;
      }

      // 断句对象
      let breakIterator = I18n.getLineInstance('cn');

      let result: string[] = [];

      let currentLineIndex = 0;
      let accumulatedHeight = 0;
      let paragraphSpacingPx = vp2px(paragraphSpacing);

      const lineFeed = '\n';

      while (accumulatedHeight + wordHeight <= constraintHeight && paragraphs.length != 0) {
        let currentTarget = paragraphs[0]
        
        // 检查是否为图片占位符
        let isImage = currentTarget.trim().startsWith('[img:') && currentTarget.trim().endsWith(']');
        if (isImage) {
          // 图片实际渲染高度: 180vp + 上下各8vp margin = 196vp
          let imgHeightPx = vp2px(180 + 16);
          let imgLinesNeeded = Math.max(1, Math.ceil(imgHeightPx / wordHeight));
          let imgHeightNeeded = wordHeight * imgLinesNeeded;
          if (accumulatedHeight === 0 || accumulatedHeight + imgHeightNeeded <= constraintHeight) {
            result[currentLineIndex] = currentTarget.trim();
            for (let i = 1; i < imgLinesNeeded; i++) {
              result[currentLineIndex + i] = '';
            }
            currentLineIndex += imgLinesNeeded;
            accumulatedHeight += imgHeightNeeded;
            paragraphs.splice(0, 1);
          } else {
            // 空间不够，留到下一页
            break;
          }
          continue;
        }

        let isNeedAddLineFeed = currentTarget.endsWith(lineFeed);
        if (isNeedAddLineFeed) {
          currentTarget = currentTarget.substring(0, currentTarget.length - 1)
        }

        if (currentTarget.length === 0) {
          result[currentLineIndex] = isNeedAddLineFeed ? lineFeed : '';
          currentLineIndex++;
          accumulatedHeight += wordHeight;
          if (isNeedAddLineFeed) {
            accumulatedHeight += paragraphSpacingPx;
          }
          paragraphs.splice(0, 1);
          continue;
        }

        let heightLimit = wordHeight * 1.15;
        let currentTargetHeight = NovelContentParseHelper.measureTextHeight(currentTarget, constraintWidth, fontSize, lineHeight, letterSpacing);

        if (currentTargetHeight <= heightLimit) {
          result[currentLineIndex] = currentTarget + (isNeedAddLineFeed ? lineFeed : '');
          currentLineIndex++
          accumulatedHeight += wordHeight;
          if (isNeedAddLineFeed) {
            accumulatedHeight += paragraphSpacingPx;
          }
          paragraphs.splice(0, 1)
        } else {
          breakIterator.setLineBreakText(currentTarget)
          breakIterator.following(guessLineWordCount)
          let currentPos = breakIterator.current();

          if (currentPos <= 0 || currentPos > currentTarget.length) {
            currentPos = Math.max(1, Math.min(currentTarget.length, guessLineWordCount));
          }

          let tempCurrentTarget = currentTarget.substring(0, currentPos)
          let testHeight = NovelContentParseHelper.measureTextHeight(tempCurrentTarget, constraintWidth, fontSize, lineHeight, letterSpacing);

          if (testHeight <= heightLimit) {
            while (true) {
              let nextPos = breakIterator.next();
              if (nextPos === -1 || nextPos > currentTarget.length) {
                break;
              }
              let nextTarget = currentTarget.substring(0, nextPos);
              let nextHeight = NovelContentParseHelper.measureTextHeight(nextTarget, constraintWidth, fontSize, lineHeight, letterSpacing);
              if (nextHeight > heightLimit) {
                break;
              }
              currentPos = nextPos;
              tempCurrentTarget = nextTarget;
            }
          } else {
            while (currentPos > 1) {
              let prevPos = breakIterator.previous();
              if (prevPos === -1 || prevPos === 0) {
                break;
              }
              let prevTarget = currentTarget.substring(0, prevPos);
              let prevHeight = NovelContentParseHelper.measureTextHeight(prevTarget, constraintWidth, fontSize, lineHeight, letterSpacing);
              if (prevHeight <= heightLimit) {
                currentPos = prevPos;
                tempCurrentTarget = prevTarget;
                break;
              }
              currentPos = prevPos;
              tempCurrentTarget = prevTarget;
            }
          }

          // 确保每次循环至少消耗 1 个字符，保证有进度，绝不死循环
          if (tempCurrentTarget.length === 0 && currentTarget.length > 0) {
            tempCurrentTarget = currentTarget.substring(0, 1);
            currentPos = 1;
          }

          result[currentLineIndex] = tempCurrentTarget;
          currentLineIndex++
          accumulatedHeight += wordHeight;
          
          let remaining = paragraphs[0].substring(tempCurrentTarget.length);
          if (remaining.length === 0 || remaining === lineFeed) {
            if (isNeedAddLineFeed) {
              accumulatedHeight += paragraphSpacingPx;
              result[currentLineIndex - 1] += lineFeed;
            }
            paragraphs.splice(0, 1);
          } else {
            paragraphs[0] = remaining;
          }
        }
      }

      resolve(result)
    });
  }

  /**
   * 测量给定文字的高度
   * measure the height of text
   *
   * @param {string} content 文字内容 the content of given text
   * @param {number} constraintWidth 约束宽度 the measure width;
   * @param {number} fontSize 展示内容的文字大小 the text size of display config
   * @param {number} lineHeight 展示内容的行高 the line height of display config
   * @return {number} 测量的文字高度 The height of given text
   */
  static measureTextHeight(content: string, constraintWidth: number, fontSize: number, lineHeight: number,
    letterSpacing: number = 0): number {
    let height = measure.measureTextSize({
      textContent: content,
      constraintWidth: `${constraintWidth}px`,
      fontSize: fontSize,
      lineHeight: lineHeight,
      letterSpacing: `${letterSpacing}px`
    }).height

    return typeof height === 'number' ? height : 0;
  }
}