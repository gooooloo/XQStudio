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
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 40; // red shuai at (4,0)
      pieces[21] = 49; // black jiang at (4,9)
      final board = BoardState.fromList(pieces);
      expect(KingSafety.kingsAreFacing(board), true);
    });

    test('kings on same column but piece between: not facing', () {
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 40; // red shuai at (4,0)
      pieces[21] = 49; // black jiang at (4,9)
      pieces[10] = 44; // piece at (4,4) between them
      final board = BoardState.fromList(pieces);
      expect(KingSafety.kingsAreFacing(board), false);
    });

    test('kings on different columns: not facing', () {
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 30; // red shuai at (3,0)
      pieces[21] = 49; // black jiang at (4,9)
      final board = BoardState.fromList(pieces);
      expect(KingSafety.kingsAreFacing(board), false);
    });

    test('kings adjacent on same column: facing', () {
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 44; // red shuai at (4,4)
      pieces[21] = 45; // black jiang at (4,5)
      final board = BoardState.fromList(pieces);
      expect(KingSafety.kingsAreFacing(board), true);
    });

    test('kings on same column with multiple pieces between: not facing', () {
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 41; // red shuai at (4,1)
      pieces[21] = 48; // black jiang at (4,8)
      pieces[1] = 44; // piece at (4,4)
      pieces[2] = 46; // piece at (4,6)
      final board = BoardState.fromList(pieces);
      expect(KingSafety.kingsAreFacing(board), false);
    });

    test('red king captured: not facing', () {
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      // pieces[5] remains kCapturedXY
      pieces[21] = 49;
      final board = BoardState.fromList(pieces);
      expect(KingSafety.kingsAreFacing(board), false);
    });

    test('black king captured: not facing', () {
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 40;
      // pieces[21] remains kCapturedXY
      final board = BoardState.fromList(pieces);
      expect(KingSafety.kingsAreFacing(board), false);
    });
  });
}
