# 插件对接规范 · Plugin Integration Spec

> **v1.0 | Phase 1**
> 本文档定义第三方开发者如何创建插件并接入「个人集成工具平台」外壳。
> 阅读本文档前，请先了解平台架构：[DEVELOPMENT_DOCS.md](./DEVELOPMENT_DOCS.md)

---

## 1. 概述

### 1.1 什么是插件

插件是一个独立的 Flutter package，可以：
- 在外壳 App 内运行（共享用户系统、数据层、UI 主题）
- 独立编译为 App 运行（`cd plugins/xxx && flutter run`）

### 1.2 外壳提供什么

| 能力 | 说明 | 获取方式 |
|------|------|---------|
| 用户认证 | 登录/注册/Token 管理 | `shared_auth` package |
| 本地数据库 | drift SQLite，离线可用 | `shared_db` package |
| 数据同步 | 客户端与后端自动同步 | `shared_db` sync_service |
| UI 主题 | 统一的颜色、字体、间距 | `shared_ui` theme |
| 响应式布局 | 手机/平板/桌面自适应 | `shared_ui` responsive |
| 通用组件 | 按钮、卡片、对话框等 | `shared_ui` widgets |
| 后端 API | 用户数据 CRUD、AI 代理 | `shared_auth` dio 实例 |

### 1.3 数据互通

插件之间可以通过 `shared_db` 直接读取共享数据表。**共享表（如 `collocations`、`favorites`、`flashcards`）定义在 `shared_db` package 中**，不属于任何具体插件，由所有插件共同读写。

**规则**：
- 共享表定义在 `shared_db` 中，各插件均可读写
- 插件私有表（如 `ab_loop_history`）定义在插件自身中，其他插件不可直接访问
- 插件间数据互通通过共享表实现，不可通过直接引用其他插件的 package 实现

---

## 2. 快速开始

### 2.1 创建插件

```bash
cd platform/plugins/
flutter create --template=package my_plugin
cd my_plugin
```

### 2.2 目录结构

```
my_plugin/
├── lib/
│   ├── plugin.dart          # 实现 PlatformPlugin 接口（必需）
│   ├── standalone.dart      # 独立运行入口（必需）
│   ├── models/              # 数据模型
│   ├── providers/           # Riverpod 状态管理
│   ├── screens/             # 页面
│   ├── widgets/             # 组件
│   └── services/            # 服务层
├── pubspec.yaml
└── test/
```

### 2.3 最小可运行示例

**`pubspec.yaml`**：

```yaml
name: my_plugin
description: My custom plugin
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  # 依赖共享基础设施
  shared_auth:
    path: ../../shared/shared_auth
  shared_db:
    path: ../../shared/shared_db
  shared_ui:
    path: ../../shared/shared_ui
  # 其他依赖
  flutter_riverpod: ^2.4.0
  go_router: ^13.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

**`lib/plugin.dart`**（必需）：

```dart
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'screens/home_screen.dart';

class MyPlugin implements PlatformPlugin {
  @override
  String get id => 'my_plugin';

  @override
  String get name => '我的插件';

  @override
  String get description => '这是一个示例插件';

  @override
  IconData get icon => Icons.extension;

  @override
  String get routePath => '/my-plugin';

  @override
  WidgetBuilder get pageBuilder => (context) => const MyPluginHomeScreen();

  @override
  int get sortOrder => 100;
}
```

**`lib/standalone.dart`**（必需）：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_db/shared_db.dart';
import 'plugin.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 独立模式：使用 mock 认证
  await AuthService.initialize(mockMode: true);

  // 初始化本地数据库（隔离模式，不与外壳共享）
  await AppDatabase.initialize(mode: DatabaseMode.isolated);

  final plugin = MyPlugin();

  runApp(
    ProviderScope(
      child: MaterialApp(
        title: plugin.name,
        theme: PlatformTheme.light,
        darkTheme: PlatformTheme.dark,
        home: plugin.pageBuilder(null),
      ),
    ),
  );
}
```

---

## 3. PlatformPlugin 接口规范

```dart
/// 所有插件必须实现此接口
abstract class PlatformPlugin {
  /// 唯一标识符，使用 snake_case，如 "english_listening"
  /// 不可与已有插件重复
  String get id;

  /// 显示名称，用于首页卡片标题
  /// 支持多语言：返回当前 locale 对应的名称
  String get name;

  /// 简短描述（≤ 30 字符），用于首页卡片副标题
  String get description;

  /// 图标，使用 Material Icons 或自定义 IconData
  IconData get icon;

  /// 路由路径，以 "/" 开头，如 "/my-plugin"
  /// 不可与已有插件路由冲突
  String get routePath;

  /// 页面构建器，返回插件的主页面 Widget
  /// context 可能为 null（独立模式）
  WidgetBuilder get pageBuilder;

  /// 排序权重，越小越靠前
  /// 建议范围：0-999
  int get sortOrder;
}
```

### 3.1 字段约束

| 字段 | 约束 | 示例 |
|------|------|------|
| `id` | 小写字母 + 下划线，长度 3-50 | `english_listening` |
| `name` | ≤ 20 字符 | `英语听力` |
| `description` | ≤ 30 字符 | `影音字幕听力练习` |
| `routePath` | 以 `/` 开头，kebab-case | `/english-listening` |
| `sortOrder` | 0-999，10 的倍数 | `10`, `20`, `30` |

---

## 4. 接入外壳

### 4.1 注册插件

1. 在 `platform/shell/pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  my_plugin:
    path: ../plugins/my_plugin
```

2. 在 `platform/shell/lib/registry.dart` 中注册：

```dart
import 'package:my_plugin/plugin.dart';

final List<PlatformPlugin> pluginRegistry = [
  EnglishListeningPlugin(),
  FlashcardsPlugin(),
  MyPlugin(),   // ← 添加这一行
  // 未来更多插件...
];
```

3. 重新编译外壳：

```bash
cd platform/shell && flutter run
```

### 4.2 验证

- 外壳首页应显示新插件的卡片
- 点击卡片应导航到插件页面
- 独立运行 `cd platform/plugins/my_plugin && flutter run` 应正常工作

---

## 5. 使用共享基础设施

### 5.1 认证

```dart
import 'package:shared_auth/shared_auth.dart';

// 获取当前用户
final user = ref.watch(currentUserProvider);

// 检查登录状态
if (user == null) {
  // 未登录，引导用户登录
}

// 使用 dio 实例（已附带 JWT Token）
final response = await AuthService.dio.get('/api/my-data');
```

### 5.2 数据库

```dart
import 'package:shared_db/shared_db.dart';

// 获取数据库实例（外壳模式）
final db = ref.watch(databaseProvider);

// 获取数据库实例（独立模式）
// standalone.dart 中传入 DatabaseMode.isolated
final db = await AppDatabase.initialize(mode: DatabaseMode.isolated);

// 读取共享表数据
final items = await db.myTableDao.getAll();

// 写入共享表数据
await db.myTableDao.insert(item);

// 读取其他插件写入的共享表
final collocations = await db.collocationsDao.getAll();
```

**数据库模式**：

| 模式 | 数据库文件名 | 使用场景 |
|------|-------------|---------|
| `DatabaseMode.shared` | `shared.db` | 外壳 App 内所有插件共享 |
| `DatabaseMode.isolated` | `standalone_{plugin_id}.db` | 插件独立运行，与外壳物理隔离 |

**访问控制**：共享表（`collocations`、`favorites`、`flashcards` 等）的 DAO 定义在 `shared_db` 中，所有插件均可读写。插件私有表（如 `ab_loop_history`）的 DAO 定义在插件自身 package 中，其他插件无法 import 其 DAO，编译时即被阻止。**代码审查时检查：插件不得在 `pubspec.yaml` 中依赖其他插件的 package。**

**Schema 兼容性承诺**：`shared_db` 的 schema 变更遵循以下规则，插件开发者无需手动更新 `standalone.dart` 初始化代码：

| 变更类型 | 兼容性 | 要求 |
|---------|:--:|------|
| 新增表 | ✅ 向后兼容 | 不影响已有插件，`AppDatabase.initialize()` 自动创建新表 |
| 新增字段（带默认值） | ✅ 向后兼容 | drift migration 自动处理 |
| 新增字段（NOT NULL 无默认值） | ❌ 不兼容 | 需提供迁移脚本，至少提前一个大版本通知 |
| 删除表 | ❌ 不兼容 | 至少提前一个大版本通知，提供废弃期 |
| 删除字段 | ❌ 不兼容 | 至少提前一个大版本通知，提供废弃期 |
| 重命名字段 | ❌ 不兼容 | 提供迁移脚本，至少提前一个大版本通知 |

### 5.3 UI 主题

```dart
import 'package:shared_ui/shared_ui.dart';

// 使用平台颜色
color: PlatformColors.primary

// 使用平台字体
style: PlatformTextStyles.body

// 使用平台间距
padding: EdgeInsets.all(PlatformSpacing.md)
```

### 5.4 响应式布局

```dart
import 'package:shared_ui/shared_ui.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      compact: (context) => MobileLayout(),
      medium: (context) => TabletLayout(),
      expanded: (context) => DesktopLayout(),
    );
  }
}
```

---

## 6. 数据同步

### 6.1 自动同步

使用 `shared_db` 的 `SyncService` 标记需要同步的表：

```dart
// 在插件的数据库初始化代码中
SyncService.registerTable(
  tableName: 'my_table',
  dao: myTableDao,
  apiPath: '/api/my-plugin/data',
);
```

注册后，该表的数据会自动在客户端和后端之间同步。

### 6.2 后端 API 要求

插件需要同步数据时，必须在后端实现对应的 API 端点。详见 [第 7 节](#7-后端-api-规范)。

---

## 7. 后端 API 规范

### 7.1 插件数据端点

如果插件需要后端存储数据，需在 `server/routers/` 下创建路由文件：

```python
# server/routers/my_plugin.py
from fastapi import APIRouter, Depends
from ..middleware.auth import get_current_user

router = APIRouter(prefix="/api/my-plugin", tags=["my-plugin"])

@router.get("/data")
async def get_data(user_id: str = Depends(get_current_user)):
    # 查询当前用户的数据
    pass

@router.post("/data")
async def save_data(data: dict, user_id: str = Depends(get_current_user)):
    # 保存数据
    pass

@router.delete("/data/{item_id}")
async def delete_data(item_id: str, user_id: str = Depends(get_current_user)):
    # 删除数据
    pass
```

在 `server/main.py` 中注册路由：

```python
from routers import my_plugin
app.include_router(my_plugin.router)
```

### 7.2 数据库表

插件需在 `server/database.py` 中定义 SQLAlchemy 模型：

```python
class MyPluginData(Base):
    __tablename__ = "my_plugin_data"
    id = Column(String, primary_key=True, default=uuid4)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    # ... 其他字段
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
```

---

## 8. 测试

### 8.1 单元测试

```dart
// test/plugin_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_plugin/plugin.dart';

void main() {
  test('plugin id should be unique', () {
    final plugin = MyPlugin();
    expect(plugin.id, 'my_plugin');
  });

  test('route path should start with /', () {
    final plugin = MyPlugin();
    expect(plugin.routePath.startsWith('/'), isTrue);
  });
}
```

### 8.2 集成测试

```dart
// test/standalone_test.dart
void main() {
  testWidgets('standalone app should launch', (tester) async {
    await tester.pumpWidget(MyStandaloneApp());
    expect(find.text('我的插件'), findsOneWidget);
  });
}
```

---

## 9. 发布与版本管理

### 9.1 版本号

插件使用语义化版本号 `MAJOR.MINOR.PATCH`：
- MAJOR：不兼容的 API 变更（可能破坏外壳集成）
- MINOR：向后兼容的新功能
- PATCH：向后兼容的 bug 修复

### 9.2 发布检查清单

- [ ] `plugin.dart` 实现完整的 `PlatformPlugin` 接口
- [ ] `standalone.dart` 可独立运行
- [ ] 在外壳中注册后首页正常显示
- [ ] 点击卡片可导航到插件页面
- [ ] 页面可正常返回外壳首页
- [ ] 主题样式与平台一致
- [ ] 单元测试通过
- [ ] 代码通过 `flutter analyze` 无 error
- [ ] 文档齐全（README 说明插件功能和使用方式）

---

## 10. 常见问题

### Q: 插件可以依赖其他插件吗？

不可以。插件之间不允许直接依赖。数据互通通过 `shared_db` 读取表实现。

### Q: 插件可以使用自己的后端 API 吗？

可以。插件可以独立部署后端服务，但推荐使用平台统一后端（`server/`）以共享用户认证。

### Q: 插件可以有自己的 assets 吗？

可以。图片、字体、JSON 等资源放在插件自己的 `assets/` 目录下，在 `pubspec.yaml` 中声明。

### Q: 插件 ID 冲突怎么办？

编译时 lint 会检测重复 ID。新插件命名前请检查已有插件的 ID 列表。建议使用有意义的名称，如 `habit_tracker`、`pomodoro_timer`。

### Q: 如何卸载插件？

1. 从 `shell/pubspec.yaml` 移除依赖
2. 从 `shell/lib/registry.dart` 移除注册行
3. 重新编译外壳
4. （可选）删除 `plugins/` 下的插件目录

---

## 附录：已有插件 ID 列表

| ID | 名称 | Phase |
|----|------|-------|
| `english_listening` | 英语听力 | Phase 1 |
| `flashcards` | 闪卡系统 | Phase 1 |
| `english_songs` | 英文歌学习 | Phase 3 |
| `new_concept` | 新概念英语 | Phase 3 |
| `moral_system` | 道德系统 | Phase 2 |

新插件命名时请避免与上述 ID 重复。