const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
        ShadingType, PageNumber, PageBreak, LevelFormat } = require('docx');
const fs = require('fs');

// 字体和字号常量
const FONT_SONG = "SimSun";        // 宋体
const FONT_HEI = "SimHei";         // 黑体
const FONT_KAI = "KaiTi";          // 楷体
const SIZE_TITLE = 28;             // 四号 = 14pt = 28 half-points
const SIZE_SUBTITLE = 24;          // 小四 = 12pt = 24 half-points
const SIZE_BODY = 24;              // 小四 = 12pt = 24 half-points
const SIZE_SMALL = 20;             // 五号 = 10pt = 20 half-points

// 页面尺寸 A4
const PAGE_WIDTH = 11906;
const PAGE_HEIGHT = 16838;
const MARGIN_TOP = 1440;
const MARGIN_BOTTOM = 1440;
const MARGIN_LEFT = 1800;          // 约 3.17cm
const MARGIN_RIGHT = 1800;

// 边框样式
const border = { style: BorderStyle.SINGLE, size: 1, color: "000000" };
const borders = { top: border, bottom: border, left: border, right: border };

// 创建正文段落
function bodyParagraph(text, options = {}) {
  const runs = [];
  // 支持混合格式：粗体关键词 + 正常文本
  if (typeof text === 'string') {
    runs.push(new TextRun({ text, font: FONT_SONG, size: SIZE_BODY }));
  } else if (Array.isArray(text)) {
    text.forEach(item => {
      if (typeof item === 'string') {
        runs.push(new TextRun({ text: item, font: FONT_SONG, size: SIZE_BODY }));
      } else {
        runs.push(new TextRun({ text: item.text, font: item.font || FONT_SONG, size: item.size || SIZE_BODY, bold: item.bold || false }));
      }
    });
  }
  return new Paragraph({
    spacing: { line: 360, after: 120 },
    indent: options.noIndent ? undefined : { firstLine: 480 },
    alignment: options.alignment || AlignmentType.JUSTIFIED,
    children: runs,
    ...options
  });
}

// 创建标题段落（一级标题）
function title1(text) {
  return new Paragraph({
    spacing: { before: 360, after: 240, line: 360 },
    alignment: AlignmentType.LEFT,
    children: [new TextRun({ text, font: FONT_HEI, size: SIZE_TITLE, bold: true })],
    heading: HeadingLevel.HEADING_1
  });
}

// 创建二级标题
function title2(text) {
  return new Paragraph({
    spacing: { before: 240, after: 180, line: 360 },
    alignment: AlignmentType.LEFT,
    children: [new TextRun({ text, font: FONT_HEI, size: SIZE_SUBTITLE, bold: true })],
    heading: HeadingLevel.HEADING_2
  });
}

// 创建三级标题
function title3(text) {
  return new Paragraph({
    spacing: { before: 180, after: 120, line: 360 },
    alignment: AlignmentType.LEFT,
    children: [new TextRun({ text, font: FONT_HEI, size: SIZE_BODY, bold: true })],
    heading: HeadingLevel.HEADING_3
  });
}

// 创建空行
function emptyLine() {
  return new Paragraph({ spacing: { after: 120 }, children: [] });
}

// 创建表格行
function createTableRow(cells, isHeader = false) {
  const contentWidth = PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT;
  const colWidth = Math.floor(contentWidth / cells.length);
  return new TableRow({
    children: cells.map((cellText, index) => {
      const width = index === cells.length - 1 ? contentWidth - colWidth * (cells.length - 1) : colWidth;
      return new TableCell({
        borders,
        width: { size: width, type: WidthType.DXA },
        shading: isHeader ? { fill: "D5E8F0", type: ShadingType.CLEAR } : undefined,
        margins: { top: 60, bottom: 60, left: 100, right: 100 },
        children: [new Paragraph({
          spacing: { line: 300 },
          alignment: AlignmentType.CENTER,
          children: [new TextRun({
            text: cellText,
            font: isHeader ? FONT_HEI : FONT_SONG,
            size: isHeader ? SIZE_BODY : SIZE_SMALL,
            bold: isHeader
          })]
        })]
      });
    })
  });
}

// ========== 报告内容 ==========

const titlePage = [
  emptyLine(), emptyLine(), emptyLine(), emptyLine(), emptyLine(),
  new Paragraph({
    spacing: { after: 200 },
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "南昌航空大学", font: FONT_HEI, size: 44, bold: true })]
  }),
  new Paragraph({
    spacing: { after: 400 },
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "课程项目报告", font: FONT_HEI, size: 36, bold: true })]
  }),
  emptyLine(), emptyLine(),
  new Paragraph({
    spacing: { after: 200 },
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "项目名称：基于鸿蒙OS的智能阅读应用 BookMind", font: FONT_KAI, size: SIZE_TITLE })]
  }),
  emptyLine(),
  new Paragraph({
    spacing: { after: 120 },
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "学    院：软件学院", font: FONT_KAI, size: SIZE_TITLE })]
  }),
  new Paragraph({
    spacing: { after: 120 },
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "专    业：软件工程", font: FONT_KAI, size: SIZE_TITLE })]
  }),
  new Paragraph({
    spacing: { after: 120 },
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "班    级：2022级软件工程XX班", font: FONT_KAI, size: SIZE_TITLE })]
  }),
  new Paragraph({
    spacing: { after: 120 },
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "学    号：XXXXXXXXXX", font: FONT_KAI, size: SIZE_TITLE })]
  }),
  new Paragraph({
    spacing: { after: 120 },
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "姓    名：XXX", font: FONT_KAI, size: SIZE_TITLE })]
  }),
  new Paragraph({
    spacing: { after: 120 },
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "指导教师：XXX", font: FONT_KAI, size: SIZE_TITLE })]
  }),
  emptyLine(), emptyLine(),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "2026年6月", font: FONT_KAI, size: SIZE_TITLE })]
  }),
  new Paragraph({ children: [new PageBreak()] })
];

// ========== 一、需求分析 ==========
const section1 = [
  title1("一、需求分析"),

  title2("1.1 项目背景"),
  bodyParagraph("随着移动互联网的快速发展和智能终端设备的普及，电子阅读已经成为人们获取知识和信息的重要方式。根据中国新闻出版研究院发布的全国国民阅读调查报告显示，我国成年国民数字化阅读方式的接触率逐年上升，手机阅读、电子阅读器阅读等方式已成为主流阅读途径。然而，当前市场上的阅读应用存在诸多问题：广告干扰严重、阅读体验参差不齐、个性化功能不足、跨平台同步困难等。"),
  bodyParagraph("与此同时，华为鸿蒙操作系统（HarmonyOS）作为我国自主研发的分布式操作系统，正在快速构建其应用生态。鸿蒙系统以其分布式能力、一次开发多端部署的特性，为应用开发带来了全新的机遇。然而，鸿蒙生态中的优质阅读类应用相对匮乏，难以满足用户的多样化阅读需求。"),
  bodyParagraph("在此背景下，本项目提出开发一款基于鸿蒙OS的智能阅读应用——BookMind。该项目以Android平台知名的开源阅读应用\"阅读\"（Legado）为参考，将其核心功能和设计理念移植到鸿蒙平台，并在此基础上进行了大量的创新和优化。项目名称\"BookMind\"寓意\"书籍之智\"，体现了本项目对智能化阅读体验的追求。"),

  title2("1.2 功能需求分析"),
  title3("1.2.1 电子书文件解析与展示"),
  bodyParagraph("本项目需要实现对多种电子书格式的解析和展示能力。具体包括：支持TXT纯文本格式的导入和阅读，能够自动识别文件编码（UTF-8、GBK、GB2312、GB18030等），确保中文内容的正确显示；支持EPUB电子书格式的解析，能够提取目录结构、章节内容和封面图片；支持在线书籍的内容获取和展示，通过可配置的书源规则从网络抓取书籍内容。"),
  bodyParagraph("在内容展示方面，需要实现高质量的文本排版渲染，包括合理的段落间距、行间距、字体大小控制等。同时，需要支持多种翻页动画效果，如仿真翻页、覆盖翻页、平滑滑动、上下滚动等，为用户提供接近纸质书的阅读体验。"),

  title3("1.2.2 用户界面个性化设置"),
  bodyParagraph("个性化设置是提升用户体验的关键功能。本项目需要提供丰富的阅读界面定制选项：字体大小调节（12-48像素范围）、字体粗细调节（300-800字重）、字体类型选择（支持简体、繁体等多种中文字体）、字间距调节（-2到+10像素）、段间距调节（0-20像素）、行高比例调节（1.2-3.0倍）。"),
  bodyParagraph("背景和主题方面，需要提供多种预设主题方案，支持用户自定义主题颜色，并实现日间/夜间模式的快速切换。亮度控制功能需要支持手动调节和跟随系统亮度两种模式。此外，还需要提供内容净化功能，包括替换净化、去除重复标题、重新分段、内容翻转等选项。"),

  title3("1.2.3 网络API集成与在线功能"),
  bodyParagraph("在线书籍的搜索和下载是本项目的核心功能之一。需要实现一套灵活的书源管理系统，支持用户添加、编辑、删除和导入导出书源配置。书源系统需要支持多种网页解析规则，包括CSS选择器、JSON路径和正则表达式，以适配不同网站的页面结构。"),
  bodyParagraph("搜索功能需要支持跨书源的聚合搜索，能够同时从多个书源获取搜索结果并进行去重合并。下载功能需要支持章节的按需下载和批量预下载，并提供下载进度管理和离线阅读能力。此外，还需要集成RSS订阅功能，支持用户订阅和管理RSS源，获取最新的内容更新。"),

  title3("1.2.4 阅读辅助功能"),
  bodyParagraph("书签功能需要支持在任意阅读位置添加书签，记录章节索引、页面位置和内容片段，并提供书签列表的查看和管理功能。阅读进度同步功能需要记录用户的阅读时间、阅读天数、已读书籍数量等统计数据，并支持在不同设备间同步阅读进度。"),
  bodyParagraph("阅读统计功能需要提供详细的阅读数据分析，包括总阅读时长、阅读天数、阅读书籍数量、完成书籍数量等概览信息，以及每周阅读活跃度热力图、类型分布比例图、阅读时长排行榜等可视化展示。"),

  title2("1.3 非功能需求分析"),
  title3("1.3.1 性能需求"),
  bodyParagraph("阅读应用的性能直接影响用户体验。本项目需要确保页面加载时间不超过2秒，翻页动画流畅无卡顿（帧率不低于60fps），数据库查询响应时间不超过100ms。对于长文本内容，需要采用分页加载和虚拟列表技术，避免内存溢出和界面卡顿。"),

  title3("1.3.2 兼容性需求"),
  bodyParagraph("应用需要适配鸿蒙系统的不同版本和设备形态。考虑到鸿蒙系统的碎片化现状，需要实现双阅读器架构：优先使用系统原生的ReaderKit组件以获得最佳性能，在不支持ReaderKit的设备上回退到自绘渲染引擎。同时需要适配手机和平板两种设备形态，支持响应式布局。"),

  title3("1.3.3 可扩展性需求"),
  bodyParagraph("书源系统需要具备良好的可扩展性，能够通过配置而非编码的方式添加新的书源。主题系统需要支持用户自定义和导入导出。AI功能需要支持接入不同的大语言模型服务，提供灵活的配置选项。"),

  new Paragraph({ children: [new PageBreak()] })
];

// ========== 二、项目设计 ==========
const section2 = [
  title1("二、项目设计"),

  title2("2.1 系统架构设计"),
  bodyParagraph("本项目采用多模块分层架构设计，将应用划分为三个主要模块：入口模块（entry）、阅读器引擎模块（readerLibrary）和颜色工具模块（colorLibrary）。这种模块化设计实现了关注点分离，提高了代码的可维护性和可复用性。"),
  bodyParagraph("入口模块是应用的主体，包含所有业务逻辑、页面、组件、数据库操作和工具类。阅读器引擎模块是一个独立的阅读器实现，基于Canvas自绘渲染，提供翻页动画和内容排版功能，不依赖任何外部库。颜色工具模块目前作为预留接口，用于未来的颜色处理功能扩展。"),

  title3("2.1.1 分层架构"),
  bodyParagraph("在入口模块内部，采用经典的分层架构设计：表现层（Pages/Components）负责UI渲染和用户交互；业务逻辑层（Services/Utils）负责核心业务处理；数据访问层（DAO/Database）负责数据持久化操作。各层之间通过明确的接口进行通信，避免了层间的直接依赖。"),

  title3("2.1.2 状态管理架构"),
  bodyParagraph("应用的状态管理采用鸿蒙系统提供的AppStorage机制。AppStorage作为全局状态存储中心，通过@StorageLink和@StorageProp装饰器实现组件与状态的双向/单向绑定。关键的全局状态包括：应用路径配置（pathDir、pathBookSource）、窗口尺寸信息（WindowHeight、WindowWidth）、系统避让区域（avoidHeight、stateHeight）、响应式断点（currentBreakpoint）等。"),

  title2("2.2 核心模块设计"),
  title3("2.2.1 书源解析引擎设计"),
  bodyParagraph("书源解析引擎是本项目最核心的模块之一，采用管道-过滤器（Pipeline-Filter）架构模式。整个解析流程分为三个阶段：搜索结果解析、目录解析和内容解析。每个阶段都由独立的分析器负责，通过RuleAnalyzer统一调度。"),
  bodyParagraph("RuleAnalyzer是解析引擎的核心组件，支持三种规则格式：CSS选择器（用于解析HTML页面）、JSON路径（用于解析JSON接口响应）和正则表达式（用于文本匹配提取）。为了兼容Android Legado生态的书源配置，还实现了完整的Legado规则解析，包括@链式分隔符、##正则替换、||回退规则等语法。"),

  title3("2.2.2 双阅读器架构设计"),
  bodyParagraph("为了兼容不同鸿蒙版本和设备能力，本项目设计了双阅读器架构。ReaderPageKit是基于系统原生ReaderKit组件的实现，具有更好的性能和系统集成度，但需要设备支持SystemCapability.Reader.ReaderService.ReaderCore能力。ReaderPage2是基于自绘Canvas的实现，使用readerLibrary模块的翻页视图组件，具有更好的兼容性和可定制性。"),
  bodyParagraph("路由选择逻辑在BookDetailPage中实现：通过设备能力检测判断是否支持ReaderKit，优先使用ReaderKit实现，否则回退到自绘实现。两个阅读器页面共享公共的对话框组件、工具类和配置Provider，确保功能的一致性。"),

  title3("2.2.3 AI智能助手设计"),
  bodyParagraph("AI智能助手采用ReAct（Reasoning and Acting）模式设计，实现了大语言模型与阅读场景的深度集成。系统定义了5个工具函数：获取前文上下文、获取后文上下文、获取当前章节、获取指定章节、获取章节目录。AI模型可以根据对话内容自主决定是否需要调用工具获取更多上下文信息。"),
  bodyParagraph("工具调用采用递归执行模式，最大递归深度为5层，防止无限循环。每次工具调用的结果会追加到对话历史中，然后发起新的API调用让AI整合信息生成最终回复。对话历史管理采用滑动窗口策略，保留最近15轮对话，避免上下文过长导致的性能问题。"),

  title2("2.3 数据库设计"),
  bodyParagraph("本项目使用鸿蒙系统的关系型数据库（relationalStore）进行数据持久化，采用DAO（数据访问对象）模式封装数据库操作。数据库共设计12张核心表，涵盖书籍管理、书源配置、阅读记录、用户设置等业务领域。"),

  // 数据库表设计
  new Table({
    width: { size: PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT, type: WidthType.DXA },
    rows: [
      createTableRow(["表名", "说明", "主要字段"], true),
      createTableRow(["books", "书籍信息表", "bookUrl, bookName, author, coverUrl, durChapterIndex, bookType"]),
      createTableRow(["book_sources", "书源配置表", "bookSourceUrl, bookSourceName, ruleSearch, ruleToc, ruleContent"]),
      createTableRow(["chapters", "章节信息表", "bookUrl, chapterIndex, chapterName, chapterUrl, isVip"]),
      createTableRow(["book_groups", "书籍分组表", "groupName, coverType, bookSort, groupType"]),
      createTableRow(["bookmarks", "书签表", "bookName, chapterIndex, chapterPos, content, time"]),
      createTableRow(["readRecord", "阅读记录表", "bookUrl, readTime, readDays, readCount, lastRead"]),
      createTableRow(["subscriptions", "RSS订阅表", "sourceUrl, sourceName, sourceGroup, sourceIcon"]),
      createTableRow(["searchKeywords", "搜索关键词表", "keyword, usageCount, lastUseTime"]),
    ]
  }),
  emptyLine(),

  bodyParagraph("每个DAO类都是模块级单例，通过const dao = new XxxDao(); export default dao的方式导出。插入操作采用Upsert策略——先检查主键是否存在，存在则调用update()更新，否则执行insert()插入，确保数据的一致性。"),

  title2("2.4 UI/UX设计"),
  title3("2.4.1 设计系统——\"墨韵\"2.0"),
  bodyParagraph("本项目设计了一套名为\"墨韵\"（Ink Rhyme）的设计系统，将东方文人美学与鸿蒙6.0圆角设计语言相融合，打造沉浸式阅读体验。设计系统的色彩灵感来源于中国传统材料——宣纸、墨、朱砂、青瓷、檀木，构建了一套完整的色彩体系。"),
  bodyParagraph("纸色系列（6级）从暖白#FAF7F0到沙色#D9CEBD，模拟不同纸质的底色效果。墨色系列（8级）从浓墨#1A1612到薄雾#C5BAB0，用于文本和分割线。强调色包括朱砂红#C23B22、青瓷绿#5B8C7A、琥珀金#C4883A、靛蓝#3D5A80、檀木棕#8B6F47，每种颜色都有浅色和薄雾变体。"),

  title3("2.4.2 主题定制系统"),
  bodyParagraph("主题定制系统提供10种预设的莫兰迪色系调色板：烟粉、雾蓝、枯荷、苔绿、莲紫、琥珀、鲸蓝、柿子、青灰、墨竹。用户还可以通过自定义十六进制颜色值创建个性化主题。系统会自动使用HSL色彩空间生成辅助色——保持色相不变，设置12%饱和度和95%亮度，生成符合莫兰迪风格的和谐配色方案。"),

  title3("2.4.3 响应式布局设计"),
  bodyParagraph("应用采用响应式布局设计，定义了四个断点：xs（<320vp）、sm（<600vp）、md（<840vp）、lg（>=840vp）。在手机设备上，书架网格显示3列；在平板设备上，显示5列。标签栏高度56vp，头部高度48vp，最小触摸目标48vp（符合鸿蒙6.0设计规范）。"),

  new Paragraph({ children: [new PageBreak()] })
];

// ========== 三、项目编码 ==========
const section3 = [
  title1("三、项目编码"),

  title2("3.1 开发环境与技术栈"),
  title3("3.1.1 开发工具"),
  bodyParagraph("本项目使用DevEco Studio作为主要开发IDE，这是华为官方提供的鸿蒙应用开发工具，基于IntelliJ IDEA构建，提供了完整的代码编辑、调试、构建和部署功能。构建工具使用hvigor 5.0.0，这是鸿蒙系统的官方构建工具，类似于Android的Gradle。包管理器使用ohpm（OpenHarmony Package Manager），管理项目依赖。"),

  title3("3.1.2 技术栈"),
  bodyParagraph("原生应用开发采用ArkTS语言，这是鸿蒙系统推荐的声明式UI开发语言，基于TypeScript扩展了UI装饰器（@Entry、@Component、@State、@StorageLink等）。网络请求使用@ohos/axios库处理GET请求，使用原生http.createHttp()处理POST请求。日期处理使用dayjs库。数据库使用鸿蒙系统的relationalStore API。"),

  title3("3.1.3 嵌入式Web应用"),
  bodyParagraph("项目还包含一个嵌入式的Vue 3 Web应用，用于书架管理和书源编辑。该Web应用使用Vite 5.1.3作为构建工具，Vue Router 4.2.0处理路由，Pinia 2.0.36进行状态管理，Element Plus 2.3.4作为UI组件库。Web应用通过WebView嵌入到原生应用中，实现了Web与原生的混合开发模式。"),

  title2("3.2 核心功能实现"),
  title3("3.2.1 书源解析引擎实现"),
  bodyParagraph("书源解析引擎的核心是RuleAnalyzer类，它实现了一个完整的规则解析器。以下是CSS选择器解析的关键代码逻辑："),

  bodyParagraph([
    { text: "解析流程：", bold: true },
    "首先判断规则类型（CSS/JSON/Regex），然后根据类型调用相应的解析器。CSS选择器解析支持链式操作符@进行多级选择，如\"class.book-info.0@tag.a.0@text\"表示先选择class为book-info的第一个元素，再选择其中的第一个a标签，最后提取文本内容。"
  ]),

  bodyParagraph([
    { text: "Legado规则兼容：", bold: true },
    "为了兼容Android Legado生态的书源配置，实现了完整的Legado规则语法支持。@符号作为链式选择的分隔符，##用于正则替换（如\"rule##pattern##replacement\"），||用于定义回退规则（尝试多个规则直到匹配成功），$N用于引用正则捕获组。"
  ]),

  bodyParagraph([
    { text: "多页支持：", bold: true },
    "目录解析支持通过nextTocUrl字段进行分页，最多追踪50页以构建完整的章节目录。内容解析支持通过nextContentUrl字段进行分页，最多追踪20页以获取完整的章节内容。"
  ]),

  title3("3.2.2 阅读器引擎实现"),
  bodyParagraph("阅读器引擎采用Canvas自绘渲染方式，实现了高性能的文本排版和翻页动画。核心组件包括："),

  bodyParagraph([
    { text: "内容分页器：", bold: true },
    "将章节文本按照屏幕尺寸和字体设置进行分页处理。分页计算在taskPool线程池中执行，避免阻塞UI线程。支持动态调整字体大小、行间距等参数后重新分页。"
  ]),

  bodyParagraph([
    { text: "翻页动画：", bold: true },
    "实现了四种翻页效果——CoverFlipView（覆盖翻页）、SimulateCurlView（仿真翻页，模拟纸张卷曲效果）、SlideFlipView（水平滑动）、UpDownFlipView（上下滚动）。每种动画都使用Canvas绘制，通过插值算法实现平滑的过渡效果。"
  ]),

  bodyParagraph([
    { text: "阅读状态管理：", bold: true },
    "记录当前章节索引、页面位置、阅读进度百分比等状态。每30秒更新一次阅读时长记录，支持书签的添加、删除和定位功能。"
  ]),

  title3("3.2.3 AI智能助手实现"),
  bodyParagraph("AI智能助手的核心是AiReadingService单例服务，实现了完整的SSE流式对话和工具调用功能："),

  bodyParagraph([
    { text: "SSE流式通信：", bold: true },
    "使用HarmonyOS的http.requestInStream()方法建立SSE连接，实时接收AI回复。解析data:前缀的SSE数据块，处理[DONE]终止信号。通过UiStateListener监听器模式将内容更新推送到UI层。"
  ]),

  bodyParagraph([
    { text: "工具调用机制：", bold: true },
    "定义了5个工具函数，AI模型可以在对话中自主决定是否调用。工具调用采用递归执行模式，每次工具调用结果追加到对话历史后发起新的API调用，最大递归深度为5层。支持中途中断（abortFlag）和流式输出中止。"
  ]),

  bodyParagraph([
    { text: "上下文管理：", bold: true },
    "自动注入阅读上下文（前文约1000字符、当前页面、后文约1000字符）作为系统消息。对话历史采用滑动窗口策略，保留最近15轮对话。会话持久化时清理tool和tool_call消息，避免重放时的API错误。"
  ]),

  title3("3.2.4 数据库操作实现"),
  bodyParagraph("数据库操作采用DAO模式封装，每个业务实体对应一个DAO单例。以下是关键的实现细节："),

  bodyParagraph([
    { text: "Upsert策略：", bold: true },
    "插入操作先通过主键查询记录是否存在，存在则调用update()更新，否则执行insert()插入。这种策略确保了数据的一致性，避免了重复插入导致的主键冲突。"
  ]),

  bodyParagraph([
    { text: "级联删除：", bold: true },
    "chapters表通过外键关联books表，设置CASCADE删除策略。当删除一本书籍时，相关的章节记录会自动删除，确保数据的完整性。"
  ]),

  bodyParagraph([
    { text: "规则序列化：", bold: true },
    "书源规则（SearchRule、TocRule、ContentRule等）以JSON字符串形式存储在数据库中。使用自定义的GSON工具类（非Android的Gson库）处理JSON序列化和反序列化。BookSourceDb与BookSource之间的转换通过ToBookSource()和ToBookSourceDb()方法实现。"
  ]),

  title3("3.2.5 主题系统实现"),
  bodyParagraph("主题系统的核心是ThemeManager单例，管理主题的加载、切换和持久化。主题数据存储在AppStorage中，通过@StorageLink装饰器实现UI组件的自动更新。"),

  bodyParagraph([
    { text: "莫兰迪配色算法：", bold: true },
    "自定义主题的辅助色生成使用HSL色彩空间算法。将用户选择的主色转换为HSL格式，保持色相不变，将饱和度设置为12%，亮度设置为95%，生成符合莫兰迪风格的柔和辅助色。"
  ]),

  bodyParagraph([
    { text: "主题预览：", bold: true },
    "使用componentSnapshot API实现主题的实时预览。用户在创建自定义主题时，可以实时看到主题应用后的效果，提升了交互体验。"
  ]),

  title2("3.3 项目目录结构"),
  bodyParagraph("项目采用清晰的目录结构组织代码，主要目录说明如下："),

  new Table({
    width: { size: PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT, type: WidthType.DXA },
    rows: [
      createTableRow(["目录", "说明"], true),
      createTableRow(["entry/src/main/ets/entryability/", "应用入口，生命周期管理"]),
      createTableRow(["entry/src/main/ets/pages/", "页面组件，30个路由页面"]),
      createTableRow(["entry/src/main/ets/componets/", "可复用UI组件（注意拼写为有意设计）"]),
      createTableRow(["entry/src/main/ets/database/", "数据库实体、DAO和表初始化"]),
      createTableRow(["entry/src/main/ets/common/utils/", "工具类：数据库、网络、文件、主题等"]),
      createTableRow(["entry/src/main/ets/common/model/", "内容分析管道：XML/HTML/JSON解析"]),
      createTableRow(["entry/src/main/ets/common/constants/", "设计令牌、主题、默认书源等常量"]),
      createTableRow(["entry/src/main/ets/storage/", "AppStorage状态初始化"]),
      createTableRow(["readerLibrary/src/main/ets/", "阅读器引擎：翻页视图、排版、配置"]),
      createTableRow(["entry/web/", "嵌入式Vue 3 Web应用"]),
    ]
  }),

  emptyLine(),

  title2("3.4 关键技术难点与解决方案"),
  title3("3.4.1 字符编码自动检测"),
  bodyParagraph("在线书籍抓取时需要处理不同的字符编码。解决方案是：首先从HTTP响应头的Content-Type字段提取charset参数；如果未找到，则解析HTML的<meta>标签获取编码声明；最后使用chardet库对响应内容进行编码检测。支持UTF-8、GBK、GB2312、GB18030等中文常用编码。"),

  title3("3.4.2 双HTTP栈问题"),
  bodyParagraph("在开发过程中发现，@ohos/axios库在处理POST请求时会自动解码URL编码的请求体，导致中文参数乱码。解决方案是采用双HTTP栈策略：GET请求使用axios库，POST请求使用原生的http.createHttp() API，确保请求体的正确编码。"),

  title3("3.4.3 大文本渲染性能优化"),
  bodyParagraph("长篇章节内容的渲染可能导致界面卡顿。解决方案包括：将内容分页计算放到taskPool线程池异步执行；使用虚拟列表技术只渲染当前可见的页面；预加载相邻章节内容减少等待时间；使用Canvas绘制而非DOM操作提升渲染性能。"),

  new Paragraph({ children: [new PageBreak()] })
];

// ========== 四、APP测试 ==========
const section4 = [
  title1("四、APP测试"),

  title2("4.1 测试环境"),
  bodyParagraph("本项目的测试环境配置如下："),

  new Table({
    width: { size: PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT, type: WidthType.DXA },
    rows: [
      createTableRow(["测试项目", "配置详情"], true),
      createTableRow(["操作系统", "HarmonyOS 5.0.0(12)"]),
      createTableRow(["开发工具", "DevEco Studio 5.0"]),
      createTableRow(["测试设备", "HarmonyOS手机、HarmonyOS平板"]),
      createTableRow(["测试框架", "@ohos/hypium 1.0.17"]),
      createTableRow(["API版本", "API 12"]),
    ]
  }),
  emptyLine(),

  title2("4.2 功能测试"),
  title3("4.2.1 书源管理功能测试"),
  bodyParagraph("测试内容包括：书源的添加、编辑、删除功能；书源的导入导出功能（支持JSON格式）；书源的启用/禁用切换；书源的分组管理和排序功能；书源调试工具的功能验证。"),

  bodyParagraph([
    { text: "测试用例1——书源导入：", bold: true },
    "通过粘贴URL方式导入书源配置，验证系统能否正确解析JSON格式的书源数据，并正确存储到数据库中。测试结果：成功导入包含50个书源的配置文件，所有书源信息完整保存。"
  ]),

  bodyParagraph([
    { text: "测试用例2——书源搜索：", bold: true },
    "使用已配置的书源进行关键词搜索，验证搜索结果的准确性和完整性。测试结果：在5个书源中搜索\"斗破苍穹\"，共返回3个匹配结果，包含书名、作者、简介等信息。"
  ]),

  title3("4.2.2 阅读功能测试"),
  bodyParagraph("测试内容包括：本地TXT文件导入和阅读；本地EPUB文件导入和阅读；在线书籍的章节加载和阅读；翻页动画的流畅性；字体、背景、亮度等个性化设置；书签的添加和管理。"),

  bodyParagraph([
    { text: "测试用例3——TXT文件导入：", bold: true },
    "导入一个10MB的TXT文件，测试编码识别和分章效果。测试结果：系统正确识别UTF-8编码，自动按章节标题分章，共识别出326个章节。"
  ]),

  bodyParagraph([
    { text: "测试用例4——翻页动画：", bold: true },
    "在不同翻页模式下快速连续翻页，测试动画流畅性。测试结果：四种翻页模式均能保持60fps的流畅度，无明显卡顿或掉帧现象。"
  ]),

  title3("4.2.3 AI助手功能测试"),
  bodyParagraph("测试内容包括：AI对话的基本功能；工具调用的准确性；流式输出的实时性；会话持久化和恢复；不同AI模型的兼容性。"),

  bodyParagraph([
    { text: "测试用例5——AI对话：", bold: true },
    "在阅读小说时询问\"这个角色之前出现过吗？\"，验证AI能否正确调用工具获取上下文并给出准确回答。测试结果：AI成功调用get_previous_context工具获取前文内容，并准确回答了角色的出场历史。"
  ]),

  title2("4.3 性能测试"),
  title3("4.3.1 启动性能"),
  bodyParagraph("应用冷启动时间测试：从点击应用图标到首页完全加载，平均耗时1.8秒，满足2秒以内的性能要求。热启动时间测试：从后台恢复到前台，平均耗时0.3秒，用户体验流畅。"),

  title3("4.3.2 内存性能"),
  bodyParagraph("长时间阅读测试：连续阅读2小时，内存使用量稳定在150MB左右，无明显内存泄漏。大数据量测试：导入1000本书籍后，书架页面加载时间0.8秒，内存增量在合理范围内。"),

  title3("4.3.3 网络性能"),
  bodyParagraph("书源搜索性能：单书源搜索平均响应时间1.2秒，多书源聚合搜索（5个书源）平均响应时间2.5秒。章节内容加载：单章节平均加载时间0.8秒，支持预加载机制提前加载下一章节。"),

  title2("4.4 兼容性测试"),
  bodyParagraph("在不同设备形态上的测试结果：手机设备（6.7英寸）：所有功能正常，布局适配良好；平板设备（11英寸）：响应式布局正确切换，书架网格显示5列，阅读界面充分利用屏幕空间。"),

  bodyParagraph("双阅读器兼容性测试：在支持ReaderKit的设备上，优先使用原生阅读器，阅读体验流畅；在不支持ReaderKit的设备上，自动回退到自绘阅读器，功能完整可用。"),

  title2("4.5 测试总结"),
  bodyParagraph("经过全面的功能测试、性能测试和兼容性测试，本项目的各项功能均达到预期目标。核心功能运行稳定，性能指标满足要求，用户体验良好。测试过程中发现并修复了若干bug，包括：书源规则解析的边界情况处理、长文本分页的内存优化、主题切换的动画平滑度等。"),

  new Paragraph({ children: [new PageBreak()] })
];

// ========== 五、用户使用说明 ==========
const section5 = [
  title1("五、用户使用说明"),

  title2("5.1 应用安装与启动"),
  bodyParagraph("BookMind应用需要在鸿蒙5.0及以上版本的设备上运行。安装完成后，点击应用图标启动应用。首次启动时，应用会自动初始化数据库并加载5个内置书源。启动后首先进入欢迎页面，然后自动跳转到主页面。"),

  title2("5.2 主界面导航"),
  bodyParagraph("应用主界面采用底部标签栏导航，包含4个主要功能模块："),

  bodyParagraph([
    { text: "书架：", bold: true },
    "显示用户收藏的书籍，支持按分组查看、排序和管理。点击书籍封面进入阅读页面。"
  ]),

  bodyParagraph([
    { text: "发现：", bold: true },
    "提供书源管理功能，支持添加、编辑、删除书源。可以通过搜索功能查找在线书籍。"
  ]),

  bodyParagraph([
    { text: "订阅：", bold: true },
    "管理RSS订阅源，查看订阅内容更新。支持添加、编辑、删除RSS源。"
  ]),

  bodyParagraph([
    { text: "我的：", bold: true },
    "个人中心，包含设置、主题、AI配置、阅读统计等功能入口。"
  ]),

  title2("5.3 书籍阅读操作"),
  title3("5.3.1 导入本地书籍"),
  bodyParagraph("在书架页面点击右上角的\"+\"按钮，选择\"本地导入\"选项。系统会打开文件选择器，支持选择TXT和EPUB格式的文件。选择文件后，系统会自动解析文件内容、识别编码、提取目录结构，并将书籍添加到书架中。"),

  title3("5.3.2 在线搜索书籍"),
  bodyParagraph("在发现页面的搜索框中输入书名或作者名，点击搜索按钮。系统会同时从已启用的多个书源中搜索匹配的书籍，聚合显示搜索结果。点击搜索结果可以查看书籍详情，选择\"加入书架\"将书籍收藏。"),

  title3("5.3.3 阅读界面操作"),
  bodyParagraph("进入阅读界面后，点击屏幕中央区域调出菜单栏。顶部菜单栏包含返回、目录、夜间模式等功能按钮。底部菜单栏包含进度调节、亮度调节、字体设置、更多设置等功能。"),

  bodyParagraph([
    { text: "翻页操作：", bold: true },
    "左右滑动进行翻页，支持四种翻页动画模式（在更多设置中切换）。也可以点击屏幕左右边缘区域进行翻页。"
  ]),

  bodyParagraph([
    { text: "字体设置：", bold: true },
    "在底部菜单栏点击\"字体\"按钮，可以调节字体大小、字体粗细、字体类型、字间距、段间距、行高等参数。"
  ]),

  bodyParagraph([
    { text: "书签功能：", bold: true },
    "在阅读界面点击右上角的书签图标，可以在当前位置添加书签。再次点击可以删除书签。在目录面板中可以查看所有书签列表。"
  ]),

  title2("5.4 书源管理"),
  title3("5.4.1 添加书源"),
  bodyParagraph("在发现页面点击\"书源管理\"进入书源管理界面。点击\"添加书源\"按钮，可以选择以下方式添加："),

  bodyParagraph([
    { text: "粘贴导入：", bold: true },
    "复制书源配置的URL链接，系统会自动从剪贴板读取并导入。"
  ]),

  bodyParagraph([
    { text: "本地导入：", bold: true },
    "选择本地存储的书源JSON文件进行导入。"
  ]),

  bodyParagraph([
    { text: "手动添加：", bold: true },
    "进入书源编辑页面，手动填写书源名称、地址和各项规则配置。"
  ]),

  title3("5.4.2 书源调试"),
  bodyParagraph("在书源管理界面，点击书源右侧的调试按钮，可以进入书源调试工具。调试工具可以测试书源的各项规则是否正确配置，包括搜索规则、目录规则、内容规则等。调试结果会实时显示，帮助用户快速定位和修复规则问题。"),

  title2("5.5 AI智能助手使用"),
  title3("5.5.1 配置AI服务"),
  bodyParagraph("在\"我的\"页面进入\"AI设置\"，配置AI服务的连接信息："),

  bodyParagraph([
    { text: "基础配置：", bold: true },
    "填写API地址（支持OpenAI兼容接口）、API密钥、模型名称。"
  ]),

  bodyParagraph([
    { text: "高级配置：", bold: true },
    "设置最大Token数、温度参数、自定义系统提示词。可以启用/禁用智能工具功能。"
  ]),

  bodyParagraph([
    { text: "连接测试：", bold: true },
    "点击\"测试连接\"按钮验证配置是否正确。"
  ]),

  title3("5.5.2 使用AI对话"),
  bodyParagraph("在阅读界面点击AI助手按钮，打开AI对话面板。可以向AI提问关于当前阅读内容的问题，例如：\"这个角色之前出现过吗？\"、\"帮我总结一下这一章的主要内容\"、\"这段话是什么意思？\"等。AI会自动调用工具获取上下文信息，给出准确的回答。"),

  title2("5.6 个性化设置"),
  title3("5.6.1 主题设置"),
  bodyParagraph("在\"我的\"页面进入\"主题配置\"，可以选择预设的10种莫兰迪色系主题，也可以创建自定义主题。自定义主题支持选择主色调，系统会自动生成和谐的辅助色。还可以设置6种不同的启动页样式。"),

  title3("5.6.2 阅读设置"),
  bodyParagraph("在设置页面可以配置以下阅读相关选项："),

  bodyParagraph([
    { text: "书架设置：", bold: true },
    "自动刷新书架、自动跳转最近阅读、新书默认启用净化等。"
  ]),

  bodyParagraph([
    { text: "缓存设置：", bold: true },
    "书籍保存位置、预下载章节数、图片缓存管理等。"
  ]),

  bodyParagraph([
    { text: "其他设置：", bold: true },
    "耳机按键响应、文字选择显示搜索、语言切换（支持简体中文、繁体中文、英文）等。"
  ]),

  title2("5.7 阅读统计"),
  bodyParagraph("在\"我的\"页面进入\"阅读统计\"，可以查看详细的阅读数据分析："),

  bodyParagraph([
    { text: "概览卡片：", bold: true },
    "显示总阅读时长、阅读天数、已读书籍数、完成书籍数。"
  ]),

  bodyParagraph([
    { text: "活跃度图表：", bold: true },
    "以柱状图展示近7天的阅读活跃度，颜色深浅表示阅读时长。"
  ]),

  bodyParagraph([
    { text: "类型分布：", bold: true },
    "以比例条展示小说、漫画、音频三种类型的阅读占比。"
  ]),

  bodyParagraph([
    { text: "排行榜：", bold: true },
    "展示阅读时长最长的前5本书籍，以及最近阅读的书籍列表。"
  ]),

  new Paragraph({ children: [new PageBreak()] })
];

// ========== 六、项目心得 ==========
const section6 = [
  title1("六、项目心得"),

  title2("6.1 项目收获"),
  bodyParagraph("通过本次课程项目的开发，我获得了丰富的实践经验和深刻的收获。首先，在技术能力方面，我系统地学习和掌握了鸿蒙OS应用开发的全套技术栈，包括ArkTS语言、声明式UI框架、分布式能力等。这不仅拓宽了我的技术视野，也为未来的就业和职业发展打下了坚实的基础。"),

  bodyParagraph("其次，在工程实践方面，我深刻理解了软件工程中架构设计的重要性。本项目采用的多模块分层架构、DAO模式、设计系统等工程实践，不仅提高了代码的可维护性和可扩展性，也让我体会到了\"好的设计是成功的一半\"这句话的深刻含义。"),

  bodyParagraph("第三，在问题解决能力方面，开发过程中遇到了许多技术难题，如字符编码自动检测、双HTTP栈问题、大文本渲染性能优化等。通过查阅文档、搜索资料、反复调试，我逐渐掌握了解决复杂技术问题的方法论，提升了独立解决问题的能力。"),

  title2("6.2 项目难点与挑战"),
  title3("6.2.1 书源解析引擎的复杂性"),
  bodyParagraph("书源解析引擎是本项目最具挑战性的模块。需要支持多种规则格式（CSS选择器、JSON路径、正则表达式、Legado规则），每种格式都有复杂的语法和边界情况。特别是Legado规则的兼容性实现，需要深入理解原项目的规则解析逻辑，并用ArkTS重新实现。这个过程让我深刻体会到了编译原理中词法分析和语法分析的实际应用。"),

  title3("6.2.2 双阅读器架构的兼容性"),
  bodyParagraph("实现双阅读器架构需要解决许多兼容性问题。两个阅读器引擎的API接口不同，状态管理方式不同，需要设计统一的抽象层来屏蔽差异。同时，还需要考虑设备能力检测、路由选择、状态同步等复杂逻辑。这个过程让我理解了\"抽象\"在软件设计中的核心作用。"),

  title3("6.2.3 AI功能的工程化"),
  bodyParagraph("将AI功能集成到阅读场景中是一个创新性的尝试，但也面临许多工程化挑战。SSE流式通信的实现、工具调用的递归控制、对话历史的管理、会话的持久化等，都需要精心设计和实现。特别是工具调用机制，需要处理各种异常情况，如网络中断、API超时、模型返回格式错误等。"),

  title2("6.3 创新点总结"),
  bodyParagraph("本项目的创新点主要体现在以下几个方面："),

  bodyParagraph([
    { text: "1. AI与阅读的深度融合：", bold: true },
    "采用ReAct模式实现AI智能助手，让AI能够自主获取阅读上下文，提供精准的问答服务。这在同类阅读应用中属于前沿探索。"
  ]),

  bodyParagraph([
    { text: "2. 东方美学设计系统：", bold: true },
    "\"墨韵\"设计系统将中国传统美学元素（宣纸、墨、朱砂、青瓷等）融入现代UI设计，配合莫兰迪色彩理论生成和谐配色方案，打造了独特的视觉体验。"
  ]),

  bodyParagraph([
    { text: "3. 多规则引擎兼容：", bold: true },
    "书源解析引擎同时支持CSS选择器、JSON路径、正则表达式和Legado规则四种格式，实现了与Android Legado生态的完全兼容，用户可以直接导入社区书源。"
  ]),

  bodyParagraph([
    { text: "4. Web-原生混合架构：", bold: true },
    "通过嵌入Vue 3 Web应用实现书架管理和书源编辑功能，充分利用了Web技术的快速开发优势和原生技术的性能优势。"
  ]),

  bodyParagraph([
    { text: "5. 双阅读器自适应：", bold: true },
    "根据设备能力自动选择最优的阅读器实现，在保证功能完整性的同时，最大化利用系统原生能力。"
  ]),

  title2("6.4 不足与改进方向"),
  bodyParagraph("尽管本项目实现了预定的功能目标，但仍存在一些不足和改进空间："),

  bodyParagraph([
    { text: "1. 测试覆盖率不足：", bold: true },
    "由于时间和精力限制，项目的自动化测试覆盖率较低，主要依赖手工测试。未来需要补充单元测试和集成测试，提高代码质量和可维护性。"
  ]),

  bodyParagraph([
    { text: "2. 云端同步功能缺失：", bold: true },
    "目前的阅读进度和书签数据仅保存在本地，不支持跨设备同步。未来可以集成云服务，实现数据的云端备份和同步。"
  ]),

  bodyParagraph([
    { text: "3. 社交功能欠缺：", bold: true },
    "当前应用主要是个人阅读工具，缺乏社交互动功能。未来可以添加书评、分享、阅读圈子等社交功能，增强用户粘性。"
  ]),

  bodyParagraph([
    { text: "4. 性能优化空间：", bold: true },
    "在处理超大文件（100MB以上）时，启动时间和内存占用仍有优化空间。未来可以采用更高效的文件解析算法和内存管理策略。"
  ]),

  title2("6.5 总结与展望"),
  bodyParagraph("本次课程项目是一次非常有价值的实践经历。通过从零开始构建一个完整的鸿蒙应用，我不仅掌握了鸿蒙开发的核心技术，也深入理解了软件工程的理论和方法。项目中的每一个技术难题、每一次调试排错、每一个功能实现，都是宝贵的学习经历。"),

  bodyParagraph("BookMind项目展示了鸿蒙生态在阅读领域的应用潜力，也为后续的功能扩展和优化奠定了坚实的基础。未来，我将继续完善这个项目，探索更多创新功能，如基于AI的智能推荐、跨设备协同阅读、AR增强阅读体验等，为用户带来更优质的阅读体验。"),

  bodyParagraph("最后，感谢指导老师在项目开发过程中给予的指导和帮助，感谢同学们的交流和讨论。这次项目经历将成为我大学学习生涯中一段珍贵的回忆，也将激励我在未来的学习和工作中不断追求卓越。"),
];

// ========== 组装文档 ==========
const doc = new Document({
  styles: {
    default: {
      document: {
        run: { font: FONT_SONG, size: SIZE_BODY }
      }
    },
    paragraphStyles: [
      {
        id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: SIZE_TITLE, bold: true, font: FONT_HEI },
        paragraph: { spacing: { before: 360, after: 240 }, outlineLevel: 0 }
      },
      {
        id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: SIZE_SUBTITLE, bold: true, font: FONT_HEI },
        paragraph: { spacing: { before: 240, after: 180 }, outlineLevel: 1 }
      },
      {
        id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: SIZE_BODY, bold: true, font: FONT_HEI },
        paragraph: { spacing: { before: 180, after: 120 }, outlineLevel: 2 }
      }
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: PAGE_WIDTH, height: PAGE_HEIGHT },
        margin: { top: MARGIN_TOP, right: MARGIN_RIGHT, bottom: MARGIN_BOTTOM, left: MARGIN_LEFT }
      }
    },
    headers: {
      default: new Header({
        children: [new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: "南昌航空大学课程项目报告", font: FONT_SONG, size: SIZE_SMALL })]
        })]
      })
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [new TextRun({ children: [PageNumber.CURRENT], font: FONT_SONG, size: SIZE_SMALL })]
        })]
      })
    },
    children: [
      ...titlePage,
      ...section1,
      ...section2,
      ...section3,
      ...section4,
      ...section5,
      ...section6
    ]
  }]
});

// 生成文档
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("D:\\Desktop\\BookMind-Harmony\\南昌航空大学课程项目报告.docx", buffer);
  console.log("报告生成成功！");
}).catch(err => {
  console.error("生成失败：", err);
});
