# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BookMind is a HarmonyOS 6.0 e-book reader application (bundle: `com.legado.app`) built with ArkTS. It supports book source management, RSS subscriptions, local book import (EPUB/TXT), and a customizable reading experience with multiple page-turn animations.

## Build & Development

This is a **DevEco Studio** project. Building and running is done through the IDE, not CLI.

- **Build tool**: hvigor (config in `hvigorfile.ts` at root and module levels)
- **Target SDK**: HarmonyOS 6.0.2 (API 22)
- **Device targets**: phone, tablet
- **Package manager**: ohpm (dependencies in `oh-package.json5`)
- **Run tests**: `ohpm run test` or through DevEco Studio's test runner (Hypium framework)

## Architecture

### Multi-Module Structure

```
entry/                  # Main HAP module (app entry point)
commons/colorLibrary/   # Color utility library module
readerLibrary/          # Reader engine module (exported via Index.ets)
```

Module dependencies are declared in each module's `oh-package.json5` using `file:` references. The `entry` module depends on both `colorLibrary` and `readerLibrary`.

### Entry Module Layout (`entry/src/main/ets/`)

| Directory | Purpose |
|-----------|---------|
| `entryability/` | `EntryAbility` - app lifecycle, DB init, window setup |
| `pages/` | Route pages registered in `main_pages.json` |
| `pages/view/` | Feature views: BookShelf, Find, Reader, Subscription, MyCenter |
| `componets/` | Reusable UI components (note: intentional spelling) |
| `database/` | RDB entities, DAOs, and `DataBase.initAllTable()` |
| `storage/` | AppStorage data initialization (`appData.ets`, `bookListData.ets`, `findData.ets`) |
| `preferences/` | Persistent user preferences |
| `common/constants/` | Design tokens, themes, public constants |
| `common/utils/` | Utilities: DB, network, file handling, EPUB parsing, theme management |

### Key Architectural Patterns

- **Navigation**: Router-based via `main_pages.json` profile. Pages use `router.pushUrl()` for navigation.
- **State management**: `AppStorage` with `@StorageLink` / `@StorageProp` decorators for cross-component state. `@State` for local component state.
- **Database**: HarmonyOS `relationalStore` (RDB) with a DAO pattern. `DbUtil` (singleton) wraps all SQL operations. Tables initialized in `entry/src/main/ets/database/index.ets` via `DataBase.initAllTable()`.
- **Theme system**: "墨韵" (Ink Rhyme) design system with `InkPalette`, `InkTypography`, `InkSpacing`, `InkRadius`, `InkShadow`, `InkMotion`, `InkLayout` token classes in `DesignTokens.ets`. Morandi-inspired color themes in `Theme.ets` managed by `ThemeManager`.
- **Reader module**: `readerLibrary` exports `MainPage`, `CoverFlipView`, and `ReaderProvider`. Supports cover flip, slide, and up-down page-turn styles. Content pagination runs on `taskPool` for performance.

### Multi-Reader Architecture (重要)

项目中存在**三套并行的阅读器页面实现**，用于兼容不同鸿蒙版本和功能需求。**对阅读界面的任何 UI/功能修改都必须同步应用到以下所有三个文件：**

| 文件 | 说明 |
|------|------|
| `entry/src/main/ets/pages/view/Reader/ReaderPage.ets` | 初版阅读器 |
| `entry/src/main/ets/pages/view/Reader/ReaderPage2.ets` | 自绘渲染引擎版（使用 `readerLibrary` 的 Canvas 翻页） |
| `entry/src/main/ets/pages/view/Reader/ReaderPageKit.ets` | 原生 ReaderKit 版（使用 `@kit.ReaderKit` 系统能力） |

路由选择逻辑在 `BookDetailPage.ets` 中：优先使用 `ReaderPageKit`（若设备支持 `SystemCapability.Reader.ReaderService.ReaderCore`），否则回退到 `ReaderPage2`。

三个文件共享以下公共模块，修改这些模块时无需重复：
- `readerLibrary/` 下的排版引擎、翻页视图、配置 Provider
- `entry/.../componets/Reader/` 下的对话框组件（LayoutMoreDialog、BackgroundColorDialog、FlipModeDialog 等）
- `entry/.../common/` 下的工具类和常量

### Database Tables

Books, BookSources, BookGroups, BookHistory, WorksLists, Subscription, RssSources, RssSourcesHistory, RssSourceGroup. All DAOs are in `entry/src/main/ets/database/dao/`.

### Global State Keys (AppStorage)

Key values set in `EntryAbility.onWindowStageCreate`: `pathDir`, `pathBookSource`, `bottomRectHeight`, `topRectHeight`, `WindowHeight`, `WindowWidth`, `avoidHeight`, `stateHeight`, `currentBreakpoint`.

Breakpoints: xs (<320vp), sm (<600vp), md (<840vp), lg (>=840vp).

## Key Conventions

- **Language**: ArkTS (TypeScript-like, HarmonyOS-specific). Uses HarmonyOS UI framework decorators (`@Entry`, `@Component`, `@State`, `@StorageLink`, `@Builder`, `@BuilderParam`).
- **UI building**: Declarative `build()` method pattern with chained attribute methods (e.g., `.width()`, `.fontSize()`, `.backgroundColor()`).
- **Dependencies**: `@ohos/axios` for HTTP, `dayjs` for date handling. HarmonyOS kits accessed via `@kit.*` imports.
- **File naming**: PascalCase for components/pages (e.g., `BookShelf.ets`), camelCase for utilities (e.g., `DbUtil.ets`).
- **Chinese comments and UI strings**: The codebase uses Chinese for comments, UI labels, and log messages.
