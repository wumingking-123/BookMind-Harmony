# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BookMind is a HarmonyOS 6.0 e-book reader application (bundle: `com.legado.app`) built with ArkTS. It is a HarmonyOS port of the popular Android "Legado" (阅读) book reader — many data models, rule formats, and architectural decisions mirror the original. It supports book source management, RSS subscriptions, local book import (EPUB/TXT), and a customizable reading experience with multiple page-turn animations.

## Build & Development

This is a **DevEco Studio** project. Building and running is done through the IDE, not CLI.

- **Build tool**: hvigor (config in `hvigorfile.ts` at root and module levels)
- **Target SDK**: HarmonyOS 5.0.0(12) / API 12
- **Device targets**: phone, tablet
- **Package manager**: ohpm (dependencies in `oh-package.json5`)
- **Run tests**: `ohpm run test` or through DevEco Studio's test runner (Hypium framework)
- **Note**: Tests are currently scaffold only — no meaningful test coverage exists.

### Embedded Web App (`entry/web/`)

A Vue 3 SPA embedded in the app via WebView for bookshelf management and book source editing. Built with Vite, Element Plus, Pinia, and Vue Router. Has its own build system:

- `cd entry/web && pnpm dev` — dev server
- `pnpm build` — production build + sync to native assets
- `pnpm lint:fix` — ESLint fix

Multi-page setup: bookshelf and source editor are separate Vite entry points.

## Architecture

### Multi-Module Structure

```
entry/                  # Main HAP module (app entry point)
commons/colorLibrary/   # Color utility library module (currently a stub)
readerLibrary/          # Reader engine module (exported via Index.ets)
```

Module dependencies are declared in each module's `oh-package.json5` using `file:` references. The `entry` module depends on both `colorLibrary` and `readerLibrary`. The `readerLibrary` is self-contained with zero external dependencies.

### Entry Module Layout (`entry/src/main/ets/`)

| Directory | Purpose |
|-----------|---------|
| `entryability/` | `EntryAbility` - app lifecycle, DB init, window setup |
| `pages/` | Route pages registered in `main_pages.json` (30 routes) |
| `pages/view/` | Feature views: BookShelf, Find, Reader, Subscription, MyCenter |
| `componets/` | Reusable UI components (note: intentional spelling, not "components") |
| `database/` | RDB entities, DAOs, and `DataBase.initAllTable()` |
| `storage/` | AppStorage data initialization (`appData.ets`, `bookListData.ets`, `findData.ets`) |
| `preferences/` | Persistent user preferences |
| `common/constants/` | Design tokens, themes, public constants |
| `common/utils/` | Utilities: DB, network, file handling, EPUB parsing, theme management |
| `common/model/` | Content analysis pipeline (XML/HTML/JSON parsing with rule engine) |

### Key Architectural Patterns

- **Navigation**: Router-based via `main_pages.json` profile. Pages use `router.pushUrl()` for navigation. Initial page is `welcomePage`.
- **State management**: `AppStorage` with `@StorageLink` / `@StorageProp` decorators for cross-component state. `@State` for local component state.
- **Database**: HarmonyOS `relationalStore` (RDB) with a DAO pattern. `DbUtil` (singleton) wraps all SQL operations. Tables initialized in `entry/src/main/ets/database/index.ets` via `DataBase.initAllTable()`.
- **DAO pattern**: Each DAO is a module-level singleton (`const dao = new XxxDao(); export default dao`). Insert methods perform upsert — they check for existence by primary key and silently call `update()` if found.
- **Rule serialization**: Book source rules (SearchRule, TocRule, ContentRule, etc.) are stored as JSON strings in the database. A custom `GSON` utility (not the real Gson) handles `toJson()`/`toString()` serialization. `BookSourceDb` ↔ `BookSource` conversion via `ToBookSource()` / `ToBookSourceDb()`.
- **Theme system**: "墨韵" (Ink Rhyme) design system with `InkPalette`, `InkTypography`, `InkSpacing`, `InkRadius`, `InkShadow`, `InkMotion`, `InkLayout` token classes in `DesignTokens.ets`. Morandi-inspired color themes in `Theme.ets` managed by `ThemeManager`.
- **Reader module**: `readerLibrary` exports `MainPage`, `CoverFlipView`, and `ReaderProvider`. Supports cover flip, slide, and up-down page-turn styles. Content pagination runs on `taskPool` for performance.

### Multi-Reader Architecture (重要)

项目中存在**两套并行的阅读器页面实现**，用于兼容不同鸿蒙版本和功能需求。**对阅读界面的任何 UI/功能修改都必须同步应用到以下两个文件：**

| 文件 | 说明 |
|------|------|
| `entry/src/main/ets/pages/view/Reader/ReaderPage2.ets` | 自绘渲染引擎版（使用 `readerLibrary` 的 Canvas 翻页） |
| `entry/src/main/ets/pages/view/Reader/ReaderPageKit.ets` | 原生 ReaderKit 版（使用 `@kit.ReaderKit` 系统能力） |

路由选择逻辑在 `BookDetailPage.ets` 中：优先使用 `ReaderPageKit`（若设备支持 `SystemCapability.Reader.ReaderService.ReaderCore`），否则回退到 `ReaderPage2`。

两个文件共享以下公共模块，修改这些模块时无需重复：
- `readerLibrary/` 下的排版引擎、翻页视图、配置 Provider
- `entry/.../componets/Reader/` 下的对话框组件（LayoutMoreDialog、BackgroundColorDialog、FlipModeDialog 等）
- `entry/.../common/` 下的工具类和常量

### Book Source / Content Analysis Pipeline

This is the core feature — a multi-stage scraping pipeline for extracting book data from arbitrary websites:

1. **URL Construction** (`ParseURLUtils.ets`): Takes a source's `searchUrl` template, substitutes `{{key}}` / `{{page}}` placeholders, handles GET/POST and GBK encoding via `GbkEncoder`.
2. **HTTP Request** (`requestUtils.ets`): Fetches raw HTML/XML. Uses `@ohos/axios` for GET, native `http.createHttp()` for POST (axios decodes URL-encoded bodies). Auto-detects charset (UTF-8/GBK/GB2312/GB18030) from Content-Type and HTML `<meta>` tags.
3. **Rule Parsing** (`RuleAnalyzer.ets`): Central parser supporting three rule types — **CSS selectors**, **JSON paths** (`$.data.list`), and **Regex**. Delegates to `HtmlParser`, `CssSelectorParser`, `JsonPathParser`.
4. **Search Results** (`XmlAnalysis.ets`): Extracts `SearchBook[]` from HTML using `SearchRule` fields.
5. **TOC Parsing** (`TocAnalysis.ets`): Extracts `BookChapter[]` using `TocRule`. Supports pagination via `nextTocUrl` (max 50 pages).
6. **Content Extraction** (`ContentAnalysis.ets`): Extracts chapter text using `ContentRule`. Supports multi-page content (max 20 pages) via `nextContentUrl`. Applies regex replacement rules.

### Book Source Rule Format

Two rule syntaxes are supported (both in `RuleAnalyzer.ets`):

**Legado format** (primary, from the Android Legado ecosystem):
- `@` as chain separator: `class.cnt.0@class.tit.0@tag.a.0@text`
- `||` for fallback rules: `rule1||rule2`
- `##pattern##replacement` for regex replacement
- JS evaluation via `@js:` prefix

**Standard format**:
- `@@` or `&&` for chained selectors
- `@text` / `@href` / `@src` for attribute extraction
- `[n]` for element indexing

Rule entities are in `entry/src/main/ets/database/entities/rule/`: `SearchRule`, `TocRule`, `ContentRule`, `ExploreRule`, `BookInfoRule`, `ReviewRule`.

### App Initialization Sequence (`EntryAbility.ets`)

1. `onCreate()`: Initialize WebView engine
2. `onWindowStageCreate()`:
   - Init SQLite via `DbUtil.initDB()` → `DataBase.initAllTable()` (12 tables)
   - Auto-load default book sources (5 built-in sources in `DefaultBookSources.ets`): insert missing, update if rules differ
   - Store file paths and display metrics in `AppStorage`
   - Set full-screen layout, calculate system avoid areas
   - Load `welcomePage`, init `themeManager`

### Database Tables

12 tables total, initialized in `database/index.ets`: `book_sources`, `rssSourcesHistory`, `subscriptions`, `books`, `book_groups`, `worksLists`, `bookHistory`, `rssSourceGroups`, `bookmarks`, `chapters`, `searchKeywords`, `readRecord`. All DAOs are in `entry/src/main/ets/database/dao/`.

### Global State Keys (AppStorage)

Key values set in `EntryAbility.onWindowStageCreate`: `pathDir`, `pathBookSource`, `bottomRectHeight`, `topRectHeight`, `WindowHeight`, `WindowWidth`, `avoidHeight`, `stateHeight`, `currentBreakpoint`.

Breakpoints: xs (<320vp), sm (<600vp), md (<840vp), lg (>=840vp).

## Key Conventions

- **Language**: ArkTS (TypeScript-like, HarmonyOS-specific). Uses HarmonyOS UI framework decorators (`@Entry`, `@Component`, `@State`, `@StorageLink`, `@Builder`, `@BuilderParam`).
- **UI building**: Declarative `build()` method pattern with chained attribute methods (e.g., `.width()`, `.fontSize()`, `.backgroundColor()`).
- **Dependencies**: `@ohos/axios` for HTTP, `dayjs` for date handling. HarmonyOS kits accessed via `@kit.*` imports.
- **File naming**: PascalCase for components/pages (e.g., `BookShelf.ets`), camelCase for utilities (e.g., `DbUtil.ets`).
- **Chinese comments and UI strings**: The codebase uses Chinese for comments, UI labels, and log messages.

## Gotchas

- **Dual HTTP stack**: `requestUtils` uses axios for GET but native `http.createHttp()` for POST — a workaround because axios decodes URL-encoded POST bodies.
- **No tests**: All test files are auto-generated scaffolding with trivial assertions. There is no meaningful test coverage.
- **SQL injection risk**: Some DAO methods (`BooksDao.search()`, `BookSourceDao.flowSearch()`) use string interpolation for LIKE queries — vulnerable if search keys contain quotes.
- **Two reader pages**: `ReaderPageKit` (preferred, native ReaderKit) and `ReaderPage2` (fallback, self-drawn engine) are the two active reader routes; selection happens in `BookDetailPage.ets` based on device capability.
- **Color library is a stub**: `commons/colorLibrary/` exports only a test function. It is not yet implemented.
- **`componets/` typo**: The directory name is intentional — do not rename it.
