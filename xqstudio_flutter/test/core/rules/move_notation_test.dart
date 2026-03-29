import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/models/piece.dart';
import 'package:xqstudio/core/rules/move_notation.dart';

/// Helper to create a board from the standard initial position.
BoardState standardBoard() => BoardState.standard();

/// Helper to create a custom board with specific piece positions.
/// [overrides] maps piece index (1-32) to XY position.
BoardState customBoard(Map<int, int> overrides) {
  final pieces = List<int>.from(kInitialPieceXY);
  // First set all to captured, then apply overrides.
  for (var i = 1; i <= 32; i++) {
    pieces[i] = kCapturedXY;
  }
  for (final entry in overrides.entries) {
    pieces[entry.key] = entry.value;
  }
  return BoardState.fromList(pieces);
}

void main() {
  group('MoveNotation.generateNotation', () {
    group('Standard opening moves (Red)', () {
      test('炮二平五 — cannon from column 7 to column 4', () {
        final board = standardBoard();
        // Red pao at index 10 is at XY=72 (x=7, y=2).
        // Move to XY=42 (x=4, y=2) — horizontal.
        // Column 7 for red = kRedNum[9-7] = kRedNum[2] = 二
        // Target column 4 = kRedNum[9-4] = kRedNum[5] = 五
        final notation = MoveNotation.generateNotation(board, 72, 42);
        expect(notation, '炮二平五');
      });

      test('马八进七 — knight from column 1 to (2, 2)', () {
        final board = standardBoard();
        // Red ma at index 8 is at XY=10 (x=1, y=0).
        // Move to XY=22 (x=2, y=2).
        // Column 1 for red = kRedNum[9-1] = kRedNum[8] = 八
        // dy=2>0 → 进, target column 2 → kRedNum[9-2] = 七
        final notation = MoveNotation.generateNotation(board, 10, 22);
        expect(notation, '马八进七');
      });

      test('车九平八 — rook from column 0 horizontal to column 1', () {
        final board = standardBoard();
        // Red che at index 9 is at XY=00 (x=0, y=0).
        // Move to XY=10 (x=1, y=0).
        // Column 0 = kRedNum[9] = 九, target column 1 = kRedNum[8] = 八
        final notation = MoveNotation.generateNotation(board, 00, 10);
        expect(notation, '车九平八');
      });

      test('兵三进一 — pawn advances one step', () {
        final board = standardBoard();
        // Red bing at index 14 is at XY=63 (x=6, y=3).
        // Move to XY=64 (x=6, y=4). dy=1 → 进.
        // Column 6 = kRedNum[9-6] = kRedNum[3] = 三
        // Distance 1 = kRedNum[1] = 一
        final notation = MoveNotation.generateNotation(board, 63, 64);
        expect(notation, '兵三进一');
      });

      test('兵七进一 — pawn column 2 advances', () {
        final board = standardBoard();
        // Red bing at index 15 is at XY=23 (x=2, y=3).
        // Move to XY=24 (x=2, y=4).
        // Column 2 = kRedNum[9-2] = kRedNum[7] = 七
        final notation = MoveNotation.generateNotation(board, 23, 24);
        expect(notation, '兵七进一');
      });

      test('马二进三 — right knight opening', () {
        final board = standardBoard();
        // Red ma at index 2 is at XY=70 (x=7, y=0).
        // Move to XY=62 (x=6, y=2).
        // Column 7 = kRedNum[9-7] = kRedNum[2] = 二
        // dy=2>0 → 进, target column 6 = kRedNum[9-6] = kRedNum[3] = 三
        final notation = MoveNotation.generateNotation(board, 70, 62);
        expect(notation, '马二进三');
      });

      test('相三进五 — elephant advances', () {
        final board = standardBoard();
        // Red xiang at index 7 is at XY=20 (x=2, y=0).
        // Move to XY=02 (x=0, y=2).
        // Column 2 = kRedNum[9-2] = 七... wait that's wrong.
        // Actually index 7 is xiang at XY=20. Let me recalculate.
        // Wait: kInitialPieceXY indices:
        // 1=80(che), 2=70(ma), 3=60(xiang), 4=50(shi), 5=40(shuai),
        // 6=30(shi), 7=20(xiang), 8=10(ma), 9=00(che)
        // Xiang at index 3 is at XY=60 (x=6).
        // Column 6 = kRedNum[9-6] = 三. Move to XY=42 (x=4, y=2).
        // Target column 4 = kRedNum[9-4] = 五. dy=2>0 → 进.
        final notation = MoveNotation.generateNotation(board, 60, 42);
        expect(notation, '相三进五');
      });

      test('士四进五 — advisor advances', () {
        final board = standardBoard();
        // Red shi at index 4 is at XY=50 (x=5, y=0).
        // Move to XY=41 (x=4, y=1).
        // Column 5 = kRedNum[9-5] = 四, target column 4 = kRedNum[9-4] = 五
        // dy=1>0 → 进
        final notation = MoveNotation.generateNotation(board, 50, 41);
        expect(notation, '士四进五');
      });

      test('帅五进一 — king advances one step', () {
        // Custom board: red king at center (40, y=0), need space to move.
        customBoard({
          5: 41, // red shuai at x=4, y=1
          21: 48, // black jiang at x=4, y=8
          // Add a piece to block king-facing.
          1: 42, // red che blocking at x=4, y=2
        });
        // Move king from 41 to 42... no that's blocked.
        // Let's use a simpler setup: king at 31, move to 32.
        final board2 = customBoard({
          5: 31, // red shuai at x=3, y=1
          21: 48, // black jiang at x=4, y=8
        });
        final notation = MoveNotation.generateNotation(board2, 31, 32);
        // Column 3 = kRedNum[9-3] = 六, dy=1 → 进, dist=1 = 一
        expect(notation, '帅六进一');
      });

      test('帅五平六 — king moves horizontally', () {
        final board = customBoard({
          5: 41, // red shuai at x=4, y=1
          21: 48, // black jiang at x=4, y=8
          1: 45, // blocker
        });
        final notation = MoveNotation.generateNotation(board, 41, 31);
        // Column 4 = kRedNum[9-4] = 五, 平, target column 3 = kRedNum[9-3] = 六
        expect(notation, '帅五平六');
      });
    });

    group('Black moves', () {
      test('马８进７ — black knight advance', () {
        final board = standardBoard();
        // Black ma at index 18 is at XY=19 (x=1, y=9).
        // Move to XY=27 (x=2, y=7).
        // Column 1 for black = kBlkNum[1+1] = ８ (wait: kBlkNum[2] = ８)
        // dy = 7-9 = -2, black forward is dy<0 → 进
        // Target column 2 = kBlkNum[2+1] = ７... wait kBlkNum = ['0','９','８','７','６','５','４','３','２','１']
        // kBlkNum[3] = ７. So target column 2 → kBlkNum[2+1] = kBlkNum[3] = ７
        // Wait, column 1 → kBlkNum[1+1] = kBlkNum[2] = ８
        final notation = MoveNotation.generateNotation(board, 19, 27);
        expect(notation, '马２进３');
      });

      test('炮８平５ — black cannon center opening', () {
        final board = standardBoard();
        // Black pao at index 27 is at XY=77 (x=7, y=7).
        // Move to XY=47 (x=4, y=7).
        // Column 7 = dCBLKNUM[8] = '８'
        // dy=0 → 平, target column 4 = dCBLKNUM[5] = '５'
        final notation = MoveNotation.generateNotation(board, 77, 47);
        expect(notation, '炮８平５');
      });

      test('车１进１ — black rook advance', () {
        final board = customBoard({
          17: 09, // black che at x=0, y=9
          21: 48, // black jiang
          5: 40, // red shuai
        });
        final notation = MoveNotation.generateNotation(board, 09, 08);
        // Column 0 for black = dCBLKNUM[1] = '１'. dy=-1 → 进, dist=1 = '１'
        expect(notation, '车１进１');
      });

      test('象３进５ — black elephant advance', () {
        final board = standardBoard();
        // Black xiang at index 19 is at XY=29 (x=2, y=9).
        // Move to XY=47 (x=4, y=7).
        // Column 2 for black = dCBLKNUM[3] = '３'
        // dy = -2 → black forward → 进
        // Target column 4 = dCBLKNUM[5] = '５'
        final notation = MoveNotation.generateNotation(board, 29, 47);
        expect(notation, '象３进５');
      });

      test('将５进１ — black king advance', () {
        final board = customBoard({
          21: 48, // black jiang at x=4, y=8
          5: 40, // red shuai at x=4, y=0
          17: 45, // blocker
        });
        final notation = MoveNotation.generateNotation(board, 48, 47);
        // Column 4 = kBlkNum[4+1] = kBlkNum[5] = ５
        // dy = 7-8 = -1 → black forward → 进, dist=1 = kBlkNum[1] = ９...
        // Wait: dist uses kBlkNum which is ['0','９','８','７','６','５','４','３','２','１']
        // dist 1 → kBlkNum[1] = ９. Hmm that's the column notation.
        // Actually looking at the Delphi code for black king:
        // -9..-1: sRec := sRec + '进' + dCBLKNUM[Db]
        // Db = abs(dy) = 1. dCBLKNUM[1] = '１' — wait let me check.
        // dCBLKNUM: ('0', '１','２','３','４','５','６','７','８','９')
        // So dCBLKNUM[1] = '１'. Our kBlkNum matches this ordering!
        // kBlkNum = ['0', '９', '８', '７', '６', '５', '４', '３', '２', '１']
        // kBlkNum[1] = '９'... That doesn't match!
        // The Delphi dCBLKNUM[1] = '１', but our kBlkNum[1] = '９'.
        // Our constants have REVERSED order!
        // Actually re-reading constants.dart:
        //   kBlkNum = ['0', '９', '８', '７', '６', '５', '４', '３', '２', '１']
        // And Delphi:
        //   dCBLKNUM = ('0', '１','２','３','４','５','６','７','８','９')
        // These are DIFFERENT orderings. Our kBlkNum is used for column mapping only.
        // For distance, the Delphi code uses dCBLKNUM[Db] where Db is 1-9.
        // dCBLKNUM[1] = '１', dCBLKNUM[2] = '２', etc.
        // But our kBlkNum[1] = '９', kBlkNum[2] = '８', etc.
        // So we need _distStr to account for this difference!
        // Actually wait — let me re-read. For black COLUMN:
        //   sGetBlkLine(iX) = dCBLKNUM[iX+1]  (when bRL=false)
        //   Column 0 → dCBLKNUM[1] = '１', column 8 → dCBLKNUM[9] = '９'
        // Our _blkCol(x) = kBlkNum[x+1]:
        //   Column 0 → kBlkNum[1] = '９', column 8 → kBlkNum[9] = '１'
        // That's REVERSED! Our kBlkNum is in reverse order compared to Delphi.
        // So there's a bug in either constants or our col mapping.
        // Let me look at what kBlkNum is supposed to represent...
        // The task description says: "Black uses: ９８７...１ (from kBlkNum)"
        // and "Black counts left-to-right (column 0=１, column 8=９)"
        // So column 0 should map to '１' and column 8 to '９'.
        // Our kBlkNum = ['0', '９', '８', '７', '６', '５', '４', '３', '２', '１']
        // _blkCol(x) = kBlkNum[x+1]: col 0 → kBlkNum[1] = '９' ← WRONG
        //
        // The Delphi dCBLKNUM = ['0', '１', '２', '３', '４', '５', '６', '７', '８', '９']
        // sGetBlkLine(iX) = dCBLKNUM[iX+1]: col 0 → '１' ← CORRECT
        //
        // So our kBlkNum is in the opposite order from dCBLKNUM.
        // We need to fix _blkCol: column x → kBlkNum[9-x] instead of kBlkNum[x+1]
        // col 0 → kBlkNum[9] = '１' ✓, col 8 → kBlkNum[1] = '９' ✓
        // And _distStr for black: dist d → kBlkNum[9-d+1]... hmm
        // Actually for distance, Delphi uses dCBLKNUM[Db] directly.
        // dCBLKNUM[1] = '１'. We need kBlkNum index that gives '１' = kBlkNum[9].
        // So dist d → need index where kBlkNum gives the fullwidth digit for d.
        // dist 1 → '１' → kBlkNum[9], dist 2 → '２' → kBlkNum[8], dist d → kBlkNum[10-d]
        //
        // OK this means our _blkCol and _distStr functions need fixing.
        // Let me update the implementation...
        //
        // For now, let me just note the expected values based on Delphi behavior:
        // King at col 4, dy=-1 → 将５进１
        expect(notation, '将５进１');
      });

      test('卒３进１ — black pawn advances', () {
        final board = standardBoard();
        // Black zu at index 30 is at XY=46 (x=4, y=6).
        // Move to XY=45 (x=4, y=5). dy=-1 → black forward → 进.
        // Column 4 = dCBLKNUM[4+1] = '５'. dist=1 → dCBLKNUM[1] = '１'
        final notation = MoveNotation.generateNotation(board, 46, 45);
        expect(notation, '卒５进１');
      });
    });

    group('Direction: 退 (retreat)', () {
      test('Red che retreats', () {
        final board = customBoard({
          1: 85, // red che at x=8, y=5
          5: 40, // red shuai
          21: 48, // black jiang
        });
        final notation = MoveNotation.generateNotation(board, 85, 83);
        // Column 8 = kRedNum[9-8] = 一, dy=-2 → 退, dist=2 = 二
        expect(notation, '车一退二');
      });

      test('Red ma retreats', () {
        final board = customBoard({
          2: 62, // red ma at x=6, y=2
          5: 40, // red shuai
          21: 48, // black jiang
        });
        final notation = MoveNotation.generateNotation(board, 62, 70);
        // Column 6 = 三, dy=-2 → 退, target col 7 = 二
        expect(notation, '马三退二');
      });

      test('Black che retreats (dy>0 for black = 退)', () {
        final board = customBoard({
          17: 04, // black che at x=0, y=4
          5: 40, // red shuai
          21: 48, // black jiang
        });
        final notation = MoveNotation.generateNotation(board, 04, 06);
        // Column 0 = dCBLKNUM[0+1] = '１'. dy=2 → black retreat → 退. dist=2 → '２'
        expect(notation, '车１退２');
      });
    });

    group('Direction: 平 (horizontal)', () {
      test('Red pao horizontal', () {
        final board = customBoard({
          10: 75, // red pao at x=7, y=5
          5: 40, // red shuai
          21: 48, // black jiang
        });
        final notation = MoveNotation.generateNotation(board, 75, 55);
        // Column 7 = 二, target col 5 = 四
        expect(notation, '炮二平四');
      });

      test('Black pao horizontal', () {
        final board = customBoard({
          26: 15, // black pao at x=1, y=5
          5: 40, // red shuai
          21: 48, // black jiang
        });
        final notation = MoveNotation.generateNotation(board, 15, 55);
        // Column 1 = '２', target col 5 = '６'
        expect(notation, '炮２平６');
      });
    });

    group('Multi-piece disambiguation: 前/后 for paired pieces', () {
      test('前车进三 — front rook advances (Red)', () {
        // Two red rooks in same column.
        final board = customBoard({
          1: 85, // red che at x=8, y=5 (front, higher Y)
          9: 82, // red che at x=8, y=2 (back, lower Y)
          5: 40, // red shuai
          21: 48, // black jiang
        });
        final notation = MoveNotation.generateNotation(board, 85, 88);
        // Both in column 8. Piece at y=5 has higher Y → front.
        // 前车 + 进 + dist 3 = 三
        expect(notation, '前车进三');
      });

      test('后车退二 — back rook retreats (Red)', () {
        final board = customBoard({
          1: 85, // front (higher Y)
          9: 82, // back (lower Y)
          5: 40,
          21: 48,
        });
        final notation = MoveNotation.generateNotation(board, 82, 80);
        // y=2 < y=5 → back → 后车, dy=-2 → 退, dist=2 = 二
        expect(notation, '后车退二');
      });

      test('前马进 — front knight (Red)', () {
        final board = customBoard({
          2: 34, // red ma at x=3, y=4 (front, higher Y)
          8: 31, // red ma at x=3, y=1 (back)
          5: 40,
          21: 48,
        });
        final notation = MoveNotation.generateNotation(board, 34, 46);
        // Both in column 3. y=4 > y=1 → front.
        // 前马 + 进 + target col 4 = 五
        expect(notation, '前马进五');
      });

      test('后炮平 — back cannon horizontal (Red)', () {
        final board = customBoard({
          10: 25, // red pao at x=2, y=5 (front)
          11: 22, // red pao at x=2, y=2 (back)
          5: 40,
          21: 48,
        });
        final notation = MoveNotation.generateNotation(board, 22, 52);
        // y=2 < y=5 → back → 后炮, 平, target col 5 = 四
        expect(notation, '后炮平四');
      });

      test('前车进 — front rook (Black)', () {
        final board = customBoard({
          17: 07, // black che at x=0, y=7 (front for black = lower Y)
          25: 09, // black che at x=0, y=9 (back)
          5: 40,
          21: 48,
        });
        // Black front = lower Y. y=7 < y=9 → front.
        final notation = MoveNotation.generateNotation(board, 07, 05);
        // 前车 + 进(dy=-2, black forward) + dist=2 → '２'
        expect(notation, '前车进２');
      });

      test('后马退 — back knight retreats (Black)', () {
        final board = customBoard({
          18: 35, // black ma at x=3, y=5 (front for black = lower Y)
          24: 38, // black ma at x=3, y=8 (back)
          5: 40,
          21: 48,
        });
        // y=5 < y=8 → front is 18. So 24 at y=8 is back.
        final notation = MoveNotation.generateNotation(board, 38, 49);
        // 后马 + 退(dy=1, black backward) + target col 4 → '５'
        expect(notation, '后马退５');
      });
    });

    group('Multi-pawn disambiguation', () {
      test('前兵进一 — 2 red pawns in same column, front advances', () {
        final board = customBoard({
          12: 86, // red bing at x=8, y=6 (front = higher Y)
          13: 84, // red bing at x=8, y=4 (back)
          5: 40,
          21: 48,
        });
        // Both in column 8. y=6 > y=4 → front.
        final notation = MoveNotation.generateNotation(board, 86, 87);
        expect(notation, '前兵进一');
      });

      test('后兵进一 — 2 red pawns in same column, back advances', () {
        final board = customBoard({
          12: 86,
          13: 84,
          5: 40,
          21: 48,
        });
        final notation = MoveNotation.generateNotation(board, 84, 85);
        expect(notation, '后兵进一');
      });

      test('前兵/中兵/后兵 — 3 red pawns in same column', () {
        customBoard({
          12: 87, // y=7 (front)
          13: 85, // y=5 (middle)
          14: 83, // y=3... wait, red bing at y=3 hasn't crossed river.
          // Red bing can only be at y>=3 (initial) and moves forward to y>=4.
          // For 3 pawns in same column, they need to have crossed the river.
          // Actually bing at y=3 is initial position. Let's use y=8,6,4 after crossing.
          5: 40,
          21: 48,
        });
        // Re-do with proper positions.
        final board2 = customBoard({
          12: 28, // red bing at x=2, y=8 (front)
          13: 26, // red bing at x=2, y=6 (middle)
          14: 25, // red bing at x=2, y=5 (back)
          5: 40,
          21: 48,
        });
        expect(MoveNotation.generateNotation(board2, 28, 29), '前兵进一');
        // Middle pawn: move sideways (after crossing river).
        expect(MoveNotation.generateNotation(board2, 26, 36), '中兵平六');
        expect(MoveNotation.generateNotation(board2, 25, 15), '后兵平八');
      });

      test('前卒/后卒 — 2 black pawns in same column', () {
        final board = customBoard({
          28: 33, // black zu at x=3, y=3 (front for black = lower Y)
          29: 35, // black zu at x=3, y=5 (back)
          5: 40,
          21: 48,
        });
        final notation1 = MoveNotation.generateNotation(board, 33, 32);
        expect(notation1, '前卒进１');
        final notation2 = MoveNotation.generateNotation(board, 35, 34);
        expect(notation2, '后卒进１');
      });

      test('前卒/中卒/后卒 — 3 black pawns in same column', () {
        final board = customBoard({
          28: 52, // x=5, y=2 (front for black)
          29: 54, // x=5, y=4 (middle)
          30: 56, // x=5, y=6 (back)
          5: 40,
          21: 48,
        });
        expect(MoveNotation.generateNotation(board, 52, 51), '前卒进１');
        expect(MoveNotation.generateNotation(board, 54, 44), '中卒平５');
        expect(MoveNotation.generateNotation(board, 56, 55), '后卒进１');
      });
    });

    group('Edge cases', () {
      test('No piece at fromXY returns null', () {
        final board = standardBoard();
        expect(MoveNotation.generateNotation(board, 55, 56), isNull);
      });

      test('Red xiang without disambiguation (no pair in same column)', () {
        final board = customBoard({
          3: 42, // red xiang at x=4, y=2
          7: 20, // other xiang at different column
          5: 40,
          21: 48,
        });
        final notation = MoveNotation.generateNotation(board, 42, 24);
        // Column 4 = 五, dy=2 → 退... wait dy = 4-2 = 2 → no.
        // from (4,2) to (2,4): dy=2 → 进, target col 2 = 七
        expect(notation, '相五进七');
      });

      test('Black shi notation', () {
        final board = customBoard({
          20: 39, // black shi at x=3, y=9
          5: 40,
          21: 48,
        });
        // Move to 48 (x=4, y=8). dy=-1 → black forward → 进.
        final notation = MoveNotation.generateNotation(board, 39, 48);
        // Column 3 = kBlkNum[3+1] = ... wait we need to use Delphi mapping.
        // Column 3 for black = dCBLKNUM[3+1] = '４'
        // target col 4 = dCBLKNUM[4+1] = '５'
        expect(notation, '士４进５');
      });
    });
  });

  group('MoveNotation.parseNotation', () {
    test('Parse 炮二平五', () {
      final board = standardBoard();
      final result = MoveNotation.parseNotation(board, Side.red, '炮二平五');
      expect(result, isNotNull);
      expect(result!.fromXY, 72);
      expect(result.toXY, 42);
    });

    test('Parse 马八进七', () {
      final board = standardBoard();
      final result = MoveNotation.parseNotation(board, Side.red, '马八进七');
      expect(result, isNotNull);
      expect(result!.fromXY, 10);
      expect(result.toXY, 22);
    });

    test('Parse 车九平八', () {
      final board = standardBoard();
      final result = MoveNotation.parseNotation(board, Side.red, '车九平八');
      expect(result, isNotNull);
      expect(result!.fromXY, 00);
      expect(result.toXY, 10);
    });

    test('Parse 兵三进一', () {
      final board = standardBoard();
      final result = MoveNotation.parseNotation(board, Side.red, '兵三进一');
      expect(result, isNotNull);
      expect(result!.fromXY, 63);
      expect(result.toXY, 64);
    });

    test('Parse black 炮８平５', () {
      final board = standardBoard();
      final result = MoveNotation.parseNotation(board, Side.black, '炮８平５');
      expect(result, isNotNull);
      expect(result!.fromXY, 77);
      expect(result.toXY, 47);
    });

    test('Parse 前车进三 with disambiguation', () {
      final board = customBoard({
        1: 85,
        9: 82,
        5: 40,
        21: 48,
      });
      final result = MoveNotation.parseNotation(board, Side.red, '前车进三');
      expect(result, isNotNull);
      expect(result!.fromXY, 85);
      expect(result.toXY, 88);
    });

    test('Parse 后炮平四', () {
      final board = customBoard({
        10: 25,
        11: 22,
        5: 40,
        21: 48,
      });
      final result = MoveNotation.parseNotation(board, Side.red, '后炮平四');
      expect(result, isNotNull);
      expect(result!.fromXY, 22);
      expect(result.toXY, 52);
    });

    test('Parse invalid notation returns null', () {
      final board = standardBoard();
      expect(MoveNotation.parseNotation(board, Side.red, 'XY'), isNull);
      expect(MoveNotation.parseNotation(board, Side.red, ''), isNull);
    });
  });

  group('Round-trip: generateNotation → parseNotation', () {
    void roundTrip(String description, BoardState board, Side side,
        int fromXY, int toXY) {
      test(description, () {
        final notation = MoveNotation.generateNotation(board, fromXY, toXY);
        expect(notation, isNotNull, reason: 'generateNotation returned null');
        final parsed = MoveNotation.parseNotation(board, side, notation!);
        expect(parsed, isNotNull,
            reason: 'parseNotation returned null for "$notation"');
        expect(parsed!.fromXY, fromXY,
            reason: 'fromXY mismatch for "$notation"');
        expect(parsed.toXY, toXY, reason: 'toXY mismatch for "$notation"');
      });
    }

    final std = standardBoard();

    roundTrip('炮二平五', std, Side.red, 72, 42);
    roundTrip('马八进七', std, Side.red, 10, 22);
    roundTrip('车九平八', std, Side.red, 00, 10);
    roundTrip('兵三进一', std, Side.red, 63, 64);
    roundTrip('相三进五', std, Side.red, 60, 42);
    roundTrip('士四进五', std, Side.red, 50, 41);

    // Black
    roundTrip('Black 马２进３', std, Side.black, 19, 27);
    roundTrip('Black 炮２平５', std, Side.black, 77, 47);
    roundTrip('Black 象７进５', std, Side.black, 29, 47);

    // Disambiguation round-trips
    final disambBoard = customBoard({
      1: 85, 9: 82, 5: 40, 21: 48,
    });
    roundTrip('前车进三', disambBoard, Side.red, 85, 88);
    roundTrip('后车退二', disambBoard, Side.red, 82, 80);

    // Multi-pawn round-trip
    final pawnBoard = customBoard({
      12: 86, 13: 84, 5: 40, 21: 48,
    });
    roundTrip('前兵进一', pawnBoard, Side.red, 86, 87);
    roundTrip('后兵进一', pawnBoard, Side.red, 84, 85);
  });
}
