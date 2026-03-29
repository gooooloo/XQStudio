# XQStudio Flutter Port — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port XQStudio 1.63 (Delphi 5 Chinese Chess record editor) to Flutter/Dart, targeting all 6 platforms (iOS/Android/macOS/Windows/Linux/Web).

**Architecture:** Pure Dart core layer (models, rules, XQF I/O) with zero Flutter imports, tested via `dart test`. Flutter UI layer uses Riverpod for state, CustomPainter for board rendering. Strict TDD: every phase writes tests first, then implementation.

**Tech Stack:** Flutter 3.41+, Dart 3.11+, Riverpod, CustomPainter, file_picker, path_provider, shared_preferences

**Source reference:** Delphi source is in `Src/` (11,826 lines across 18 files). Key files: `XQDataT.pas` (constants + move validation), `XQPNode.pas` (move tree node), `XQFileRW.pas` (XQF file I/O + crypto), `XQSystem.pas` (game controller), `XQTable.pas` (board UI).

---

## File Structure

```
xqstudio_flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/                    # Pure Dart, zero Flutter imports
│   │   ├── constants.dart       # All constants from XQDataT.pas
│   │   ├── models/
│   │   │   ├── piece.dart       # PieceType enum, Side enum, piece index mapping
│   │   │   ├── position.dart    # Position value class (XY encoding)
│   │   │   ├── board_state.dart # 32-piece position array, move execution
│   │   │   ├── play_node.dart   # Game tree node (port of dTXQPlayNode)
│   │   │   └── game_metadata.dart # Title, players, match info, result
│   │   ├── rules/
│   │   │   ├── move_validator.dart  # Per-piece move validation
│   │   │   ├── move_notation.dart   # Chinese notation generation/parsing
│   │   │   └── king_safety.dart     # King face-to-face, check detection
│   │   ├── xqf/
│   │   │   ├── xqf_crypto.dart  # Key derivation, XOR encrypt/decrypt
│   │   │   ├── xqf_header.dart  # 1024-byte header struct
│   │   │   ├── xqf_reader.dart  # Read .xqf → game tree
│   │   │   └── xqf_writer.dart  # Game tree → .xqf bytes
│   │   ├── game/
│   │   │   ├── game_controller.dart # Navigation, undo/redo, variation management
│   │   │   └── variation_list.dart  # Variation list management
│   │   └── search/
│   │       ├── game_search.dart     # Search engine
│   │       └── search_criteria.dart # Search parameters
│   ├── state/
│   │   ├── game_provider.dart       # Riverpod providers for game state
│   │   └── preferences_provider.dart
│   ├── ui/
│   │   ├── board/
│   │   │   ├── board_widget.dart    # StatelessWidget with CustomPaint
│   │   │   ├── board_painter.dart   # CustomPainter: grid, pieces, indicators
│   │   │   ├── piece_painter.dart   # Piece image loading and drawing
│   │   │   └── board_gesture_handler.dart # Tap → board coordinate conversion
│   │   ├── game/
│   │   │   ├── game_screen.dart     # Main game layout (responsive)
│   │   │   ├── move_list_panel.dart # Scrollable move list
│   │   │   ├── variation_panel.dart # Variation selection
│   │   │   ├── remark_panel.dart    # Editable remarks
│   │   │   └── navigation_toolbar.dart # First/Prev/Next/Last/AutoPlay
│   │   ├── home/
│   │   │   └── home_screen.dart     # Tab-based multi-game view
│   │   ├── search/
│   │   │   └── search_screen.dart
│   │   ├── wizard/
│   │   │   └── new_game_wizard.dart
│   │   └── dialogs/
│   │       ├── about_dialog.dart
│   │       ├── file_properties_dialog.dart
│   │       └── tips_dialog.dart
│   ├── services/
│   │   ├── file_service.dart        # Platform-abstracted file I/O
│   │   ├── preferences_service.dart # SharedPreferences wrapper
│   │   ├── clipboard_service.dart   # Copy/paste game records
│   │   └── export_service.dart      # Text board diagram export
│   └── utils/
│       └── gb2312_codec.dart        # GB2312 ↔ Unicode codec
├── assets/images/
│   ├── pieces/    # red_che.png, blk_ma.png, etc.
│   ├── board/     # board.png, board_small.png
│   └── icons/     # nav icons, app icon
├── test/
│   ├── core/
│   │   ├── models/
│   │   │   ├── piece_test.dart
│   │   │   ├── position_test.dart
│   │   │   ├── board_state_test.dart
│   │   │   └── play_node_test.dart
│   │   ├── rules/
│   │   │   ├── move_validator_test.dart
│   │   │   ├── move_notation_test.dart
│   │   │   └── king_safety_test.dart
│   │   ├── xqf/
│   │   │   ├── xqf_crypto_test.dart
│   │   │   ├── xqf_header_test.dart
│   │   │   ├── xqf_reader_test.dart
│   │   │   ├── xqf_writer_test.dart
│   │   │   └── xqf_roundtrip_test.dart
│   │   ├── game/
│   │   │   └── game_controller_test.dart
│   │   └── search/
│   │       └── game_search_test.dart
│   ├── ui/
│   │   ├── board/
│   │   │   ├── board_painter_test.dart
│   │   │   └── gesture_handler_test.dart
│   │   ├── game/
│   │   │   ├── game_screen_test.dart
│   │   │   ├── move_list_panel_test.dart
│   │   │   └── navigation_toolbar_test.dart
│   │   └── goldens/    # Golden image files
│   ├── utils/
│   │   └── gb2312_codec_test.dart
│   └── fixtures/
│       ├── xqf/        # Real .xqf files for testing
│       └── hex_dumps/   # Extracted header bytes
└── pubspec.yaml
```

---

## Task 0: Project Bootstrap

**Files:**
- Create: `xqstudio_flutter/` (entire Flutter project scaffold)
- Create: `xqstudio_flutter/pubspec.yaml`
- Create: `xqstudio_flutter/analysis_options.yaml`
- Convert: `Bitmap/*.bmp` → `xqstudio_flutter/assets/images/`

- [ ] **Step 0.1: Create Flutter project**

```bash
cd /home/azureuser/dev/XQStudio
flutter create --org net.qipaile --project-name xqstudio xqstudio_flutter
```

- [ ] **Step 0.2: Verify project runs**

```bash
cd /home/azureuser/dev/XQStudio/xqstudio_flutter
flutter analyze
flutter test
```
Expected: No errors, default widget test passes.

- [ ] **Step 0.3: Configure analysis_options.yaml for strict mode**

Replace `xqstudio_flutter/analysis_options.yaml` with:
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_return: error
    dead_code: warning

linter:
  rules:
    - always_declare_return_types
    - prefer_final_locals
    - prefer_const_constructors
    - prefer_const_declarations
    - avoid_print
    - require_trailing_commas
```

- [ ] **Step 0.4: Add dependencies to pubspec.yaml**

Add to `dependencies:` section:
```yaml
  flutter_riverpod: ^2.6.0
  riverpod_annotation: ^2.6.0
  file_picker: ^8.0.0
  path_provider: ^2.1.0
  shared_preferences: ^2.3.0
  enough_convert: ^1.6.0
```

Add to `dev_dependencies:` section:
```yaml
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  mocktail: ^1.0.0
  riverpod_generator: ^2.6.0
  build_runner: ^2.4.0
```

Run: `flutter pub get`

- [ ] **Step 0.5: Convert BMP assets to PNG**

```bash
cd /home/azureuser/dev/XQStudio
sudo apt-get install -y imagemagick
mkdir -p xqstudio_flutter/assets/images/{pieces,board,icons}

# Convert piece images
for f in Bitmap/XQRed-[1-7].bmp; do
  n=$(basename "${f%.bmp}" | sed 's/XQRed-//')
  convert "$f" "xqstudio_flutter/assets/images/pieces/red_${n}.png"
done
for f in Bitmap/XQRed-S[1-7].bmp; do
  n=$(basename "${f%.bmp}" | sed 's/XQRed-S//')
  convert "$f" "xqstudio_flutter/assets/images/pieces/red_${n}_sel.png"
done
for f in Bitmap/XQRed-WBS[1-7].bmp; do
  n=$(basename "${f%.bmp}" | sed 's/XQRed-WBS//')
  convert "$f" "xqstudio_flutter/assets/images/pieces/red_${n}_wb.png"
done
for f in Bitmap/XQBlk-[1-7].bmp; do
  n=$(basename "${f%.bmp}" | sed 's/XQBlk-//')
  convert "$f" "xqstudio_flutter/assets/images/pieces/blk_${n}.png"
done
for f in Bitmap/XQBlk-S[1-7].bmp; do
  n=$(basename "${f%.bmp}" | sed 's/XQBlk-S//')
  convert "$f" "xqstudio_flutter/assets/images/pieces/blk_${n}_sel.png"
done
for f in Bitmap/XQBlk-WBS[1-7].bmp; do
  n=$(basename "${f%.bmp}" | sed 's/XQBlk-WBS//')
  convert "$f" "xqstudio_flutter/assets/images/pieces/blk_${n}_wb.png"
done

# Board images
convert Bitmap/XQBoard.bmp xqstudio_flutter/assets/images/board/board.png
convert Bitmap/XQBoardS.bmp xqstudio_flutter/assets/images/board/board_small.png
convert Bitmap/XQBoardWithNum.bmp xqstudio_flutter/assets/images/board/board_with_num.png

# Navigation icons
for f in XQFirst XQLast XQNext XQPrior XQToL XQToR XQDel; do
  convert "Bitmap/${f}.bmp" "xqstudio_flutter/assets/images/icons/${f}.png"
done

# App icon
convert Bitmap/XQStudio.bmp xqstudio_flutter/assets/images/icons/app_icon.png
```

- [ ] **Step 0.6: Declare assets in pubspec.yaml**

Add to pubspec.yaml:
```yaml
flutter:
  assets:
    - assets/images/pieces/
    - assets/images/board/
    - assets/images/icons/
```

- [ ] **Step 0.7: Create directory structure for source code**

```bash
cd /home/azureuser/dev/XQStudio/xqstudio_flutter
mkdir -p lib/{core/{models,rules,xqf,game,search},state,ui/{board,game,home,search,wizard,dialogs},services,utils}
mkdir -p test/{core/{models,rules,xqf,game,search},ui/{board,game,goldens},utils,fixtures/{xqf,hex_dumps}}
```

- [ ] **Step 0.8: Remove default test, verify clean state**

Delete `test/widget_test.dart` (the default generated test).

Run:
```bash
flutter analyze
```
Expected: No issues.

- [ ] **Step 0.9: Commit**

```bash
git add xqstudio_flutter/
git commit -m "feat: bootstrap Flutter project with assets and dependencies"
```

---

## Task 1: Core Constants

**Files:**
- Create: `lib/core/constants.dart`
- Test: `test/core/constants_test.dart` (optional sanity check)

**Source reference:** `Src/XQDataT.pas` lines 52-109, `Src/XQSystem.pas` lines 170-171

- [ ] **Step 1.1: Create constants.dart**

```dart
/// Constants ported from XQDataT.pas and XQSystem.pas.
const String kProductName = 'XQStudio';
const String kMainVersion = '1.63';
const int kFileVersion = 18;
const int kMaxRecNo = 1023;
const int kMaxVarNo = 1023;

/// XY value for a captured (off-board) piece.
const int kCapturedXY = 0xFF;

/// Initial positions of all 32 pieces (1-based, index 0 unused).
/// Encoding: tens digit = X (0-8), ones digit = Y (0-9).
/// Red: Che Che Ma Ma Xiang Xiang Shi Shi Shuai Pao Pao Bing Bing Bing Bing Bing
/// Black: Che Che Ma Ma Xiang Xiang Shi Shi Jiang Pao Pao Zu Zu Zu Zu Zu
/// Piece ordering: right-to-left, bottom-to-top for each side.
const List<int> kInitialPieceXY = [
  0,  // index 0 unused (1-based)
  // Red pieces (1-16): right to left
  80, 70, 60, 50, 40, 30, 20, 10, 00, // Che Ma Xiang Shi Shuai Shi Xiang Ma Che → actually...
  72, 12, // Pao Pao
  83, 63, 43, 23, 03, // Bing x5
  // Black pieces (17-32): right to left
  09, 19, 29, 39, 49, 59, 69, 79, 89, // Che Ma Xiang Shi Jiang Shi Xiang Ma Che
  17, 77, // Pao Pao
  06, 26, 46, 66, 86, // Zu x5
];
// Note: kInitialPieceXY has 33 elements (index 0..32), matching Delphi's dTXQZXY [1..32].

/// Red numbering system (一二三...九). Index 0 unused.
const List<String> kRedNum = ['0', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

/// Black numbering system (９８７...１). Index 0 unused.
const List<String> kBlkNum = ['0', '９', '８', '７', '６', '５', '４', '３', '２', '１'];
```

- [ ] **Step 1.2: Verify it compiles**

Run: `dart analyze lib/core/constants.dart`
Expected: No issues.

- [ ] **Step 1.3: Commit**

```bash
git add lib/core/constants.dart
git commit -m "feat: add core constants ported from XQDataT.pas"
```

---

## Task 2: Piece Model

**Files:**
- Create: `lib/core/models/piece.dart`
- Test: `test/core/models/piece_test.dart`

**Source reference:** `Src/XQDataT.pas` lines 72-82 (piece numbering comments)

- [ ] **Step 2.1: Write failing tests**

```dart
// test/core/models/piece_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/models/piece.dart';

void main() {
  group('PieceType', () {
    test('has 7 types', () {
      expect(PieceType.values.length, 7);
    });
  });

  group('Side', () {
    test('piece index 1-16 is red', () {
      for (var i = 1; i <= 16; i++) {
        expect(Piece.sideOf(i), Side.red, reason: 'piece $i should be red');
      }
    });

    test('piece index 17-32 is black', () {
      for (var i = 17; i <= 32; i++) {
        expect(Piece.sideOf(i), Side.black, reason: 'piece $i should be black');
      }
    });
  });

  group('Piece.typeOf', () {
    test('index 1 and 9 are Che (red)', () {
      expect(Piece.typeOf(1), PieceType.che);
      expect(Piece.typeOf(9), PieceType.che);
    });

    test('index 2 and 8 are Ma (red)', () {
      expect(Piece.typeOf(2), PieceType.ma);
      expect(Piece.typeOf(8), PieceType.ma);
    });

    test('index 5 is Shuai (red king)', () {
      expect(Piece.typeOf(5), PieceType.shuai);
    });

    test('index 21 is Jiang (black king)', () {
      expect(Piece.typeOf(21), PieceType.shuai);
    });

    test('index 10-11 are Pao (red)', () {
      expect(Piece.typeOf(10), PieceType.pao);
      expect(Piece.typeOf(11), PieceType.pao);
    });

    test('index 12-16 are Bing (red)', () {
      for (var i = 12; i <= 16; i++) {
        expect(Piece.typeOf(i), PieceType.bing);
      }
    });
  });
}
```

- [ ] **Step 2.2: Run test to verify it fails**

Run: `cd /home/azureuser/dev/XQStudio/xqstudio_flutter && dart test test/core/models/piece_test.dart`
Expected: FAIL — cannot find `package:xqstudio/core/models/piece.dart`

- [ ] **Step 2.3: Implement piece.dart**

```dart
// lib/core/models/piece.dart

enum PieceType { che, ma, xiang, shi, shuai, pao, bing }

enum Side { red, black }

/// Utility for mapping 1-based piece indices to type and side.
///
/// Piece indices follow Delphi's convention (XQDataT.pas):
///   Red  1-16: Che(R) Ma Xiang Shi Shuai Shi Xiang Ma Che(L) Pao Pao Bing×5
///   Black 17-32: same layout
class Piece {
  Piece._();

  /// The 16-piece layout within each side (0-based offset within side).
  /// Indices 0-8: Che Ma Xiang Shi Shuai Shi Xiang Ma Che
  /// Indices 9-10: Pao Pao
  /// Indices 11-15: Bing×5
  static const _typeMap = [
    PieceType.che,    // 0 → index 1 or 17
    PieceType.ma,     // 1 → index 2 or 18
    PieceType.xiang,  // 2 → index 3 or 19
    PieceType.shi,    // 3 → index 4 or 20
    PieceType.shuai,  // 4 → index 5 or 21
    PieceType.shi,    // 5 → index 6 or 22
    PieceType.xiang,  // 6 → index 7 or 23
    PieceType.ma,     // 7 → index 8 or 24
    PieceType.che,    // 8 → index 9 or 25
    PieceType.pao,    // 9 → index 10 or 26
    PieceType.pao,    // 10 → index 11 or 27
    PieceType.bing,   // 11 → index 12 or 28
    PieceType.bing,   // 12 → index 13 or 29
    PieceType.bing,   // 13 → index 14 or 30
    PieceType.bing,   // 14 → index 15 or 31
    PieceType.bing,   // 15 → index 16 or 32
  ];

  static Side sideOf(int index) {
    assert(index >= 1 && index <= 32);
    return index <= 16 ? Side.red : Side.black;
  }

  static PieceType typeOf(int index) {
    assert(index >= 1 && index <= 32);
    return _typeMap[(index - 1) % 16];
  }
}
```

- [ ] **Step 2.4: Run test to verify it passes**

Run: `dart test test/core/models/piece_test.dart`
Expected: All tests pass.

- [ ] **Step 2.5: Commit**

```bash
git add lib/core/models/piece.dart test/core/models/piece_test.dart
git commit -m "feat: add Piece model with type/side mapping"
```

---

## Task 3: Position Model

**Files:**
- Create: `lib/core/models/position.dart`
- Test: `test/core/models/position_test.dart`

**Source reference:** `Src/XQDataT.pas` lines 78-82 (XY encoding description)

- [ ] **Step 3.1: Write failing tests**

```dart
// test/core/models/position_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/models/position.dart';

void main() {
  group('Position', () {
    test('fromXY decodes correctly', () {
      final p = Position.fromXY(43);
      expect(p.x, 4);
      expect(p.y, 3);
    });

    test('toXY encodes correctly', () {
      expect(const Position(4, 3).toXY(), 43);
    });

    test('round-trip all valid positions', () {
      for (var x = 0; x <= 8; x++) {
        for (var y = 0; y <= 9; y++) {
          final xy = x * 10 + y;
          final p = Position.fromXY(xy);
          expect(p.x, x);
          expect(p.y, y);
          expect(p.toXY(), xy);
        }
      }
    });

    test('origin (0,0) encodes to 0', () {
      expect(const Position(0, 0).toXY(), 0);
    });

    test('max position (8,9) encodes to 89', () {
      expect(const Position(8, 9).toXY(), 89);
    });

    test('isValid returns true for board positions', () {
      expect(const Position(0, 0).isValid, true);
      expect(const Position(8, 9).isValid, true);
      expect(const Position(4, 5).isValid, true);
    });

    test('equality and hashCode', () {
      expect(const Position(3, 7), const Position(3, 7));
      expect(const Position(3, 7).hashCode, const Position(3, 7).hashCode);
      expect(const Position(3, 7), isNot(const Position(7, 3)));
    });
  });
}
```

- [ ] **Step 3.2: Run test to verify it fails**

Run: `dart test test/core/models/position_test.dart`
Expected: FAIL

- [ ] **Step 3.3: Implement position.dart**

```dart
// lib/core/models/position.dart

/// A position on the 9×10 xiangqi board.
///
/// XY encoding: tens digit = X (column, 0-8), ones digit = Y (row, 0-9).
/// Origin (0,0) is bottom-left from Red's perspective.
class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  factory Position.fromXY(int xy) => Position(xy ~/ 10, xy % 10);

  int toXY() => x * 10 + y;

  bool get isValid => x >= 0 && x <= 8 && y >= 0 && y <= 9;

  @override
  bool operator ==(Object other) =>
      other is Position && other.x == x && other.y == y;

  @override
  int get hashCode => x * 10 + y;

  @override
  String toString() => 'Position($x, $y)';
}
```

- [ ] **Step 3.4: Run test to verify it passes**

Run: `dart test test/core/models/position_test.dart`
Expected: All pass.

- [ ] **Step 3.5: Commit**

```bash
git add lib/core/models/position.dart test/core/models/position_test.dart
git commit -m "feat: add Position model with XY encoding"
```

---

## Task 4: Board State Model

**Files:**
- Create: `lib/core/models/board_state.dart`
- Test: `test/core/models/board_state_test.dart`

**Source reference:** `Src/XQSystem.pas` lines 170-171 (dCXqzXY), `Src/XQDataT.pas` lines 78-82

- [ ] **Step 4.1: Write failing tests**

```dart
// test/core/models/board_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/models/piece.dart';

void main() {
  group('BoardState', () {
    test('standard opening has 32 pieces on board', () {
      final board = BoardState.standard();
      var count = 0;
      for (var i = 1; i <= 32; i++) {
        if (board.pieceXY(i) != kCapturedXY) count++;
      }
      expect(count, 32);
    });

    test('standard opening matches kInitialPieceXY', () {
      final board = BoardState.standard();
      for (var i = 1; i <= 32; i++) {
        expect(board.pieceXY(i), kInitialPieceXY[i], reason: 'piece $i');
      }
    });

    test('red shuai (index 5) is at position (4,0) = XY 40', () {
      final board = BoardState.standard();
      expect(board.pieceXY(5), 40);
    });

    test('black jiang (index 21) is at position (4,9) = XY 49', () {
      final board = BoardState.standard();
      expect(board.pieceXY(21), 49);
    });

    test('pieceIndexAt returns piece at given XY', () {
      final board = BoardState.standard();
      expect(board.pieceIndexAt(40), 5); // red shuai
      expect(board.pieceIndexAt(49), 21); // black jiang
      expect(board.pieceIndexAt(44), 0); // empty square
    });

    test('movePiece updates positions', () {
      final board = BoardState.standard();
      // Move red che from (8,0)=80 to (8,4)=84
      final newBoard = board.movePiece(80, 84);
      expect(newBoard.pieceXY(1), 84); // piece 1 is red che at 80
      expect(newBoard.pieceIndexAt(80), 0); // old position empty
      expect(newBoard.pieceIndexAt(84), 1); // new position has piece
    });

    test('movePiece captures opponent piece', () {
      // Set up: move red che to a position where black piece is
      final board = BoardState.standard();
      // Red che (index 1) at 80, black che (index 17) at 09
      // Force a capture scenario by manually constructing
      final pieces = List<int>.from(kInitialPieceXY);
      pieces[1] = 09; // move red che to where black che is — would be a capture
      // Actually, let's just test the capture logic directly
      final customBoard = BoardState.fromList(pieces);
      // At XY 09, both piece 1 (red che, placed at 09) and piece 17 (black che, at 09)
      // The last one placed wins — but actually BoardState should handle this.
      // Better test: use movePiece to capture
      final board2 = BoardState.standard();
      // Move red pao (index 10) from 72 to 77 (where black pao is at 77)
      final captured = board2.movePiece(72, 77);
      expect(captured.pieceXY(10), 77); // red pao moved
      expect(captured.pieceXY(27), kCapturedXY); // black pao captured
    });

    test('clone creates independent copy', () {
      final board = BoardState.standard();
      final clone = board.clone();
      final modified = clone.movePiece(80, 84);
      expect(board.pieceXY(1), 80); // original unchanged
      expect(modified.pieceXY(1), 84);
    });
  });
}
```

- [ ] **Step 4.2: Run test to verify it fails**

Run: `dart test test/core/models/board_state_test.dart`
Expected: FAIL

- [ ] **Step 4.3: Implement board_state.dart**

```dart
// lib/core/models/board_state.dart
import 'package:xqstudio/core/constants.dart';

/// Immutable representation of all 32 pieces' positions on the board.
///
/// Uses 1-based indexing (index 0 unused) matching Delphi's dTXQZXY[1..32].
/// Each value is an XY-encoded position, or [kCapturedXY] (0xFF) if captured.
class BoardState {
  /// 33 elements: index 0 is unused, indices 1-32 are piece positions.
  final List<int> _pieces;

  BoardState._(this._pieces);

  /// Standard opening position.
  factory BoardState.standard() => BoardState.fromList(kInitialPieceXY);

  /// Construct from a 33-element list (index 0 unused).
  factory BoardState.fromList(List<int> pieces) {
    assert(pieces.length == 33);
    return BoardState._(List<int>.unmodifiable(pieces));
  }

  /// Get the XY position of piece [index] (1-32).
  int pieceXY(int index) => _pieces[index];

  /// Find which piece (1-32) is at [xy], or 0 if empty.
  int pieceIndexAt(int xy) {
    for (var i = 1; i <= 32; i++) {
      if (_pieces[i] == xy) return i;
    }
    return 0;
  }

  /// Return a new BoardState with the piece at [fromXY] moved to [toXY].
  /// If an opponent piece is at [toXY], it is captured (set to kCapturedXY).
  BoardState movePiece(int fromXY, int toXY) {
    final newPieces = List<int>.of(_pieces);
    final moverIndex = pieceIndexAt(fromXY);
    assert(moverIndex != 0, 'No piece at XY=$fromXY');

    // Capture any piece at destination
    final capturedIndex = pieceIndexAt(toXY);
    if (capturedIndex != 0) {
      newPieces[capturedIndex] = kCapturedXY;
    }

    newPieces[moverIndex] = toXY;
    return BoardState._(List<int>.unmodifiable(newPieces));
  }

  /// Create an independent mutable copy.
  BoardState clone() => BoardState._(List<int>.of(_pieces));

  /// Get the raw pieces list (for serialization).
  List<int> toList() => List<int>.of(_pieces);
}
```

- [ ] **Step 4.4: Run test to verify it passes**

Run: `dart test test/core/models/board_state_test.dart`
Expected: All pass.

- [ ] **Step 4.5: Commit**

```bash
git add lib/core/models/board_state.dart test/core/models/board_state_test.dart
git commit -m "feat: add BoardState model with standard opening and move logic"
```

---

## Task 5: Play Node (Game Tree Node)

**Files:**
- Create: `lib/core/models/play_node.dart`
- Test: `test/core/models/play_node_test.dart`

**Source reference:** `Src/XQPNode.pas` lines 55-126 — complete file

- [ ] **Step 5.1: Write failing tests**

```dart
// test/core/models/play_node_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/play_node.dart';

void main() {
  group('PlayNode', () {
    test('root node has stepNo 0 and no children', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      expect(root.stepNo, 0);
      expect(root.lChild, isNull);
      expect(root.rChild, isNull);
      expect(root.strRec, '');
    });

    test('setLChild links parent and child correctly', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      final child = PlayNode(
        stepNo: 1,
        strRec: '炮二平五',
        xyf: 77,
        xyt: 74,
        qiziXY: List<int>.from(kInitialPieceXY),
      );
      root.setLChild(child);
      expect(root.lChild, child);
      expect(child.rParent, root);
      expect(child.lParent, isNull);
    });

    test('setRChild links as sibling (variation)', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      final mainMove = PlayNode(
        stepNo: 1,
        strRec: '炮二平五',
        xyf: 77,
        xyt: 74,
        qiziXY: List<int>.from(kInitialPieceXY),
      );
      final variation = PlayNode(
        stepNo: 1,
        strRec: '马八进七',
        xyf: 10,
        xyt: 22,
        qiziXY: List<int>.from(kInitialPieceXY),
      );
      root.setLChild(mainMove);
      mainMove.setRChild(variation);
      expect(mainMove.rChild, variation);
      expect(variation.lParent, mainMove);
      expect(variation.rParent, isNull);
    });

    test('3-level deep tree with variations', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      final step1 = PlayNode(stepNo: 1, strRec: 'S1', xyf: 0, xyt: 0, qiziXY: List<int>.from(kInitialPieceXY));
      final step2 = PlayNode(stepNo: 2, strRec: 'S2', xyf: 0, xyt: 0, qiziXY: List<int>.from(kInitialPieceXY));
      final step3 = PlayNode(stepNo: 3, strRec: 'S3', xyf: 0, xyt: 0, qiziXY: List<int>.from(kInitialPieceXY));
      final var2a = PlayNode(stepNo: 2, strRec: 'V2a', xyf: 0, xyt: 0, qiziXY: List<int>.from(kInitialPieceXY));
      final var2b = PlayNode(stepNo: 2, strRec: 'V2b', xyf: 0, xyt: 0, qiziXY: List<int>.from(kInitialPieceXY));

      root.setLChild(step1);
      step1.setLChild(step2);
      step2.setLChild(step3);
      // Add 2 variations at step 2
      step2.setRChild(var2a);
      var2a.setRChild(var2b);

      // Verify main line traversal
      expect(root.lChild, step1);
      expect(step1.lChild, step2);
      expect(step2.lChild, step3);

      // Verify variations
      expect(step2.rChild, var2a);
      expect(var2a.rChild, var2b);
    });

    test('detach removes node from parent', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      final child = PlayNode(stepNo: 1, strRec: 'S1', xyf: 0, xyt: 0, qiziXY: List<int>.from(kInitialPieceXY));
      root.setLChild(child);
      child.detach();
      expect(root.lChild, isNull);
    });
  });
}
```

- [ ] **Step 5.2: Run test to verify it fails**

Run: `dart test test/core/models/play_node_test.dart`
Expected: FAIL

- [ ] **Step 5.3: Implement play_node.dart**

```dart
// lib/core/models/play_node.dart

/// A node in the game move tree, ported from dTXQPlayNode (XQPNode.pas).
///
/// Tree structure:
/// - [lChild]: next move in main line (left child)
/// - [rChild]: first variation at this position (right child / sibling)
/// - [lParent]: non-null if this node is a variation (sibling link back)
/// - [rParent]: non-null if this node is a main-line child
class PlayNode {
  int stepNo;
  String strRec;
  int xyf;
  int xyt;
  List<int> qiziXY; // 33-element list, 1-based
  List<String>? remark;
  PlayNode? lastStepNode;
  PlayNode? lParent;
  PlayNode? rParent;
  PlayNode? lChild;
  PlayNode? rChild;

  PlayNode({
    required this.stepNo,
    required this.strRec,
    required this.xyf,
    required this.xyt,
    required this.qiziXY,
    this.remark,
    this.lastStepNode,
    this.lParent,
    this.rParent,
  });

  /// Create the root node (step 0, initial position).
  factory PlayNode.root(List<int> initialPieceXY) => PlayNode(
        stepNo: 0,
        strRec: '',
        xyf: 0,
        xyt: 0,
        qiziXY: initialPieceXY,
      );

  /// Set [node] as the left child (main-line continuation).
  /// Mirrors dTXQPlayNode.dSetLChild from XQPNode.pas:86-90.
  void setLChild(PlayNode? node) {
    lChild = node;
    if (node != null) {
      node.rParent = this;
      node.lParent = null;
    }
  }

  /// Set [node] as the right child (variation/sibling).
  /// Mirrors dTXQPlayNode.dSetRChild from XQPNode.pas:92-96.
  void setRChild(PlayNode? node) {
    rChild = node;
    if (node != null) {
      node.lParent = this;
      node.rParent = null;
    }
  }

  /// Detach this node from its parent.
  void detach() {
    if (lParent != null) {
      lParent!.rChild = null;
      lParent = null;
    }
    if (rParent != null) {
      rParent!.lChild = null;
      rParent = null;
    }
  }
}
```

- [ ] **Step 5.4: Run test to verify it passes**

Run: `dart test test/core/models/play_node_test.dart`
Expected: All pass.

- [ ] **Step 5.5: Commit**

```bash
git add lib/core/models/play_node.dart test/core/models/play_node_test.dart
git commit -m "feat: add PlayNode game tree node ported from XQPNode.pas"
```

---

## Task 6: Game Metadata Model

**Files:**
- Create: `lib/core/models/game_metadata.dart`
- Test: (trivial data class, tested implicitly by XQF reader tests)

- [ ] **Step 6.1: Implement game_metadata.dart**

```dart
// lib/core/models/game_metadata.dart

enum GameResult { unknown, redWin, blackWin, draw }
enum WhoPlay { red, black, none, pause }

class GameMetadata {
  String titleA;
  String titleB;
  String matchName;
  String matchTime;
  String matchAddr;
  String redPlayer;
  String blkPlayer;
  String timeRule;
  String redTime;
  String blkTime;
  String rmkWriter;
  String author;
  GameResult result;
  WhoPlay whoPlay;

  GameMetadata({
    this.titleA = '',
    this.titleB = '',
    this.matchName = '',
    this.matchTime = '',
    this.matchAddr = '',
    this.redPlayer = '',
    this.blkPlayer = '',
    this.timeRule = '',
    this.redTime = '',
    this.blkTime = '',
    this.rmkWriter = '',
    this.author = '',
    this.result = GameResult.unknown,
    this.whoPlay = WhoPlay.red,
  });
}
```

- [ ] **Step 6.2: Verify it compiles**

Run: `dart analyze lib/core/models/game_metadata.dart`
Expected: No issues.

- [ ] **Step 6.3: Commit**

```bash
git add lib/core/models/game_metadata.dart
git commit -m "feat: add GameMetadata model"
```

---

## Task 7: Move Validator

**Files:**
- Create: `lib/core/rules/move_validator.dart`
- Create: `lib/core/rules/king_safety.dart`
- Test: `test/core/rules/move_validator_test.dart`
- Test: `test/core/rules/king_safety_test.dart`

**Source reference:** `Src/XQDataT.pas` lines 115-555 (`sGetPlayRecStr` — 440 lines of move validation + notation). This is the most complex porting task in the core layer.

**Approach:** Port `sGetPlayRecStr` but split it into two concerns: (1) validation — `isValidMove()`, (2) notation — `generateNotation()`. Both share the same per-piece-type dispatch logic.

- [ ] **Step 7.1: Write king_safety tests**

```dart
// test/core/rules/king_safety_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/rules/king_safety.dart';

void main() {
  group('KingSafety', () {
    test('standard opening: kings not facing each other', () {
      final board = BoardState.standard();
      expect(KingSafety.kingsAreFacing(board), false);
    });

    test('kings facing on same column with no pieces between', () {
      // Place red shuai at (4,0) and black jiang at (4,9), clear column 4
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 40;   // red shuai
      pieces[21] = 49;  // black jiang
      final board = BoardState.fromList(pieces);
      expect(KingSafety.kingsAreFacing(board), true);
    });

    test('kings on same column but piece between: not facing', () {
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 40;   // red shuai
      pieces[21] = 49;  // black jiang
      pieces[10] = 44;  // red pao in between
      final board = BoardState.fromList(pieces);
      expect(KingSafety.kingsAreFacing(board), false);
    });

    test('kings on different columns: not facing', () {
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 30;   // red shuai at (3,0)
      pieces[21] = 49;  // black jiang at (4,9)
      final board = BoardState.fromList(pieces);
      expect(KingSafety.kingsAreFacing(board), false);
    });
  });
}
```

- [ ] **Step 7.2: Run king safety test to verify it fails**

Run: `dart test test/core/rules/king_safety_test.dart`
Expected: FAIL

- [ ] **Step 7.3: Implement king_safety.dart**

```dart
// lib/core/rules/king_safety.dart
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/models/position.dart';

class KingSafety {
  KingSafety._();

  /// Check if the two kings are directly facing each other (illegal position).
  /// Red shuai = piece 5, Black jiang = piece 21.
  static bool kingsAreFacing(BoardState board) {
    final redXY = board.pieceXY(5);
    final blkXY = board.pieceXY(21);
    if (redXY == kCapturedXY || blkXY == kCapturedXY) return false;

    final redPos = Position.fromXY(redXY);
    final blkPos = Position.fromXY(blkXY);

    // Must be on same column
    if (redPos.x != blkPos.x) return false;

    // Check if any piece is between them on this column
    final minY = redPos.y < blkPos.y ? redPos.y + 1 : blkPos.y + 1;
    final maxY = redPos.y > blkPos.y ? redPos.y : blkPos.y;
    for (var y = minY; y < maxY; y++) {
      if (board.pieceIndexAt(redPos.x * 10 + y) != 0) return false;
    }
    return true;
  }
}
```

- [ ] **Step 7.4: Run king safety test to verify it passes**

Run: `dart test test/core/rules/king_safety_test.dart`
Expected: All pass.

- [ ] **Step 7.5: Write move_validator tests (comprehensive, by piece type)**

Create `test/core/rules/move_validator_test.dart` with test groups for each piece type:
- Che (Rook): straight-line movement, blocking, capture
- Ma (Knight): L-shape, hobbled leg (蹩马腿)
- Xiang (Elephant): diagonal 2, blocking eye (塞象眼), cannot cross river
- Shi (Advisor): diagonal 1 within palace
- Shuai/Jiang (King): orthogonal 1 within palace, king-facing check
- Pao (Cannon): straight move without capture, jump-capture over exactly 1 piece
- Bing/Zu (Pawn): forward only before river, forward + sideways after river

Each test constructs a specific board position and verifies `isValidMove()` returns true/false.

Minimum 80 test cases covering valid moves, invalid moves, boundary conditions.

- [ ] **Step 7.6: Run tests to verify they fail**

Run: `dart test test/core/rules/move_validator_test.dart`
Expected: FAIL

- [ ] **Step 7.7: Implement move_validator.dart**

Port the validation logic from `sGetPlayRecStr` (XQDataT.pas:115-555), splitting into per-piece-type methods:
- `isValidMove(BoardState board, int fromXY, int toXY) → bool`
- Internal: `_validateChe()`, `_validateMa()`, `_validateXiang()`, `_validateShi()`, `_validateShuai()`, `_validatePao()`, `_validateBing()`
- After each move, check `KingSafety.kingsAreFacing()` — if facing, the move is illegal.

Key porting notes from `sGetPlayRecStr`:
- Piece side detection: index 1-16 = red, 17-32 = black
- Capture validation: cannot capture own pieces
- Path blocking: Che/Pao check each square along the path
- Ma hobble: check the blocking square at `(Xf + dx_half, Yf + dy_half)`
- Xiang eye: check the blocking square at `(Xf + dx/2, Yf + dy/2)`

- [ ] **Step 7.8: Run tests to verify they pass**

Run: `dart test test/core/rules/move_validator_test.dart`
Expected: All pass.

- [ ] **Step 7.9: Commit**

```bash
git add lib/core/rules/ test/core/rules/
git commit -m "feat: add move validator and king safety ported from sGetPlayRecStr"
```

---

## Task 8: Move Notation

**Files:**
- Create: `lib/core/rules/move_notation.dart`
- Test: `test/core/rules/move_notation_test.dart`

**Source reference:** `Src/XQDataT.pas` lines 115-555 (notation generation part of `sGetPlayRecStr`)

- [ ] **Step 8.1: Write failing tests**

Test cases for Chinese move notation:
- Standard opening moves: 炮二平五, 马八进七, 车九平八
- Direction characters: 进 (advance), 退 (retreat), 平 (horizontal)
- Red uses Chinese numerals (一二三...九), Black uses Arabic-style (１２３...９)
- Multi-piece disambiguation: 前车, 后车, 前马, 后马
- Multi-pawn: 前兵, 中兵, 后兵 (2-3 pawns in same column)
- Round-trip: generate notation → parse notation → verify from/to match

- [ ] **Step 8.2: Run tests to verify they fail**

Run: `dart test test/core/rules/move_notation_test.dart`
Expected: FAIL

- [ ] **Step 8.3: Implement move_notation.dart**

Port the notation logic from `sGetPlayRecStr`:
- `String generateNotation(BoardState board, int fromXY, int toXY)` — generate Chinese notation string
- `({int fromXY, int toXY})? parseNotation(BoardState board, WhoPlay who, String notation)` — reverse: notation → from/to
- Uses `kRedNum` and `kBlkNum` arrays from constants.dart

- [ ] **Step 8.4: Run tests to verify they pass**

Run: `dart test test/core/rules/move_notation_test.dart`
Expected: All pass.

- [ ] **Step 8.5: Commit**

```bash
git add lib/core/rules/move_notation.dart test/core/rules/move_notation_test.dart
git commit -m "feat: add Chinese move notation generation and parsing"
```

---

## Task 9: GB2312 Codec

**Files:**
- Create: `lib/utils/gb2312_codec.dart`
- Test: `test/utils/gb2312_codec_test.dart`

- [ ] **Step 9.1: Write failing tests**

```dart
// test/utils/gb2312_codec_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/utils/gb2312_codec.dart';

void main() {
  group('GB2312 codec', () {
    test('decode known Chinese string', () {
      // "象棋" in GB2312: CF F3 C6 E5
      final bytes = Uint8List.fromList([0xCF, 0xF3, 0xC6, 0xE5]);
      expect(decodeGB2312(bytes), '象棋');
    });

    test('decode ASCII passthrough', () {
      final bytes = Uint8List.fromList([0x41, 0x42, 0x43]); // "ABC"
      expect(decodeGB2312(bytes), 'ABC');
    });

    test('decode mixed ASCII and Chinese', () {
      // "XQ象棋" = 58 51 CF F3 C6 E5
      final bytes = Uint8List.fromList([0x58, 0x51, 0xCF, 0xF3, 0xC6, 0xE5]);
      expect(decodeGB2312(bytes), 'XQ象棋');
    });

    test('encode and decode round-trip', () {
      const text = '红方：张三';
      final encoded = encodeGB2312(text);
      expect(decodeGB2312(encoded), text);
    });
  });
}
```

- [ ] **Step 9.2: Run tests to verify they fail**

Run: `dart test test/utils/gb2312_codec_test.dart`
Expected: FAIL

- [ ] **Step 9.3: Implement gb2312_codec.dart**

Use the `enough_convert` package which provides GBK/GB2312 support:

```dart
// lib/utils/gb2312_codec.dart
import 'dart:typed_data';
import 'package:enough_convert/enough_convert.dart';

final _codec = const GbkCodec(allowInvalid: false);

String decodeGB2312(Uint8List bytes) => _codec.decode(bytes);

Uint8List encodeGB2312(String text) => Uint8List.fromList(_codec.encode(text));
```

- [ ] **Step 9.4: Run tests to verify they pass**

Run: `dart test test/utils/gb2312_codec_test.dart`
Expected: All pass.

- [ ] **Step 9.5: Commit**

```bash
git add lib/utils/gb2312_codec.dart test/utils/gb2312_codec_test.dart
git commit -m "feat: add GB2312 codec using enough_convert"
```

---

## Task 10: XQF Crypto

**Files:**
- Create: `lib/core/xqf/xqf_crypto.dart`
- Test: `test/core/xqf/xqf_crypto_test.dart`

**Source reference:** `Src/XQFileRW.pas` lines 161-199 (F32Keys), lines 483-506 (dCalculateSecurityKeys), lines 201-260 (Read=subtract decrypt, Write=addition encrypt)

**CRITICAL:** The .xqf encryption uses **subtraction/addition**, NOT XOR. Delphi source (line 224): `P^ := P^ - KeyByte` (decrypt), line 255: `P^ := P^ + KeyByte` (encrypt). The key rotation uses **absolute stream position**: `F32Keys[(iPos mod 32) + 1]` where `iPos` is the stream position, not the buffer index.

- [ ] **Step 10.1: Write failing tests**

```dart
// test/core/xqf/xqf_crypto_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/xqf/xqf_crypto.dart';

void main() {
  group('XqfCrypto', () {
    group('calculateSecurityKeys', () {
      test('version <= 10 returns all zeros', () {
        final keys = XqfCrypto.calculateSecurityKeys(version: 10, keyXY: 0xAB, keyXYf: 0xCD, keyXYt: 0xEF, keysSum: 0x12);
        expect(keys.keyXY, 0);
        expect(keys.keyXYf, 0);
        expect(keys.keyXYt, 0);
        expect(keys.keyRMKSize, 0);
      });

      test('version 12 with bKey=0 computes correctly', () {
        // Formula: (((((bKey*bKey)*3+9)*3+8)*2+1)*3+8) * bKey
        // bKey=0: entire expression * 0 = 0, & 0xFF = 0
        final keys = XqfCrypto.calculateSecurityKeys(version: 12, keyXY: 0, keyXYf: 0, keyXYt: 0, keysSum: 0);
        expect(keys.keyXY, 0);
      });

      test('version 12 with bKey=1 computes correctly', () {
        // bKey=1: (((((1)*3+9)*3+8)*2+1)*3+8)*1
        // = ((((12)*3+8)*2+1)*3+8)*1 = (((44)*2+1)*3+8)*1 = ((89)*3+8)*1 = 275
        // 275 & 0xFF = 19
        final keys = XqfCrypto.calculateSecurityKeys(version: 12, keyXY: 1, keyXYf: 1, keyXYt: 1, keysSum: 1);
        expect(keys.keyXY, 19);
      });

      test('version 18 with bKey=200 computes correctly', () {
        // Compute in full integer then truncate to byte at end:
        // (((((200*200)*3+9)*3+8)*2+1)*3+8)*200
        // = ((((40000)*3+9)*3+8)*2+1)*3+8)*200
        // = (((120009)*3+8)*2+1)*3+8)*200
        // = ((360035)*2+1)*3+8)*200
        // = (720071*3+8)*200
        // = 2160221*200 = 432044200
        // 432044200 & 0xFF = 168
        final keys = XqfCrypto.calculateSecurityKeys(version: 18, keyXY: 200, keyXYf: 0, keyXYt: 0, keysSum: 0);
        expect(keys.keyXY, 168);
      });

      test('all 256 bKey values produce byte results', () {
        for (var b = 0; b < 256; b++) {
          final keys = XqfCrypto.calculateSecurityKeys(version: 18, keyXY: b, keyXYf: b, keyXYt: b, keysSum: b);
          expect(keys.keyXY, lessThanOrEqualTo(255), reason: 'keyXY for bKey=$b');
          expect(keys.keyXY, greaterThanOrEqualTo(0), reason: 'keyXY for bKey=$b');
        }
      });

      test('keyXYf depends on keyXY result (chained)', () {
        // KeyXYf = (((((bKeyXYf*bKeyXYf)*3+9)*3+8)*2+1)*3+8) * KeyXY
        // With keyXY=1 → KeyXY=19, keyXYf=1 → derived=275, 275*19=5225, & 0xFF = 105
        final keys = XqfCrypto.calculateSecurityKeys(version: 18, keyXY: 1, keyXYf: 1, keyXYt: 0, keysSum: 0);
        expect(keys.keyXYf, 105);
      });
    });

    group('encrypt/decrypt round-trip (subtraction/addition)', () {
      test('encrypt then decrypt restores original', () {
        final original = Uint8List.fromList(List.generate(100, (i) => i * 3 + 7));
        final f32Keys = XqfCrypto.buildF32Keys(0x12, 0x34, 0x56, 0x78);
        final data = Uint8List.fromList(original);
        // Encrypt (addition)
        XqfCrypto.encrypt(data, f32Keys, streamOffset: 0);
        // Encrypted data should differ
        expect(data, isNot(equals(original)));
        // Decrypt (subtraction)
        XqfCrypto.decrypt(data, f32Keys, streamOffset: 0);
        expect(data, original);
      });

      test('stream offset affects key rotation', () {
        final data1 = Uint8List.fromList([0x42]);
        final data2 = Uint8List.fromList([0x42]);
        final f32Keys = XqfCrypto.buildF32Keys(0x12, 0x34, 0x56, 0x78);
        XqfCrypto.decrypt(data1, f32Keys, streamOffset: 0);
        XqfCrypto.decrypt(data2, f32Keys, streamOffset: 5);
        // Different stream offsets → different key bytes → different results
        expect(data1[0], isNot(data2[0]));
      });
    });

    group('buildF32Keys', () {
      test('produces 32 keys matching copyright string AND pattern', () {
        final keys = XqfCrypto.buildF32Keys(0xFF, 0xFF, 0xFF, 0xFF);
        const copyrightStr = '[(C) Copyright Mr. Dong Shiwei.]';
        for (var i = 0; i < 32; i++) {
          expect(keys[i], copyrightStr.codeUnitAt(i) & 0xFF);
        }
      });
    });
  });
}
```

- [ ] **Step 10.2: Run tests to verify they fail**

Run: `dart test test/core/xqf/xqf_crypto_test.dart`
Expected: FAIL

- [ ] **Step 10.3: Implement xqf_crypto.dart**

```dart
// lib/core/xqf/xqf_crypto.dart
import 'dart:typed_data';

class SecurityKeys {
  final int keyXY;
  final int keyXYf;
  final int keyXYt;
  final int keyRMKSize;
  const SecurityKeys(this.keyXY, this.keyXYf, this.keyXYt, this.keyRMKSize);
}

class XqfCrypto {
  XqfCrypto._();

  static const _copyrightStr = '[(C) Copyright Mr. Dong Shiwei.]';

  /// Apply the key derivation formula: (((((b*b)*3+9)*3+8)*2+1)*3+8)*b
  ///
  /// Delphi computes the entire expression as 32-bit Integer, then truncates
  /// to Byte on assignment. We replicate this by computing in int and masking
  /// only at the end (& 0xFF). See XQFileRW.pas:498-503.
  static int _deriveKey(int bKey) {
    final v = (((((bKey * bKey) * 3 + 9) * 3 + 8) * 2 + 1) * 3 + 8) * bKey;
    return v & 0xFF;
  }

  /// Calculate the 4 security keys from the XQF header fields.
  /// Port of dCalculateSecurityKeys (XQFileRW.pas:483-506).
  static SecurityKeys calculateSecurityKeys({
    required int version,
    required int keyXY,
    required int keyXYf,
    required int keyXYt,
    required int keysSum,
  }) {
    if (version <= 10) {
      return const SecurityKeys(0, 0, 0, 0);
    }
    final kXY = _deriveKey(keyXY);
    // KeyXYf = derive(bKeyXYf) * KeyXY, truncated to byte
    final kXYf = (_deriveKey(keyXYf) * kXY) & 0xFF;
    // KeyXYt = derive(bKeyXYt) * KeyXYf, truncated to byte
    final kXYt = (_deriveKey(keyXYt) * kXYf) & 0xFF;
    final wKey = keysSum * 256 + keyXY;
    final kRMKSize = (wKey % 32000) + 767;
    return SecurityKeys(kXY, kXYf, kXYt, kRMKSize);
  }

  /// Build the 32-byte key array from 4 key bytes.
  /// Port of SetKeyBytes (XQFileRW.pas:161-199).
  static List<int> buildF32Keys(int b1, int b2, int b3, int b4) {
    final keys = List<int>.filled(32, 0);
    final mask = [b1, b2, b3, b4];
    for (var i = 0; i < 32; i++) {
      keys[i] = _copyrightStr.codeUnitAt(i) & mask[i % 4];
    }
    return keys;
  }

  /// Decrypt [data] in-place using SUBTRACTION (not XOR!).
  /// Port of dTXqfStream.Read (XQFileRW.pas:221-227).
  /// [streamOffset] is the absolute position in the .xqf file stream
  /// where this data block starts — needed for correct key rotation.
  static void decrypt(Uint8List data, List<int> f32Keys, {required int streamOffset}) {
    for (var i = 0; i < data.length; i++) {
      final keyByte = f32Keys[(streamOffset + i) % 32];
      data[i] = (data[i] - keyByte) & 0xFF;
    }
  }

  /// Encrypt [data] in-place using ADDITION (not XOR!).
  /// Port of dTXqfStream.Write (XQFileRW.pas:252-257).
  static void encrypt(Uint8List data, List<int> f32Keys, {required int streamOffset}) {
    for (var i = 0; i < data.length; i++) {
      final keyByte = f32Keys[(streamOffset + i) % 32];
      data[i] = (data[i] + keyByte) & 0xFF;
    }
  }
}
```

- [ ] **Step 10.4: Run tests to verify they pass**

Run: `dart test test/core/xqf/xqf_crypto_test.dart`
Expected: All pass.

- [ ] **Step 10.5: Commit**

```bash
git add lib/core/xqf/xqf_crypto.dart test/core/xqf/xqf_crypto_test.dart
git commit -m "feat: add XQF crypto key derivation and XOR encrypt/decrypt"
```

---

## Task 11: XQF Header

**Files:**
- Create: `lib/core/xqf/xqf_header.dart`
- Test: `test/core/xqf/xqf_header_test.dart`

**Source reference:** `Src/XQFileRW.pas` lines 53-106 (dTXQFHead packed record, 1024 bytes total)

- [ ] **Step 11.1: Write failing tests**

Test that:
- `XqfHeader.fromBytes()` correctly parses a hand-crafted 1024-byte buffer with known field values
- Signature `0x5158` is validated
- Version, KeyMask, piece positions, player names (GB2312 decoded) are correct
- `XqfHeader.toBytes()` round-trips: `fromBytes(toBytes(header))` matches original
- Delphi `String[N]` format: 1 byte length prefix + N bytes content — must parse correctly

- [ ] **Step 11.2: Run tests to verify they fail**

Run: `dart test test/core/xqf/xqf_header_test.dart`
Expected: FAIL

- [ ] **Step 11.3: Implement xqf_header.dart**

Implement `XqfHeader` class with:
- All fields matching `dTXQFHead` at exact byte offsets (see record definition in explore report)
- `factory XqfHeader.fromBytes(Uint8List bytes)` — reads 1024 bytes, decodes Delphi `String[N]` fields via GB2312
- `Uint8List toBytes()` — serializes back to 1024 bytes
- Helper: `_readDelphiString(Uint8List bytes, int offset, int maxLen)` — reads 1-byte length prefix + content

Key byte offsets:
| Offset | Field | Size |
|--------|-------|------|
| 0 | Signature (0x5158) | 2 |
| 2 | Version | 1 |
| 3 | KeyMask | 1 |
| 4 | ProductId | 4 |
| 8 | KeyOrA,B,C,D | 4 |
| 12 | KeysSum | 1 |
| 13 | KeyXY | 1 |
| 14 | KeyXYf | 1 |
| 15 | KeyXYt | 1 |
| 16 | QiziXY[1..32] | 32 |
| 48 | PlayStepNo | 2 |
| 50 | WhoPlay | 1 |
| 51 | PlayResult | 1 |
| 52 | PlayNodes | 4 |
| 56 | PTreePos | 4 |
| 80 | TitleA (String[63]) | 64 |
| 144 | TitleB (String[63]) | 64 |
| 208 | MatchName (String[63]) | 64 |
| 272 | MatchTime (String[15]) | 16 |
| 288 | MatchAddr (String[15]) | 16 |
| 304 | RedPlayer (String[15]) | 16 |
| 320 | BlkPlayer (String[15]) | 16 |
| 336 | TimeRule (String[63]) | 64 |
| 400 | RedTime (String[15]) | 16 |
| 416 | BlkTime (String[15]) | 16 |
| 464 | RMKWriter (String[15]) | 16 |
| 480 | Author (String[15]) | 16 |

- [ ] **Step 11.4: Run tests to verify they pass**

Run: `dart test test/core/xqf/xqf_header_test.dart`
Expected: All pass.

- [ ] **Step 11.5: Commit**

```bash
git add lib/core/xqf/xqf_header.dart test/core/xqf/xqf_header_test.dart
git commit -m "feat: add XQF header parser/serializer (1024-byte packed record)"
```

---

## Task 12: XQF Reader

**Files:**
- Create: `lib/core/xqf/xqf_reader.dart`
- Test: `test/core/xqf/xqf_reader_test.dart`
- Fixtures: `test/fixtures/xqf/` (need real .xqf files)

**Source reference:** `Src/XQFileRW.pas` lines 308-480 (`iLoadXQFile` + `dInsertPNintoPlayTree`)

**Pre-requisite:** Need .xqf test fixtures. Download from the internet or create programmatically using the writer. For initial tests, construct synthetic .xqf bytes manually.

- [ ] **Step 12.1: Write failing tests**

Test with a hand-crafted minimal .xqf byte array:
- Valid signature → parses successfully
- Invalid signature → throws
- Header fields decoded correctly
- Move tree with 3 steps built correctly
- Move tree with 1 variation branch

Also search for real .xqf files online to add to test fixtures.

- [ ] **Step 12.2: Run tests to verify they fail**

Run: `dart test test/core/xqf/xqf_reader_test.dart`
Expected: FAIL

- [ ] **Step 12.3: Implement xqf_reader.dart**

Port `iLoadXQFile` and `dInsertPNintoPlayTree` from XQFileRW.pas:
- `GameData readXqf(Uint8List bytes)` — returns game metadata + move tree root
- Steps: validate signature → parse header → derive crypto keys → decrypt piece positions → read move records → build PlayNode tree
- Move record format: each record is 4 bytes (XYf, XYt encrypted with KeyXYf/KeyXYt)
- Remark reading: size encrypted with KeyRMKSize offset

- [ ] **Step 12.4: Run tests to verify they pass**

Run: `dart test test/core/xqf/xqf_reader_test.dart`
Expected: All pass.

- [ ] **Step 12.5: Commit**

```bash
git add lib/core/xqf/xqf_reader.dart test/core/xqf/xqf_reader_test.dart test/fixtures/
git commit -m "feat: add XQF reader ported from iLoadXQFile"
```

---

## Task 13: XQF Writer

**Files:**
- Create: `lib/core/xqf/xqf_writer.dart`
- Test: `test/core/xqf/xqf_writer_test.dart`
- Test: `test/core/xqf/xqf_roundtrip_test.dart`

**Source reference:** `Src/XQFileRW.pas` (`iSaveXQFile` + `dSavePlayNodeIntoXQFile`)

- [ ] **Step 13.1: Write failing tests**

- Construct a GameData object → write to bytes → read back → compare tree structure
- Round-trip test: for each .xqf fixture file, read → write → read again → compare every PlayNode field

- [ ] **Step 13.2: Run tests to verify they fail**

Run: `dart test test/core/xqf/`
Expected: FAIL

- [ ] **Step 13.3: Implement xqf_writer.dart**

- `Uint8List writeXqf(GameData data)` — serialize game to .xqf bytes
- Steps: build header → encrypt piece positions → serialize move tree depth-first → encrypt moves/remarks → write

- [ ] **Step 13.4: Run tests to verify they pass**

Run: `dart test test/core/xqf/`
Expected: All pass (including round-trip tests).

- [ ] **Step 13.5: Commit**

```bash
git add lib/core/xqf/xqf_writer.dart test/core/xqf/xqf_writer_test.dart test/core/xqf/xqf_roundtrip_test.dart
git commit -m "feat: add XQF writer with round-trip verification"
```

---

## Task 14: Game Controller

**Files:**
- Create: `lib/core/game/game_controller.dart`
- Create: `lib/core/game/variation_list.dart`
- Test: `test/core/game/game_controller_test.dart`

**Source reference:** `Src/XQSystem.pas` lines 90-167 (dTXiangQi class), entire file for method implementations

- [ ] **Step 14.1: Write failing tests**

Test all navigation and editing operations:
- `makeMove()`: execute 3 moves from standard opening, verify board state after each
- `undoMove()`: undo after 3 moves, verify board reverts step by step
- `redoMove()`: undo then redo, verify restoration
- `goToStep(n)`: jump to arbitrary step in loaded game
- `goToFirst()` / `goToLast()`: boundary navigation
- `addVariation()`: create variation at step 5, verify in rChild chain
- `switchToVariation()`: switch to variation, verify board shows variation position
- `deleteCurrentMove()`: delete step, verify tree integrity
- `setRemark()` / `getRemark()`: add/retrieve comments
- Load from XQF: read a real .xqf file, navigate all steps

- [ ] **Step 14.2: Run tests to verify they fail**

Run: `dart test test/core/game/game_controller_test.dart`
Expected: FAIL

- [ ] **Step 14.3: Implement game_controller.dart**

Port `dTXiangQi` from XQSystem.pas, stripping all UI references:
- Pure logic: `makeMove()`, `undoMove()`, `redoMove()`, `goToStep()`, `goToFirst()`, `goToLast()`, `goToPrev()`, `goToNext()`
- Variation management: `addVariation()`, `switchToVariation()`, `deleteCurrentMove()`, `moveVariationUp()`, `moveVariationDown()`
- State: `currentStep`, `totalSteps`, `currentBoard`, `currentNode`, `whoPlay`, `variations`
- Remark: `setRemark()`, `getRemark()`

- [ ] **Step 14.4: Implement variation_list.dart**

Simple list management for current node's variations (rChild chain traversal).

- [ ] **Step 14.5: Run tests to verify they pass**

Run: `dart test test/core/game/`
Expected: All pass.

- [ ] **Step 14.6: Commit**

```bash
git add lib/core/game/ test/core/game/
git commit -m "feat: add GameController with full navigation and variation support"
```

---

## Task 15: Riverpod State Layer

**Files:**
- Create: `lib/state/game_provider.dart`
- Create: `lib/state/preferences_provider.dart`

- [ ] **Step 15.1: Implement game_provider.dart**

Note: `GameController` is a pure Dart class in `lib/core/` (no Flutter imports). The Riverpod provider wraps it without requiring `ChangeNotifier`.

```dart
// lib/state/game_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xqstudio/core/game/game_controller.dart';

/// Wraps the pure-Dart GameController for use in Flutter widgets.
/// GameController does NOT extend ChangeNotifier — it stays in core/.
/// The notifier calls ref.notifyListeners() after each mutation.
class GameControllerNotifier extends Notifier<GameController> {
  @override
  GameController build() => GameController();

  void makeMove(int fromXY, int toXY) {
    state.makeMove(fromXY, toXY);
    ref.notifyListeners();
  }

  void undoMove() {
    state.undoMove();
    ref.notifyListeners();
  }

  // ... delegate other methods similarly
}

final gameControllerProvider = NotifierProvider<GameControllerNotifier, GameController>(
  GameControllerNotifier.new,
);
```

- [ ] **Step 15.2: Implement preferences_provider.dart**

Basic SharedPreferences wrapper provider.

- [ ] **Step 15.3: Verify it compiles**

Run: `flutter analyze lib/state/`
Expected: No issues.

- [ ] **Step 15.4: Commit**

```bash
git add lib/state/
git commit -m "feat: add Riverpod state providers"
```

---

## Task 16: Board Rendering

**Files:**
- Create: `lib/ui/board/board_painter.dart`
- Create: `lib/ui/board/piece_painter.dart`
- Create: `lib/ui/board/board_widget.dart`
- Create: `lib/ui/board/board_gesture_handler.dart`
- Test: `test/ui/board/board_painter_test.dart` (golden tests)
- Test: `test/ui/board/gesture_handler_test.dart` (widget tests)

**Source reference:** `Src/XQTable.pas` (3,001 lines) — rewrite as Flutter, not port line-by-line

- [ ] **Step 16.1: Write failing golden tests**

- Empty board → golden test
- Standard opening → golden test
- Board with move indicators → golden test

- [ ] **Step 16.2: Write gesture handler widget tests**

- Tap at board coordinate → verify callback with correct (x, y)
- Tap piece → tap destination → verify `onMove(fromXY, toXY)` callback
- Tap outside board → no callback

- [ ] **Step 16.3: Run tests to verify they fail**

Run: `flutter test test/ui/board/`
Expected: FAIL

- [ ] **Step 16.4: Implement board_painter.dart**

CustomPainter subclass:
- `paintBoard()`: 9 horizontal lines, 10 vertical lines (with river gap), palace diagonals, star markers
- `paintPieces()`: draw piece images at board positions
- `paintIndicators()`: highlight from/to positions
- `shouldRepaint()`: only on state change

- [ ] **Step 16.5: Implement piece_painter.dart**

Load piece PNG images from assets, cache them, draw at calculated positions.

- [ ] **Step 16.6: Implement board_widget.dart**

StatelessWidget wrapping GestureDetector + CustomPaint + RepaintBoundary.

- [ ] **Step 16.7: Implement board_gesture_handler.dart**

Convert tap pixel coordinates to board coordinates using board dimensions and padding.

- [ ] **Step 16.8: Run tests, generate golden files**

```bash
flutter test --update-goldens test/ui/board/
flutter test test/ui/board/
```

Visually inspect golden files, then check them in.

- [ ] **Step 16.9: Commit**

```bash
git add lib/ui/board/ test/ui/board/
git commit -m "feat: add board rendering with CustomPainter and golden tests"
```

---

## Task 17: Game Screen UI

**Files:**
- Create: `lib/ui/game/game_screen.dart`
- Create: `lib/ui/game/move_list_panel.dart`
- Create: `lib/ui/game/variation_panel.dart`
- Create: `lib/ui/game/remark_panel.dart`
- Create: `lib/ui/game/navigation_toolbar.dart`
- Test: `test/ui/game/game_screen_test.dart`
- Test: `test/ui/game/move_list_panel_test.dart`
- Test: `test/ui/game/navigation_toolbar_test.dart`

- [ ] **Step 17.1: Write widget tests for each panel**

- MoveListPanel: displays N moves, current step highlighted, tap triggers callback
- NavigationToolbar: First/Prev disabled at step 0, Next/Last disabled at end
- VariationPanel: shows variations when present, empty when none
- RemarkPanel: shows remark text, edit triggers callback

- [ ] **Step 17.2: Run tests to verify they fail**

Run: `flutter test test/ui/game/`
Expected: FAIL

- [ ] **Step 17.3: Implement navigation_toolbar.dart**

First/Prev/Next/Last buttons + auto-play with speed options (0.4s, 0.8s, 1.5s, 3s, 8s).

- [ ] **Step 17.4: Implement move_list_panel.dart**

Scrollable ListView of move records, current step highlighted, tap to navigate.

- [ ] **Step 17.5: Implement variation_panel.dart and remark_panel.dart**

- [ ] **Step 17.6: Implement game_screen.dart**

Responsive layout with `LayoutBuilder`:
- Wide (>800px): board left + tabbed panel right
- Narrow (≤800px): board top + tabbed panel bottom

Connect to Riverpod `gameControllerProvider`.

- [ ] **Step 17.7: Run tests to verify they pass**

Run: `flutter test test/ui/game/`
Expected: All pass.

- [ ] **Step 17.8: Commit**

```bash
git add lib/ui/game/ test/ui/game/
git commit -m "feat: add game screen with responsive layout and all panels"
```

---

## Task 18: Application Shell

**Files:**
- Create: `lib/ui/home/home_screen.dart`
- Create: `lib/services/file_service.dart`
- Create: `lib/services/preferences_service.dart`
- Create: `lib/services/clipboard_service.dart`
- Create: `lib/app.dart`
- Modify: `lib/main.dart`
- Test: `test/ui/home/home_screen_test.dart`
- Test: `test/services/file_service_test.dart`

- [ ] **Step 18.1: Write widget and unit tests**

- HomeScreen: empty state, 2 open games show 2 tabs, tab switching
- FileService: mock file_picker, verify open/save flows

- [ ] **Step 18.2: Run tests to verify they fail**

Run: `flutter test test/ui/home/ test/services/`
Expected: FAIL

- [ ] **Step 18.3: Implement file_service.dart**

Platform-abstracted file I/O:
- Desktop: `file_picker` + `dart:io` File
- Web: `file_picker` web + in-memory `Uint8List`

- [ ] **Step 18.4: Implement home_screen.dart**

Tab-based multi-game view with file open/close.

- [ ] **Step 18.5: Implement app.dart and update main.dart**

MaterialApp with routing, theme, ProviderScope.

- [ ] **Step 18.6: Implement preferences_service.dart and clipboard_service.dart**

- [ ] **Step 18.7: Run tests to verify they pass**

Run: `flutter test test/ui/home/ test/services/`
Expected: All pass.

- [ ] **Step 18.8: Manual smoke test**

```bash
cd /home/azureuser/dev/XQStudio/xqstudio_flutter
flutter run -d linux
```

Verify: app launches, can open .xqf file, board renders, navigation works.

- [ ] **Step 18.9: Commit**

```bash
git add lib/ui/home/ lib/services/ lib/app.dart lib/main.dart test/ui/home/ test/services/
git commit -m "feat: add application shell with file I/O and multi-tab support"
```

---

## Task 19: Search

**Files:**
- Create: `lib/core/search/search_criteria.dart`
- Create: `lib/core/search/game_search.dart`
- Create: `lib/ui/search/search_screen.dart`
- Test: `test/core/search/game_search_test.dart`
- Test: `test/ui/search/search_screen_test.dart`

- [ ] **Step 19.1: Write tests for search engine**

- Search by player name, title, result — verify correct filtering
- Empty criteria returns all, no match returns empty

- [ ] **Step 19.2: Implement search_criteria.dart and game_search.dart**

Port search logic from `Src/XQSearch.pas`.

- [ ] **Step 19.3: Implement search_screen.dart**

- [ ] **Step 19.4: Run tests and commit**

```bash
dart test test/core/search/
flutter test test/ui/search/
git add lib/core/search/ lib/ui/search/ test/core/search/ test/ui/search/
git commit -m "feat: add search functionality"
```

---

## Task 20: Wizard & Dialogs

**Files:**
- Create: `lib/ui/wizard/new_game_wizard.dart`
- Create: `lib/ui/dialogs/about_dialog.dart`
- Create: `lib/ui/dialogs/file_properties_dialog.dart`
- Create: `lib/ui/dialogs/tips_dialog.dart`
- Create: `lib/services/export_service.dart`
- Test: `test/ui/wizard/new_game_wizard_test.dart`
- Test: `test/ui/dialogs/file_properties_test.dart`

- [ ] **Step 20.1: Write widget tests**

- New game wizard: standard opening selection, custom position
- File properties dialog: display and edit metadata

- [ ] **Step 20.2: Implement all dialogs and wizard**

Port from `Src/XQWizard.pas` (804 lines) and dialog units.

- [ ] **Step 20.3: Implement export_service.dart**

Port `dMakeQiTuText` — text board diagram export.

- [ ] **Step 20.4: Run tests and commit**

```bash
flutter test test/ui/wizard/ test/ui/dialogs/
git add lib/ui/wizard/ lib/ui/dialogs/ lib/services/export_service.dart test/ui/wizard/ test/ui/dialogs/
git commit -m "feat: add new game wizard, dialogs, and text export"
```

---

## Task 21: Polish & Cross-Platform

**Files:**
- Modify: various UI files for responsive layout
- Create: keyboard shortcut bindings
- Modify: platform-specific configuration files

- [ ] **Step 21.1: Write responsive layout golden tests**

- 400×800 (phone portrait) → board top, panel bottom
- 1200×800 (desktop) → board left, panel right

- [ ] **Step 21.2: Add keyboard shortcuts**

Desktop: ← → (prev/next), Home/End (first/last), Ctrl+S (save), Ctrl+O (open).

- [ ] **Step 21.3: Run full test suite**

```bash
cd /home/azureuser/dev/XQStudio/xqstudio_flutter
flutter analyze
flutter test
```
Expected: All tests pass, no analysis issues.

- [ ] **Step 21.4: Cross-platform smoke test**

```bash
flutter run -d linux    # Desktop
flutter run -d chrome   # Web
```

- [ ] **Step 21.5: Final commit**

```bash
git add -A
git commit -m "feat: polish responsive layout, keyboard shortcuts, cross-platform support"
```

---

## Dependency Graph

```
Task 0 (Bootstrap)
  └── Task 1 (Constants)
        ├── Task 2 (Piece) ──────┐
        ├── Task 3 (Position) ───┤
        └── Task 4 (BoardState) ─┤
              └── Task 5 (PlayNode)
                    └── Task 6 (GameMetadata)
                          │
        ┌─────────────────┤
        │                 │
  Task 7 (MoveValidator)  Task 9 (GB2312)
        │                 │
  Task 8 (MoveNotation)   Task 10 (XqfCrypto)
        │                 │
        │           Task 11 (XqfHeader)
        │                 │
        │           Task 12 (XqfReader)
        │                 │
        │           Task 13 (XqfWriter)
        │                 │
        └────────┬────────┘
                 │
           Task 14 (GameController)
                 │
           Task 15 (RiverpodState)
                 │
        ┌────────┼────────┐
        │        │        │
  Task 16    Task 17    Task 18
  (Board)   (GameUI)   (AppShell)
        │        │        │
        └────────┼────────┘
                 │
           Task 19 (Search)
                 │
           Task 20 (Wizard/Dialogs)
                 │
           Task 21 (Polish)
```

**Parallelizable tasks:**
- Tasks 2, 3 can run in parallel
- Tasks 7-8 (rules) and Tasks 9-13 (XQF I/O) can run in parallel after Task 6
- Tasks 16, 17, 18 can partially overlap after Task 15
