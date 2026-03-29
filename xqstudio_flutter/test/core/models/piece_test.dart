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
