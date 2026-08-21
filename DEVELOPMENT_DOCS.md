# 个人集成工具平台 · 需求开发文档

> **Phase 1 | v3**
> Flutter 3.x 客户端 + FastAPI 后端 + SQLite，自建 PC 服务器。
> 本文档涵盖「外壳平台」及首个插件「英语听力练习 + 闪卡系统」，按 INVEST 原则编写。
> 第三方开发者对接请参阅 [PLUGIN_SPEC.md](./PLUGIN_SPEC.md)。

---

## 1. 背景与目标

### 1.1 业务价值

**解决的问题**：英语学习者缺乏一个集「媒体播放 + 字幕分析 + 听写练习 + 词汇检测 + 固定搭配记忆」于一体的跨平台工具。现有方案要么是纯播放器（无学习功能），要么是纯学习 App（无媒体导入灵活性），无法满足从 B站/抖音/网盘等渠道获取学习素材后一站式练习的需求。

**成功指标**：

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| 本地媒体文件加载成功率 | ≥ 99% | 自动化测试覆盖 MP4/MKV/MP3/SRT/ASS/VTT 格式 |
| 字幕 CEFR 检测耗时 | ≤ 50ms/句（5000 词词典） | 性能测试 |
| 打字评分准确率偏差 | ≤ 2%（与人工标注对比） | 100 组测试用例 |
| 视频链接解析成功率 | ≥ 90%（B站/YouTube） | 100 条真实链接回归测试 |
| AI 代理请求 P99 延迟 | ≤ 5000ms（含第三方 API 调用） | 监控日志 |
| 闪卡复习 SM-2 算法正确率 | 100%（与本系统定义的 SM-2 公式对比） | 单元测试覆盖所有评分分支（rating 0-3 × 4 种 interval 状态） |

### 1.2 用户故事

| 编号 | 作为 | 我希望 | 以便 |
|------|------|--------|------|
| US-01 | 英语学习者 | 导入本地视频/音频文件和字幕文件 | 使用自己喜欢的影视素材练习听力 |
| US-02 | 英语学习者 | 粘贴 B站/YouTube/抖音链接后自动下载视频和字幕 | 无需手动下载、转格式，直接开始练习 |
| US-03 | 英语学习者 | 从百度网盘/夸克网盘选择视频文件导入 | 使用网盘中存储的学习素材 |
| US-04 | 英语学习者 | 在聆听模式下看到字幕按 CEFR 等级着色 | 直观了解当前句子中每个单词的难度 |
| US-05 | 英语学习者 | 逐句听写并自动评分 | 检验自己是否真的听懂了每个单词 |
| US-06 | 英语学习者 | 设置 AB 循环反复听某个片段 | 攻克听不懂的难点句子 |
| US-07 | 英语学习者 | 收藏单词/短语/句子并按 CEFR 等级筛选 | 建立自己的分级生词本 |
| US-08 | 英语学习者 | 看到字幕中高亮标记的固定搭配并查看释义 | 学习地道表达，而非孤立单词 |
| US-09 | 英语学习者 | 将固定搭配一键生成造句填空闪卡 | 通过间隔重复记忆固定搭配 |
| US-10 | 英语学习者 | 每天复习到期闪卡，翻卡查看原视频/音频 | 在原始语境中巩固记忆 |
| US-11 | 英语学习者 | 点击字幕中的生词查看 AI 生成的释义和例句 | 即时理解陌生词汇 |
| US-12 | 英语学习者 | 在多设备间同步学习数据 | 手机和电脑上学习进度一致 |
| US-13 | 平台用户 | 打开外壳 App 后看到已安装的应用列表（英语听力、闪卡、英文歌等） | 一站式访问所有个人工具，无需切换 App |
| US-14 | 第三方开发者 | 按照插件规范文档开发自己的模块并接入外壳 | 将自己的工具集成到平台中，共享用户系统和数据层 |
| US-15 | 英语学习者 | 将 Anki 导出的 .apkg 或 .csv 文件导入闪卡系统 | 无需手动重建卡片，直接迁移 Anki 中的学习数据 |
| US-S01 | 英语学习者 | 导入 LRC/SRT 歌词文件关联音频 | 用自己喜欢的英文歌练听力 |
| US-S02 | 英语学习者 | 看到歌词中连读、弱读位置被标注 | 理解为什么听歌时单词会"连在一起" |
| US-S03 | 英语学习者 | 逐句跟唱并录音，获得发音评分 | 模仿原唱的发音和节奏 |
| US-S04 | 英语学习者 | 将歌词中的连读标记收藏 | 在其他歌曲中复习同类连读现象 |

### 1.3 外壳架构

**设计理念**：外壳（Shell）是一个轻量级聚合容器，本身不包含任何业务功能，仅提供插件注册、路由分发、用户认证、数据共享等基础设施。每个插件是一个独立的 Flutter package，可以：
- 在外壳内运行：共享用户系统、数据层、UI 主题
- 独立运行：`cd plugins/xxx && flutter run`，自带最小化的独立入口

**架构图**：

```
┌─────────────────────────────────────────────────────┐
│                    外壳 (Shell)                       │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐       │
│  │ 英语听力   │  │ 闪卡系统   │  │ 英文歌学习  │  ...  │
│  │ (plugin)  │  │ (plugin)  │  │ (plugin)  │       │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘       │
│        │              │              │               │
│  ┌─────┴──────────────┴──────────────┴─────┐        │
│  │          共享基础设施 (shared/)            │        │
│  │  shared_auth │ shared_db │ shared_ui     │        │
│  └──────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────┘
```

**项目结构（monorepo）**：

```
platform/
├── shell/                        # 外壳 App（聚合入口）
│   ├── lib/
│   │   ├── main.dart             # 入口，加载插件注册表
│   │   ├── app.dart              # MaterialApp + go_router 配置
│   │   ├── registry.dart         # 插件注册表（声明式）
│   │   └── screens/
│   │       └── home_screen.dart  # 首页：应用网格 + 用户头像
│   └── pubspec.yaml              # 依赖所有 plugin + shared
├── plugins/
│   ├── english_listening/        # 英语听力（独立 Flutter package）
│   │   ├── lib/
│   │   │   ├── plugin.dart       # 实现 Plugin 接口
│   │   │   ├── standalone.dart   # 独立运行入口
│   │   │   └── ...               # 业务代码
│   │   └── pubspec.yaml
│   ├── flashcards/               # 闪卡（独立 Flutter package）
│   │   ├── lib/
│   │   │   ├── plugin.dart
│   │   │   ├── standalone.dart
│   │   │   └── ...
│   │   └── pubspec.yaml
│   ├── english_songs/            # 英文歌学习（独立 Flutter package）→ [PLUGIN_SONGS.md](./PLUGIN_SONGS.md)
│   │   ├── lib/
│   │   │   ├── plugin.dart
│   │   │   ├── standalone.dart
│   │   │   └── ...
│   │   └── pubspec.yaml
│   ├── new_concept/              # 新概念英语（Phase 3）
├── shared/                       # 共享基础设施
│   ├── shared_auth/              # 统一认证（JWT + 拦截器）
│   ├── shared_db/                # 统一数据层（drift 数据库 + 同步）
│   └── shared_ui/                # 统一 UI 组件（主题、布局、Widget）
├── server/                       # Python 后端（同上）
├── PLUGIN_SPEC.md                # 第三方开发者对接规范
└── README.md
```

**插件注册表（`registry.dart`）**：

```dart
// 每个插件实现此接口
abstract class PlatformPlugin {
  String get id;                    // 唯一标识，如 "english_listening"
  String get name;                   // 显示名称，如 "英语听力"
  String get description;            // 简短描述
  IconData get icon;                 // 图标
  String get routePath;             // 路由路径，如 "/english-listening"
  WidgetBuilder get pageBuilder;    // 页面构建器
  int get sortOrder;                // 排序权重，越小越靠前
}

// 注册表：声明式列出所有已安装插件
final List<PlatformPlugin> pluginRegistry = [
  EnglishListeningPlugin(),
  FlashcardsPlugin(),
  SongLearningPlugin(),
  // 未来添加新插件只需在此新增一行
];
```

**独立运行机制**：每个 plugin 的 `standalone.dart` 提供最小化的 `main()` 函数，仅包含该插件自身需要的依赖（auth mock、本地数据库），确保剥离外壳后仍可独立编译为 App。

**数据互通**：所有插件共享 `shared_db` 中的 `users` 表和认证状态。插件间数据互通通过共享数据库实现——例如闪卡插件可以直接读取英语听力插件写入的 `collocations` 表来生成卡片，无需通过 API 中转。

**未来 AI 生成插件**（Phase 3+）：用户通过自然语言描述需求 → AI 根据 `PLUGIN_SPEC.md` 规范自动生成 Flutter package 骨架代码 → 用户回答确认问题 → 生成完整插件代码并注册到外壳。

---

## 2. 功能需求

### 优先级定义

| 级别 | 含义 | 上线条件 |
|------|------|---------|
| **P0** | 核心功能，无此不可用 | 必须 Phase 1 交付 |
| **P1** | 重要功能，核心体验 | 必须 Phase 1 交付 |
| **P2** | 增强功能，体验优化 | Phase 1 尽量交付，可延后 |

---

### P0-01 用户认证

**INVEST 评估**：独立于其他模块，可单独测试，用户价值明确。

#### 前置条件
- 后端服务已启动，`/api/auth/register` 和 `/api/auth/login` 端点可访问
- 客户端 `shared_preferences` 已初始化
- 数据库 `users` 表已创建，字段：`id(UUID)`, `username(UNIQUE NOT NULL)`, `email(UNIQUE NOT NULL)`, `password_hash(NOT NULL)`, `created_at`, `updated_at`

#### 主流程

1. 用户打开 App → 检查 `shared_preferences` 中 `jwt_token` 是否存在
2. Token 存在 → 调用 `GET /api/auth/me` 验证 Token 有效性
   - 返回 200 → 进入主页
   - 返回 401 → 尝试 `POST /api/auth/refresh`
     - 刷新成功 → 更新 `jwt_token` → 进入主页
     - 刷新失败 → 跳转登录页
3. Token 不存在 → 显示登录/注册页面
4. 注册：用户输入 `username(3-30字符)`, `email`, `password(≥8字符，含大小写字母+数字)`
   - 客户端验证格式 → `POST /api/auth/register` → 返回 `access_token(exp=24h)` + `refresh_token(exp=30d)`
5. 登录：用户输入 `email` + `password`
   - `POST /api/auth/login` → 返回 Token 对
6. Token 存入 `shared_preferences`，设置 `dio` 拦截器自动附加 `Authorization: Bearer <token>`

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 用户名已存在 | 注册时 `username: "admin"`（已占用） | 返回 409，提示 "Username already exists" |
| 邮箱格式错误 | 注册时 `email: "notanemail"` | 客户端拦截，提示 "Invalid email format"，不发送请求 |
| 密码强度不足 | 注册时 `password: "12345678"` | 客户端拦截，提示 "Password must contain at least one uppercase letter, one lowercase letter, and one digit" |
| 登录凭据错误 | 登录时 `email: "a@b.com", password: "wrong"` | 返回 401，提示 "Invalid credentials"，不区分是邮箱不存在还是密码错误 |
| 网络不可达 | 后端服务未启动 | 客户端显示 "Server unavailable. Check your network and server address."，不阻塞离线使用 |
| Token 过期 | 操作需要认证的接口 | 返回 401，自动触发刷新，刷新失败则跳转登录页 |

#### 验收标准

```gherkin
Scenario: 新用户注册成功
  Given 后端服务 `/api/health` 返回 200
  When 用户提交 username="testuser", email="test@example.com", password="Abc12345"
  Then HTTP 状态码为 200
  And 响应包含 access_token 字段
  And 响应包含 refresh_token 字段
  And access_token 可被 jwt.decode 验证
  And 数据库中 users 表新增一条记录，password_hash 不以明文存储

Scenario: 已注册用户登录成功
  Given 用户 test@example.com 已注册，密码为 Abc12345
  When 用户提交 email="test@example.com", password="Abc12345"
  Then HTTP 状态码为 200
  And 响应包含 access_token 和 refresh_token

Scenario: Token 过期后自动刷新
  Given 用户已登录，持有过期 access_token 和有效 refresh_token
  When 用户请求 GET /api/favorites
  Then 返回 401
  And 客户端自动调用 POST /api/auth/refresh
  And 刷新成功后使用新 token 重试原请求
  And 最终返回 200 和收藏列表

Scenario: 离线模式不阻塞使用
  Given 用户已登录，但后端服务不可达
  When 用户打开 App
  Then 显示 "Offline mode" 提示
  And 用户可使用本地已有数据的所有功能
  And 不会弹出登录页面
```

---

### P0-02 媒体播放

**INVEST 评估**：独立模块，可单独测试，是整个系统的入口。

#### 前置条件
- 用户已通过文件选择器 (`file_picker`) 选择至少一个媒体文件，或通过视频导入模块下载了媒体文件
- 设备支持所选媒体格式的硬件解码
- `just_audio` 和 `video_player` 插件已初始化

#### 主流程

1. 用户点击「导入媒体」→ 打开系统文件选择器，过滤 `mp4, mkv, webm, mov, avi, mp3, m4a, wav, ogg, flac, aac`
2. 选择文件后 → 创建 `MediaFile` 对象（name, path, type, mimeType）
3. `type == video` → 初始化 `VideoPlayerController.file(filePath)`，显示 `VideoPlayer` widget
4. `type == audio` → 初始化 `AudioPlayer`，设置 `AudioSource.file(filePath)`，显示波形占位图
5. 播放器就绪后自动播放
6. 用户交互：
   - 点击视频区域 / 播放按钮 → 切换播放/暂停
   - 拖动进度条 → seek 到指定位置
   - 键盘 Space → 播放/暂停（仅此一个快捷键由播放器处理，其余键盘导航由字幕模块统一处理）
7. 播放进度通过 `Ticker` 以 30fps 更新 `currentTime`，驱动字幕同步

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 不支持的格式 | 选择 `.rmvb` 文件 | 文件选择器过滤掉不支持的格式，用户不可见；若绕过过滤，播放器报错，显示 "Unsupported format: .rmvb" |
| 文件损坏 | 选择损坏的 `.mp4` 文件 | 播放器初始化失败，显示 "Failed to load media file. The file may be corrupted." |
| 文件被删除 | 播放过程中文件被外部删除 | 播放器报错，显示 "Media file not found. It may have been moved or deleted." |
| 内存不足 | 加载 4K 视频到低端设备 | 播放卡顿时自动降级到 720p 解码，仍失败则提示 "Insufficient device resources for this video quality." |
| 音频焦点丢失 | 播放中接到电话 | 暂停播放，通话结束后不自动恢复，用户手动点击播放 |

#### 验收标准

```gherkin
Scenario: 加载本地 MP4 视频并播放
  Given 用户设备上存在 test_video.mp4（1920x1080, H.264, 30s）
  When 用户通过文件选择器选择该文件
  Then 1 秒内显示第一帧画面
  And 播放器自动开始播放
  And 进度条从 0:00 开始递增
  And 视频画面占满播放器容器宽度，保持 16:9 比例

Scenario: 加载本地 MP3 音频并播放
  Given 用户设备上存在 test_audio.mp3（128kbps, 60s）
  When 用户通过文件选择器选择该文件
  Then 1 秒内开始播放音频
  And 显示波形占位图
  And 进度条从 0:00 开始递增

Scenario: 播放/暂停切换
  Given 视频正在播放，currentTime = 5.0s
  When 用户点击视频区域
  Then 视频暂停，currentTime 停留在 5.0s ± 0.1s
  When 用户再次点击视频区域
  Then 视频从暂停位置继续播放

Scenario: 拖动进度条跳转
  Given 视频总时长 30s，当前播放到 5s
  When 用户拖动进度条到 15s 位置
  Then 视频 seek 到 15s ± 0.5s 并继续播放
  And 字幕同步到 15s 对应的句子
```

---

### P0-03 字幕系统

**INVEST 评估**：独立模块，可单独测试（给定字幕文件，验证解析结果），是 CEFR/搭配/收藏等模块的基础。

#### 前置条件
- 媒体文件已加载
- 用户通过 `file_picker` 选择了字幕文件（SRT/VTT/ASS/SSA），或视频导入模块自动下载了字幕
- 字幕文件编码为 UTF-8 或 UTF-8 BOM（ASS/SSA 可为 ANSI）

#### 主流程

1. 用户点击「导入字幕」→ 打开系统文件选择器，过滤 `srt, vtt, ass, ssa`
2. 读取文件内容 → 根据扩展名路由到对应解析器
   - `.srt` / `.vtt` → `subtitle_parser.dart`，正则提取 `index, start, end, text`
   - `.ass` / `.ssa` → `ass_parser.dart`，提取 `preamble(样式头)` + `cues(对话行)`
3. ASS 文件 → `bilingual_text.dart` 检测每行 CJK 字符比例，≥30% 视为中文翻译行，分离到 `nativeTranslation`
4. 解析完成后：
   - 按 `start` 时间升序排序所有 cues
   - 检测重叠字幕（当前 cue.start < 前一个 cue.end），自动将当前 cue.start 调整为前一个 cue.end + 0.01s
   - 触发 CEFR 词汇检测（如已实现，见 P1-03；通过可选回调 `onSubtitlesLoaded` 注入，若回调为 null 则静默跳过）
   - 触发固定搭配检测（如已实现，见 P1-07；同上，通过可选回调注入）
5. 字幕面板显示：当前播放时间对应的字幕高亮，自动滚动到可见区域
6. 字幕切换模式：用户可切换 `EN / 中文 / 双语 / 隐藏`
7. 键盘 ← → 跳转到上/下一句，同时播放器 seek 到对应 start 时间（**字幕模块是键盘导航的唯一处理者**，播放器不监听 ← → 事件，避免双重 seek）
8. 用户可点击字幕条目上的 ✏️ 编辑按钮修改文本或时间，点击 ★ 收藏整句

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 文件编码非 UTF-8 | 选择 GBK 编码的 `.srt` 文件 | 尝试 UTF-8 解码失败 → 尝试 GBK/GB2312 解码 → 仍失败则提示 "Unsupported encoding. Please convert to UTF-8." |
| 格式错误的 SRT | 序号缺失、时间戳格式错误 | 跳过错误行，解析成功的 cues 正常显示，日志记录解析失败的行号和原因 |
| 空字幕文件 | 选择 0 字节的 `.srt` 文件 | 提示 "The subtitle file is empty." |
| ASS 文件无对话行 | 只有样式定义无对话 | 提示 "No dialogue lines found in the ASS file." |
| 字幕与视频时长不匹配 | 字幕最后一句 end=90s，视频总长 30s | 正常显示全部字幕，超出视频时长部分以灰色标记 |
| 同时间戳多个字幕 | 两条字幕在同一秒内 | 合并显示，使用 `\n` 分隔，不覆盖 |

#### 验收标准

```gherkin
Scenario: 解析标准 SRT 文件
  Given 存在 test.srt 文件，内容为 3 条标准 SRT 格式字幕
  When 用户导入该文件
  Then 解析出 3 个 SubtitleCue 对象
  And 每个 cue 的 id 为 UUID 格式
  And 每个 cue 的 start < end
  And cues 按 start 时间升序排列

Scenario: 解析双语 ASS 文件
  Given 存在 bilingual.ass 文件，其中英文行包含 CJK 字符比例 < 30%，中文行 ≥ 30%
  When 用户导入该文件
  Then 每个 cue 的 text 字段为英文
  And 每个 cue 的 nativeTranslation 字段为中文
  And 英文和中文行正确配对

Scenario: 字幕随播放进度自动高亮
  Given 字幕已加载，第 2 句 start=3.0s, end=5.0s
  When 播放器 currentTime 从 2.0s 推进到 3.5s
  Then 当 currentTime ≥ 3.0s 时，第 2 句字幕高亮
  And 当 currentTime ≥ 5.0s 时，第 2 句字幕取消高亮
  And 字幕面板自动滚动使高亮句可见
```

---

### P0-04 外壳与插件系统

**INVEST 评估**：独立模块，外壳不依赖任何具体插件，插件通过接口定义与外壳解耦，可单独测试。

#### 前置条件
- Flutter 项目采用 monorepo 结构，`shell/`、`plugins/`、`shared/` 三个顶层目录已创建
- `shared/` 下的 `shared_auth`、`shared_db`、`shared_ui` 三个 package 已初始化
- `shell/pubspec.yaml` 已配置对 `shared/` 和所有插件的依赖
- 每个插件的 `pubspec.yaml` 已配置对 `shared/` 的依赖

#### 主流程

**外壳启动流程**
1. 用户打开外壳 App
2. `main.dart` → 初始化 `shared_auth`（检查 JWT Token）→ 初始化 `shared_db`（打开 drift 数据库）
3. 用户认证状态确认后 → 进入 `HomeScreen`
4. `HomeScreen` 读取 `pluginRegistry`（来自 `registry.dart`）
5. 按 `sortOrder` 升序排列插件，以网格布局展示插件卡片（图标 + 名称 + 描述）
6. 用户点击插件卡片 → `go_router` 导航到 `plugin.routePath` → 加载 `plugin.pageBuilder(context)`
7. 插件页面内，可通过 `shared_auth` 获取当前用户信息，通过 `shared_db` 读写数据

**插件注册流程（开发者视角）**
8. 开发者在 `plugins/` 下创建新 Flutter package
9. 实现 `PlatformPlugin` 接口（`plugin.dart`）
10. 在 `shell/pubspec.yaml` 中添加依赖：`path: ../plugins/my_plugin`
11. 在 `shell/lib/registry.dart` 的 `pluginRegistry` 列表中添加一行：`MyPlugin()`
12. 重新编译外壳 App，新插件出现在首页网格中

**独立运行流程**
13. 开发者 `cd plugins/my_plugin && flutter run`
14. `standalone.dart` 提供最小化 `main()`：初始化 `shared_auth`（mock 模式）、`shared_db`（**isolated 模式**，使用独立数据库文件名 `standalone_{plugin_id}.db`，不与外壳共享物理数据库文件）、`MaterialApp` + 该插件路由
15. 插件独立 App 运行，功能与外壳内完全一致，但数据与外壳物理隔离

**首页布局**
16. compact（手机）：2 列网格，插件卡片带图标和名称
17. medium（平板）：3 列网格
18. expanded（桌面）：4 列网格 + 左侧 Sidebar 导航
19. 顶部显示用户头像和用户名，点击进入设置

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 插件注册了重复 ID | 两个插件 `id` 均为 `"flashcards"` | 编译时 lint 报错，提示 "Duplicate plugin ID: flashcards" |
| 插件 package 未安装 | `shell/pubspec.yaml` 引用但未执行 `flutter pub get` | 编译失败，Dart 分析器提示 "Package not found" |
| 独立运行时缺少 shared 依赖 | 插件 `standalone.dart` 引用了 `shared_auth` 但未在 `pubspec.yaml` 声明 | 编译失败，提示 import 错误 |
| 插件页面抛出未捕获异常 | 插件内部 `pageBuilder` 抛出异常 | 外壳捕获异常，显示错误页面 "Plugin crashed. Please contact the plugin developer." + 返回首页按钮 |
| 外壳中卸载插件 | 开发者注释掉 `registry.dart` 中的注册行和 `pubspec.yaml` 中的依赖 | 外壳编译后首页不再显示该插件，但插件 package 代码保留在磁盘，可随时恢复注册 |
| 外壳 App 与独立 App 同时安装 | 用户手机上同时安装外壳 App 和英语听力独立 App | 两者使用不同数据库文件（外壳用 `shared.db`，独立用 `standalone_english_listening.db`），WAL 模式互不干扰，数据不共享 |

#### 验收标准

```gherkin
Scenario: 外壳首页展示已注册插件
  Given pluginRegistry 包含 EnglishListeningPlugin 和 FlashcardsPlugin
  When 用户登录后进入首页
  Then 首页显示 2 个插件卡片
  And 卡片显示插件名称 "英语听力" 和 "闪卡系统"
  And 卡片显示对应图标
  And 卡片按 sortOrder 排序

Scenario: 点击插件卡片导航到插件页面
  Given 用户在首页
  When 用户点击 "英语听力" 卡片
  Then 路由导航到 "/english-listening"
  And 页面显示英语听力模块的主界面
  And 顶部导航栏显示返回按钮

Scenario: 插件独立运行
  Given 开发者在 english_listening 目录下
  When 执行 flutter run
  Then 启动独立 App
  And 无需外壳即可使用英语听力全部功能
  And 登录使用 mock 模式，无需后端

Scenario: 新插件注册流程
  Given 开发者创建了 my_plugin 并实现了 PlatformPlugin 接口
  When 在 shell/pubspec.yaml 添加依赖，在 registry.dart 添加注册
  And 重新编译外壳 App
  Then 首页网格中显示 my_plugin 的卡片
  And 点击卡片可正常导航到插件页面
```

---

### P1-01 AB 循环

**INVEST 评估**：独立功能，可单独测试循环逻辑，不依赖其他模块。

#### 前置条件
- 媒体已加载并正在播放
- 字幕已加载（AB 标记在进度条上依赖字幕时间轴定位）

#### 主流程

1. 用户点击「SET A」→ 记录当前 `currentTime` 为 `pointA`，在进度条上标记绿点
2. 用户点击「SET B」→ 记录当前 `currentTime` 为 `pointB`（必须 > pointA），在进度条上标记红点
3. 用户点击「LOOP」→ 开启循环
   - 每帧（30fps）检测：`currentTime >= pointB - 0.02s` → `seek` 到 `pointA`
4. 用户调整「LEAD」滑块（0–500ms）→ 循环跳回时提前 `leadTime` 毫秒，即 seek 到 `pointA - leadTime`
5. 用户点击「SKIP」→ 启用静音跳过：当 `currentTime` 不在任何字幕时间范围内且持续 200ms 时，在 500ms 内自动 seek 到下一个字幕的 `start`（计时从检测到静音开始，而非从离开字幕范围开始，为静音阈值判断留出缓冲）
6. 用户点击「SAVE」→ 弹出命名对话框，保存 AB 片段（label, pointA, pointB）到本地数据库
7. 用户点击「AB HISTORY」→ 显示最近 8 条保存记录，点击某条加载对应的 pointA/pointB
8. 历史记录可左滑删除

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| SET B 小于 SET A | pointA=10s, 用户在 5s 处点击 SET B | 忽略操作，提示 "Point B must be after Point A" |
| AB 区间过短 | pointA=10s, pointB=10.1s（间隔 < 0.5s） | 忽略操作，提示 "AB segment must be at least 0.5 seconds" |
| 无字幕时使用 SKIP | 字幕未加载，用户点击 SKIP | 提示 "Skip silent requires subtitles to be loaded" |
| 历史记录超过 8 条 | 保存第 9 条 AB 片段 | 自动删除最早的一条，保持上限 8 条 |
| LEAD 导致 pointA 为负 | pointA=0.3s, leadTime=500ms | 自动 clamp 到 0.0s |

#### 验收标准

```gherkin
Scenario: AB 循环正确跳回
  Given pointA=5.0s, pointB=10.0s, LOOP 开启, leadTime=0ms
  When currentTime 达到 10.0s
  Then 播放器在 50ms 内 seek 到 5.0s ± 0.1s

Scenario: LEAD 提前量生效
  Given pointA=5.0s, pointB=10.0s, LOOP 开启, leadTime=500ms
  When currentTime 达到 10.0s
  Then 播放器 seek 到 4.5s ± 0.1s

Scenario: 保存并加载 AB 片段
  Given 已设置 pointA=5.0s, pointB=10.0s
  When 用户点击 SAVE，输入 label="difficult part"
  Then AB 历史列表中显示 "difficult part (5.0s - 10.0s)"
  When 用户退出后重新打开 App，点击该历史记录
  Then pointA 恢复为 5.0s, pointB 恢复为 10.0s

Scenario: SKIP 静音跳过
  Given 字幕：cue1(0s-3s), cue2(5s-8s), SKIP 开启
  When currentTime 在 3.5s（无字幕区间，已持续 200ms）
  Then 播放器在 500ms 内自动 seek 到 5.0s ± 0.1s
```

---

### P1-02 打字练习模式

**INVEST 评估**：独立模块，可单独测试评分算法，不依赖网络。

#### 前置条件
- 媒体已加载
- 字幕已加载
- 用户已切换到打字模式（PracticeMode.typing）

#### 主流程

1. 进入打字模式时，检查 AB 循环状态，若开启则自动关闭并提示 "AB Loop disabled in typing mode"
2. 系统自动播放当前字幕句子的音频片段：从 `max(0, cue.start - leadTime)` 到 `cue.end`。`leadTime` 为打字模式独立参数，默认值 200ms，与 AB 循环的 LEAD 滑块互不干扰，分别存储在 `shared_preferences` 的 `typing_lead_ms` 和 `ab_lead_ms` 中。用户可在打字模式控制栏中通过滑块调整（0–500ms）
3. 音频播放结束后，输入框自动获得焦点
4. 用户在输入框中输入听到的英文
5. 用户按 Enter 或点击「CHECK」提交
6. 系统执行评分算法：
   ```
   normalizeForCompare(text):
     1. 转小写
     2. 移除所有非 [a-z0-9 '] 的字符，替换为空格
     3. 合并连续空格为一个空格
     4. 去除首尾空格

   calcAccuracy(expected, typed):
     matches = 逐字符比较 normalized 后的 expected 和 typed
     matches / max(len(expected), len(typed)) * 100
   ```
6. 显示结果：
   - 准确率 100% → 播放成功音效（单元测试中验证 `AudioPlayer.play()` 被调用并传入 `success_sound.mp3`，不验证实际音频输出） + 绿色对勾动画
   - 准确率 < 100% → 显示标准答案与用户输入的逐字符对比（正确字符绿色，错误字符红色，缺失字符灰色）
7. 按 ← 回到上一句，按 → 进入下一句，自动播放下一句音频

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 空输入提交 | 用户直接按 Enter 未输入任何内容 | 准确率 0%，显示完整标准答案 |
| 输入纯标点 | 用户输入 "...,!!!" | 归一化后为空字符串，准确率 0% |
| 字幕句子为空 | cue.text 为纯标点或空字符串 | 跳过该句，自动进入下一句 |
| 音频片段长度为零 | cue.start == cue.end | 跳过音频播放，直接显示输入框 |
| 快速连续提交 | 用户在 1 秒内按 Enter 3 次 | 只处理第一次提交，后续两次忽略（防抖 500ms） |

#### 验收标准

```gherkin
Scenario: 完全正确输入
  Given 字幕句子为 "Hello, world!"
  When 用户输入 "Hello, world!" 并提交
  Then 准确率为 100.0%
  And 播放成功音效
  And 显示绿色对勾动画

Scenario: 部分正确输入
  Given 字幕句子为 "Hello, world!"
  When 用户输入 "Hello world" 并提交
  Then 准确率 = 字符匹配数 / max(13, 12) * 100，约为 92.3%
  And 显示逐字符对比：'H','e','l','l','o',',',' ','w','o','r','l','d','!' vs 用户输入，缺失字符标灰

Scenario: 大小写不敏感
  Given 字幕句子为 "Hello, World!"
  When 用户输入 "hello, world!" 并提交
  Then 准确率为 100.0%

Scenario: 标点符号忽略
  Given 字幕句子为 "Hello, world!"
  When 用户输入 "hello world" 并提交
  Then 归一化后 expected="hello world", typed="hello world"，准确率为 100.0%
```

---

### P1-03 CEFR 词汇检测

**INVEST 评估**：独立模块，纯本地运算，无需网络，可单独测试。

#### 前置条件
- 字幕已加载（至少有 1 个 cue 的 text 非空）
- `assets/cefr_vocabulary.json` 文件存在且格式正确，包含 ≥ 5000 条 `{ "word": "example", "level": "B1", "meaning": "例子" }` 记录
- JSON 文件在 App 启动时加载到内存 Map，key 为 lowercased word

#### 主流程

1. 字幕加载完成后，对每条 cue 的 `text` 调用 `detectCEFR(cue.text, dictionary)`
2. 分词：按空格和标点 `[^a-zA-Z'-]` 分割文本
3. **复合词优先匹配**：对 2-3 词窗口进行 n-gram 扫描，优先查询词典中的多词条目（如 "ice cream" → A1）。多词条目命中后，其组成单词不再单独标记，避免 "ice cream" 被错误标记为 "ice"(A2) + "cream"(B1)
4. 对剩余未匹配单词，查 `dictionary[word.toLowerCase()]`
4.5 **词形还原（Lemmatization）**：对仍未匹配的单词，尝试还原为词根形式（如 "running"→"run"、"happier"→"happy"、"colours"→"colour"），用词根再次查询词典。若命中，标记原单词为词根对应的 CEFR 等级。使用简单规则引擎：去 -ing/-ed/-s/-es/-er/-est/-ly/-'s 后缀，处理辅音双写（"running"→"run"）和 y→i 变体（"happier"→"happy"）。不依赖外部 NLP 库，纯 Dart 实现
5. 命中 → 创建 `CEFRToken(word, level, meaning, startIndex, endIndex)`
6. 未命中 → 不标记
7. 全部 tokens 附加到 `cue.cefrTokens`
8. 字幕渲染时，每个 token 按等级着色（下划线 + 颜色）：
   - A1: `#22C55E`（绿色）
   - A2: `#10B981`（蓝绿色）
   - B1: `#3B82F6`（蓝色）
   - B2: `#8B5CF6`（紫色）
   - C1: `#F97316`（橙色）
   - C2: `#EF4444`（红色）
9. 词汇面板按等级分组显示所有检测到的词汇，统计数量和占比

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 词典文件缺失 | `cefr_vocabulary.json` 不存在 | App 启动时打印错误日志，CEFR 检测功能不启用，字幕正常显示无着色 |
| 词典格式错误 | JSON 解析失败 | 同上，记录具体错误信息（行号、字段） |
| 字幕包含非英文单词 | "你好 world" | 仅对 "world" 检测，CJK 字符跳过 |
| 同一单词多义 | 词典中单词有多个等级 | 取词典中第一个匹配的等级。**词典是 CEFR 等级的单一权威来源**，任何其他模块（收藏、闪卡）不得覆盖词典等级。用户可附加自定义标签，但不改变系统记录的 CEFR 等级。 |
| 超长字幕 | 字幕文本 > 1000 字符 | 仍然检测，但超过 1000 字符部分截断不检测 |

#### 验收标准

```gherkin
Scenario: 检测已知词汇
  Given 词典包含 {"word": "hello", "level": "A1", "meaning": "你好"}
  And 字幕为 "Hello, world!"
  When 执行 detectCEFR
  Then 返回 1 个 CEFRToken
  And token.word = "Hello", token.level = A1, token.meaning = "你好"

Scenario: 未知词汇不标记
  Given 词典不包含 "xyzabc"
  And 字幕为 "This is xyzabc"
  When 执行 detectCEFR
  Then 返回的 tokens 中不包含 word="xyzabc" 的条目

Scenario: 检测性能达标
  Given 字幕包含 50 个单词，词典 5000 条
  When 执行 detectCEFR
  Then 耗时 ≤ 50ms

Scenario: 字幕着色正确
  Given cue 的 cefrTokens 包含 [{"word":"hello","level":"A1"}]
  When 渲染字幕
  Then "hello" 以 `#22C55E` 颜色显示，带下划线
  And 其他单词以默认颜色显示
```

---

### P1-04 收藏系统

**INVEST 评估**：独立模块，可单独测试 CRUD 操作，不依赖其他模块。

#### 前置条件
- 用户已登录（离线时仍可操作本地数据）
- 本地 drift 数据库 `favorites` 表已创建，字段：`id, type, text, context, cefrLevel, mediaTime, cueId, createdAt, updatedAt`

#### 主流程

1. 添加收藏：
   - **从字幕**：字幕面板中，用户点击某条字幕的 ★ 按钮 → 创建 `FavoriteItem(type=sentence, text=cue.text, context=cue.text, cueId=cue.id, mediaTime=cue.start)`
   - **从词汇面板**：点击词汇卡片 → 创建 `FavoriteItem(type=word, text=token.word, cefrLevel=token.level)`
   - **手动添加**：在收藏面板点击 + 按钮 → 选择类型（单词/短语/句子）→ 输入文本 → 可选填写自定义标签（如 "difficult"、"review"），系统自动从词典查询 CEFR 等级（词典有则取词典值，无则标记 `UNKNOWN`）
2. 收藏列表显示：
   - 默认按创建时间倒序排列
   - 支持按类型筛选：ALL / WORD / PHRASE / SENTENCE
   - 支持按 CEFR 等级筛选：A1 / A2 / B1 / B2 / C1 / C2
3. 用户点击收藏条目 → 展示详情（文本、类型、CEFR 等级、来源字幕上下文、收藏时间）
4. 批量操作：点击「选择」→ 勾选多个条目 → 点击「删除所选」→ 弹出确认对话框
5. 单个删除：左滑条目 → 点击删除按钮 → 确认
6. 数据同步：新增/删除操作先写本地 drift，再异步调用后端 API；冲突以 `updatedAt` 时间戳为准（last-write-wins）

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 重复收藏同一句子 | 对同一 cueId 两次点击 ★ | 第二次点击取消收藏（Toggle 行为），而非创建重复条目 |
| 手动添加空文本 | 输入框为空，点击保存 | 提示 "Text cannot be empty"，不保存 |
| 批量删除误操作 | 选中 50 条，点击删除 | 弹出确认对话框 "Delete 50 favorites?"，需用户二次确认 |
| 离线时收藏 | 无网络，收藏一个单词 | 成功写入本地 drift，待网络恢复后自动同步到后端 |
| 同步冲突 | 同一收藏在手机和电脑上分别修改了 CEFR 等级 | 以 `updatedAt` 较新的版本为准，旧的被覆盖 |

#### 验收标准

```gherkin
Scenario: 从字幕添加收藏
  Given 字幕 cue_1 的 text="Hello world"
  When 用户点击 cue_1 的 ★ 按钮
  Then 本地数据库 favorites 表新增一条记录
  And type="sentence", text="Hello world", cueId=cue_1.id
  And 后端 API 收到 POST /api/favorites 请求

Scenario: 按 CEFR 等级筛选
  Given 收藏列表包含 A1(3条), B1(2条), C1(1条)
  When 用户选择筛选 B1
  Then 列表仅显示 2 条 B1 收藏
  When 用户选择筛选 ALL
  Then 列表显示全部 6 条收藏

Scenario: Toggle 取消收藏
  Given 字幕 cue_1 已被收藏（★ 实心）
  When 用户再次点击 cue_1 的 ★ 按钮
  Then 本地数据库 favorites 表删除该记录
  And ★ 变为空心
  And 后端 API 收到 DELETE /api/favorites/{id} 请求

Scenario: 离线收藏后同步
  Given 用户离线，收藏了一个单词
  When 网络恢复
  Then 该收藏自动同步到后端
  And 后端返回的收藏列表包含该条目
```

---

### P1-05 在线视频导入

**INVEST 评估**：独立模块，可单独测试链接解析和下载流程，但依赖后端 yt-dlp 和 AI 转录服务。

#### 前置条件
- 后端服务已启动，`/api/video/parse` 和 `/api/video/download` 端点可访问
- 后端服务器已安装 `yt-dlp` 和 `ffmpeg`
- 用户已登录（需携带 JWT Token）

#### 主流程

1. 用户打开导入页面，点击「粘贴链接」
2. 系统监听剪贴板，检测到匹配正则的视频链接时自动填充到输入框
3. 支持的平台正则：
   - Bilibili: `bilibili\.com/video/(BV[a-zA-Z0-9]+)`
   - YouTube: `(youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]+)`
   - 抖音: `douyin\.com/video/(\d+)` / `v\.douyin\.com/(\w+)`
   - TikTok: `tiktok\.com/@[\w.-]+/video/(\d+)`
   - 小红书: `xhslink\.com/(\w+)` / `xiaohongshu\.com/explore/(\w+)`
4. 用户点击「解析」→ `POST /api/video/parse { url }`
5. 后端返回：`{ platform, title, thumbnailUrl, duration, hasSubtitles }`
6. 用户确认后点击「下载」→ `POST /api/video/download { url }`
7. 后端执行：
   - `yt-dlp` 下载视频（优先 720p，最小文件体积）
   - 有字幕平台 → 同时下载字幕文件
   - 无字幕平台 → 提取音频 → 调用 Groq Whisper API 转录 → 生成 SRT
8. 下载进度通过 SSE (`/api/video/progress/{task_id}`) 推送到客户端
9. 客户端显示进度条和状态：解析中 → 下载中(XX%) → 转录中 → 完成
10. 下载完成后，返回 `{ fileId, title, duration, hasSubtitles, subtitleFormat }`，其中 `fileId` 为服务端文件唯一标识
11. 客户端将 `fileId` 加入本地媒体库，播放时通过 `GET /api/media/{fileId}/stream` 获取 HTTP 流媒体 URL（支持 Range 请求，无需客户端二次下载整个文件），字幕文件通过 `GET /api/media/{fileId}/subtitle` 获取
12. 媒体库加载完成后自动跳转到聆听模式

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 无效链接 | `https://example.com/notavideo` | 正则不匹配，提示 "Unsupported URL format. Please paste a link from Bilibili, YouTube, Douyin, TikTok, or Xiaohongshu." |
| 视频已删除 | B站视频已被 up 主删除 | 后端 yt-dlp 返回错误，提示 "Video unavailable. It may have been deleted or made private." |
| 下载超时 | 视频文件 > 2GB，30 分钟未完成 | 自动重试 1 次，仍失败则提示 "Download timed out. The video may be too large. Try a shorter video." |
| 转录失败 | 无字幕视频，AI 转录 API 超限 | 下载视频成功，字幕标记为 "No subtitles available"，提示用户手动导入 |
| 磁盘空间不足 | 后端服务器磁盘 < 500MB | 下载前检查磁盘空间，不足时提示 "Server disk space insufficient. Please free up at least 500MB." |
| 同时下载多个视频 | 用户在第一个视频下载中又提交第二个 | 排队处理，第二个任务状态为 "queued"，第一个完成后自动开始第二个 |
| 服务端崩溃重启 | 下载中途后端进程被 kill 或服务器重启 | 后端 `download_tasks` 表持久化每个任务的状态（pending/downloading/transcribing/done/failed）、进度（bytes_downloaded/total_bytes）、yt-dlp 临时文件路径。重启后扫描表中 status=downloading 的任务，通过 yt-dlp `--continue` 从断点恢复。客户端 SSE 断连后每 5 秒重试连接，重连后通过 `GET /api/video/progress/{task_id}` 恢复进度显示 |

#### 验收标准

```gherkin
Scenario: 解析 B站视频链接
  Given 用户粘贴 "https://www.bilibili.com/video/BV1xx411c7mD"
  When 用户点击「解析」
  Then 3 秒内返回视频信息
  And platform="bilibili"
  And title 不为空
  And duration > 0

Scenario: 下载 YouTube 视频（含字幕）
  Given 用户粘贴有效 YouTube 链接
  When 用户点击「下载」
  Then 显示下载进度（百分比）
  And 下载完成后返回 fileId 和元数据
  And 客户端可通过 GET /api/media/{fileId}/stream 播放视频（HTTP Range 流媒体）

Scenario: 抖音视频转录
  Given 用户粘贴有效抖音链接
  When 用户点击「下载」
  Then 下载完成后调用 AI 转录
  And 生成 SRT 字幕文件，可通过 GET /api/media/{fileId}/subtitle 获取
  And 转录准确率 ≥ 80%（人工抽样 100 条对比，抽样测试，非自动化 CI）

Scenario: 无效链接被拒绝
  Given 用户粘贴 "https://weibo.com/status/123456"
  When 用户点击「解析」
  Then 显示 "Unsupported URL format" 错误
  And 不发送网络请求
```

---

### P1-06 网盘资源导入

**INVEST 评估**：独立模块，但依赖第三方网盘平台的 OAuth 授权和 API，存在外部依赖风险。

#### 前置条件
- 用户设备上已安装目标网盘 App（或可通过网页版授权）
- 后端已配置百度网盘 Open API 的 `app_key` 和 `secret_key`
- 用户已登录

#### 主流程

1. 用户点击「网盘导入」→ 底部 Sheet 列出支持的平台：百度网盘、夸克网盘
2. 用户选择平台 → 打开 `webview_flutter` 全屏加载网盘网页版 OAuth 授权页
3. 用户在 WebView 中完成授权登录
4. 授权成功后，WebView 中显示文件选择器，用户选择文件
5. 通过 JavaScript Channel 将文件信息（文件名、大小、下载链接）回传给 Flutter
6. 客户端调用 `POST /api/video/download-from-cloud { platform, downloadUrl, fileName }`
7. 后端代理下载文件到服务器本地
8. 下载完成后返回 `{ localVideoPath, localSubtitlePath }`
9. 下载进度通过 SSE 推送
10. 完成后自动加入媒体库

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| OAuth 授权失败 | 用户在 WebView 中取消授权 | 关闭 WebView，返回导入页面，不报错 |
| 文件超过 2GB | 用户选择 3GB 的视频 | 提示 "File too large (>2GB). Please download to your device first, then import locally." |
| 网盘 API 限流 | 短时间内多次下载 | 第 2 次请求排队，提示 "Download queued. Estimated wait: 5 minutes." |
| 下载链接过期 | 网盘生成的临时下载链接已过期 | 提示 "Download link expired. Please re-authorize and select the file again." |
| 不支持的文件类型 | 用户选择 `.pdf` 文件 | 提示 "Unsupported file type. Supported: MP4, MKV, WEBM, MOV, AVI, MP3, M4A, WAV, OGG, FLAC, AAC, SRT, VTT, ASS, SSA" |

#### 验收标准

```gherkin
Scenario: 百度网盘 OAuth 授权
  Given 用户选择「百度网盘」
  When 打开 WebView 授权页
  Then 显示百度网盘登录页面
  And 用户完成登录后显示文件选择器
  And 用户选择 test.mp4 后，WebView 关闭
  And 客户端获取到文件信息

Scenario: 后端代理下载
  Given 客户端发送百度网盘文件下载链接
  When 调用 POST /api/video/download-from-cloud
  Then 后端开始下载文件
  And SSE 推送下载进度（百分比）
  And 下载完成后文件存在于服务器磁盘
```

---

### P1-07 固定搭配识别

**INVEST 评估**：独立模块，本地词典匹配可单独测试，AI 增强部分依赖后端。

#### 前置条件
- 字幕已加载
- `shared_db/assets/collocations.json` 文件存在且格式正确，包含 ≥ 2000 条 `{ "text": "look after", "type": "phrasalVerb", "meaning": "照顾" }` 记录（位于 `shared_db` package，所有插件共享）
- 后端 AI 服务可用（用于 AI 增强检测，非必需）

#### 主流程

1. 字幕加载完成后，对每条 cue 的 `text` 执行双层检测：

**检测期间 UI 状态**
1a. 字幕已显示，搭配面板（Collocation Panel）显示 shimmer loading 骨架屏
1b. 搭配面板顶部显示 "Detecting collocations..." 状态文字
1c. 字幕中的已识别搭配实时高亮（边检测边渲染），「添加到闪卡」按钮在检测完成前灰化

**第一层：本地词典匹配（离线）**
2. 将 cue.text 分词为单词列表
3. 对 2-5 词窗口进行 n-gram 扫描
4. 每个 n-gram 查 `collocationsMap`（以 lowercased 文本为 key 的 HashMap）
5. 命中 → 创建 `Collocation` 对象，标记 `aiDetected=false`

**第二层：AI 增强检测（在线）**
6. 本地词典未覆盖的句子 → 发送到 `POST /api/ai/detect-collocations`
7. 后端调用 Gemini 2.0 Flash，prompt 要求返回 JSON 格式的搭配列表
8. AI 返回结果 → 合并到本地结果 → 写入本地缓存
9. 同一句子（`md5(cue.text)`）的 AI 结果缓存 24 小时

10. 字幕渲染时，匹配到的搭配以对应颜色下划线标记：
    - 动词短语：金色 `#F59E0B`
    - 介词搭配：橙色 `#F97316`
    - 名词搭配：青绿色 `#14B8A6`
    - 形容词搭配：浅蓝 `#0EA5E9`
    - 习语：紫色 `#A855F7`
11. 点击搭配 → 弹出 Popover 显示释义和例句
12. 搭配面板展示当前字幕中检测到的所有搭配，支持按类型筛选

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 词典文件缺失 | `collocations.json` 不存在 | 本地检测不可用，仅依赖 AI 检测（需网络） |
| AI 服务不可用 | 后端 AI 代理全部降级失败 | 仅使用本地词典结果，搭配面板显示 "AI detection unavailable" |
| 搭配重叠 | "look after" 和 "after my" 同时匹配 | 取最长匹配（"look after"），较短匹配忽略 |
| 同一搭配多次出现 | "look after" 在同一字幕中出现 2 次 | 每个位置独立标记，不合并 |
| 中文句子误检测 | 字幕为中文 | 检测到 CJK 字符比例 ≥ 50% 时跳过检测 |

#### 验收标准

```gherkin
Scenario: 本地词典匹配搭配
  Given 词典包含 {"text":"look after","type":"phrasalVerb","meaning":"照顾"}
  And 字幕为 "I need to look after my sister"
  When 执行 collocation detection
  Then 返回 1 个 Collocation
  And text="look after", type=phrasalVerb, meaning="照顾", aiDetected=false

Scenario: 字幕中搭配高亮
  Given 检测到搭配 "look after"
  When 渲染字幕 "I need to look after my sister"
  Then "look after" 以金色 (#F59E0B) 下划线高亮
  And 点击 "look after" 弹出 Popover 显示 "照顾"

Scenario: AI 检测作为补充
  Given 本地词典未覆盖 "take the plunge"
  And 字幕为 "I decided to take the plunge"
  And 后端 AI 服务可用
  When 执行 collocation detection
  Then AI 返回 "take the plunge" 为 idiom
  And 结果缓存到本地，相同句子 24h 内不再请求 AI

Scenario: AI 不可用时降级
  Given 后端 AI 服务不可用
  And 字幕为 "I decided to take the plunge"
  When 执行 collocation detection
  Then 仅返回本地词典匹配结果
  And 显示 "AI detection unavailable" 提示
```

---

### P1-08 AI 功能

**INVEST 评估**：独立模块，后端代理设计使前端无需关心 AI 提供商细节，可单独测试每个 AI 任务。

#### 前置条件
- 后端服务已启动
- 后端环境变量已配置：`OLLAMA_BASE_URL`（可选，默认 `http://localhost:11434`）、`OLLAMA_MODEL`（可选，默认 `llama3.2`）、`GEMINI_API_KEY`（可选，无 Ollama 时必选）、`GROQ_API_KEY`（可选）、`DEEPSEEK_API_KEY`（可选）
- 后端 `ai_cache` 表已创建
- 用户已登录

#### 主流程

**翻译任务 (`POST /api/ai/translate`)**
1. 用户点击字幕中的「翻译」按钮
2. 客户端发送 `{ text: "原文", sourceLang: "en", targetLang: "zh" }`
3. 后端检查缓存：`cacheKey = md5("translate" + text)`，命中则直接返回
4. 未命中 → 按降级链调用 AI（Ollama → Gemini 2.0 Flash → DeepSeek-V3 → Groq），prompt: "Translate the following English text to Chinese. Keep the original tone and style. Only return the translation."
5. 返回 `{ translation: "译文", cached: false }`，写入缓存

**固定搭配提取 (`POST /api/ai/detect-collocations`)**
1. 字幕加载时自动触发
2. 客户端发送 `{ text: "原文" }`
3. 后端检查缓存后按降级链调用 AI（Ollama → Gemini 2.0 Flash → DeepSeek-V3 → Groq），要求返回结构化 JSON：
   ```json
   [{ "text": "look after", "type": "phrasalVerb", "meaning": "照顾" }]
   ```
4. 返回搭配列表

**造句填空生成 (`POST /api/ai/generate-cloze`)**
1. 用户将搭配添加到闪卡时触发
2. 客户端发送 `{ collocation: "look after", originalSentence: "I need to look after my sister" }`
3. 后端按降级链调用 AI（Ollama → Gemini 2.0 Flash → DeepSeek-V3 → Groq），要求生成填空句：
   ```json
   { "clozeSentence": "I need to ______ my sister", "hint": "照顾" }
   ```
4. 返回填空句和提示

**降级策略**
1. 首选 Ollama 本地模型（如已配置 `OLLAMA_BASE_URL`，默认 `http://localhost:11434`，模型名通过 `OLLAMA_MODEL` 配置，默认 `llama3.2`）
2. Ollama 不可达 → 降级到 Gemini 2.0 Flash（1500 req/day 免费）
3. 失败 → 重试 1 次
4. 仍失败 → 降级到 DeepSeek-V3（如已配置 API Key）
5. 仍失败 → 降级到 Groq（如已配置 API Key）
6. 全部失败 → 返回 `{ error: "AI_SERVICE_UNAVAILABLE" }`

> **注意**：Ollama 仅用于文本类任务（翻译、搭配检测、造句生成），不用于 Whisper 音频转录——本地 Whisper 模型质量不稳定，转录仍走 Groq。Groq 排在云端最后，优先将 Groq 免费额度留给 P1-05 的 Whisper 转录任务。

**Ollama 对接方式**：
- Ollama 原生支持 OpenAI 兼容的 `/v1/chat/completions` 端点（v0.5.0+），无需额外适配层
- 后端使用 `httpx` 或 `openai` Python SDK（`base_url` 指向 `http://localhost:11434/v1`）
- 调用前先 `GET /api/tags` 检查目标模型是否已拉取，未拉取则跳过 Ollama 并记日志
- 模型名可配置：`OLLAMA_MODEL` 环境变量（默认 `llama3.2`，用户可改为 `qwen2.5:7b`、`gemma3:4b` 等）

**Groq 配额优先级实现机制**：
- 后端维护全局标志 `transcription_in_progress: bool`（存储于内存，服务重启后重置为 `false`）
- 转录任务（`POST /api/video/download` 中的 Whisper 步骤）开始时设为 `true`，结束时设为 `false`
- 翻译/搭配检测/造句生成的降级逻辑在切换到 Groq 前检查此标志：若 `transcription_in_progress=true`，跳过 Groq（不调用），直接返回 `AI_SERVICE_UNAVAILABLE`
- 若翻译先于转录获得 Groq 配额（`transcription_in_progress=false`），翻译正常使用 Groq；转录任务到达时，翻译已占用 Groq 的本次请求不受影响，转录可正常发起新请求（Groq 免费层通常允许并发请求）

**缓存策略**
- `cacheKey = md5(taskType + ":" + inputText)`
- 过期时间：24 小时
- 存储于 `ai_cache` 表

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 所有 AI 提供商不可用 | API Key 全部失效或超限 | 返回 `error: "AI_SERVICE_UNAVAILABLE"`，前端显示 "AI is temporarily unavailable" |
| 输入超长 | 翻译文本 > 5000 字符 | 返回 400，提示 "Input text too long. Maximum 5000 characters." |
| AI 返回格式错误 | Gemini 返回非 JSON 格式 | 重试 1 次，仍失败则返回 `error: "AI_RESPONSE_PARSE_ERROR"` |
| 并发请求过多 | 同一用户 1 秒内发送 10 个请求 | 仅处理前 3 个，其余返回 429 "Too many requests" |
| 缓存命中 | 24h 内相同文本再次请求翻译 | 直接返回缓存结果，不消耗 API 额度 |

#### 验收标准

```gherkin
Scenario: Ollama 本地翻译
  Given 后端 Ollama 可用（OLLAMA_BASE_URL=http://localhost:11434, OLLAMA_MODEL=llama3.2）
  When 用户请求翻译 "Hello, how are you?"
  Then 3 秒内返回中文翻译
  And 不消耗任何云端 API 额度

Scenario: Ollama 不可达自动降级
  Given 后端 Ollama 不可达
  And Gemini API 可用
  When 用户请求翻译 "Hello"
  Then 自动降级到 Gemini 并返回翻译结果
  And 前后端日志记录 "ollama unreachable, fell back to gemini"

Scenario: 翻译英文字幕
  Given 后端 AI 服务可用
  When 用户请求翻译 "Hello, how are you?"
  Then 3 秒内返回中文翻译
  And 翻译结果包含目标语言文本，非空且字符数 ≥ 原文字符数 × 0.3（基础完整性校验，不评估语义质量）
  And 翻译结果被缓存，再次请求相同文本时 cached=true

Scenario: 固定搭配 AI 提取
  Given 后端 Gemini API 可用
  When 用户请求检测 "I need to look after my sister"
  Then 返回包含 "look after" 的搭配列表
  And 每个搭配包含 type 和 meaning 字段

Scenario: AI 降级流程
  Given Gemini API 返回 429（超限）
  And Groq API 已配置且可用
  When 用户请求翻译
  Then 自动降级到 Groq
  And 返回翻译结果

Scenario: 缓存命中不消耗额度
  Given 翻译 "Hello" 的结果已缓存
  When 再次请求翻译 "Hello"
  Then 3 秒内返回结果
  And 不调用任何外部 AI API
```

---

### P1-09 Anki 风格闪卡

**INVEST 评估**：独立模块，可单独测试 SM-2 算法和 CRUD 操作。

#### 前置条件
- 用户已登录（离线时仍可操作本地数据）
- 本地 drift 数据库 `flashcards` 和 `flashcard_reviews` 表已创建
- 固定搭配检测已完成（生成闪卡的来源）

#### 主流程

**创建闪卡**
1. 用户在搭配面板或字幕中点击「添加到闪卡」
2. 客户端尝试调用 `POST /api/ai/generate-cloze` 生成造句填空。若 AI 不可用（网络错误或独立运行模式），自动降级为模板生成：将原句中搭配替换为 `______`，`aiGenerated` 标记为 `false`。降级后闪卡详情页显示「Regenerate with AI」按钮，联网后用户可点击重新生成
3. 创建 `Flashcard` 对象：
   - `frontText`: AI 生成的填空句
   - `frontHint`: 中文提示
   - `backAnswer`: 搭配文本
   - `backMeaning`: 释义
   - `backOriginal`: 原始句子
   - `mediaFilePath`: 当前媒体文件路径（本地创建时使用）
   - `mediaFileId`: 服务端媒体文件 ID（Anki 导入或在线视频导入时使用，外键指向 `video_sources`，与 `mediaFilePath` 二选一）
   - `mediaTime`: 当前播放时间戳
   - `cueId`: 原字幕 ID
   - `sourceTitle`: 媒体文件名
   - `aiGenerated`: true（AI 路径）/ false（手动路径）
4. 保存到本地 drift，同步到后端
5. 支持手动创建：用户输入搭配和原句，系统生成填空。手动创建的闪卡 `mediaFilePath`=null, `mediaTime`=null, `cueId`=null, `aiGenerated`=false，复习时不显示「播放原音频」按钮，仅显示「跳转到字幕原句」按钮（也因 `cueId` 为空而灰化）

**复习流程**
6. 用户打开「闪卡复习」页面
7. 查询 `nextReviewAt <= NOW()` 的卡片，按到期时间排序
8. 显示卡片正面：填空句 + 提示 + "显示答案" 按钮
9. 用户点击「显示答案」→ 翻转动画 → 显示背面：答案 + 释义 + 原句 + 来源 + 播放按钮 + 跳转按钮
10. 用户点击评分按钮：
    - [忘记了](rating=0) → `interval = 0, easeFactor = max(1.3, easeFactor - 0.2), nextReviewAt = now + 1d`
    - [困难](rating=1) → `interval = max(1, interval * 0.5), easeFactor = max(1.3, easeFactor - 0.15), nextReviewAt = now + interval days`
    - [良好](rating=2) → `interval = interval == 0 ? 1 : interval == 1 ? 3 : interval * easeFactor, nextReviewAt = now + interval days`
    - [简单](rating=3) → `interval = interval == 0 ? 1 : (interval + 1) * easeFactor * 1.3, easeFactor += 0.15, nextReviewAt = now + interval days`
11. 保存 `FlashcardReview(id, flashcardId, rating, reviewedAt)` 到本地
12. 自动展示下一张卡片

**原音频回放**
13. 点击「播放」按钮 → 按优先级检查：`mediaFileId` 非空 → 通过 `GET /api/media/{mediaFileId}/stream` 流式播放；否则检查 `mediaFilePath` 是否可访问
14. `mediaFileId` 路径：使用 `just_audio` 加载 HTTP 流 URL，播放 `mediaTime ± 5s` 的音频片段（通过 Range 请求）
15. `mediaFilePath` 路径：使用 `just_audio` 播放 `mediaTime ± 5s` 的本地音频片段
16. 两者均不可访问 → 提示 "Original media file not found"

**闪卡管理**
17. 卡片列表支持按创建时间、下次复习时间、来源排序
18. 支持筛选：按搭配类型、来源视频
19. 支持批量从收藏夹转为闪卡，按收藏类型应用映射规则：
   - **type=word**：调用 AI 生成例句 + 填空（`POST /api/ai/generate-cloze`），fallback 为 `______` + 释义
   - **type=phrase**：直接作为 `backAnswer`，`frontText` = 将原句中搭配替换为 `______`（需有 `context` 字段）
   - **type=sentence**：提示用户选择句子中的目标搭配，不支持全句直接转换
   - 批量转换时逐条应用上述规则，失败的单条跳过并记录到 `errors` 列表
20. 支持删除/归档已掌握的卡片

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| AI 造句生成失败 | 后端 AI 不可用 | 使用模板生成填空：将原句中搭配替换为 `______`，`aiGenerated` 标记为 `false`。闪卡详情页显示「Regenerate with AI」按钮，联网后用户可点击重新生成，更新 `frontText` 并设置 `aiGenerated=true`，保留 `reviewCount` 和 `easeFactor` 不变 |
| 原媒体文件丢失 | 复习时 mediaFilePath 指向的文件不存在 | 显示 "Original media not available"，仅展示文本信息 |
| 原媒体文件被替换 | 文件路径存在但 `mediaFileHash`（MD5 前 1MB）不匹配，或 `mediaFileSize` 不一致 | 显示 "Media file may have been replaced. Original audio may be inaccurate." + 提供「跳转到字幕原句」降级方案 |
| 跨设备媒体路径不可达 | 数据从 PC 同步到手机，mediaFilePath 指向 PC 路径（如 `/home/user/videos/`） | 检测路径前缀不匹配当前平台 → 显示 "Media file stored on another device (PC). Transfer the file to this device to resume playback." 同时在 `video_sources` 表增加 `original_device_id` 字段标记来源设备 |
| 今日无到期卡片 | 所有卡片的 nextReviewAt > 今天 | 显示 "No cards due today. Next review: YYYY-MM-DD" |
| 快速连续评分 | 用户在 200ms 内点击两次评分按钮 | 防抖处理，忽略第二次点击 |
| 闪卡数量为 0 | 用户首次使用，无卡片 | 显示引导页 "Create your first flashcard from collocations you find in subtitles" |

#### 验收标准

```gherkin
Scenario: 从搭配创建闪卡
  Given 检测到搭配 "look after"
  And 原句为 "I need to look after my sister"
  When 用户点击「添加到闪卡」
  Then 生成 frontText="I need to ______ my sister"
  And frontHint="照顾"
  And backAnswer="look after"
  And backMeaning="照顾"
  And backOriginal="I need to look after my sister"
  And nextReviewAt = 当前时间 + 1 天

Scenario: SM-2 间隔推进
  Given 一张闪卡 interval=1, easeFactor=2.5, reviewCount=0
  When 用户评分「良好」(rating=2)
  Then interval=3, easeFactor=2.5(不变), reviewCount=1, nextReviewAt=当前时间+3天
  When 用户再次评分「良好」(rating=2)
  Then interval=7.5(3*2.5), nextReviewAt=当前时间+7.5天

Scenario: 「忘记了」重置间隔
  Given 一张闪卡 interval=7, easeFactor=2.5, reviewCount=3
  When 用户评分「忘记了」(rating=0)
  Then interval=0, easeFactor=2.3, nextReviewAt=当前时间+1天

Scenario: 原音频回放
  Given 闪卡 mediaFilePath 指向有效视频文件，mediaTime=30.0
  When 用户点击「播放」
  Then 播放音频片段，从 25.0s 到 35.0s（mediaTime 前后各 5s，共 10 秒片段）
  And 播放到 35.0s 后自动停止，或用户手动点击停止
```

#### 子功能：Anki 数据导入

**INVEST 评估**：闪卡模块的子功能，可单独测试文件解析和卡片映射，不依赖其他模块。

##### 前置条件
- 用户已登录
- 用户持有 Anki 导出的文件：`.apkg`（Anki 集合包）或 `.csv`/`.txt`（纯文本导出）
- `.apkg` 文件为 Anki 2.1+ 格式（实质为 zip 包，内含 `collection.anki2` SQLite 数据库 + 媒体文件）
- `.csv` 文件编码为 UTF-8，第一行为列标题，分隔符为逗号或制表符
- 后端 `/api/flashcards/import/anki` 端点可访问

##### 主流程

**方式一：`.apkg` 导入（推荐）**
1. 用户打开闪卡管理页面 → 点击「导入 Anki」
2. 系统弹出文件选择器，过滤 `apkg, colpkg, anki2`
3. 用户选择 `.apkg` 文件 → 客户端读取文件为字节流 → `POST /api/flashcards/import/anki`（multipart/form-data）
4. 后端解析流程：
   a. 解压 zip → 读取 `collection.anki2`（SQLite 数据库）
   b. **线程安全**：整个解析在 `asyncio.to_thread()` 中独立线程执行，使用 `sqlite3.connect(uri, check_same_thread=False)` 打开 Anki 数据库，与主数据库 SQLAlchemy 异步引擎隔离。解析完成后立即关闭连接。
   c. 查询 `col` 表获取牌组信息（`name`, `deck_id`）
   d. 查询 `notes` 表获取笔记数据（`id`, `guid`, `mid`, `mod`, `flds`, `tags`）
   e. 查询 `cards` 表获取卡片数据（`id`, `nid`, `ord`, `mod`, `type`, `queue`, `due`, `factor`, `reps`）
   f. 根据 `mid` 查询 `notetypes` 表获取笔记模板的字段名称
   g. 将 `flds`（以 `\x1f` 分隔的字段值）按模板映射为字段名
   h. 提取每个卡片的正面（`ord=0` 字段）和背面（`ord=1` 字段）
   i. 提取媒体文件：遍历 zip 中非数据库文件，拷贝到服务器媒体目录
5. 后端返回解析结果预览：
   ```json
   {
     "deckName": "English::Phrasal Verbs",
     "totalCards": 150,
     "preview": [
       { "front": "look ____ my sister", "back": "look after", "noteType": "Cloze" },
       { "front": "give up", "back": "放弃", "noteType": "Basic" }
     ],
     "mediaFiles": ["look_after.mp3", "give_up.jpg"]
   }
   ```
6. 用户确认导入 → 后端执行映射：
   - Anki 正面 → `frontText`
   - Anki 背面 → `backAnswer` + `backMeaning`
   - 若 Anki 字段包含 `{{cloze:...}}` 模板 → 解析为填空句 + 答案
   - Anki 标签 → 保留到 `tags` 字段
   - Anki 复习历史（`reps`, `factor`, `due`）→ **Phase 1 不保留**。Anki 使用修改版 SM-2 算法（含 `lapses`、`lastIvl`、`odue` 等字段），与本系统简化 SM-2 不可直接映射。导入后所有卡片 `reviewCount=0`, `easeFactor=2.5`（默认值）, `nextReviewAt=当天`，用户需重新开始复习。Phase 2 可考虑完整实现 Anki 的 SM-2 变体以支持历史迁移。
   - 媒体文件 → 存入 `video_sources` 表，返回 `fileId`。闪卡不直接存储服务端路径，而是存储 `mediaFileId`（外键指向 `video_sources`）。复习时通过 `GET /api/media/{fileId}/stream` 流式播放音频，与 P1-05 在线视频播放路径一致，客户端无需二次下载
7. 导入完成后，返回 `{ importedCount: 150, skippedCount: 0, errors: [] }`
8. 客户端刷新闪卡列表，导入的卡片立即可用

**方式二：`.csv` / `.txt` 导入**
9. 用户选择 `.csv` 或 `.txt` 文件
10. 客户端读取文件内容 → 检测编码（UTF-8/GBK）→ 检测分隔符（逗号/制表符）
11. 显示预览表格：用户指定哪一列对应「正面」、哪一列对应「背面」、哪一列对应「标签」（可选）
12. 用户确认列映射 → 客户端发送 `POST /api/flashcards/import/csv`：
    ```json
    {
      "cards": [
        { "frontText": "look ____ my sister", "backAnswer": "look after", "backMeaning": "", "tags": "phrasal-verb" }
      ]
    }
    ```
13. 后端批量创建闪卡 → 返回导入结果

##### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 非 Anki 格式的 apkg | 用户选择伪造的 `.apkg`（不含 `collection.anki2`） | 后端解压后验证失败，返回 400 "Invalid Anki package: collection.anki2 not found" |
| Anki 版本过旧 | Anki 1.x 格式的 `.apkg`（schema 不同） | 后端检测 schema 版本，返回 400 "Unsupported Anki version. Please use Anki 2.1+ to export." |
| apkg 文件过大 | `.apkg` > 200MB（含大量媒体） | 返回 413 "File too large. Maximum 200MB. Try exporting without media files." |
| 卡片重复 | 导入的卡片与已有卡片相同（`frontText` + `backAnswer` 均一致） | 跳过该卡片，`skippedCount + 1`，不创建重复记录 |
| CSV 编码检测失败 | GBK 编码的 CSV 但检测为 UTF-8 导致乱码 | 尝试 UTF-8 → 检测到乱码（ 字符）→ 回退 GBK 解码 → 仍失败则提示用户手动选择编码 |
| CSV 列映射不完整 | 用户未指定「正面」列就点击确认 | 提示 "Please map the Front field to a column" |
| 媒体文件路径冲突 | 两个 Anki 牌组包含同名媒体文件 | 导入时在文件名加 `_import_{timestamp}` 后缀避免覆盖 |
| 复习历史映射失败 | Anki 卡片 `due` 字段为无效日期 | 该卡片复习历史不导入，`nextReviewAt` 设为当天，`reviewCount=0` |

##### 验收标准

```gherkin
Scenario: 导入 Anki .apkg 文件
  Given 用户持有 Anki 导出的 english_phrasal_verbs.apkg（含 50 张卡片、10 个媒体文件）
  When 用户选择该文件并确认导入
  Then 后端解析成功，返回 { importedCount: 50, skippedCount: 0 }
  And 闪卡列表新增 50 张卡片
  And 每张卡片的 frontText 和 backAnswer 与原 Anki 卡片一致
  And 10 个媒体文件可正常播放

Scenario: 导入含填空模板的 Anki 卡片
  Given Anki 卡片使用 Cloze 模板，正面为 "{{c1::look after}} my sister"
  When 导入完成
  Then 生成的闪卡 frontText="look ______ my sister"
  And backAnswer="look after"
  And reviewCount=0, easeFactor=2.5, nextReviewAt=当天（Phase 1 不保留 Anki 复习历史）

Scenario: 导入 CSV 文件
  Given 用户持有 cards.csv，内容为 "Front,Back,Tags\nlook ____ my sister,look after,phrasal-verb"
  When 用户选择文件，指定 Front 列映射到正面，Back 列映射到背面
  Then 导入 1 张闪卡
  And frontText="look ____ my sister", backAnswer="look after", tags="phrasal-verb"

Scenario: 重复卡片跳过
  Given 闪卡列表中已存在 frontText="look after", backAnswer="照顾" 的卡片
  And 导入的 .apkg 中包含一张相同内容的卡片
  When 导入完成
  Then 返回 { skippedCount: 1 }
  And 总卡片数不变

Scenario: 无效 Anki 文件拒绝
  Given 用户选择 fake.apkg（不含 collection.anki2）
  When 提交导入
  Then 返回 400 错误
  And 提示 "Invalid Anki package"
```

---

### P2-01 数据同步

**INVEST 评估**：独立模块，但依赖所有数据表，需在其他模块完成后实现。

#### 前置条件
- 用户已登录，持有有效 JWT Token
- 后端 `/api/sync/push` 和 `/api/sync/pull` 端点可访问
- 客户端本地 drift 数据库已初始化

#### 主流程

1. App 启动 → 登录成功后 → 触发同步
2. **推送本地变更（先 push）**：`POST /api/sync/push`，body 包含 `lastSyncedAt` 之后本地变更的所有记录
   - 确保本地离线修改先写入云端，避免被云端旧数据覆盖
3. **拉取云端数据（后 pull）**：`GET /api/sync/pull?since={lastSyncedAt}`
   - 后端返回 `lastSyncedAt` 之后所有已变更的记录（包括刚刚 push 的），按表分组
4. 客户端合并：逐表逐条处理
   - 本地无此记录 → 插入
   - 本地有且云端 `updatedAt` > 本地 `updatedAt` → 更新
   - 本地有且本地 `updatedAt` > 云端 `updatedAt` → 保留本地（刚 push 的记录不会被覆盖）
   - 两端 `updatedAt` 相等 → 跳过
5. 客户端记录服务端返回的 `serverGeneration`（单调递增整数），存入本地 `sync_status` 表
6. 更新 `sync_status.last_synced_at`
7. 定期同步：每 5 分钟自动触发一次（App 在前台时），同样遵循先 push 后 pull 顺序

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 同步时网络中断 | 推送过程中 Wi-Fi 断开 | 已推送成功的部分不回滚，失败部分下次同步重试 |
| 大量数据首次同步 | 用户在新设备登录，云端有 10000+ 条记录 | 分页拉取，每页 500 条，显示同步进度 |
| 同步冲突 | 同一收藏在手机和电脑上分别修改了 CEFR 等级 | 以 `updatedAt` 较新的版本为准 |
| 服务端数据回滚 | 客户端 pull 时携带的 `serverGeneration` 与服务端当前值不匹配（差距 > 客户端预期） | 服务端返回 `409 Conflict` + `{ serverGeneration, clientGeneration }`，客户端弹出选择框 "Server data has been modified externally. [Keep Local] [Replace with Server] [Cancel]" — Phase 1 不提供逐条合并，用户选择全量替换或保留本地 |
| 同步过程中退出登录 | 用户点击退出 | 等待当前同步操作完成，不再触发新的同步 |

#### 验收标准

```gherkin
# 集成测试（需启动后端服务 + 数据库）
Scenario: 首次同步拉取云端数据
  Given 用户在新设备登录，云端有 10 条收藏
  And 后端服务 `/api/health` 返回 200
  When 同步完成
  Then 本地 drift 数据库 favorites 表包含 10 条记录
  And 每条记录的 id 和内容字段与云端一致（id 集合相同，text/context/cefr_level 等字段值相等，updatedAt 允许微小偏差）

Scenario: 离线修改后同步
  Given 用户离线时收藏了 1 个单词
  When 网络恢复，触发同步
  Then 云端 favorites 表新增 1 条记录
  And 内容与本地一致

Scenario: 冲突解决
  Given 同一收藏在本地 updatedAt=10:00，云端 updatedAt=10:05
  When 同步合并
  Then 以云端版本为准（updatedAt 更新）
```

---

### P2-02 设置

**INVEST 评估**：独立模块，可单独测试。

#### 前置条件
- `shared_preferences` 已初始化

#### 主流程

1. 用户点击设置图标 → 进入设置页面
2. 设置项：
   - **界面语言**：下拉选择 en / zh，切换后即时生效
   - **CEFR 显示等级**：多选 Chip（A1-C2），默认全选，取消选中某等级后字幕中不再着色该等级词汇
   - **后端地址**：文本输入框，格式 `http://host:port`，保存后重新连接
   - **清除本地数据**：按钮，点击后弹出确认对话框，明确告知 "This will only clear local cache. Cloud data is unaffected and will be restored on next sync." 确认后清除所有 drift 表和 shared_preferences，同时将 `lastSyncedAt` 重置为 0（下次同步将拉取全量云端数据）
3. 所有设置变更即时写入 `shared_preferences`

#### 验收标准

```gherkin
Scenario: 切换界面语言
  Given 当前语言为 English
  When 用户选择「中文」
  Then 首页、设置页、播放器控制栏、字幕面板的 UI 文本切换为中文（覆盖 4 个关键页面）
  And 设置保存在 shared_preferences，重启后保持

Scenario: 取消 CEFR 等级显示
  Given 所有等级都选中
  When 用户取消选中 A1
  Then 字幕中 A1 词汇不再着色，其他等级正常着色

Scenario: 修改后端地址
  Given 当前后端地址为 http://192.168.1.100:8000
  When 用户输入新的后端地址 http://192.168.1.200:8000 并保存
  Then 客户端断开旧连接
  And 对新地址发起 GET /api/health
  And 若返回 200 则提示 "Connected"
  And 若连接失败则提示 "Unable to connect. Please check the address."

Scenario: 清除本地数据
  Given 本地 drift 数据库 favorites 表有 10 条记录
  And sync_status.lastSyncedAt 为 2025-01-01T00:00:00Z
  When 用户点击「清除本地数据」并确认
  Then 所有 drift 业务表（favorites/flashcards/flashcard_reviews/collocations_cache）行数为 0
  And sync_status.lastSyncedAt 重置为 0
  And shared_preferences 中所有非认证相关键值被清除
  And 弹出提示 "Local data cleared. Cloud data will be restored on next sync."
```

---

### P2-03 响应式设计

**INVEST 评估**：横切关注点，贯穿所有 UI 模块。

#### 前置条件
- 所有页面使用 `LayoutBuilder` 获取可用宽度
- 断点定义：compact(<600dp), medium(600-840dp), expanded(≥840dp)

#### 主流程

1. **compact（手机竖屏）**：
   - 单列布局，内容全宽
   - 底部 `NavigationBar` 导航（字幕/词汇/收藏/闪卡）
   - 视频固定在顶部，自适应宽度
   - 弹窗使用 `BottomSheet`
   - 输入框字体 ≥16sp

2. **medium（平板/手机横屏）**：
   - 视频左侧，面板右侧（320dp），使用 `Row`
   - 底部导航保留

3. **expanded（桌面）**：
   - 视频居中，最大宽度 1200dp
   - 右侧面板 320dp–480dp，使用 `TabBar` 切换
   - 左侧 Sidebar 导航
   - 键盘快捷键全部可用，完整清单如下：

| 快捷键 | 作用 | 处理模块 |
|--------|------|---------|
| `Space` | 播放/暂停 | 播放器 |
| `←` | 跳转到上一句字幕 + seek | 字幕模块 |
| `→` | 跳转到下一句字幕 + seek | 字幕模块 |
| `↑` | 上一句字幕（不 seek，仅浏览） | 字幕模块 |
| `↓` | 下一句字幕（不 seek，仅浏览） | 字幕模块 |
| `Ctrl+F` | 字幕搜索 | 字幕模块 |
| `Escape` | 关闭弹窗/退出搜索 | 全局 |

#### 验收标准

```gherkin
Scenario: 手机竖屏布局
  Given 设备宽度 < 600dp
  When 打开 App
  Then 底部显示 NavigationBar
  And 视频占满屏幕宽度
  And 内容区域为单列布局

Scenario: 桌面布局
  Given 设备宽度 ≥ 840dp
  When 打开 App
  Then 左侧显示 Sidebar 导航
  And 右侧显示面板（字幕/词汇/收藏 TabBar）
  And 按 Space 暂停/播放
  And 按 ← 跳转到上一句字幕并 seek
  And 按 → 跳转到下一句字幕并 seek
```

---

## 3. 非功能性需求

### 3.1 性能

| 指标 | 目标值 | 测试条件 |
|------|--------|---------|
| 媒体文件加载（视频首帧） | ≤ 1000ms | 720p H.264 MP4，设备 iPhone 12 / 骁龙 8 Gen2 同级 |
| 媒体文件加载（音频开始） | ≤ 500ms | 128kbps MP3 |
| 字幕解析（SRT, 1000条） | ≤ 200ms | 客户端 Dart 解析 |
| 字幕解析（ASS, 1000条） | ≤ 500ms | 客户端 Dart 解析 |
| CEFR 词汇检测（单句，50词） | ≤ 50ms | 5000 词词典 |
| 固定搭配本地检测（单句，20词） | ≤ 5ms | 2000 条搭配词典 |
| 打字评分计算 | ≤ 10ms | 单句 100 字符 |
| AI 翻译请求 P99 | ≤ 5000ms | 含第三方 API 网络延迟 |
| AI 翻译请求 P50 | ≤ 2000ms | 含第三方 API 网络延迟 |
| 视频链接解析 | ≤ 3000ms | yt-dlp 网络请求 |
| 视频下载吞吐量 | ≥ 1MB/s | 100Mbps 带宽 |
| 数据同步（100条记录） | ≤ 5000ms | 局域网环境 |
| 闪卡复习翻页 | ≤ 200ms | 卡片翻转动画 |
| 页面切换 | ≤ 300ms | go_router 导航 |
| 后台同步间隔 | 300s | App 在前台 |

### 3.2 安全

| 要求 | 实现方式 |
|------|---------|
| 密码存储 | bcrypt 哈希，cost factor=12，不存储明文 |
| JWT Token | HS256 签名，access_token 有效期 24h，refresh_token 有效期 30d |
| API 认证 | 所有 `/api/*` 端点（除 auth）需 `Authorization: Bearer <token>` |
| AI API Key 保护 | 存储在后端环境变量，前端不可见，所有 AI 请求通过后端代理 |
| 密码强度 | 客户端校验：≥8 字符，含大小写字母+数字；服务端二次校验 |
| 登录失败限制 | 同一 IP 连续失败 5 次 → 锁定 15 分钟 |
| 数据传输 | 局域网 HTTP（自建 PC），未来公网部署时升级 HTTPS |
| SQL 注入防护 | 使用 SQLAlchemy ORM 参数化查询，禁止拼接 SQL |
| 敏感信息日志 | 不在日志中输出 password、token、API Key |

### 3.3 兼容性

| 维度 | 要求 |
|------|------|
| **操作系统** | iOS 15+, Android 8.0+, HarmonyOS 4.0+, macOS 12+, Windows 10+, Web (Chrome 100+/Safari 16+/Edge 100+) |
| **屏幕尺寸** | 320dp – 2560dp 宽度 |
| **屏幕方向** | 竖屏 + 横屏 |
| **输入方式** | 触摸 + 鼠标 + 键盘 + 外接键盘（iPad） |
| **媒体格式** | 视频：MP4(H.264/H.265), MKV, WEBM, MOV, AVI。音频：MP3, M4A, WAV, OGG, FLAC, AAC |
| **字幕格式** | SRT, VTT, ASS, SSA，编码 UTF-8/GBK/GB2312 |
| **后端 Python** | 3.12+ |
| **Flutter** | 3.x stable channel |
| **AI 提供商** | Ollama 本地（llama3.2，默认），Gemini 2.0 Flash，Groq (Llama 3.3 / Whisper)，DeepSeek-V3 |

---

## 4. 开放问题与风险

### 4.1 待确认项

| 编号 | 问题 | 影响 | 建议 |
|------|------|------|------|
| Q-01 | CEFR 词汇 JSON 数据来源？Oxford 3000/5000 还是 Cambridge EVP？ | 词汇检测的准确性和覆盖范围 | 建议使用 Oxford 3000/5000（开源，覆盖广） |
| Q-02 | 固定搭配 JSON 数据来源？ | 搭配检测的覆盖范围 | 需要调研开源搭配词典或自行构建 |
| Q-03 | 百度网盘 Open API 是否支持个人开发者申请？ | 网盘导入功能是否可行 | 需实际申请验证，如不可行则降级为「手动下载后本地导入」 |
| Q-04 | 夸克网盘是否提供公开 API？ | 同上 | 如无 API，仅支持百度网盘或降级为 WebView 手动下载 |
| Q-05 | yt-dlp 对小红书/抖音的支持是否稳定？ | 视频导入的覆盖率 | 需要持续关注 yt-dlp 更新，平台可能随时更改反爬策略 |
| Q-06 | 自建 PC 服务器从外网访问的可行性？ | 用户在外网时能否使用 | 初期仅局域网，外网访问需配置端口转发/DDNS/内网穿透 |
| Q-07 | 是否需要在 Phase 1 就支持多用户？ | 后端架构复杂度 | 建议 Phase 1 仅单用户（或少量用户），数据库已预留 user_id 字段 |
| Q-08 | Anki .apkg 的 Cloze 模板到填空句的映射规则是否足够通用？ | 闪卡导入的准确性 | 需要收集常见 Anki 牌组模板格式，建立映射规则表；复杂模板可降级为「正面=原文，背面=答案」 |

### 4.2 技术风险

| 编号 | 风险 | 概率 | 影响 | 缓解措施 |
|------|------|:--:|:--:|---------|
| R-01 | yt-dlp 被视频平台反爬封锁 | 中 | 高 | 关注 yt-dlp 更新频率，提供降级方案（手动下载本地导入） |
| R-02 | 免费 AI API 变更计费策略 | 中 | 中 | 支持多提供商降级（Ollama 本地 → Gemini → DeepSeek → Groq），Ollama 作为零成本兜底方案 |
| R-03 | Flutter 鸿蒙支持不成熟 | 低 | 中 | 关注 Flutter 鸿蒙适配进度，优先保证 iOS/Android 体验 |
| R-04 | drift 数据库迁移失败导致数据丢失 | 低 | 高 | 每次迁移前自动备份 SQLite 文件，迁移脚本需在测试环境验证 |
| R-05 | 百度网盘/夸克网盘 API 变更或关闭 | 中 | 低 | 网盘导入为辅助功能，主要依赖本地文件导入 |
| R-06 | 音频转录准确率不达标（<80%） | 中 | 中 | 提供手动导入字幕的降级方案，允许用户自行校对 |
| R-07 | SQLite 并发写入瓶颈 | 低 | 低 | 初期单用户场景无问题，多用户时迁移到 PostgreSQL |
| R-08 | Anki .apkg 格式未来版本变更 | 低 | 中 | 关注 Anki 发布说明，解析器按 schema 版本号做兼容分支，优先支持 Anki 2.1.x 稳定版 |
| R-09 | 插件接口设计不够灵活，未来扩展受限 | 中 | 中 | 接口设计遵循开闭原则，新增字段不影响已有插件；Phase 1 后收集反馈迭代 |

### 4.3 技术债

| 编号 | 项目 | 说明 |
|------|------|------|
| TD-01 | 冲突解决策略 | 当前为 last-write-wins，未来可能需要 CRDT 或操作日志 |
| TD-02 | 大文件处理 | 视频文件 > 2GB 时体验不佳，未来可考虑分片下载/流式播放 |
| TD-03 | 离线 AI | 当前 AI 功能依赖网络，Ollama 本地推理已集成（降级链第一优先级），但客户端独立运行模式下仍需后端 Ollama 服务。 |
| TD-04 | 测试覆盖 | 初期优先功能和性能测试，UI 自动化测试和集成测试逐步补充 |
| TD-05 | 国际化 | 当前仅支持中英文，未来可扩展更多语言 |

---

## 附录 A：技术栈

| 层次 | 技术 | 选型理由 |
|------|------|---------|
| 客户端框架 | Flutter 3.x + Dart | 官方支持 iOS、Android、鸿蒙、Web、macOS、Windows |
| 状态管理 | Riverpod 2.x | 编译时安全、可测试、无全局单例 |
| 路由 | go_router | 声明式路由，支持嵌套导航 |
| 本地数据库 | drift（SQLite） | 类型安全、支持迁移、离线可用 |
| HTTP 客户端 | dio | 拦截器、重试、文件上传 |
| 音频播放 | just_audio | 跨平台，支持片段播放 |
| 视频播放 | video_player | Flutter 官方 |
| 文件选择 | file_picker | 跨平台系统文件选择器 |
| WebView | webview_flutter | 网盘 OAuth 授权 |
| 后端框架 | Python 3.12+ + FastAPI | 自动 Swagger 文档、Pydantic 校验、异步 |
| ORM | SQLAlchemy 2.0（异步） | 成熟稳定 |
| 数据库 | SQLite | 零运维，文件级备份 |
| 认证 | JWT + bcrypt | 无状态认证 |
| 视频下载 | yt-dlp | 支持 1000+ 平台 |
| AI SDK | google-generativeai, groq | 免费 AI 提供商 |

## 附录 B：项目结构

```
platform/                              # 仓库根目录
├── shell/                             # 外壳 App（聚合入口）
│   ├── lib/
│   │   ├── main.dart                  # 入口，加载插件注册表
│   │   ├── app.dart                   # MaterialApp + go_router
│   │   ├── registry.dart              # 插件注册表
│   │   └── screens/
│   │       └── home_screen.dart       # 首页：应用网格
│   ├── pubspec.yaml                   # 依赖所有 plugin + shared
│   └── test/
├── plugins/
│   ├── english_listening/             # 英语听力插件
│   │   ├── lib/
│   │   │   ├── plugin.dart            # 实现 PlatformPlugin 接口
│   │   │   ├── standalone.dart        # 独立运行入口
│   │   │   ├── models/                # 数据模型
│   │   │   ├── providers/             # Riverpod 状态管理
│   │   │   ├── screens/               # 页面
│   │   │   ├── widgets/               # 组件
│   │   │   │   ├── player/            # 播放器
│   │   │   │   ├── subtitle/          # 字幕
│   │   │   │   ├── practice/          # 打字练习
│   │   │   │   ├── vocabulary/        # 词汇面板
│   │   │   │   ├── favorites/         # 收藏
│   │   │   │   ├── collocation/       # 固定搭配
│   │   │   │   └── flashcard/         # 闪卡
│   │   │   ├── services/              # 服务层
│   │   │   └── utils/                 # 工具函数
│   │   ├── assets/
│   │   │   └── cefr_vocabulary.json   # CEFR 词典（仅英语听力使用）
│   │   ├── pubspec.yaml
│   │   └── test/
│   ├── flashcards/                    # 闪卡插件（独立）
│   │   ├── lib/
│   │   │   ├── plugin.dart
│   │   │   ├── standalone.dart
│   │   │   ├── models/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── services/
│   │   │       └── anki_parser.dart   # Anki .apkg 解析
│   │   ├── pubspec.yaml
│   │   └── test/
│   └── ...                             # 未来更多插件
├── shared/                            # 共享基础设施
│   ├── shared_auth/                   # 统一认证
│   │   ├── lib/
│   │   │   ├── auth_provider.dart     # 认证状态 + JWT 管理
│   │   │   └── auth_interceptor.dart  # dio 拦截器
│   │   └── pubspec.yaml
│   ├── shared_db/                     # 统一数据层
│   │   ├── lib/
│   │   │   ├── database.dart          # drift 数据库定义
│   │   │   ├── tables/                # 表定义（含 collocations、favorites、flashcards 等共享表）
│   │   │   └── sync_service.dart      # 数据同步
│   │   ├── assets/
│   │   │   └── collocations.json      # 固定搭配离线词典（所有插件共享）
│   │   └── pubspec.yaml
│   └── shared_ui/                     # 统一 UI 组件
│       ├── lib/
│       │   ├── theme.dart             # 主题
│       │   ├── responsive.dart        # 响应式布局
│       │   └── widgets/               # 通用组件
│       └── pubspec.yaml
├── server/                            # Python 后端
│   ├── main.py
│   ├── config.py
│   ├── database.py
│   ├── models/                        # SQLAlchemy 模型
│   ├── schemas/                       # Pydantic 校验
│   ├── routers/                       # API 路由
│   │   ├── auth.py
│   │   ├── favorites.py
│   │   ├── flashcards.py
│   │   ├── sync.py
│   │   ├── video.py
│   │   └── ai.py
│   ├── services/                      # 业务逻辑
│   │   ├── anki_parser.py             # Anki .apkg 解析
│   │   └── ai_service.py              # AI 提供商代理
│   └── middleware/                    # 中间件
├── PLUGIN_SPEC.md                     # 第三方开发者对接规范
├── .env.example
├── start.sh
└── README.md
```

## 附录 C：API 端点汇总

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|:--:|
| POST | `/api/auth/register` | 注册 | ❌ |
| POST | `/api/auth/login` | 登录 | ❌ |
| POST | `/api/auth/refresh` | 刷新 Token | ❌ |
| GET | `/api/auth/me` | 当前用户信息 | ✅ |
| GET | `/api/favorites` | 收藏列表 | ✅ |
| POST | `/api/favorites` | 批量创建/更新收藏 | ✅ |
| DELETE | `/api/favorites/{id}` | 删除收藏 | ✅ |
| GET | `/api/typing-results` | 打字结果 | ✅ |
| POST | `/api/typing-results` | 上传打字结果 | ✅ |
| GET | `/api/ab-history` | AB 循环历史 | ✅ |
| POST | `/api/ab-history` | 上传 AB 历史 | ✅ |
| DELETE | `/api/ab-history/{id}` | 删除 AB 历史 | ✅ |
| POST | `/api/sync/push` | 推送本地变更 | ✅ |
| GET | `/api/sync/pull` | 拉取云端变更 | ✅ |
| POST | `/api/video/parse` | 解析视频链接 | ✅ |
| POST | `/api/video/download` | 下载视频 | ✅ |
| GET | `/api/video/progress/{id}` | 下载进度 | ✅ |
| POST | `/api/video/download-from-cloud` | 网盘下载 | ✅ |
| GET | `/api/collocations` | 搭配列表 | ✅ |
| POST | `/api/collocations/detect` | AI 检测搭配 | ✅ |
| POST | `/api/collocations` | 保存搭配 | ✅ |
| DELETE | `/api/collocations/{id}` | 删除搭配 | ✅ |
| GET | `/api/flashcards` | 闪卡列表 | ✅ |
| POST | `/api/flashcards` | 创建闪卡 | ✅ |
| PUT | `/api/flashcards/{id}` | 更新闪卡 | ✅ |
| DELETE | `/api/flashcards/{id}` | 删除闪卡 | ✅ |
| POST | `/api/flashcards/{id}/review` | 提交复习 | ✅ |
| POST | `/api/ai/translate` | AI 翻译 | ✅ |
| POST | `/api/ai/detect-collocations` | AI 搭配检测 | ✅ |
| POST | `/api/ai/generate-cloze` | AI 造句填空 | ✅ |
| POST | `/api/ai/analyze-grammar` | AI 语法分析 | ✅ |
| POST | `/api/ai/explain-word` | AI 生词解释 | ✅ |
| POST | `/api/flashcards/import/anki` | 导入 Anki .apkg | ✅ |
| POST | `/api/flashcards/import/csv` | 导入 CSV 闪卡 | ✅ |
| GET | `/api/flashcards/import/history` | Anki 导入历史 | ✅ |

## 附录 D：数据库表结构

```sql
-- 用户
users(id TEXT PK, username TEXT UNIQUE, email TEXT UNIQUE, password_hash TEXT, created_at, updated_at)

-- 收藏
favorites(id TEXT PK, user_id FK, type TEXT, text TEXT, context TEXT, cefr_level TEXT, media_time REAL, cue_id TEXT, created_at, updated_at)

-- 打字结果
typing_results(id TEXT PK, user_id FK, cue_id TEXT, expected TEXT, typed TEXT, accuracy REAL, created_at)

-- AB 循环历史
ab_history(id TEXT PK, user_id FK, label TEXT, point_a REAL, point_b REAL, created_at)

-- 固定搭配
collocations(id TEXT PK, user_id FK, type TEXT, text TEXT, meaning TEXT, source_cue_id TEXT, source_text TEXT, ai_detected BOOL, created_at)

-- 闪卡
flashcards(id TEXT PK, user_id FK, front_text TEXT, front_hint TEXT, back_answer TEXT, back_meaning TEXT, back_original TEXT, media_file_path TEXT, media_time REAL, media_file_hash TEXT, media_file_size INT, cue_id TEXT, source_title TEXT, tags TEXT, review_count INT, next_review_at, ease_factor REAL, interval INT, anki_import_id TEXT, created_at, updated_at)

-- 闪卡复习记录
flashcard_reviews(id TEXT PK, flashcard_id FK, rating INT, reviewed_at)

-- 视频来源
video_sources(id TEXT PK, user_id FK, platform TEXT, url TEXT, title TEXT, thumbnail_url TEXT, file_id TEXT, local_video_path TEXT, local_subtitle_path TEXT, original_device_id TEXT, downloaded_at)

-- 同步状态
sync_status(user_id TEXT PK, last_synced_at TEXT, server_generation INT DEFAULT 0)

-- AI 缓存
ai_cache(cache_key TEXT PK, task_type TEXT, input_hash TEXT, response TEXT, created_at, expires_at)

-- Anki 导入日志
anki_import_logs(id TEXT PK, user_id FK, file_name TEXT, source_type TEXT, deck_name TEXT, total_cards INT, imported_count INT, skipped_count INT, errors TEXT, imported_at)
```

## 附录 E：集成平台规划

| 模块 | Phase | 状态 |
|------|-------|------|
| 外壳（Shell） | Phase 1 | 当前文档 |
| 插件对接规范（PLUGIN_SPEC.md） | Phase 1 | 当前文档 |
| 英语听力练习 | Phase 1 | 当前文档 |
| 闪卡系统（Anki-like + Anki 导入） | Phase 1 | 当前文档 |
| 道德系统（习惯打卡） | Phase 2 | 规划中 |
| 英语口语/阅读/写作 | Phase 3 | 规划中 |
| 英文歌学习 | Phase 1 | [PLUGIN_SONGS.md](./PLUGIN_SONGS.md) |
| 新概念英语 | Phase 3 | 规划中 |
| AI 语音控制 | Phase 3+ | 规划中 |
| AI 一键生成插件 | Phase 3+ | 规划中 |

平台约束：每个模块可独立剥离（独立 Flutter package），共享用户系统，模块间数据互通。第三方开发者按 [PLUGIN_SPEC.md](./PLUGIN_SPEC.md) 规范接入。