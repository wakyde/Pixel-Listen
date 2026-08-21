# 英文歌学习插件 · 需求文档

> **Phase 1 | v1**
> 依赖 [DEVELOPMENT_DOCS.md](./DEVELOPMENT_DOCS.md) 中定义的外壳基础设施和 [PLUGIN_SPEC.md](./PLUGIN_SPEC.md) 中定义的插件接口。

---

## 1. 背景与目标

### 1.1 业务价值

**解决的问题**：英语学习者通过听英文歌练听力时，常遇到两个痛点：① 歌词中连读、弱读现象导致"看着歌词认识，听歌时听不出"；② 自己跟唱时无法判断发音是否准确。现有方案要么是纯音乐播放器（无学习功能），要么是通用发音 App（无歌词上下文），无法将"听歌 → 学连读 → 练跟唱 → 评分"串成闭环。

**成功指标**：

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| 歌词文件解析成功率 | ≥ 99% | 自动化测试覆盖 LRC/增强LRC/SRT/TXT 格式 |
| 连读检测耗时 | ≤ 100ms/句 | 性能测试 |
| 录音评分计算耗时 | ≤ 500ms/句 | 性能测试 |
| 歌词同步精度 | ≤ 50ms 偏差 | 50 句人工标注对比 |
| AI 连读检测准确率 | ≥ 80%（人工抽样 100 句对比） | 抽样测试，非自动化 CI |

### 1.2 用户故事

| 编号 | 作为 | 我希望 | 以便 |
|------|------|--------|------|
| US-S01 | 英语学习者 | 导入本地 LRC/SRT 歌词文件 | 用自己喜欢的英文歌练听力 |
| US-S02 | 英语学习者 | 看到歌词中连读、弱读位置被标注 | 理解为什么听歌时单词会"连在一起" |
| US-S03 | 英语学习者 | 点击某句歌词后循环播放该句 | 反复听直到听懂连读 |
| US-S04 | 英语学习者 | 逐句跟唱并录音 | 模仿原唱的发音和节奏 |
| US-S05 | 英语学习者 | 录音后获得发音评分 | 知道自己的发音哪里不对 |
| US-S06 | 英语学习者 | 对比录音波形和原唱波形 | 直观看到发音差异 |
| US-S07 | 英语学习者 | 将喜欢的歌词中的连读标记收藏 | 在其他歌曲中复习同类连读现象 |

### 1.3 插件架构

```
┌─────────────────────────────────────────────────────┐
│                  英文歌学习插件 (song_learning)         │
│                                                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ 歌词导入  │  │ 连读检测  │  │ 跟唱评分  │           │
│  │ LRC/SRT  │  │ AI 标注  │  │ 录音+评分 │           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │             │             │                   │
│  ┌────┴─────────────┴─────────────┴─────┐            │
│  │        共享基础设施 (shared/)          │            │
│  │  shared_auth │ shared_db │ shared_ui │            │
│  └───────────────────────────────────────┘            │
└─────────────────────────────────────────────────────┘
```

**私有表**（定义在插件自身 package 中）：
- `song_lyrics`：歌词文件元数据
- `song_lyric_lines`：逐句歌词（含时间轴、连读标记）
- `song_recordings`：用户录音文件
- `song_scores`：评分记录

**共享表**（复用 `shared_db` 中已有表）：
- `favorites`：收藏歌词句子（复用现有收藏表，`type` 新增 `song_lyric` 类型）
- `collocations`：收藏连读搭配（复用现有搭配表，`type` 新增 `liaison` 类型）
- `ai_cache`：AI 连读检测结果缓存

**复用已有基础设施**：
- `just_audio`：音频播放（与英语听力插件一致）
- `record` package：录音
- AI 代理降级链：Ollama → Gemini → DeepSeek → Groq（与 P1-08 一致）

---

## 2. 功能需求

### 优先级定义

| 级别 | 含义 | 上线条件 |
|------|------|---------|
| **P0** | 核心功能，无此不可用 | 必须 Phase 1 交付 |
| **P1** | 重要功能，核心体验 | 必须 Phase 1 交付 |
| **P2** | 增强功能，体验优化 | Phase 1 尽量交付，可延后 |

---

### P0-01 歌词导入与解析

**INVEST 评估**：独立模块，可单独测试，是插件的入口。

#### 前置条件
- 用户已登录
- 用户已通过文件选择器选择歌词文件，或通过 `shared_preferences` 记录了上次导入的歌曲音频文件路径

#### 主流程

1. 用户点击「导入歌词」→ 打开系统文件选择器，过滤 `lrc, srt, vtt, txt`
2. 选择文件后 → 检测文件编码（UTF-8 → GBK → Latin-1），创建 `SongLyrics` 对象
3. 按歌词格式分行解析：

   **LRC 格式**（`[mm:ss.xx]歌词文本`）：
   - 逐行解析时间标签和文本
   - 支持增强 LRC（`<mm:ss.xx>` 逐词时间标签），若存在则提取

   **SRT/VTT 格式**（`序号\nmm:ss.xxx --> mm:ss.xxx\n歌词文本`）：
   - 逐块解析时间范围和文本
   - `start` = 第一个时间戳，`end` = 第二个时间戳

   **TXT 格式**（纯文本，无时间标签）：
   - 按空行分行，每行作为一句歌词
   - 无时间轴，不可用于跟唱（需用户手动关闭跟唱模式）

4. 创建 `SongLyricLine` 对象列表，每条包含：
   - `lineIndex`：行号（从 0 开始）
   - `startTime`：起始时间（LRC/SRT 格式，TXT 为 `null`）
   - `endTime`：结束时间（下一句的 `start`，最后一句为 `start + 5s`；SRT 用自身 `end`）
   - `text`：原始歌词文本
   - `liaisonMarks`：连读标记（初始为空，后续由 P1-01 填充）

5. 用户可选择关联音频文件（MP3/M4A/WAV/FLAC）：
   - 系统自动扫描同目录下同名音频文件并提示
   - 也可手动选择
   - 音频文件关联后，歌词行变为可点击状态

6. 歌词列表渲染到主界面，当前行高亮

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 编码检测失败 | GBK 歌词被误识别为 UTF-8 | 显示乱码时自动重试：UTF-8 → GBK → Latin-1。若均失败，提示用户手动选择编码 |
| LRC 时间标签格式错误 | `[xx:xx.xx]` 时间戳格式异常 | 跳过该行，记录到 `parseErrors` 列表，解析完成后显示 "N lines skipped due to format errors" |
| SRT 序号不连续 | 序号 1,3,5（跳号） | 不影响解析，按实际顺序处理 |
| 增强 LRC 逐词标签缺失 | 部分行有 `<00:01.23>word` 标签，部分行无 | 有标签的行记录逐词时间，无标签的行仅记录整句时间 |
| 歌词文件为空 | 选择 0 字节文件 | 提示 "The file is empty. Please select a valid lyrics file." |
| 音频文件不存在 | 关联的音频文件被删除 | 歌词仍可显示，但播放按钮灰化，点击时提示 "Audio file not found. Please re-associate it." |
| TXT 格式无时间轴 | 用户导入纯文本歌词 | 显示 "This lyrics file has no timestamps. Sing-along mode is disabled." 跟唱按钮灰化 |

#### 验收标准

```gherkin
Scenario: 导入 LRC 歌词文件
  Given 用户持有 "Yesterday.lrc" 文件（含 30 行歌词，均有时间标签）
  When 用户选择该文件
  Then 解析成功，显示 30 行歌词
  And 每行歌词包含 startTime、endTime、text 字段
  And 第 1 行 startTime = 文件中第一个时间标签的值
  And 最后一行 endTime = 最后一行的 startTime + 5s

Scenario: 导入增强 LRC（逐词时间标签）
  Given 歌词文件包含 `<00:01.23>Hello <00:01.56>world` 逐词标签
  When 解析完成
  Then 该行 lyricLine 包含 wordTimings: [{word:"Hello", time:1.23}, {word:"world", time:1.56}]

Scenario: 导入 SRT 歌词文件
  Given 用户持有 "Yesterday.srt" 文件（含 30 个字幕块）
  When 用户选择该文件
  Then 解析成功，显示 30 行歌词
  And 每行的 startTime 和 endTime 与 SRT 时间戳一致

Scenario: TXT 歌词无时间轴提示
  Given 用户选择纯文本歌词文件
  When 解析完成
  Then 显示提示 "This lyrics file has no timestamps. Sing-along mode is disabled."
  And 跟唱按钮灰化

Scenario: 编码自动检测及回退
  Given 用户持有 GBK 编码的歌词文件（无 BOM）
  When 解析时 UTF-8 解码失败
  Then 自动回退 GBK 解码
  And 所有中文字符正确显示，无乱码
```

---

### P0-02 歌词播放与同步

**INVEST 评估**：独立模块，核心体验。

#### 前置条件
- 歌词已解析并关联音频文件
- `just_audio` 已初始化

#### 主流程

1. 用户点击歌词行 → 音频 seek 到该行 `startTime`，开始播放
2. 音频播放过程中，`currentTime` 驱动歌词滚动：
   - 当前歌词行高亮（金色背景 `#F59E0B` 20% 透明度）
   - 自动滚动到可视区域中央
3. 用户点击「播放全部」→ 从头播放音频，歌词自动滚动
4. 播放控制：
   - 播放/暂停按钮
   - 进度条（显示当前时间 / 总时长）
   - 上一句/下一句按钮
5. 单句循环：长按歌词行 → 弹出「循环播放」选项 → 该句反复播放直到用户取消

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 音频文件不存在 | 关联的音频文件被删除 | 歌词仍显示，播放按钮灰化，点击提示 "Audio file not found" |
| 音频格式不支持 | 选择 `.aac` 文件（设备不支持） | just_audio 报错，显示 "Unsupported audio format" |
| 歌词行 startTime 为 null | TXT 歌词点击播放 | 不响应点击，播放按钮灰化 |

#### 验收标准

```gherkin
Scenario: 歌词播放同步
  Given 歌词第 5 行 startTime=50.0s
  When 用户点击第 5 行歌词
  Then 音频 seek 到 50.0s ± 0.1s 并开始播放
  And 第 5 行歌词高亮显示

Scenario: 自动滚动
  Given 音频播放到 75.0s（第 8 行歌词）
  When currentTime 超过第 7 行 endTime
  Then 第 8 行自动高亮
  And 列表滚动使第 8 行出现在可视区域中央

Scenario: 单句循环
  Given 第 3 行歌词 startTime=30.0s, endTime=35.0s
  When 用户长按第 3 行并选择「循环播放」
  Then 音频在 30.0s-35.0s 之间循环
  And 循环图标显示在该行右侧
```

---

### P1-01 连读检测与标注

**INVEST 评估**：依赖 AI 代理，但可在离线时跳过 AI 部分，仅使用规则引擎。

#### 前置条件
- 歌词已解析完成
- 后端 AI 服务可用（可选，不可用时仅使用规则引擎）
- 每条歌词行的 `text` 字段非空

#### 主流程

**第一层：规则引擎（离线，始终可用）**

1. 对每句歌词文本，按以下规则检测连读：
   - 辅音 + 元音连读：`look at` → `loo-kat`（前词尾辅音 + 后词首元音）
   - 相同辅音合并：`good day` → `goo-day`（前词尾辅音 = 后词首辅音）
   - /t/ + /j/ 变 /tʃ/：`meet you` → `mee-chyou`
   - /d/ + /j/ 变 /dʒ/：`did you` → `di-jyou`
   - 弱读 to：`going to` → `gonna`

2. 规则引擎输出 `LiaisonMark` 对象：
   ```json
   { "text": "look at", "startChar": 4, "endChar": 11, "type": "consonantVowel", "pronunciation": "loo-kat", "detectedBy": "rule" }
   ```

**第二层：AI 增强检测（在线）**

3. 规则引擎未覆盖的句子 → 发送到 `POST /api/ai/detect-liaison`
4. 后端按降级链调用 AI（Ollama → Gemini → DeepSeek → Groq），prompt 要求返回结构化 JSON：
   ```json
   [{ "text": "look at", "startChar": 0, "endChar": 7, "type": "consonantVowel", "pronunciation": "loo-kat" }]
   ```
5. AI 结果合并到规则引擎结果，`detectedBy` 标记为 `ai`
6. 同一句子的 AI 结果缓存 24 小时（`cacheKey = md5("liaison" + text)`）

**渲染**

7. 歌词中连读位置以彩色下划线 + 弧线连接标记：
   - 辅音+元音连读：绿色弧线 `#10B981`
   - 相同辅音合并：蓝色弧线 `#3B82F6`
   - /t/+/j/ → /tʃ/：橙色弧线 `#F97316`
   - /d/+/j/ → /dʒ/：红色弧线 `#EF4444`
   - 弱读：灰色虚线 `#6B7280`

8. 点击连读标记 → 弹出 Popover 显示发音提示（如 "loo-kat"）和解释

#### 连读类型定义

| 类型 | 英文名 | 规则 | 示例 | 检测方式 |
|------|--------|------|------|:--:|
| consonantVowel | 辅音+元音 | 前词尾辅音 + 后词首元音 → 连读 | `look‿at` → `loo-kat` | 规则引擎 |
| sameConsonant | 相同辅音合并 | 前词尾辅音 = 后词首辅音 → 合并 | `good‿day` → `goo-day` | 规则引擎 |
| tPlusJ | /t/+/j/→/tʃ/ | /t/ 结尾 + you/your → /tʃ/ | `meet‿you` → `mee-chyou` | 规则引擎 |
| dPlusJ | /d/+/j/→/dʒ/ | /d/ 结尾 + you/your → /dʒ/ | `did‿you` → `di-jyou` | 规则引擎 |
| weakForm | 弱读 | 功能词（to/of/and/for）弱读 | `going‿to` → `gonna` | 规则引擎 + AI |
| linkingR | 连接 R | 英式英语中词尾 r + 元音开头词 | `far‿away` → `fa-raway` | AI |
| intrusiveR | 侵入 R | 非 r 结尾词 + 元音开头词时插入 /r/ | `law‿and order` → `law-rand order` | AI |
| elision | 省音 | /t/ /d/ 在辅音间省略 | `next‿day` → `nex-day` | AI |
| other | 其他 | AI 检测到的非标准连读 | — | AI |

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| AI 服务不可用 | 后端 AI 代理全部降级失败 | 仅使用规则引擎结果，连读面板显示 "AI detection unavailable. Showing rule-based results only." |
| 连读重叠 | "look at me" 中 "look at" 和 "at me" 同时匹配 | 取最长匹配（"look at"），较短匹配忽略。不拆分连读 |
| 歌词为纯中文 | 检测到 CJK 字符比例 ≥ 80% | 跳过连读检测，连读面板显示 "No liaison marks for Chinese lyrics" |
| 歌词含大量标点 | "Hello, world! How are you?" | 标点符号不影响连读检测，检测前移除标点，记录原始位置偏移 |

#### 验收标准

```gherkin
Scenario: 规则引擎检测辅音+元音连读
  Given 歌词行文本为 "I need to look at my sister"
  When 执行连读检测
  Then 检测到连读 "look at"（type=consonantVowel）
  And pronunciation="loo-kat", detectedBy="rule"
  And 歌词中 "look at" 以绿色弧线标记

Scenario: 规则引擎检测 /t/+/j/→/tʃ/
  Given 歌词行文本为 "I will meet you there"
  When 执行连读检测
  Then 检测到连读 "meet you"（type=tPlusJ）
  And pronunciation="mee-chyou"

Scenario: AI 检测补充规则引擎
  Given 歌词行文本为 "far away from home"
  And 规则引擎未检测到 "far away" 连读
  And 后端 AI 服务可用
  When 执行连读检测
  Then AI 检测到连读 "far away"（type=linkingR）
  And pronunciation="fa-raway", detectedBy="ai"

Scenario: AI 服务不可用时降级
  Given 后端 AI 服务不可用
  When 执行连读检测
  Then 仅返回规则引擎检测到的连读
  And 连读面板显示 "AI detection unavailable"
  And 不阻塞用户正常使用

Scenario: 连读标记点击显示发音
  Given 检测到连读 "look at"（pronunciation="loo-kat"）
  When 用户点击歌词中 "look at" 标记
  Then 弹出 Popover 显示 "loo-kat" 和类型说明 "辅音+元音连读"
```

---

### P1-02 跟唱录音与评分

**INVEST 评估**：独立模块，但依赖 P0-02 的播放同步和 P1-01 的连读标记。

#### 前置条件
- 歌词已解析且有关联音频文件
- 设备麦克风权限已授权
- `record` package 已初始化

#### 主流程

1. 用户点击「跟唱模式」→ 进入跟唱界面
2. 界面布局：
   - 上方：原唱音频波形（只读）
   - 中间：当前歌词行（含连读标记）
   - 下方：录音按钮（红色圆形）
3. 用户点击录音按钮 → 倒计时 3-2-1 → 开始播放当前句（`startTime` 到 `endTime`）
4. 播放同时录音，录音文件保存到 `recordings/` 目录
5. 播放结束后，录音自动停止
6. 评分计算（本地执行，无需后端）：
   - **发音准确度**（40%）：对比录音和原唱的 MFCC 特征向量余弦相似度（使用 `pitch_detector` 或简单 DTW 对比）
   - **节奏匹配度**（30%）：录音的声波能量峰值时间点与原唱 `startTime`/`endTime` 的偏差
   - **连读还原度**（30%）：若原句有连读标记，检测录音中对应位置是否有连读特征（辅音+元音过渡）
   - 综合分数 = 加权平均，输出 0-100 分

7. 评分展示：
   - 总分数 + 环形进度条
   - 三个维度分项分数
   - 波形对比图：录音波形（蓝色）叠加在原唱波形（灰色）上
   - 连读位置高亮：若某连读分数 < 60，该位置红色闪烁提示

8. 用户可点击「重录」重新录音，或「下一句」继续

#### 异常流程

| 场景 | 输入 | 预期行为 |
|------|------|---------|
| 麦克风权限未授权 | 用户拒绝麦克风权限 | 录音按钮灰化，点击时提示 "Microphone permission required. Please enable it in Settings." |
| 录音过程中音频中断 | 录音中接到电话 | 录音自动停止，已录部分保存，提示 "Recording interrupted. Please try again." |
| 录音时长异常 | 用户录了 0.5 秒就停止 | 提示 "Recording too short. Please sing the complete line." |
| 无连读标记的句子 | 该句歌词没有连读 | 连读还原度维度显示 "N/A"，权重重新分配：发音 55% + 节奏 45% |
| 存储空间不足 | 录音文件写入失败 | 提示 "Insufficient storage space. Please free up at least 50MB." |

#### 验收标准

```gherkin
Scenario: 逐句跟唱录音
  Given 当前歌词行 startTime=30.0s, endTime=35.0s
  And 麦克风权限已授权
  When 用户点击录音按钮
  Then 倒计时 3-2-1 后开始播放原唱
  And 同时开始录音
  And 播放到 35.0s 时自动停止录音
  And 录音文件保存到本地 recordings/ 目录

Scenario: 录音评分
  Given 用户完成第 3 句歌词的录音
  When 录音结束后
  Then 500ms 内显示评分结果
  And 总分数为 0-100 的整数
  And 显示发音准确度、节奏匹配度、连读还原度三个分项分数
  And 显示录音波形与原唱波形的对比图

Scenario: 连读位置评分反馈
  Given 该句有连读 "look at"（pronunciation="loo-kat"）
  And 用户录音中该位置的连读还原度 < 60 分
  When 评分展示
  Then 歌词中 "look at" 位置红色闪烁
  And 提示 "Try linking 'look' and 'at' as 'loo-kat'"

Scenario: 重录
  Given 用户完成录音并查看评分
  When 用户点击「重录」按钮
  Then 清除当前录音和评分
  And 重新开始倒计时 3-2-1
  And 上次录音文件被删除
```

---

### P1-03 歌词收藏与连读复习

**INVEST 评估**：依赖 `shared_db` 的 `favorites` 和 `collocations` 表，复用已有基础设施。

#### 前置条件
- `favorites` 表和 `collocations` 表已在 `shared_db` 中创建
- 用户已登录

#### 主流程

1. 用户在歌词中选中文本 → 弹出操作菜单：
   - 「收藏句子」：将整句歌词存入 `favorites` 表（`type=song_lyric`）
   - 「收藏连读」：将连读标记存入 `collocations` 表（`type=liaison`）
2. 收藏成功后，星标图标点亮
3. 连读复习面板：
   - 按连读类型分组展示所有收藏的连读
   - 点击某条连读 → 播放原句音频片段（需关联音频文件）
   - 显示发音提示和例句
4. 数据同步：收藏和连读通过 `shared_db` 的 `SyncService` 自动同步到云端

#### 验收标准

```gherkin
Scenario: 收藏歌词句子
  Given 当前歌词第 5 行文本为 "I will always love you"
  When 用户选中文本并点击「收藏句子」
  Then favorites 表新增一条记录（type=song_lyric, text="I will always love you"）
  And 该行歌词右侧显示星标图标

Scenario: 收藏连读标记
  Given 歌词中检测到连读 "meet you"（type=tPlusJ）
  When 用户点击连读标记并选择「收藏」
  Then collocations 表新增一条记录（type=liaison, text="meet you", meaning="mee-chyou"）
  And 该连读标记颜色加深

Scenario: 连读复习
  Given 用户已收藏 3 条连读
  When 用户打开连读复习面板
  Then 按类型分组展示（tPlusJ: 2条, consonantVowel: 1条）
  And 点击某条连读时播放原句音频片段
```

---

### P2-01 全曲跟唱模式

**INVEST 评估**：增强功能，可延后。

#### 主流程

1. 用户点击「全曲跟唱」→ 从头播放音频，不暂停
2. 全程录音，歌词自动滚动
3. 唱完后生成全曲评分报告：
   - 每句分数折线图
   - 最低分 3 句高亮（建议重点练习）
   - 连读还原度最低的连读类型统计
4. 支持导出录音为 MP3

#### 验收标准

```gherkin
Scenario: 全曲跟唱
  Given 歌曲有 30 句歌词
  When 用户点击「全曲跟唱」并跟唱完整首歌
  Then 生成全曲评分报告
  And 折线图显示 30 句的分数变化
  And 最低分 3 句高亮显示
```

---

### P2-02 多语言歌词支持

**INVEST 评估**：增强功能，可延后。

#### 主流程

1. 支持导入双语歌词（LRC 中 `[mm:ss.xx]英文歌词 // 中文翻译` 格式）
2. 歌词显示切换：EN / 中文 / 双语
3. 连读检测仅在英文歌词上执行，中文翻译不参与

---

## 3. 数据模型

### 3.1 私有表（定义在插件 `song_learning` package 中）

```sql
-- 歌词文件
song_lyrics(
  id TEXT PK,
  user_id TEXT FK,
  song_title TEXT NOT NULL,
  artist TEXT,
  file_path TEXT NOT NULL,
  lyrics_format TEXT NOT NULL,  -- 'lrc', 'enhanced_lrc', 'srt', 'vtt', 'txt'
  audio_file_path TEXT,         -- 关联的音频文件路径
  line_count INT,
  has_timestamps BOOL DEFAULT 1,
  created_at TEXT,
  updated_at TEXT
)

-- 歌词行
song_lyric_lines(
  id TEXT PK,
  song_id TEXT FK NOT NULL,
  line_index INT NOT NULL,
  start_time REAL,              -- 秒，TXT 格式为 null
  end_time REAL,                -- 秒，TXT 格式为 null
  text TEXT NOT NULL,
  text_zh TEXT,                 -- 中文翻译（如有）
  word_timings TEXT,            -- JSON: [{"word":"Hello","time":1.23},...]
  liaison_marks TEXT,           -- JSON: [{"text":"look at","startChar":0,...},...]
  created_at TEXT
)

-- 录音文件
song_recordings(
  id TEXT PK,
  user_id TEXT FK,
  lyric_line_id TEXT FK NOT NULL,
  file_path TEXT NOT NULL,
  duration REAL,                -- 录音时长（秒）
  sample_rate INT,              -- 采样率
  created_at TEXT
)

-- 评分记录
song_scores(
  id TEXT PK,
  recording_id TEXT FK NOT NULL,
  lyric_line_id TEXT FK NOT NULL,
  total_score INT NOT NULL,     -- 0-100
  pronunciation_score INT,      -- 0-100
  rhythm_score INT,             -- 0-100
  liaison_score INT,            -- 0-100, 无连读时为 null
  created_at TEXT
)
```

### 3.2 共享表扩展（需在 `shared_db` 中新增字段/类型）

| 表 | 变更 | 说明 |
|----|------|------|
| `favorites` | `type` 字段新增枚举值 `song_lyric` | 歌词句子收藏 |
| `collocations` | `type` 字段新增枚举值 `liaison` | 连读搭配收藏 |

> **注意**：`favorites` 和 `collocations` 的 `type` 字段为 `TEXT` 类型，新增枚举值无需 migration，向后兼容。

---

## 4. API 端点

### 4.1 新增端点

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|:--:|
| POST | `/api/ai/detect-liaison` | AI 连读检测 | ✅ |
| POST | `/api/songs/recordings` | 上传录音文件 | ✅ |
| GET | `/api/songs/recordings/{id}` | 下载录音文件 | ✅ |
| DELETE | `/api/songs/recordings/{id}` | 删除录音 | ✅ |

### 4.2 复用已有端点

| 端点 | 用途 |
|------|------|
| `POST /api/ai/translate` | 歌词翻译（复用翻译端点） |
| `POST /api/sync/push` | 同步收藏和连读数据 |
| `GET /api/sync/pull` | 拉取云端收藏和连读数据 |

### 4.3 端点详细设计

**`POST /api/ai/detect-liaison`**

```
Request:
{
  "text": "I need to look at my sister",
  "ruleResults": [{"text": "look at", "type": "consonantVowel", ...}]  // 规则引擎已检测到的
}

Response:
{
  "liaisons": [
    {"text": "look at", "startChar": 10, "endChar": 17, "type": "consonantVowel", "pronunciation": "loo-kat", "detectedBy": "ai"}
  ],
  "cached": false
}
```

后端实现：
- 在 `server/routers/ai.py` 中新增 `detect_liaison` 函数
- 复用降级链（Ollama → Gemini → DeepSeek → Groq）
- 缓存 key: `md5("liaison" + ":" + text)`
- `server/routers/songs.py` 中新增 `recordings` 相关路由

---

## 5. 与已有插件的交互

### 5.1 数据依赖

| 已有插件/模块 | 本插件依赖 | 方式 |
|-------------|----------|------|
| 英语听力（P1-08 AI 代理） | 连读 AI 检测 | 复用 `POST /api/ai/detect-liaison`，走相同降级链 |
| 英语听力（P1-04 收藏） | 歌词句子收藏 | 复用 `favorites` 表，新增 `type=song_lyric` |
| 英语听力（P1-07 搭配） | 连读搭配收藏 | 复用 `collocations` 表，新增 `type=liaison` |
| 英语听力（P1-05 在线视频） | 音频文件流式播放 | 不依赖。本插件使用本地音频文件，不走 `video_sources` 表 |

### 5.2 潜在冲突

| 冲突点 | 分析 | 结论 |
|--------|------|------|
| `favorites` 表 `type` 字段 | 已有 `word/phrase/sentence`，新增 `song_lyric` | 无冲突，TEXT 字段可任意扩展 |
| `collocations` 表 `type` 字段 | 已有 `phrasalVerb/prepositional/noun/adjective/idiom`，新增 `liaison` | 无冲突，同上 |
| AI 降级链 Groq 配额 | 连读检测与翻译/搭配共享 Groq 配额 | 连读检测为非实时任务（用户导入歌词时触发），优先级低于翻译和转录，不参与 `transcription_in_progress` 锁检查 |
| `just_audio` 实例 | 英语听力插件和本插件可能同时持有 AudioPlayer | 各自维护独立实例，不冲突。外壳内切换插件时，前一个插件的 AudioPlayer 自动 dispose |

---

## 6. 独立运行模式

独立运行时（`standalone.dart`）：
- 使用 mock 认证（`AuthService.initialize(mockMode: true)`）
- 本地数据库隔离模式（`DatabaseMode.isolated`）
- 连读检测仅使用规则引擎（无 AI）
- 录音评分正常工作（本地计算）
- 收藏和连读数据仅存本地，不同步

---

## 7. 技术栈补充

| 组件 | 选型 | 说明 |
|------|------|------|
| 音频播放 | `just_audio` | 与英语听力插件一致 |
| 录音 | `record` (v5.0+) | 支持 Android/iOS/macOS/Windows |
| 波形显示 | `flutter_audio_waveforms` | 录音波形和原唱波形对比 |
| 音频分析 | `pitch_detector` 或 DTW | 发音评分和节奏匹配 |
| 歌词解析 | 纯 Dart 实现 | 正则匹配 LRC/SRT/VTT 格式 |
| 连读规则引擎 | 纯 Dart 实现 | 正则 + 音标映射表 |
| AI 连读检测 | 复用后端 AI 代理 | 见 P1-08 降级链 |

---

## 8. 与外壳的接入点

```dart
// lib/plugin.dart
class SongLearningPlugin implements PlatformPlugin {
  @override
  String get id => 'song_learning';
  @override
  String get name => '英文歌学习';
  @override
  String get description => '歌词连读标注与跟唱评分';
  @override
  IconData get icon => Icons.music_note;
  @override
  String get routePath => '/song-learning';
  @override
  WidgetBuilder get pageBuilder => (context) => const SongLearningHomeScreen();
  @override
  int get sortOrder => 30;
}
```

```dart
// shell/lib/registry.dart 中新增一行
SongLearningPlugin(),
```

---

## 9. 开放问题

| 编号 | 问题 | 影响 | 建议 |
|------|------|:--:|------|
| Q-01 | MFCC/DTW 发音评分精度 | 评分不准会降低用户信任 | Phase 1 使用简化版 DTW 对比，Phase 2 考虑接入专业发音评分 API |
| Q-02 | 连读规则引擎的覆盖率 | 规则有限，复杂连读需 AI | 规则引擎覆盖 5 种常见连读类型，AI 补充 4 种高级类型 |
| Q-03 | 增强 LRC 逐词标签的普及度 | 大多数歌词文件没有逐词时间 | 不影响核心功能，有逐词标签时连读标记更精确 |