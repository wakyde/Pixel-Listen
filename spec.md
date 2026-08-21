# Bug 扫描报告 · Round 2

> 2026-08-16 · 第三轮全量扫描  
> 重点：深色模式适配 + 历史播放功能  
> 范围：3 个插件 + shell，共 30+ 个文件

---

## 场景一：深色模式 - 全局颜色硬编码（系统性缺陷）

### 1.1 PlatformColors 硬编码浅色值，深色模式下文字不可见 🔴 P0

- **严重度**: P0
- **影响范围**: 30+ 文件，158 处使用
- **根因**: `PlatformColors.surface`、`onSurface`、`onSurfaceVariant`、`background`、`outline` 均为 `static const` 浅色模式值，深色模式下不自动切换
  - `onSurface` = `#1E293B`（深色）→ 深色背景下**完全不可见**
  - `onSurfaceVariant` = `#64748B`（中灰）→ 深色背景下**难以辨认**
  - `surface` = `#FFFFFF`（白色）→ 深色背景下卡片呈白色，不协调
  - `background` = `#F8FAFC`（近白）→ 深色背景下页面背景错误
  - `outline` = `#E2E8F0`（浅灰）→ 深色背景下边框不可见
- **受影响文件**:
  - english_listening/screens: 12 文件 65 处
  - english_listening/widgets: 4 文件 29 处
  - flashcards: 3 文件 23 处
  - english_songs: 5 文件 41 处
- **修复方案**: 创建 `ThemeColors.of(context)` 上下文感知颜色类，统一替换
- **状态**: ✅ 已修复 — 创建 `ThemeColors` 类，158 处全部替换为 `ThemeColors.of(context).xxx`，4 个插件 + shell 均通过 `dart analyze`

### 1.2 设置页深色模式开关与外壳主题不同步

- **严重度**: P1
- **状态**: ✅ 已修复 — shell 的 `ThemeModeNotifier` 新增 `refreshFromPrefs()` 方法，home_screen 在 `addPostFrameCallback` 中调用同步
- **文件**: [settings_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/screens/settings_screen.dart#L88-L91) vs [theme_provider.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/shell/lib/providers/theme_provider.dart)
- **根因**: 设置页写 `platform_theme_mode` 到 SharedPreferences，但 shell 的 `themeModeProvider` 只在初始化时读取，运行时不会收到变更通知
- **表现**: 在设置页切换深色模式后，返回首页主题不变，需重启 App

### 1.3 导入页分类标签硬编码白色文字

- **严重度**: P1
- **状态**: ✅ 已修复 — 全局替换为 `ThemeColors.of(context).onSurface`
- **文件**: [category_bar.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/screens/import/category_bar.dart#L61-L75)

### 1.4 播放器字幕面板多处硬编码

- **严重度**: P1
- **状态**: ✅ 已修复 — 全局替换为 `ThemeColors.of(context)`
- **文件**: [subtitle_panel.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/widgets/player/subtitle_panel.dart) (10 处)

### 1.5 播放器控制栏按钮不可见

- **严重度**: P1
- **状态**: ✅ 已修复 — 全局替换为 `ThemeColors.of(context)`
- **文件**: [control_bar.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/widgets/player/control_bar.dart) (13 处)

### 1.6 收藏页卡片和文字不可见

- **严重度**: P1
- **状态**: ✅ 已修复 — 全局替换为 `ThemeColors.of(context)`
- **文件**: [favorites_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/screens/favorites_screen.dart) (13 处)

### 1.7 打字练习页文字不可见

- **严重度**: P2
- **状态**: ✅ 已修复 — 全局替换为 `ThemeColors.of(context)`
- **文件**: [typing_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/screens/typing_screen.dart) (6 处)

### 1.8 播放器弹窗（词汇/搭配面板）深色模式不可见

- **严重度**: P2
- **状态**: ✅ 已修复 — 全局替换为 `ThemeColors.of(context)`
- **文件**: [player_dialogs.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/screens/player/player_dialogs.dart) (13 处)

### 1.9 分类管理对话框深色模式不可见

- **严重度**: P2
- **状态**: ✅ 已修复 — 全局替换为 `ThemeColors.of(context)`
- **文件**: [category_manage_dialog.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/screens/category_manage_dialog.dart) (7 处)

### 1.10 媒体记录列表深色模式不可见

- **严重度**: P2
- **状态**: ✅ 已修复 — 全局替换为 `ThemeColors.of(context)`
- **文件**: [media_records_list.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/screens/import/media_records_list.dart) (4 处)

### 1.11 播放器布局深色模式不可见

- **严重度**: P2
- **状态**: ✅ 已修复 — 全局替换为 `ThemeColors.of(context)`
- **文件**: [player_layout.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/screens/player/player_layout.dart) (13 处)

### 1.12 设置页自身深色模式不可见

- **严重度**: P2
- **状态**: ✅ 已修复 — 全局替换为 `ThemeColors.of(context)`
- **文件**: [settings_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/screens/settings_screen.dart#L222) (1 处)

### 1.13 闪卡插件深色模式不可见

- **严重度**: P2
- **状态**: ✅ 已修复 — 全局替换为 `ThemeColors.of(context)`
- **文件**: [flashcard_list_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/flashcards/lib/screens/flashcard_list_screen.dart) (8 处), [review_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/flashcards/lib/screens/review_screen.dart) (10 处), [anki_import_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/flashcards/lib/screens/anki_import_screen.dart) (5 处)

### 1.14 英文歌曲插件深色模式不可见

- **严重度**: P2
- **状态**: ✅ 已修复 — 全局替换为 `ThemeColors.of(context)`
- **文件**: [song_list_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_songs/lib/screens/song_list_screen.dart) (6 处), [search_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_songs/lib/screens/search_screen.dart) (8 处), [player_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_songs/lib/screens/player_screen.dart) (19 处), [import_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_songs/lib/screens/import_screen.dart) (5 处), [favorites_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_songs/lib/screens/favorites_screen.dart) (3 处)

---

## 场景二：播放历史 - 点不进去

### 2.1 `_playFromHistory` 未传递 `subtitlePath` 🔴 P1

- **严重度**: P1
- **状态**: ✅ 已修复 — 增加 `subtitlePath` 传递，`subtitleExtension` 从 `subtitlePath` 扩展名推导
- **文件**: [import_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/screens/import_screen.dart#L107-L119)

### 2.2 历史条目缺少 `subtitleExtension` 参数

- **严重度**: P2
- **状态**: ✅ 已修复 — 从 `subtitlePath` 扩展名推导，无 `subtitlePath` 时默认 `.srt`
- **文件**: [import_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/screens/import_screen.dart#L107-L119)

### 2.3 历史条目保存时缺少 `subtitleExtension`

- **严重度**: P3
- **状态**: ⚠️ 暂缓 — `ListeningHistoryEntry` 模型无 `subtitleExtension` 字段，需 DB migration，影响较小暂缓
- **文件**: [listening_history_store.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/providers/listening_history_store.dart#L81-L102)

### 2.4 历史条目指向的文件可能已删除，无错误提示

- **严重度**: P3
- **状态**: ⚠️ 暂缓 — 播放器已有错误处理，不会崩溃，但无友好提示，影响较小暂缓

---

## 场景三：设置页

### 3.1 设置页深色模式开关只写 SharedPreferences，不通知 shell 刷新

- **严重度**: P1
- **状态**: ✅ 已修复 — shell 的 `ThemeModeNotifier` 新增 `refreshFromPrefs()` 方法，`home_screen` 在 `addPostFrameCallback` 中调用同步
- **文件**: [settings_screen.dart](file:///Users/wakyde/Downloads/EnglishListenTool/platform/plugins/english_listening/lib/screens/settings_screen.dart#L88-L91)

---

## 汇总

| 严重度 | 数量 | 已修复 | 暂缓 | 类别 |
|--------|------|--------|------|------|
| P0 | 1 | 1 | 0 | 全局深色模式颜色硬编码（系统性） |
| P1 | 6 | 6 | 0 | 历史播放、设置同步、核心页面不可见 |
| P2 | 10 | 10 | 0 | 次要页面深色模式不可见 |
| P3 | 2 | 0 | 2 | 字幕扩展名、文件删除提示 |

**总计 19 个 bug，已修复 17 个，暂缓 2 个（P3 低优先）。**

### 修复完成清单

| 修复项 | 文件数 | 变更行数 |
|--------|--------|---------|
| 创建 `ThemeColors.of(context)` 类 | 1 | +25 |
| 全局替换 158 处硬编码颜色 | 30+ | 158 |
| 修复 `_playFromHistory` 传参 | 1 | +8 |
| 修复 shell 主题同步 | 2 | +13 |
| 修复 `const` 冲突 | 8 | 适配 |
| 修复 `_buildSeekBar` 等无 context 方法 | 3 | 6 方法签名 |