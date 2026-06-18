import { InkPalette, InkTypography, InkSpacing, InkRadius } from '../../common/constants/DesignTokens'

interface MdBlock {
  type: string
  text: string
  level?: number
  items?: string[]
  lang?: string
  table?: MdTable
}

interface MdTable {
  headers: string[]
  rows: string[][]
  aligns: string[]
}

@Component
export struct MarkdownView {
  @Prop @Watch('onContentChange') content: string = ''
  @State blocks: MdBlock[] = new Array()
  @Prop isNightMode: boolean = false

  aboutToAppear(): void {
    this.blocks = this.parse(this.content)
  }

  aboutToRecycle(): void {
    this.blocks = new Array()
  }

  onContentChange(): void {
    this.blocks = this.parse(this.content)
  }

  @Builder
  RichText(text: string) {
    Text() {
      if (text.length > 0) {
        ForEach(this.parseInline(text), (seg: string, idx: number) => {
          if (seg.startsWith('***') && seg.endsWith('***') && seg.length > 6) {
            Span(seg.substring(3, seg.length - 3))
              .fontWeight(FontWeight.Bold)
              .fontStyle(FontStyle.Italic)
              .fontSize(InkTypography.BODY)
              .fontColor(this.isNightMode ? '#EDE4D3' : InkPalette.INK)
          } else if (seg.startsWith('**') && seg.endsWith('**') && seg.length > 4) {
            Span(seg.substring(2, seg.length - 2))
              .fontWeight(FontWeight.Bold)
              .fontSize(InkTypography.BODY)
              .fontColor(this.isNightMode ? '#EDE4D3' : InkPalette.INK)
          } else if (seg.startsWith('~~') && seg.endsWith('~~') && seg.length > 4) {
            Span(seg.substring(2, seg.length - 2))
              .decoration({ type: TextDecorationType.LineThrough })
              .fontSize(InkTypography.BODY)
              .fontColor(this.isNightMode ? '#A89B8C' : InkPalette.INK_MIST)
          } else if (seg.startsWith('*') && seg.endsWith('*') && !seg.startsWith('**') && seg.length > 2) {
            Span(seg.substring(1, seg.length - 1))
              .fontStyle(FontStyle.Italic)
              .fontSize(InkTypography.BODY)
              .fontColor(this.isNightMode ? '#EDE4D3' : InkPalette.INK)
          } else if (seg.startsWith('`') && seg.endsWith('`') && seg.length > 2) {
            Span(seg.substring(1, seg.length - 1))
              .fontColor(this.isNightMode ? '#E0A856' : InkPalette.CINNABAR)
              .fontFamily('monospace')
              .fontSize(InkTypography.BODY_SMALL)
              .textBackgroundStyle({
                color: this.isNightMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)',
                radius: { topLeft: 4, topRight: 4, bottomLeft: 4, bottomRight: 4 }
              })
          } else if (seg.startsWith('[[') && seg.endsWith(']]')) {
            Span(seg.substring(2, seg.length - 2))
              .fontSize(InkTypography.BODY)
              .fontColor(this.isNightMode ? '#7EB8DA' : '#4A90D9')
              .decoration({ type: TextDecorationType.Underline })
          } else {
            Span(seg)
              .fontSize(InkTypography.BODY)
              .fontColor(this.isNightMode ? '#EDE4D3' : InkPalette.INK)
          }
        }, (seg: string, idx: number) => idx + '_' + seg.length)
      }
    }
    .fontSize(InkTypography.BODY)
    .fontColor(this.isNightMode ? '#EDE4D3' : InkPalette.INK)
    .lineHeight(22)
    .wordBreak(WordBreak.BREAK_ALL)
  }

  parseInline(text: string): string[] {
    const result: string[] = new Array()
    let current = ''
    let i = 0
    while (i < text.length) {
      // 链接: [text](url)
      if (text[i] === '[' && i + 1 < text.length) {
        const closeBracket = text.indexOf('](', i + 2)
        if (closeBracket > 0) {
          const endParen = text.indexOf(')', closeBracket + 2)
          if (endParen > 0) {
            if (current.length > 0) { result.push(current); current = '' }
            result.push('[[' + text.substring(i + 1, closeBracket) + ']]')
            i = endParen + 1
            continue
          }
        }
      }
      // 粗体: **text**
      if (text[i] === '*' && i + 1 < text.length && text[i + 1] === '*') {
        const end = text.indexOf('**', i + 2)
        if (end > 0) {
          if (current.length > 0) { result.push(current); current = '' }
          result.push(text.substring(i, end + 2))
          i = end + 2
          continue
        }
      }
      // 斜体: *text* (非 **)
      if (text[i] === '*' && (i + 1 < text.length && text[i + 1] !== '*')) {
        const end = text.indexOf('*', i + 1)
        if (end > 0 && end !== i + 1) {
          if (current.length > 0) { result.push(current); current = '' }
          result.push(text.substring(i, end + 1))
          i = end + 1
          continue
        }
      }
      // 行内代码: `text`
      if (text[i] === '`') {
        const end = text.indexOf('`', i + 1)
        if (end > 0) {
          if (current.length > 0) { result.push(current); current = '' }
          result.push(text.substring(i, end + 1))
          i = end + 1
          continue
        }
      }
      // 删除线: ~~text~~
      if (text[i] === '~' && i + 1 < text.length && text[i + 1] === '~') {
        const end = text.indexOf('~~', i + 2)
        if (end > 0) {
          if (current.length > 0) { result.push(current); current = '' }
          result.push(text.substring(i, end + 2))
          i = end + 2
          continue
        }
      }
      // 加粗斜体: ***text***
      if (text[i] === '*' && i + 2 < text.length && text[i + 1] === '*' && text[i + 2] === '*') {
        const end = text.indexOf('***', i + 3)
        if (end > 0) {
          if (current.length > 0) { result.push(current); current = '' }
          result.push(text.substring(i, end + 3))
          i = end + 3
          continue
        }
      }
      current += text[i]
      i++
    }
    if (current.length > 0) result.push(current)
    return result
  }

  parse(md: string): MdBlock[] {
    const blocks: MdBlock[] = new Array()
    const lines = md.split('\n')
    let i = 0
    while (i < lines.length) {
      const line = lines[i]

      if (line.trim().length === 0) { i++; continue }

      const trimmedLine = line.trimStart()

      if (trimmedLine.startsWith('```')) {
        const lang = trimmedLine.substring(3).trim()
        let code = ''
        i++
        while (i < lines.length && !lines[i].trimStart().startsWith('```')) {
          code += lines[i] + '\n'
          i++
        }
        if (i < lines.length) i++ // 跳过结束的 ```
        const block: MdBlock = { type: 'code', text: code.trim(), lang: lang }
        blocks.push(block)
        continue
      }

      const headingMatch = trimmedLine.match(/^(#{1,6})\s*(.*)/)
      if (headingMatch) {
        const level = headingMatch[1].length
        const text = headingMatch[2].trim()
        const block: MdBlock = { type: 'heading', text: text, level: level }
        blocks.push(block)
        i++
        continue
      }

      if (trimmedLine.startsWith('> ')) {
        let quote = trimmedLine.substring(2)
        i++
        while (i < lines.length && lines[i].trimStart().startsWith('> ')) {
          quote += '\n' + lines[i].trimStart().substring(2)
          i++
        }
        const block: MdBlock = { type: 'quote', text: quote }
        blocks.push(block)
        continue
      }

      if (trimmedLine === '---' || trimmedLine === '***' || trimmedLine === '___') {
        const block: MdBlock = { type: 'hr', text: '' }
        blocks.push(block)
        i++
        continue
      }

      // 表格检测: 当前行包含 | 且下一行是分隔行 |---|---|
      if (trimmedLine.includes('|') && i + 1 < lines.length && /^\|?\s*:?-+\s*:?(\s*\|\s*:?-+\s*:?)*\s*\|?$/.test(lines[i + 1].trim())) {
        const headers: string[] = this.parseTableRow(trimmedLine)
        const aligns: string[] = this.parseTableAligns(lines[i + 1])
        const rows: string[][] = new Array()
        i += 2
        while (i < lines.length && lines[i].trimStart().includes('|') && lines[i].trim().length > 0) {
          const cells: string[] = this.parseTableRow(lines[i])
          if (cells.length > 0) {
            rows.push(cells)
          }
          i++
        }
        const table: MdTable = { headers: headers, rows: rows, aligns: aligns }
        const block: MdBlock = { type: 'table', text: '', table: table }
        blocks.push(block)
        continue
      }

      if (trimmedLine.startsWith('- ') || trimmedLine.startsWith('* ') || trimmedLine.startsWith('+ ')) {
        const items: string[] = new Array()
        while (i < lines.length) {
          const l = lines[i].trimStart()
          if (l.startsWith('- ') || l.startsWith('* ') || l.startsWith('+ ')) {
            items.push(lines[i]) // 保留原始缩进，便于 RichText 虽然目前没有处理层级
            i++
          } else if (l.length === 0) {
            i++
          } else {
            break
          }
        }
        const block: MdBlock = { type: 'list', text: '', items: items }
        blocks.push(block)
        continue
      }

      if (/^\d+\.\s/.test(trimmedLine)) {
        const items: string[] = new Array()
        while (i < lines.length) {
          const l = lines[i].trimStart()
          if (/^\d+\.\s/.test(l)) {
            items.push(lines[i]) // 保留缩进
            i++
          } else if (l.length === 0) {
            i++
          } else {
            break
          }
        }
        const block: MdBlock = { type: 'olist', text: '', items: items }
        blocks.push(block)
        continue
      }

      // 段落：合并相邻非空行
      let para = line
      i++
      while (i < lines.length && lines[i].trim().length > 0) {
        const l = lines[i].trimStart()
        if (l.match(/^(#{1,6})\s*/) ||
            l.startsWith('> ') ||
            l.startsWith('```') ||
            l.startsWith('- ') || l.startsWith('* ') || l.startsWith('+ ') ||
            /^\d+\.\s/.test(l) ||
            l.includes('|') ||
            l === '---' || l === '***' || l === '___') {
          break
        }
        para += '\n' + lines[i]
        i++
      }
      const block: MdBlock = { type: 'paragraph', text: para }
      blocks.push(block)
    }
    return blocks
  }

  parseTableRow(line: string): string[] {
    let trimmed = line.trim()
    if (trimmed.startsWith('|')) trimmed = trimmed.substring(1)
    if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1)
    const cells: string[] = trimmed.split('|')
    const result: string[] = new Array()
    for (let c of cells) {
      result.push(c.trim())
    }
    return result
  }

  parseTableAligns(line: string): string[] {
    let trimmed = line.trim()
    if (trimmed.startsWith('|')) trimmed = trimmed.substring(1)
    if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1)
    const cells: string[] = trimmed.split('|')
    const result: string[] = new Array()
    for (let c of cells) {
      const t = c.trim()
      if (t.startsWith(':') && t.endsWith(':')) {
        result.push('center')
      } else if (t.endsWith(':')) {
        result.push('right')
      } else {
        result.push('left')
      }
    }
    return result
  }

  build() {
    Column({ space: InkSpacing.SM }) {
      ForEach(this.blocks, (block: MdBlock, idx: number) => {
        if (block.type === 'heading') {
          Text(block.text.replace(/\s*#+\s*$/, ''))
            .fontSize((block.level ?? 3) === 1 ? InkTypography.TITLE : ((block.level ?? 3) === 2 ? InkTypography.TITLE_SMALL : ((block.level ?? 3) === 3 ? InkTypography.BODY_LARGE : InkTypography.BODY)))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isNightMode ? '#EDE4D3' : InkPalette.INK)
            .width('100%')
            .margin({ top: (block.level ?? 3) <= 2 ? InkSpacing.MD : InkSpacing.SM, bottom: InkSpacing.XS })
        } else if (block.type === 'paragraph') {
          Column() {
            this.RichText(block.text)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: 6 })
        } else if (block.type === 'list') {
          Column({ space: 4 }) {
            ForEach(block.items, (item: string, itemIdx: number) => {
              Row({ space: 8 }) {
                Text('•')
                  .fontSize(InkTypography.BODY)
                  .fontColor(this.isNightMode ? '#A89B8C' : InkPalette.INK_LIGHT)
                Column() {
                  this.RichText(item)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }.width('100%')
            }, (item: string, idx: number) => idx + '_' + item.length)
          }.width('100%').alignItems(HorizontalAlign.Start)
        } else if (block.type === 'olist') {
          Column({ space: 4 }) {
            ForEach(block.items, (item: string, itemIdx: number) => {
              Row({ space: 8 }) {
                Text((itemIdx + 1) + '.')
                  .fontSize(InkTypography.BODY)
                  .fontColor(this.isNightMode ? '#A89B8C' : InkPalette.INK_LIGHT)
                Column() {
                  this.RichText(item)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }.width('100%')
            }, (item: string, idx: number) => idx + '_' + item.length)
          }.width('100%').alignItems(HorizontalAlign.Start)
        } else if (block.type === 'quote') {
          Column() {
            Text(block.text)
              .fontSize(InkTypography.BODY_SMALL)
              .fontColor(this.isNightMode ? '#A89B8C' : InkPalette.INK_LIGHT)
              .lineHeight(20)
              .wordBreak(WordBreak.BREAK_ALL)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ left: 12, top: 8, bottom: 8 })
          .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.03)')
          .borderRadius(InkRadius.SM)
          .borderWidth({ left: 3 })
          .borderColor({ left: this.isNightMode ? '#6B5E52' : InkPalette.CINNABAR_LIGHT })
        } else if (block.type === 'code') {
          Text(block.text)
            .fontSize(InkTypography.BODY_SMALL)
            .fontColor(this.isNightMode ? '#E0A856' : InkPalette.INDIGO)
            .fontFamily('monospace')
            .lineHeight(20)
            .wordBreak(WordBreak.BREAK_ALL)
            .width('100%')
            .padding(12)
            .backgroundColor(this.isNightMode ? 'rgba(0,0,0,0.3)' : '#F5EFE0')
            .borderRadius(InkRadius.SM)
        } else if (block.type === 'hr') {
          Divider()
            .color(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
            .margin({ top: 8, bottom: 8 })
            .width('100%')
        } else if (block.type === 'table' && block.table) {
          Column() {
            // 表头
            Row() {
              ForEach(block.table.headers, (header: string, hIdx: number) => {
                Column() {
                  this.RichText(header)
                }
                .layoutWeight(1)
                .padding({ left: 8, right: 8, top: 8, bottom: 8 })
              }, (header: string, idx: number) => 'h_' + idx + '_' + header)
            }
            .width('100%')
            .backgroundColor(this.isNightMode ? 'rgba(255,255,255,0.06)' : InkPalette.PAPER_WARM)

            // 数据行
            ForEach(block.table.rows, (row: string[], rIdx: number) => {
              Row() {
                ForEach(row, (cell: string, cIdx: number) => {
                  Column() {
                    this.RichText(cell)
                  }
                  .layoutWeight(1)
                  .padding({ left: 8, right: 8, top: 6, bottom: 6 })
                }, (cell: string, idx: number) => 'r' + rIdx + '_c' + idx + '_' + cell.length)
              }
              .width('100%')
              .backgroundColor(rIdx % 2 === 0 ? Color.Transparent : (this.isNightMode ? 'rgba(255,255,255,0.02)' : 'rgba(0,0,0,0.015)'))
            }, (row: string[], idx: number) => 'row_' + idx + '_' + row.length)
          }
          .width('100%')
          .margin({ top: 4, bottom: 8 })
          .borderWidth(0.5)
          .borderColor(this.isNightMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)')
          .borderRadius(InkRadius.SM)
          .clip(true)
        }
      }, (block: MdBlock, idx: number) => idx + '_' + block.type + '_' + block.text.length)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
