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
      final bytes = Uint8List.fromList([0x41, 0x42, 0x43]);
      expect(decodeGB2312(bytes), 'ABC');
    });

    test('decode mixed ASCII and Chinese', () {
      final bytes = Uint8List.fromList([0x58, 0x51, 0xCF, 0xF3, 0xC6, 0xE5]);
      expect(decodeGB2312(bytes), 'XQ象棋');
    });

    test('encode and decode round-trip', () {
      const text = '红方：张三';
      final encoded = encodeGB2312(text);
      expect(decodeGB2312(encoded), text);
    });

    test('decode empty bytes returns empty string', () {
      expect(decodeGB2312(Uint8List(0)), '');
    });

    test('encode empty string returns empty bytes', () {
      expect(encodeGB2312(''), isEmpty);
    });
  });
}
