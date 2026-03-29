import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/board_state.dart';

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
      expect(newBoard.pieceXY(1), 84);
      expect(newBoard.pieceIndexAt(80), 0);
      expect(newBoard.pieceIndexAt(84), 1);
    });

    test('movePiece captures opponent piece', () {
      // Construct a board where red pao can capture black pao
      final pieces = List<int>.from(kInitialPieceXY);
      pieces[10] = 77; // move red pao to where black pao (index 27) is
      // Note: movePiece is low-level, doesn't validate legality
      final board = BoardState.standard();
      final captured = board.movePiece(72, 77);
      expect(captured.pieceXY(10), 77); // red pao moved
      expect(captured.pieceXY(27), kCapturedXY); // black pao captured
    });

    test('clone creates independent copy', () {
      final board = BoardState.standard();
      final modified = board.movePiece(80, 84);
      expect(board.pieceXY(1), 80); // original unchanged
      expect(modified.pieceXY(1), 84);
    });
  });
}
