# XQStudio Flutter Port — Implementation Plan

## Context

XQStudio 1.63 is a Delphi 5 Chinese Chess (象棋) game record editor (~11,700 lines Pascal, 102 BMP assets). Goal: complete 1:1 feature port to Flutter/Dart, targeting iOS/Android/macOS/Windows/Linux/Web.

The codebase is roughly 50% pure game logic (easily portable) and 50% Delphi VCL UI (needs full rewrite). Total scale is modest — the main challenge is byte-level fidelity in the .xqf file format and move validation correctness.

## Tech Choices

- **Framework**: Flutter (multi-platform from single codebase)
- **State management**: Riverpod
- **Board rendering**: CustomPainter (not widget grid)
- **File format**: Full .xqf read/write support with XOR decryption
- **Key packages**: `riverpod`, `file_picker`, `path_provider`, `shared_preferences`

## Project Structure

```
xqstudio_flutter/
├── lib/
│   ├── core/           # Pure Dart, zero Flutter imports
│   │   ├── models/     # piece, position, board_state, play_node, game_metadata
│   │   ├── rules/      # move_validator, move_notation, king_safety
│   │   ├── xqf/        # xqf_file, xqf_header, xqf_crypto, xqf_reader, xqf_writer
│   │   ├── game/       # game_controller, move_record_list, variation_list
│   │   └── search/     # game_search, search_criteria
│   ├── state/          # Riverpod providers and notifiers
│   ├── ui/
│   │   ├── board/      # board_widget, board_painter, piece_painter, gesture_handler
│   │   ├── game/       # game_screen, move_list, variation_panel, remark_panel, nav_toolbar
│   │   ├── home/       # home_screen (replaces MDI)
│   │   ├── search/     # search_screen
│   │   ├── wizard/     # new_game_wizard
│   │   └── dialogs/    # about, tips, file_properties
│   ├── services/       # file_service, preferences_service, clipboard_service
│   └── utils/          # gb2312_codec, platform_utils
├── assets/images/      # Converted PNGs (pieces/, board/, icons/)
├── test/
│   ├── core/           # Unit tests (pure Dart, no Flutter)
│   │   ├── models/     # play_node_test, board_state_test
│   │   ├── rules/      # move_validator_test, king_safety_test
│   │   ├── xqf/        # xqf_crypto_test, xqf_reader_test, xqf_writer_test, xqf_roundtrip_test
│   │   └── game/       # game_controller_test
│   ├── ui/             # Widget tests (need Flutter test harness)
│   │   ├── board/      # board_painter_test, gesture_handler_test
│   │   ├── game/       # game_screen_test, move_list_test, nav_toolbar_test
│   │   └── goldens/    # Golden image files for visual regression
│   ├── integration_test/  # Full app integration tests (run on device/emulator)
│   │   ├── file_open_save_test.dart
│   │   ├── play_through_game_test.dart
│   │   └── search_test.dart
│   └── fixtures/       # Test data files
│       ├── xqf/        # 50+ real .xqf files (various versions, with/without variations & remarks)
│       ├── hex_dumps/   # Extracted header bytes from .xqf files as reference
│       └── move_corpus/ # JSON files with 200+ move test cases
└── pubspec.yaml
```

## Testing Principles

**原则：Test-First。** 原始 Delphi 代码没有任何自动化测试，且 Delphi 5 无法在 Linux 上运行。测试基准不依赖运行原始代码，而是来自三个来源：

1. **象棋规则本身** — 公开确定的知识，走法合法性有唯一正确答案
2. **.xqf 文件的原始字节** — 用 `xxd` hex dump 提取，不需要编译运行任何东西
3. **源码中的数学公式** — 密钥推导等纯数学运算可用 Dart/Python 直接计算

每个核心 phase 的节奏：**先写测试用例 → 再实现 Dart 代码使测试通过。**

**测试分三层：**

| 层次 | 工具 | 运行方式 | 适用范围 |
|------|------|---------|---------|
| **Unit tests** | `dart test` / `flutter test` | 无需设备，CI 可跑 | Phase 1-4 核心逻辑 |
| **Widget tests** | `flutter test` + `testWidgets()` | 无需设备，模拟渲染 | Phase 5-9 UI 组件 |
| **Integration tests** | `flutter test integration_test/` | 需要设备或模拟器 | Phase 7+ 端到端流程 |

**GUI 验证策略：**

- **Golden tests** (`matchesGoldenFile()`): 对已知棋局局面渲染截图，存为 golden image。后续改代码后自动逐像素比对，防止渲染回归。Golden 文件 check in 到 `test/ui/goldens/`。
- **Widget tests** (`testWidgets()`): 模拟用户操作（tap 棋盘坐标、点击按钮），验证 widget 树状态变化（棋子位置更新、面板内容刷新），不需要真机。
- **Integration tests**: 在真实设备或模拟器上跑完整操作流程，验证端到端行为。
- **手动对照验证**: 跑 `flutter run`，对照原版 XQStudio 截图比对棋盘外观和交互行为。准备一组原版截图作为视觉参考放在 `docs/reference_screenshots/`。

---

## Phased Implementation

### Phase 0: Bootstrap (1 week)

**0.1 项目初始化**
- `flutter create --org net.qipaile --project-name xqstudio xqstudio_flutter`
- 启用所有平台 target: `flutter config --enable-linux-desktop --enable-macos-desktop --enable-windows-desktop`
- 配置 `analysis_options.yaml`（strict mode + lints）
- 添加 pubspec.yaml 依赖：`flutter_riverpod`, `riverpod_annotation`, `file_picker`, `path_provider`, `shared_preferences`
- 添加 dev 依赖：`flutter_test`, `integration_test`, `mocktail`

**0.2 资源转换**
- 批量转换 102 个 BMP → PNG：`for f in Bitmap/*.bmp; do convert "$f" "assets/images/$(basename ${f%.bmp}.png)"; done`
- 按类别重命名和分组到 `assets/images/{pieces,board,icons}/`
- 资源命名规范：`red_che.png`, `blk_ma_sel.png`, `red_pao_wb.png` 等
- 在 pubspec.yaml 中声明 asset 目录

**0.3 测试素材收集**
- 搜集 50+ 个真实 .xqf 文件（覆盖：不同 XQF 版本、有/无变例、有/无注释、多局棋谱、特殊开局），放入 `test/fixtures/xqf/`
- 用 `xxd` 从几个代表性 .xqf 文件提取前 1024 字节 header 的 hex dump，手动标注关键字段偏移量和期望值，保存为 `test/fixtures/hex_dumps/*.txt`
- 收集原版 XQStudio 的界面截图（如有 Windows 虚拟机可截取，否则从网上搜集），放入 `docs/reference_screenshots/`

**0.4 验证**
- `flutter analyze` 无报错
- `flutter test` 能跑通（此时只有默认的 widget_test.dart）
- `flutter run -d linux` 能启动空白应用

---

### Phase 1: Core Data Models (1 week)

**1.1 先写测试** (`test/core/models/`)
- `play_node_test.dart`:
  - 创建根节点，验证初始状态（StepNo=0, 无子节点）
  - 添加 LChild（下一步），验证 parent 指针正确
  - 添加 RChild（变例），验证 sibling 链
  - 三层深嵌套树：主线 3 步 + 第 2 步有 2 个变例，验证遍历正确性
  - 删除中间节点，验证树结构完整性（parent 重新连接）
  - 删除有子树的节点，验证整个子树被移除
- `board_state_test.dart`:
  - 初始化标准开局，验证 32 个棋子的位置匹配 `dCXqzXY` 常量
  - 移动一个棋子，验证旧位置清空、新位置正确
  - 验证 XY 编码：`Position(x: 4, y: 0).toXY()` == 40, `Position.fromXY(40).x` == 4
  - 边界测试：XY = 0xFF 表示被吃掉的棋子
- `piece_test.dart`:
  - 验证棋子编号映射：1=红车, 2=红马, ..., 7=红兵, 8=黑车, ..., 14=黑卒
  - 验证红黑方判断：piece 1-7 为红方, 8-14 为黑方

**1.2 实现**
- `lib/core/models/piece.dart`: `enum PieceType { che, ma, xiang, shi, shuai, pao, bing }`, `enum Side { red, black }`, piece index ↔ type/side 转换
- `lib/core/models/position.dart`: `Position` 值类，封装 XY 单字节编码，提供 `x`, `y` getter 和 `toXY()`/`fromXY()` 工厂方法
- `lib/core/models/board_state.dart`: 32 元素棋子位置数组（1-based, length 33），标准开局初始化，棋子移动操作
- `lib/core/models/play_node.dart`: 移植 `dTXQPlayNode`，包含 LChild/RChild/LParent/RParent 指针，StepNo, StrRec, XYf/XYt, Remark 字段
- `lib/core/models/game_metadata.dart`: 标题、红/黑方棋手、比赛信息、时间控制、结果
- `lib/core/constants.dart`: 从 `XQDataT.pas` 移植所有常量（`dCMaxRecNo`, `dCFileVersion`, 棋子编号常量, 中文数字数组）

**1.3 验证**
- `dart test test/core/models/` 全部通过
- 代码覆盖率 > 90%：`flutter test --coverage test/core/models/`

---

### Phase 2: Move Validation Engine (2 weeks)

**2.1 先写测试** (`test/core/rules/`)

准备测试数据文件 `test/fixtures/move_corpus/moves.json`，格式：
```json
[
  {
    "description": "炮二平五 — 开局当头炮",
    "board": [/* 32 个棋子的 XY 位置，标准开局 */],
    "from_xy": 77,
    "to_xy": 74,
    "expected_notation": "炮二平五",
    "is_valid": true,
    "piece_index": 6
  },
  ...
]
```

- `move_validator_test.dart` — 200+ 测试用例，分组：
  - **车 (Rook)**: 直线移动、吃子、被己方棋子阻挡（非法）、越过棋子（非法）
  - **马 (Knight)**: L 形移动、蹩马腿（非法）、吃子
  - **象 (Elephant)**: 田字对角、塞象眼（非法）、不能过河（非法）
  - **士 (Advisor)**: 斜线一格、不能出九宫（非法）
  - **将/帅 (King)**: 正交一格、不能出九宫（非法）、将帅对面（非法）
  - **炮 (Cannon)**: 直线移动（不吃子）、隔一子吃子、隔零子或多子（非法）
  - **兵/卒 (Pawn)**: 未过河只能前进、过河后可横走、不能后退（非法）
  - **前中后兵区分**: 同列 2 个兵（前/后）、同列 3 个兵（前/中/后）、同列 5 个兵的极端情况
  - **记谱法**: 验证每步的中文记谱字符串（如"马八进七"、"炮二平五"）
  - **红黑数字系统**: 红方用中文数字（一二三...九），黑方用阿拉伯数字（1 2 3...9）
- `move_notation_test.dart`:
  - 正向：给定 board + from/to → 生成记谱字符串
  - 反向：给定 board + 记谱字符串 → 解析出 from/to XY（`wGetPlayRecXY` 移植）
  - Round-trip：生成 → 解析 → 验证 from/to 一致
- `king_safety_test.dart`:
  - 将帅对面检测：清空中间棋子后将帅在同一列 → 非法
  - 被将军检测：各种将军局面

**2.2 实现**
- `lib/core/rules/move_validator.dart`: 移植 `sGetPlayRecStr()`（~440 行），拆分为：
  - `bool isValidMove(BoardState board, int fromXY, int toXY)` — 纯合法性判断
  - `String? generateNotation(BoardState board, int fromXY, int toXY)` — 生成中文记谱，非法走法返回 null
  - 内部按棋子类型 dispatch：`_validateChe()`, `_validateMa()`, `_validateXiang()`, `_validateShi()`, `_validateShuai()`, `_validatePao()`, `_validateBing()`
- `lib/core/rules/move_notation.dart`: 中文数字数组、进/退/平 判断、前/中/后 区分逻辑
- `lib/core/rules/king_safety.dart`: 将帅对面检测、被将军检测

**2.3 验证**
- `dart test test/core/rules/` — 200+ 测试全部通过
- 特别关注：前中后兵区分、记谱字符串完全匹配
- 代码覆盖率 > 95%

---

### Phase 3: XQF File I/O (2 weeks)

**3.1 先写测试** (`test/core/xqf/`)

准备测试基准：
- 用 `xxd test/fixtures/xqf/sample1.xqf | head -64` 提取前 1024 字节，手动标注每个字段的偏移量和值
- 编写 `test/fixtures/hex_dumps/sample1_header.dart`：以 Dart 常量形式记录 expected 字段值
- 用 Dart 脚本 `tool/generate_crypto_reference.dart` 根据 XQFileRW.pas 中的公式计算 256 个 bKey 的密钥推导参考表，输出为 `test/fixtures/crypto_reference.dart`

测试文件：
- `xqf_crypto_test.dart`:
  - 对 256 个 bKey 值（0x00-0xFF），验证 `calculateSecurityKeys(bKey)` 输出的 KeyXY/KeyXYf/KeyXYt/KeyRMKSize 与参考表一致
  - XOR 加密 → 解密 round-trip：随机 100 字节，加密后解密应恢复原文
  - 边界测试：bKey = 0, bKey = 0xFF
- `xqf_header_test.dart`:
  - 读取 sample1.xqf 前 1024 字节，解析 header，验证各字段与手动标注值一致
  - Signature 必须是 0x5158 ("XQ")
  - Version 字段验证
  - 棋手名称、标题等 GB2312 字符串正确解码
- `xqf_reader_test.dart`:
  - 读取 sample1.xqf，验证：开局棋子位置 == 标准开局（或文件中指定的开局）
  - 验证走法树的步数、第 N 步的记谱字符串
  - 验证变例数量和内容
  - 验证注释文本
  - 读取不同版本的 .xqf 文件（version <= 10 无加密 vs version >= 12 有加密）
  - 读取包含多局棋谱的文件，验证每局独立正确
- `xqf_writer_test.dart`:
  - 构造一个已知的棋谱树 → 写出 → 用 reader 读回 → 验证完全一致
  - Round-trip: 读取真实 .xqf → 写出 → 读回 → 比对棋谱树（每个节点的 StepNo, StrRec, XYf, XYt, Remark）
- `xqf_roundtrip_test.dart`:
  - 对 `test/fixtures/xqf/` 下所有 50+ 个文件执行 round-trip 测试
  - 统计通过/失败数量，100% 通过才算 Phase 3 完成
- `gb2312_codec_test.dart`:
  - 已知 GB2312 字节序列 → 解码 → 验证 Unicode 字符串正确
  - 测试常见中文姓名、棋谱术语

**3.2 实现**
- `lib/utils/gb2312_codec.dart`: GB2312 编解码器（使用 `enough_convert` 包或内嵌查找表）
- `lib/core/xqf/xqf_crypto.dart`:
  - `calculateSecurityKeys(int bKey)` — 移植 `dCalculateSecurityKeys`，每步 `& 0xFF`
  - `decryptBytes(Uint8List data, List<int> f32Keys)` — XOR 解密
  - `encryptBytes(Uint8List data, List<int> f32Keys)` — XOR 加密
  - 内部使用的 32 字节密钥串 `(C) Copyright Mr. Dong Shiwei.`
- `lib/core/xqf/xqf_header.dart`: 1024 字节 header 的 Dart 类，所有字段对应 `dTXQFHead` packed record，提供 `fromBytes(Uint8List)` 和 `toBytes()` 方法
- `lib/core/xqf/xqf_reader.dart`: `readXqfFile(Uint8List bytes)` — 返回完整的棋谱数据结构，移植 `iLoadXQFile` + `dInsertPNintoPlayTree`
- `lib/core/xqf/xqf_writer.dart`: `writeXqfFile(GameData data)` — 返回 `Uint8List`，移植 `iSaveXQFile` + `dSavePlayNodeIntoXQFile`

**3.3 验证**
- `dart test test/core/xqf/` 全部通过
- 50+ 个 .xqf 文件 round-trip 测试 100% 通过
- 256 个 bKey 密钥推导全部匹配参考表

---

### Phase 4: Game Controller (1.5 weeks)

**4.1 先写测试** (`test/core/game/`)
- `game_controller_test.dart`:
  - **走棋序列**：从标准开局执行 "炮二平五, 马8进7, 马二进三" 三步，验证每步后的棋盘状态、当前步数、轮到谁走
  - **悔棋**：走 3 步 → 悔棋 1 步 → 验证棋盘回到第 2 步状态 → 再悔棋 → 验证回到第 1 步
  - **重做**：悔棋后重做，验证恢复到悔棋前的状态
  - **导航**：加载一个 20 步的棋谱 → `goToStep(10)` → 验证棋盘显示第 10 步局面 → `goToFirst()` → 验证回到开局 → `goToLast()` → 验证到最后一步
  - **变例创建**：在第 5 步创建一个变例走法 → 验证变例出现在当前节点的 RChild 链上
  - **变例切换**：有变例的节点 → 切换到变例 → 验证棋盘显示变例走法 → 切回主线 → 验证恢复
  - **变例排序**：上移/下移变例，验证顺序改变
  - **删除走法**：删除第 10 步 → 验证步数变为 9 → 删除有变例的步骤 → 验证变例也被移除
  - **删除主线保留变例**：删除主线走法但有变例 → 验证变例提升为主线
  - **注释管理**：给某步添加注释 → 导航离开再回来 → 验证注释仍在
  - **从 .xqf 加载**：读取一个真实 .xqf 文件，用 GameController 加载，验证能正常导航所有步骤
- `move_record_list_test.dart`:
  - 添加走法记录到列表 → 验证步数递增
  - 列表容量上限 `dCMaxRecNo = 1023`
  - 删除记录后列表收缩

**4.2 实现**
- `lib/core/game/game_controller.dart`: 移植 `dTXiangQi`，纯逻辑无 UI：
  - `makeMove(int fromXY, int toXY)` → 执行走棋（内部调用 move_validator）
  - `undoMove()` → 悔棋
  - `redoMove()` → 重做
  - `goToStep(int n)` / `goToFirst()` / `goToLast()` / `goToPrev()` / `goToNext()` → 导航
  - `addVariation(int fromXY, int toXY)` → 在当前节点添加变例
  - `switchToVariation(int index)` → 切换到第 N 个变例
  - `deleteCurrentMove()` → 删除当前步
  - `setRemark(String text)` / `getRemark()` → 注释管理
  - 状态暴露：`currentStep`, `totalSteps`, `currentBoard`, `currentNode`, `whoPlay`, `variations`
- `lib/core/game/move_record_list.dart`: 走法记录列表，移植 `dTXQRecListBox` 的数据逻辑
- `lib/core/game/variation_list.dart`: 当前节点的变例列表管理

**4.3 验证**
- `dart test test/core/game/` 全部通过
- 用 3-5 个真实 .xqf 文件做端到端测试：加载 → 遍历所有步骤 → 验证每步记谱字符串

---

### Phase 5: Board Rendering (2 weeks)

**5.1 先写测试** (`test/ui/board/`)

- `board_painter_test.dart` — **Golden tests**:
  - 渲染空棋盘（无棋子）→ `matchesGoldenFile('goldens/empty_board.png')`
  - 渲染标准开局 → `matchesGoldenFile('goldens/standard_opening.png')`
  - 渲染中局局面（指定棋子位置）→ `matchesGoldenFile('goldens/midgame_position.png')`
  - 渲染翻转棋盘（黑方视角）→ `matchesGoldenFile('goldens/flipped_board.png')`
  - 渲染走法指示器（from/to 高亮）→ `matchesGoldenFile('goldens/move_indicator.png')`
  - 渲染不同棋子风格（传统 vs 木纹）→ golden 各一张
  - **首次运行**会生成 golden 文件（`flutter test --update-goldens`），人工肉眼确认正确后 check in

- `board_widget_test.dart` — **Widget tests**:
  - 创建 BoardWidget with 标准开局 → 验证 widget 树包含 CustomPaint
  - 验证 widget 尺寸计算：给定 400x500 的约束 → 验证棋盘保持 9:10 比例

- `gesture_handler_test.dart` — **Widget tests**:
  - 模拟 tap 棋盘左上角 → 验证回调收到正确的棋盘坐标 (0, 0)
  - 模拟 tap 棋盘中心 → 验证回调收到 (4, 5)
  - 模拟 tap 棋盘右下角 → 验证回调收到 (8, 9)
  - 模拟 tap 棋盘外区域 → 验证无回调
  - 模拟选中红车(0,0) → tap 目标位置(0,4) → 验证 `onMove(fromXY, toXY)` 回调触发
  - 模拟选中红车 → tap 非法目标 → 验证选中状态取消

**5.2 实现**
- `lib/ui/board/board_painter.dart`: CustomPainter 子类
  - `paintBoard()`: 9 条横线、10 条竖线（中间河界断开竖线）、九宫斜线、星位标记、坐标标签
  - `paintPieces()`: 遍历 BoardState，在对应位置绘制棋子 PNG sprite
  - `paintIndicators()`: from/to 位置高亮
  - `shouldRepaint()`: 仅当棋盘状态或选中状态变化时重绘
- `lib/ui/board/piece_painter.dart`: 棋子图片加载和绘制，支持样式切换
- `lib/ui/board/board_widget.dart`: StatelessWidget，包含 GestureDetector + CustomPaint + RepaintBoundary
- `lib/ui/board/board_gesture_handler.dart`: 将 tap 像素坐标转换为棋盘坐标，管理"选中→落子"两步交互
- `lib/ui/board/board_theme.dart`: 棋子样式配置（传统/木纹），棋盘颜色

**5.3 验证**
- `flutter test test/ui/board/` 全部通过
- Golden tests：首次 `flutter test --update-goldens` 生成 → 肉眼对照原版截图确认 → check in golden 文件
- 手动验证：`flutter run -d linux` → 查看棋盘渲染效果 → 对照 `docs/reference_screenshots/` 中的原版截图
- 验证棋盘在不同窗口尺寸下正确缩放（拖拽调整窗口大小）

---

### Phase 6: Game Screen UI (2 weeks)

**6.1 先写测试** (`test/ui/game/`)

- `game_screen_test.dart` — **Widget tests**:
  - 渲染 GameScreen → 验证包含 BoardWidget、MoveListPanel、NavigationToolbar
  - Golden test: 标准开局的完整界面 → `matchesGoldenFile('goldens/game_screen_opening.png')`

- `move_list_panel_test.dart` — **Widget tests**:
  - 加载一个 10 步棋谱 → 验证列表显示 10 个条目
  - 每个条目格式匹配：步数 + 记谱字符串（如 "1. 炮二平五"）
  - 点击列表中的第 5 步 → 验证 `onStepSelected(5)` 回调触发
  - 当前步高亮显示
  - 有变例的步骤显示标记

- `variation_panel_test.dart` — **Widget tests**:
  - 当前步无变例 → 面板为空或不显示
  - 当前步有 2 个变例 → 显示 2 个选项
  - 点击变例 → 验证 `onVariationSelected(index)` 回调触发

- `remark_panel_test.dart` — **Widget tests**:
  - 当前步有注释 → 显示注释文本
  - 编辑注释 → 验证 `onRemarkChanged(text)` 回调触发
  - 当前步无注释 → 显示空文本区域

- `navigation_toolbar_test.dart` — **Widget tests**:
  - 在开局（第 0 步）→ "First"和"Prev"按钮 disabled
  - 在最后一步 → "Next"和"Last"按钮 disabled
  - 在中间某步 → 所有按钮 enabled
  - 点击 "Next" → 验证 `onNext()` 回调触发
  - 点击 "Delete" → 验证弹出确认对话框

- `auto_play_test.dart` — **Widget tests**:
  - 启动自动播放 → 验证定时器触发 → 步数自动递增
  - 播放到最后一步 → 自动停止
  - 手动停止 → 定时器取消

**6.2 实现**
- `lib/ui/game/game_screen.dart`: 主游戏界面
  - 响应式布局：`LayoutBuilder` 检测宽度
    - 宽屏（>800px）：棋盘左侧 + 右侧 TabView（走法列表、注释、棋局信息）
    - 窄屏（<=800px）：棋盘上方 + 下方 TabView
  - 连接 Riverpod `gameControllerProvider`
- `lib/ui/game/move_list_panel.dart`: 可滚动走法列表，当前步高亮，点击跳转
- `lib/ui/game/variation_panel.dart`: 当前节点的变例选择
- `lib/ui/game/remark_panel.dart`: 可编辑注释文本区域
- `lib/ui/game/player_info_panel.dart`: 红/黑方棋手名、标题、结果
- `lib/ui/game/navigation_toolbar.dart`: First/Prev/Next/Last/Delete 按钮 + 自动播放控制
  - 自动播放速度：0.4s / 0.8s / 1.5s / 3s / 8s（匹配原版的弹出菜单选项）

**6.3 验证**
- `flutter test test/ui/game/` 全部通过
- Golden tests：完整游戏界面的截图 → 人工确认布局正确
- 手动验证（`flutter run -d linux`）：
  - 打开一个 .xqf 文件 → 走法列表正确显示
  - 点击导航按钮 → 棋盘正确更新
  - 点击走法列表中的某步 → 棋盘跳转到该步
  - 切换变例 → 棋盘更新
  - 编辑注释 → 导航离开再回来 → 注释保留
  - 自动播放 → 观察是否流畅
  - 调整窗口大小 → 布局正确切换（宽屏/窄屏）

---

### Phase 7: Application Shell (1.5 weeks)

**7.1 先写测试**

- `test/ui/home/home_screen_test.dart` — **Widget tests**:
  - 初始状态 → 显示空列表或欢迎界面
  - 有 2 个已打开的棋谱 → 显示 2 个 tab/卡片
  - 切换 tab → 验证 `onGameSelected(index)` 回调

- `test/integration_test/file_open_save_test.dart` — **Integration test**:
  - 打开一个 .xqf 文件 → 验证棋盘显示正确的开局
  - 走几步 → 保存到新文件 → 关闭 → 重新打开 → 验证状态一致
  - 新建棋谱 → 手动走几步 → 保存 → 重新打开 → 验证
  - 打开多个文件 → 验证 tab 切换正确

- `test/services/file_service_test.dart` — **Unit test**:
  - mock file picker → 验证 open/save 流程调用正确的 API
  - 验证文件扩展名过滤为 `.xqf`

- `test/services/preferences_service_test.dart` — **Unit test**:
  - 保存偏好设置 → 读取 → 验证一致
  - 缺省值测试

**7.2 实现**
- `lib/ui/home/home_screen.dart`: 主页面，打开的棋谱列表，Tab 或 Card 布局
- `lib/services/file_service.dart`: 平台抽象的文件 I/O
  - Desktop: `file_picker` + `dart:io File`
  - Mobile: `file_picker` + app documents directory
  - Web: `file_picker` web + 内存 `Uint8List`
- `lib/services/preferences_service.dart`: 用 `shared_preferences` 替代 Windows 注册表
- `lib/services/clipboard_service.dart`: 棋谱记录的剪贴板复制/粘贴
- `lib/app.dart`: MaterialApp 配置、路由、主题
- 菜单系统：
  - macOS: `PlatformMenuBar`
  - Windows/Linux: 自定义 `MenuBar` widget
  - Mobile: Drawer 或 AppBar 弹出菜单

**7.3 验证**
- `flutter test test/ui/home/ test/services/` 全部通过
- `flutter test integration_test/file_open_save_test.dart -d linux` 端到端通过
- 手动验证：
  - 菜单栏 File → New/Open/Save/Save As/Close 全部可操作
  - 打开多个文件 → tab 切换 → 每个棋谱独立正确
  - 修改后关闭 → 提示保存
  - 设置持久化：改变某个偏好 → 重启应用 → 偏好保留

---

### Phase 8: Search (1 week)

**8.1 先写测试**

- `test/core/search/game_search_test.dart` — **Unit test**:
  - 创建 3 个已知的 GameData 对象 → 按棋手名搜索 → 验证命中正确的棋谱
  - 按标题搜索 → 验证结果
  - 按结果搜索（红胜/黑胜/和棋）→ 验证过滤
  - 按开局走法搜索 → 验证匹配
  - 空搜索条件 → 返回所有
  - 无匹配 → 返回空

- `test/ui/search/search_screen_test.dart` — **Widget test**:
  - 输入搜索词 → 点击搜索 → 验证结果列表显示
  - 点击搜索结果 → 验证 `onGameSelected` 回调

**8.2 实现**
- `lib/core/search/search_criteria.dart`: 搜索条件（棋手、标题、结果、开局走法、目录路径、是否含子目录）
- `lib/core/search/game_search.dart`: 搜索引擎 — 遍历目录读取 .xqf 文件 header，按条件过滤
- `lib/ui/search/search_screen.dart`: 搜索对话框 UI

**8.3 验证**
- `dart test test/core/search/` 全部通过
- `flutter test test/ui/search/` 全部通过
- 手动验证：在包含多个 .xqf 文件的目录上执行搜索，验证结果正确

---

### Phase 9: Wizard & Dialogs (1 week)

**9.1 先写测试**

- `test/ui/wizard/new_game_wizard_test.dart` — **Widget tests**:
  - 打开向导 → 验证显示空棋盘（可摆子）
  - 选择"标准开局" → 验证棋盘填充标准位置
  - 手动摆放棋子 → 点击完成 → 验证 `onGameCreated(boardState)` 回调携带正确的棋子位置
  - Golden test: 向导界面截图

- `test/ui/dialogs/file_properties_test.dart` — **Widget test**:
  - 传入 GameMetadata → 验证各字段显示正确
  - 修改字段 → 点击确定 → 验证回调携带更新后的 metadata

- `test/core/rules/board_diagram_test.dart` — **Unit test**:
  - 标准开局 → 生成文字棋盘图 → 验证字符串格式匹配（`dMakeQiTuText` 的输出格式）
  - 验证 BBS 彩色模式的 ANSI 转义码正确

**9.2 实现**
- `lib/ui/wizard/new_game_wizard.dart`: 新棋谱向导，可选标准开局或自定义摆子
- `lib/ui/file_properties/file_properties_dialog.dart`: 棋谱属性编辑（标题、棋手、结果等）
- `lib/ui/dialogs/about_dialog.dart`: 关于对话框
- `lib/ui/dialogs/tips_dialog.dart`: 提示对话框
- `lib/services/export_service.dart`: 文字棋盘图导出（移植 `dMakeQiTuText`，支持纯文本和 BBS 彩色）

**9.3 验证**
- `flutter test test/ui/wizard/ test/ui/dialogs/` 全部通过
- 手动验证：新建棋谱向导完整流程、属性编辑保存

---

### Phase 10: Polish & Cross-Platform (1.5 weeks)

**10.1 先写测试**

- `test/ui/board/responsive_layout_test.dart` — **Widget tests**:
  - 400x800 约束（手机竖屏）→ golden test → 验证棋盘在上、面板在下
  - 1200x800 约束（桌面）→ golden test → 验证棋盘在左、面板在右
  - 800x600 约束（小窗口）→ golden test → 验证布局切换点正确

- `test/integration_test/play_through_game_test.dart` — **Integration test**:
  - 完整端到端流程：打开文件 → 浏览所有步骤 → 切换变例 → 查看注释 → 保存 → 重新打开 → 验证

**10.2 实现**
- 响应式布局优化：手机竖屏、平板横屏、桌面窗口三种断点
- 桌面键盘快捷键：← →（前/后一步）、Home/End（跳到开头/结尾）、Ctrl+S（保存）、Ctrl+O（打开）
- 平台文件关联：`.xqf` 文件类型注册
  - Android: `intent-filter` in `AndroidManifest.xml`
  - iOS: `UTI` in `Info.plist`
  - Desktop: 平台特定的文件关联配置
- App 图标和启动画面（各平台尺寸适配）
- 国际化基础设施（中文为主，英文为辅）

**10.3 验证**
- `flutter test` 全部通过（所有 unit + widget tests）
- `flutter test integration_test/ -d linux` 全部通过
- 多平台手动验证：
  - Linux: `flutter run -d linux` → 完整功能测试
  - Android: `flutter run -d <device>` → 触屏交互、文件打开、横竖屏切换
  - Web: `flutter run -d chrome` → 文件上传/下载、布局适配
  - iOS/macOS/Windows: 如有对应环境则测试，否则依赖 CI

---

## Key Porting Pitfalls

1. **1-based indexing**: Piece array `dTXQZXY` is `[1..32]`. Keep 1-based in Dart to avoid hundreds of index bugs.
2. **Byte overflow**: XOR crypto key formula `(((((bKey*bKey)*3+9)*3+8)*2+1)*3+8)*bKey` overflows Byte — must `& 0xFF` at each step.
3. **GB2312 strings**: .xqf metadata uses GB2312 encoding. Dart has no built-in codec.
4. **XY encoding**: Position = `X*10 + Y` in single byte. `0xFF` = captured. Preserve this encoding.
5. **Short strings**: Delphi `String[N]` = 1 byte length prefix + N bytes content. Must handle in binary reader.

## Critical Source Files

| File | What to extract |
|------|----------------|
| `Src/XQDataT.pas` | All constants, types, move validation (the 440-line `sGetPlayRecStr`) |
| `Src/XQFileRW.pas` | Complete .xqf format: header, crypto, tree serialization |
| `Src/XQSystem.pas` | Game controller class `dTXiangQi` (strip UI references) |
| `Src/XQPNode.pas` | Move tree node with exact parent/child linking semantics |
| `Src/XQTable.pas` | UI interaction model reference (3,001 lines, rewrite as Flutter) |

## Verification Summary

测试基准均不依赖运行 Delphi 原始代码（Linux 上无法运行 Delphi 5）：

| 验证项 | 基准来源 | 方法 |
|--------|---------|------|
| XQF round-trip | .xqf 文件原始字节 | 读→写→再读→比对棋谱树 (50+ files) |
| Move validation | 象棋规则（公开知识）| 200+ 步测试集 |
| Crypto keys | XQFileRW.pas 中的数学公式 | Dart 脚本计算 256 个 bKey 参考值 |
| XQF header | `xxd` hex dump | 手动标注字段值作为 expected |
| Board rendering | 原版截图 + 肉眼确认 | Golden tests (`matchesGoldenFile`) |
| UI interaction | 原版行为描述 | Widget tests (`testWidgets`) |
| 端到端流程 | 功能规格 | Integration tests (真机/模拟器) |
| 跨平台适配 | 各平台 UI 规范 | 手动验证 + responsive golden tests |
