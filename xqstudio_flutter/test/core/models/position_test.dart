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
