# 英语学习项目优化 · 开发执行计划

> **版本**: v1.0 | **日期**: 2026-08-15
> **基于**: spec.md v1.0 | **原则**: 先修 Bug，再做优化，分阶段交付

---

## 0. Bug 审查报告

在制定优化计划前，先对当前代码库进行全面审查，发现以下 Bug：

### 0.1 Bug 清单

| # | 严重程度 | 分类 | 文件 | 问题描述 |
|---|---------|------|------|---------|
| **B1** | 🔴 Critical | 静默吞异常 | `ai_service.dart` 5处 | 所有 AI API 调用（翻译/搭配检测/转录/缓存检查/字幕缓存）`catch (_) { return null; }`，用户看不到任何错误提示 |
| **B2** | 🔴 Critical | 静默吞异常 | `favorites_api_service.dart` 3处 | 收藏的增删查全部 `catch (_) { return []; }`，包括 403 错误 |
| **B3** | 🔴 Critical | 静默吞异常 | `typing_screen.dart:134` | 视频初始化失败 `catch (_) {}`，用户打开打字练习页可能看到空白 |
| **B4** | 🔴 Critical | 静默吞异常 | `import_screen.dart:362` | 在线下载后的字幕内容获取失败 `catch (_) {}`，导致下载成功但字幕丢失 |
| **B5** | 🟠 High | 静默吞异常 | `media_scanner.dart:168` | 文件夹扫描失败 `catch (_) {}`，剧集列表不显示但无提示 |
| **B6** | 🟠 High | 静默吞异常 | `listening_history_store.dart:59` | 播放历史保存失败静默，用户下次打开找不到历史 |
| **B7** | 🟠 High | 静默吞异常 | `ab_loop_history.dart:56` | AB 循环历史保存失败静默 |
| **B8** | 🟠 High | 静默吞异常 | `favorites_store.dart:63,96` | 本地收藏保存失败静默 |
| **B9** | 🟠 High | 认证错误 | `favorites_api_service.dart` | `/api/favorites` 返回 403 Forbidden（mock 模式下缺少有效 token），但被静默吞掉 |
| **B10** | 🟠 High | 数据丢失 | `import_screen.dart` | blob URL 在页面刷新后失效，历史记录中的 blob 链接无法播放 |
| **B11** | 🟡 Medium | 资源泄漏 | `player_screen.dart` | `_historySaveTimer` 在 dispose 时可能未取消 |
| **B12** | 🟡 Medium | 资源泄漏 | `player_screen.dart` | `_videoController` 监听器在某些异常路径下未移除 |
| **B13** | 🟡 Medium | 空安全 | `import_screen.dart` | `_videoInfo?['title']` 可空但未处理 null 情况 |
| **B14** | 🟡 Medium | 空安全 | 多处 | `ref.read(mediaCategoryProvider).valueOrNull` 在异步未完成时可能为 null |
| **B15** | 🟢 Low | 代码规范 | 多处 | `use_build_context_synchronously` 警告 |
| **B16** | 🟢 Low | 性能 | `player_screen.dart` | `_saveHistory` 每 10 秒调用一次，即使用户未播放也写入数据库 |
| **B17** | 🟢 Low | 数据一致性 | `database.dart` | `Collocations` 表在开发文档中规划但未实现，搭配数据仅存本地 JSON |

### 0.2 静默吞异常统计

```
总 catch 块: 32 个
├── 静默吞异常（无日志、无用户提示）: 19 个 (59%)
├── 有错误处理但无日志: 6 个 (19%)
└── 有完整错误处理: 7 个 (22%)
```

这是一个系统性风险：59% 的错误被静默吞掉，用户无法感知问题，调试也无法定位。

---

## 1. 执行总览

```
Phase 0: Bug 修复（紧急）    → 1.5h  → 消除所有静默吞异常 + 403 错误
Phase 1: 代码拆分            → 3.0h  → ImportScreen / PlayerScreen 拆分
Phase 2: 状态管理优化        → 2.0h  → 消除不必要重建
Phase 3: 性能优化            → 2.0h  → 懒加载 + 缓存 + 索引
Phase 4: 错误处理 + 规范     → 1.5h  → 统一错误边界 + 消除魔法值
Phase 5: 测试 + 验收         → 2.0h  → 补齐测试 + 全流程验证
─────────────────────────────────────
总计: 12.0h
```

---

## 2. Phase 0: Bug 修复（最高优先级）

> **目标**: 消除所有静默吞异常，让错误可感知、可调试
> **原则**: 不改变任何功能逻辑，仅增强错误处理

### 2.1 任务清单

| 任务 | 文件 | 改动 | 验收 |
|------|------|------|------|
| **T0.1** | `ai_service.dart` | 5 个 `catch (_)` 改为 `catch (e, st)` → `debugPrint` 日志 + 返回 null（保持现有行为，增加日志） | AI 调用失败时控制台有日志，不影响 UI |
| **T0.2** | `favorites_api_service.dart` | 3 个 `catch (_)` 改为 `catch (e, st)` → `debugPrint` 日志 + 返回原默认值 | 收藏 API 失败时控制台有日志 |
| **T0.3** | `typing_screen.dart` | `catch (_) {}` 改为 `catch (e, st) { debugPrint(...); if (mounted) setState(() => _initError = e.toString()); }` | 视频初始化失败时 UI 显示错误提示 |
| **T0.4** | `import_screen.dart:362` | `catch (_) {}` 改为 `catch (e, st) { debugPrint(...); }` | 字幕下载失败时有日志 |
| **T0.5** | `media_scanner.dart:168` | `catch (_) {}` 改为 `catch (e, st) { debugPrint(...); }` | 扫描失败时有日志 |
| **T0.6** | `listening_history_store.dart` | `catch (_)` 改为 `catch (e, st) { debugPrint(...); }` | 历史保存失败有日志 |
| **T0.7** | `ab_loop_history.dart` | `catch (_)` 改为 `catch (e, st) { debugPrint(...); }` | AB 循环历史保存失败有日志 |
| **T0.8** | `favorites_store.dart` | 2 个 `catch (_)` 改为 `catch (e, st) { debugPrint(...); }` | 本地收藏保存失败有日志 |
| **T0.9** | `favorites_api_service.dart` | 检查 `AuthService.dio` 拦截器，确保 mock 模式不发送 403 请求；或前端 `fetchFavorites` 在 mock 模式下降级为本地存储 | 403 错误不再出现 |
| **T0.10** | `player_screen.dart` | 确保 `dispose()` 中取消 `_historySaveTimer`，移除所有 VideoPlayerController 监听器 | 退出播放器无 Timer 泄漏 |
| **T0.11** | `player_screen.dart` | `_saveHistory` 增加 `_isPlaying` 判断，仅在播放中写入 | 暂停/未播放时不再写入数据库 |

### 2.2 验收标准

```gherkin
Scenario: Bug 修复后所有错误可感知
  Given 人为触发一个错误场景（如断开后端）
  When 执行对应操作
  Then 控制台有 debugPrint 日志输出
  And 用户看到友好的错误提示（如有 UI 交互）
  And 功能降级运行（不崩溃）

Scenario: 403 错误不再出现
  Given Mock 模式下运行 App
  When 打开收藏页面
  Then 不出现 403 错误
  And 收藏列表正常显示本地数据
```

### 2.3 产出

- `dart analyze` 0 error 0 warning
- 所有 `catch (_)` 替换为 `catch (e, st)` 并附带 `debugPrint`
- `_historySaveTimer` 和 `_videoController` 资源正确释放

---

## 3. Phase 1: 代码拆分

> **目标**: 单文件 ≤ 300 行，职责单一
> **原则**: 拆分过程中不修改任何业务逻辑，纯搬迁

### 3.1 ImportScreen 拆分（目标：1845 行 → 6 个文件，每个 ≤ 300 行）

| 任务 | 新文件 | 搬迁内容 | 预估行数 |
|------|--------|---------|---------|
| **T1.1** | `lib/screens/import/category_bar.dart` | `_buildCategoryBar` + 分类状态管理 | ~100 |
| **T1.2** | `lib/screens/import/category_manage_dialog.dart` | `_showCategoryManageDialog` + 分类 CRUD 对话框 | ~150 |
| **T1.3** | `lib/screens/import/local_import_tab.dart` | 本地文件选择 + 剧集扫描 + `_pickMedia` + `_buildEpisodeSelector` | ~250 |
| **T1.4** | `lib/screens/import/online_import_tab.dart` | 在线 URL 粘贴 + 下载 + `_startDownload` + `_onDownloadComplete` | ~250 |
| **T1.5** | `lib/screens/import/media_records_list.dart` | `_buildCategoryRecords` + 记录列表 + 播放操作 | ~150 |
| **T1.6** | `lib/screens/import_screen.dart` | 瘦身：仅保留 Scaffold 组装 + 路由 + 公共状态 | ~250 |

**拆分策略**:

```
原 import_screen.dart 的 StatefulWidget 拆分为：
  - CategoryBar: ConsumerWidget（独立 watch mediaCategoryProvider）
  - CategoryManageDialog: 独立函数/Widget，接收回调
  - LocalImportTab: ConsumerWidget，通过回调通知父组件
  - OnlineImportTab: ConsumerWidget，通过回调通知父组件
  - MediaRecordsList: ConsumerWidget，独立 watch mediaRecordsProvider
  - ImportScreen: ConsumerStatefulWidget（仅保留组装 + 全局状态）
```

**关键重构点**:

```
原 _onDownloadComplete 在 ImportScreen 中：
  → 移到 OnlineImportTab 中
  → 通过 VoidCallback? onRecordSaved 通知父组件刷新

原 _playFromRecord / _playFromHistory 在 ImportScreen 中：
  → 移到 MediaRecordsList 中
  → 通过 context.push 直接导航（无需父组件中转）
```

### 3.2 PlayerScreen 拆分（目标：1682 行 → 6 个文件，每个 ≤ 300 行）

| 任务 | 新文件 | 搬迁内容 | 预估行数 |
|------|--------|---------|---------|
| **T1.7** | `lib/screens/player/player_initializer.dart` | `_initVideo` + `_initAudio` + 播放器控制器创建 | ~200 |
| **T1.8** | `lib/screens/player/player_layout.dart` | `_buildWideLayout` + `_buildNarrowLayout` + 响应式布局 | ~150 |
| **T1.9** | `lib/screens/player/player_app_bar.dart` | AppBar + 菜单 + 收藏/闪卡徽章 | ~100 |
| **T1.10** | `lib/screens/player/player_keyboard.dart` | `_handleKeyEvent` + FocusNode + 快捷键映射 | ~100 |
| **T1.11** | `lib/screens/player/subtitle_loader.dart` | `_loadSubtitle` + `_detectCefr` + `_detectCollocations` + `_loadAISubtitles` | ~200 |
| **T1.12** | `lib/screens/player_screen.dart` | 瘦身：保留布局组装 + 状态管理 + 操作分发 | ~300 |

### 3.3 Provider 拆分

| 任务 | 文件 | 改动 |
|------|------|------|
| **T1.13** | 新建 `lib/providers/media_category_provider.dart` | 从 `media_record_provider.dart` 拆出：`MediaCategory` 模型 + `mediaCategoryProvider` + 种子数据 + 分类 CRUD |
| **T1.14** | 修改 `lib/providers/media_record_provider.dart` | 瘦身：仅保留 `MediaRecord` 模型 + `mediaRecordsProvider` + 记录 CRUD |

### 3.4 验收标准

```gherkin
Scenario: 拆分后功能完全不变
  Given 拆分前所有功能正常
  When 拆分完成
  Then dart analyze 0 error 0 warning
  And 每个文件 ≤ 300 行
  And 导入本地视频 → 播放 → 字幕着色 → 收藏 → 闪卡 全流程正常
  And 导入在线视频（示例）→ 播放 → 打字练习 全流程正常
  And 分类管理（添加/删除）→ 记录保存/删除 正常
  And AB 循环 → AI 翻译 → 搭配检测 正常
  And 热重载正常
```

---

## 4. Phase 2: 状态管理优化

> **目标**: 消除不必要的 Widget 重建
> **原则**: 使用 Flutter DevTools 的 "Highlight Rebuilds" 验证

### 4.1 任务清单

| 任务 | 改动 | 验收方式 |
|------|------|---------|
| **T2.1** | 新增 `selectedCategoryProvider = StateProvider<String?>` 在 `media_category_provider.dart` 中 | 分类切换不再触发 ImportScreen 全量重建 |
| **T2.2** | `ImportScreen` 改为 `ConsumerWidget`，不再 `setState` 管理分类选中状态 | DevTools 验证：切换标签时仅 CategoryBar + 内容区重建 |
| **T2.3** | `CategoryBar` 独立 `watch(mediaCategoryProvider)` 和 `watch(selectedCategoryProvider)` | DevTools 验证：分类标签栏独立更新 |
| **T2.4** | `MediaRecordsList` 独立 `watch(mediaRecordsProvider(selectedCategoryId))` | DevTools 验证：记录列表独立更新 |
| **T2.5** | `PlayerScreen` 中 `_isVideoInitialized` / `_subtitleSource` 等 setState 变量下沉到对应子组件内部 | DevTools 验证：PlayerScreen 的 setState 调用次数减少 50%+ |
| **T2.6** | `PlayerAppBar` 独立 `watch` 收藏/闪卡数量，不再从父组件传参 | DevTools 验证：收藏操作时仅 AppBar 重建 |

### 4.2 验收标准

```gherkin
Scenario: 状态管理优化后重建范围最小化
  Given 使用 Flutter DevTools 的 "Highlight Rebuilds"
  When 执行以下操作：
    - 切换分类标签
    - 添加收藏
    - 点击播放/暂停
  Then 每次操作后仅相关 Widget 重建
  And 页面整体不重建
```

---

## 5. Phase 3: 性能优化

> **目标**: 启动速度 + 200ms，列表滚动 60fps，查询加速
> **原则**: 数据库仅新增索引，不修改表结构

### 5.1 任务清单

| 任务 | 文件 | 改动 | 验收 |
|------|------|------|------|
| **T3.1** | `cefr_detector.dart` | 词典加载改为懒加载（首次使用时加载，非 App 启动时） | 启动时间减少 ≥ 200ms |
| **T3.2** | 新建 `lib/services/subtitle_cache.dart` | 字幕解析结果 LRU 缓存（最多 10 个文件，1 小时过期） | 重复打开同一字幕 ≤ 50ms |
| **T3.3** | `database.dart` | Schema v3 迁移：新增 6 个索引（favorites.user_id, flashcards.user_id/next_review, flashcard_reviews.flashcard_id, listening_history.user_id, media_records.user_id+category_id） | 查询速度提升 5-10x |
| **T3.4** | `player_screen.dart` / `subtitle_panel.dart` | 长字幕列表（1000+ 条）使用 `ScrollablePositionedList` 替代 `ListView` + 手动计算偏移 | 滚动 60fps 无卡顿 |
| **T3.5** | `collocation_detector.dart` | 搭配检测结果缓存（同一字幕文本不重复检测） | 切换字幕时搭配检测不重复计算 |

### 5.2 数据库迁移（Schema v2 → v3）

```dart
// 在 database.dart 的 migration.onUpgrade 中新增：
if (from < 3) {
  await m.createIndex('idx_favorites_user_id', on: favorites, columns: [favorites.userId]);
  await m.createIndex('idx_flashcards_user_id', on: flashcards, columns: [flashcards.userId]);
  await m.createIndex('idx_flashcards_next_review', on: flashcards, columns: [flashcards.userId, flashcards.nextReviewAt]);
  await m.createIndex('idx_fr_flashcard_id', on: flashcardReviews, columns: [flashcardReviews.flashcardId]);
  await m.createIndex('idx_lh_user_id', on: listeningHistory, columns: [listeningHistory.userId]);
  await m.createIndex('idx_mr_user_category', on: mediaRecords, columns: [mediaRecords.userId, mediaRecords.categoryId]);
}
// schemaVersion: 2 → 3
```

**注意**: 仅新增索引，不修改任何表字段，属于安全变更。

### 5.3 验收标准

```gherkin
Scenario: 性能优化可量化验证
  Given 优化前后同一设备
  When 测量以下指标
  Then App 冷启动时间减少 ≥ 200ms
  And 重复打开同一字幕文件加载时间 ≤ 50ms
  And 1000 条字幕列表滚动 60fps 无卡顿
  And 数据库查询使用索引（EXPLAIN QUERY PLAN 验证）
```

---

## 6. Phase 4: 错误处理 + 代码规范

> **目标**: 统一错误体验，消除魔法值，规范命名

### 6.1 任务清单

| 任务 | 文件 | 改动 | 验收 |
|------|------|------|------|
| **T4.1** | 新建 `lib/widgets/error_boundary.dart` | 统一错误边界组件，捕获子组件异常并显示「加载失败」+ 重试按钮 | 子组件异常不导致整页崩溃 |
| **T4.2** | 新建 `lib/utils/async_guard.dart` | 统一异步异常处理函数，自动记录日志 + 可选用户提示 | 所有异步操作使用统一模式 |
| **T4.3** | `import_screen.dart` 等 | 关键区域包裹 `ErrorBoundary`（字幕面板、视频区域、收藏列表） | 异常时显示降级 UI |
| **T4.4** | 全局 | 消除魔法数字/字符串：`'本地视频'` → 常量、`900` → `PlatformBreakpoints.wide`、`Color(0xFF...)` → 命名常量 | 搜索魔法值无残留 |
| **T4.5** | 全局 | 命名规范化：`_cues` → `_subtitleCues`、`_db` → `_database`、`cat` → `category` | 代码审查通过 |
| **T4.6** | 全局 | `dart fix --apply` 自动修复所有 lint 警告 | `dart analyze` 0 info |

### 6.2 验收标准

```gherkin
Scenario: 错误边界生效
  Given 人为抛出一个异常（如字幕面板渲染异常）
  When 异常触发
  Then 错误边界捕获异常
  And 显示「加载失败」+ 重试按钮
  And 页面其他区域正常渲染

Scenario: 代码规范达标
  When 执行 dart analyze
  Then 0 error, 0 warning, 0 info
```

---

## 7. Phase 5: 测试 + 最终验收

> **目标**: 核心模块测试覆盖 ≥ 80%，全流程功能验证

### 7.1 单元测试清单

| 任务 | 被测模块 | 测试用例 | 预估 |
|------|---------|---------|------|
| **T5.1** | `CefrDetector` | 词典加载、词形还原、复合词匹配、空输入、未命中回退 | 5 个 |
| **T5.2** | `CollocationDetector` | 本地词典匹配、AI 搭配回退、重叠搭配处理、空输入 | 4 个 |
| **T5.3** | `SubtitleParser` | SRT/VTT/ASS 解析、双语合并、编码检测、空文件 | 5 个 |
| **T5.4** | `SubtitleParseCache` | 缓存命中、缓存过期、LRU 淘汰、文件哈希变更 | 4 个 |
| **T5.5** | `MediaRecordNotifier` | 保存/更新/删除记录、按分类查询 | 4 个 |
| **T5.6** | `MediaCategoryNotifier` | 种子数据创建、添加/删除分类 | 3 个 |
| **T5.7** | `SM2Algorithm` | 评分 0-3 的 interval 计算、easeFactor 边界 | 4 个 |

### 7.2 Widget 测试清单

| 任务 | 被测页面 | 测试用例 | 预估 |
|------|---------|---------|------|
| **T5.8** | `CategoryBar` | 分类渲染、选中状态切换、管理按钮 | 3 个 |
| **T5.9** | `MediaRecordsList` | 空记录显示、记录列表渲染、点击播放 | 3 个 |
| **T5.10** | `SubtitlePanel` | 字幕列表渲染、高亮当前句、滚动同步 | 3 个 |
| **T5.11** | `ErrorBoundary` | 正常渲染、异常捕获、重试按钮 | 3 个 |

### 7.3 全流程验收

```bash
# 每个 Phase 结束后执行
cd platform/plugins/english_listening && dart analyze
cd platform/plugins/english_listening && dart test
cd platform/plugins/english_listening && flutter test
```

**手动验收清单**:

```
Phase 0 验收:
☐ 断开后端，打开收藏页面 → 不报 403，显示本地收藏
☐ 断开后端，AI 翻译/搭配检测 → 降级提示，不崩溃
☐ 打开打字练习页 → 视频正常初始化
☐ 退出播放器后检查内存 → 无 Timer 泄漏

Phase 1 验收:
☐ 导入本地视频 → 播放 → 字幕着色 → 收藏 → 闪卡
☐ 导入在线视频（示例）→ 播放 → 打字练习
☐ 分类管理 → 添加/删除分类 → 记录保存/删除
☐ AB 循环 → AI 翻译 → 搭配检测
☐ 热重载正常

Phase 2 验收:
☐ Flutter DevTools "Highlight Rebuilds" 验证重建范围

Phase 3 验收:
☐ 冷启动时间对比
☐ 重复打开字幕文件加载时间对比
☐ 1000 条字幕列表滚动流畅度

Phase 4 验收:
☐ dart analyze 0 error 0 warning 0 info
☐ 人为触发异常 → 错误边界生效

Phase 5 验收:
☐ dart test 全部通过
☐ flutter test 全部通过
```

---

## 8. 风险与回滚

### 8.1 风险矩阵

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| 拆分后 import 路径错误 | 中 | 高 | 每个 Phase 完成后立即 `dart analyze` |
| 状态管理优化导致 UI 不刷新 | 低 | 高 | DevTools 验证 + 手动全流程测试 |
| 数据库迁移失败 | 低 | 高 | 仅新增索引，不修改任何现有数据 |
| 懒加载导致首次使用卡顿 | 低 | 中 | 加载时显示 loading 状态 |
| 拆分后子组件之间通信断裂 | 中 | 中 | 每一阶段拆分完立即手动验证 |

### 8.2 回滚策略

```
每个 Phase 独立分支:
  git checkout -b phase/0-bug-fixes
  git checkout -b phase/1-code-split
  git checkout -b phase/2-state-optimize
  ...

任一 Phase 出现问题:
  → git checkout main（回滚到上一阶段）
  → 分析问题 → 修复 → 重新提交
```

### 8.3 不可妥协的底线

- **数据库**: 绝不修改现有字段类型或删除字段，仅允许新增表/字段/索引
- **功能**: 所有现有功能零退化
- **编译**: 每个 Phase 完成后 `dart analyze` 必须 0 error

---

## 9. 附录

### 9.1 文件变更总览

| 文件 | Phase | 操作 | 说明 |
|------|-------|------|------|
| `lib/services/ai_service.dart` | 0 | 修改 | 补日志 |
| `lib/services/favorites_api_service.dart` | 0 | 修改 | 补日志 |
| `lib/screens/typing_screen.dart` | 0 | 修改 | 补错误处理 |
| `lib/screens/import_screen.dart` | 0,1,2,4 | 修改 | Bug 修复 + 拆分瘦身 |
| `lib/screens/player_screen.dart` | 0,1,2,4 | 修改 | Bug 修复 + 拆分瘦身 |
| `lib/services/media_scanner.dart` | 0 | 修改 | 补日志 |
| `lib/providers/listening_history_store.dart` | 0 | 修改 | 补日志 |
| `lib/providers/ab_loop_history.dart` | 0 | 修改 | 补日志 |
| `lib/providers/favorites_store.dart` | 0 | 修改 | 补日志 |
| `lib/screens/import/category_bar.dart` | 1 | **新增** | ImportScreen 拆分 |
| `lib/screens/import/category_manage_dialog.dart` | 1 | **新增** | ImportScreen 拆分 |
| `lib/screens/import/local_import_tab.dart` | 1 | **新增** | ImportScreen 拆分 |
| `lib/screens/import/online_import_tab.dart` | 1 | **新增** | ImportScreen 拆分 |
| `lib/screens/import/media_records_list.dart` | 1 | **新增** | ImportScreen 拆分 |
| `lib/screens/player/player_initializer.dart` | 1 | **新增** | PlayerScreen 拆分 |
| `lib/screens/player/player_layout.dart` | 1 | **新增** | PlayerScreen 拆分 |
| `lib/screens/player/player_app_bar.dart` | 1 | **新增** | PlayerScreen 拆分 |
| `lib/screens/player/player_keyboard.dart` | 1 | **新增** | PlayerScreen 拆分 |
| `lib/screens/player/subtitle_loader.dart` | 1 | **新增** | PlayerScreen 拆分 |
| `lib/providers/media_category_provider.dart` | 1 | **新增** | Provider 拆分 |
| `lib/providers/media_record_provider.dart` | 1 | 修改 | Provider 瘦身 |
| `lib/services/cefr_detector.dart` | 3 | 修改 | 懒加载 |
| `lib/services/subtitle_cache.dart` | 3 | **新增** | 字幕缓存 |
| `shared_db/lib/database.dart` | 3 | 修改 | Schema v3 索引 |
| `lib/widgets/error_boundary.dart` | 4 | **新增** | 错误边界 |
| `lib/utils/async_guard.dart` | 4 | **新增** | 异步异常处理 |
| 多个测试文件 | 5 | **新增/修改** | 补齐测试 |

### 9.2 每日执行建议

```
Day 1 (3.5h):  Phase 0 Bug 修复 + Phase 1 ImportScreen 拆分
Day 2 (3.5h):  Phase 1 PlayerScreen 拆分 + Provider 拆分
Day 3 (3.0h):  Phase 2 状态管理优化 + Phase 3 性能优化
Day 4 (2.0h):  Phase 4 错误处理 + 规范 + Phase 5 测试 + 验收
```