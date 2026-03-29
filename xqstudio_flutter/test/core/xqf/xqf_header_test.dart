import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/xqf/xqf_header.dart';

void main() {
  group('XqfHeader', () {
    late Uint8List validHeader;

    setUp(() {
      // Build a 1024-byte header with known values
      validHeader = Uint8List(1024);
      // Signature: 0x5158 ("XQ") little-endian
      validHeader[0] = 0x58; // 'X'
      validHeader[1] = 0x51; // 'Q'
      // Version: 18
      validHeader[2] = 18;
      // KeyMask
      validHeader[3] = 0;
      // KeyOrA..D
      validHeader[8] = 0x10;
      validHeader[9] = 0x20;
      validHeader[10] = 0x30;
      validHeader[11] = 0x40;
      // KeysSum, KeyXY, KeyXYf, KeyXYt
      validHeader[12] = 0;
      validHeader[13] = 1;
      validHeader[14] = 2;
      validHeader[15] = 3;
      // QiziXY: standard opening at offset 16-47
      final stdPositions = [
        80, 70, 60, 50, 40, 30, 20, 10, 00, 72, 12, 83, 63, 43, 23, 03,
        09, 19, 29, 39, 49, 59, 69, 79, 89, 17, 77, 06, 26, 46, 66, 86
      ];
      for (var i = 0; i < 32; i++) {
        validHeader[16 + i] = stdPositions[i];
      }
      // PlayStepNo: 0 (little-endian word)
      validHeader[48] = 0;
      validHeader[49] = 0;
      // WhoPlay: 0 = Red
      validHeader[50] = 0;
      // PlayResult: 0
      validHeader[51] = 0;
      // PlayNodes: 10 (little-endian dword)
      validHeader[52] = 10;
      // PTreePos: 1024 (little-endian dword)
      validHeader[56] = 0;
      validHeader[57] = 4;
      // RedPlayer at offset 304: String[15] — length byte + content
      // Write "Red" as ASCII
      validHeader[304] = 3; // length
      validHeader[305] = 0x52; // 'R'
      validHeader[306] = 0x65; // 'e'
      validHeader[307] = 0x64; // 'd'
      // BlkPlayer at offset 320
      validHeader[320] = 5;
      validHeader[321] = 0x42; // 'B'
      validHeader[322] = 0x6C; // 'l'
      validHeader[323] = 0x61; // 'a'
      validHeader[324] = 0x63; // 'c'
      validHeader[325] = 0x6B; // 'k'
    });

    test('fromBytes parses signature correctly', () {
      final header = XqfHeader.fromBytes(validHeader);
      expect(header.signature, 0x5158);
    });

    test('fromBytes throws on invalid signature', () {
      validHeader[0] = 0x00;
      expect(() => XqfHeader.fromBytes(validHeader), throwsFormatException);
    });

    test('fromBytes parses version', () {
      final header = XqfHeader.fromBytes(validHeader);
      expect(header.version, 18);
    });

    test('fromBytes parses key fields', () {
      final header = XqfHeader.fromBytes(validHeader);
      expect(header.keyOrA, 0x10);
      expect(header.keyOrB, 0x20);
      expect(header.keyOrC, 0x30);
      expect(header.keyOrD, 0x40);
      expect(header.keyXY, 1);
      expect(header.keyXYf, 2);
      expect(header.keyXYt, 3);
    });

    test('fromBytes parses piece positions', () {
      final header = XqfHeader.fromBytes(validHeader);
      expect(header.qiziXY[0], 80); // red che at (8,0)
      expect(header.qiziXY[4], 40); // red shuai at (4,0)
      expect(header.qiziXY[20], 49); // black jiang at (4,9)
      expect(header.qiziXY.length, 32);
    });

    test('fromBytes parses playNodes and pTreePos', () {
      final header = XqfHeader.fromBytes(validHeader);
      expect(header.playNodes, 10);
      expect(header.pTreePos, 1024);
    });

    test('fromBytes parses Delphi String[N] player names', () {
      final header = XqfHeader.fromBytes(validHeader);
      expect(header.redPlayer, 'Red');
      expect(header.blkPlayer, 'Black');
    });

    test('toBytes round-trip preserves all fields', () {
      final header = XqfHeader.fromBytes(validHeader);
      final bytes = header.toBytes();
      final header2 = XqfHeader.fromBytes(bytes);
      expect(header2.signature, header.signature);
      expect(header2.version, header.version);
      expect(header2.keyOrA, header.keyOrA);
      expect(header2.qiziXY, header.qiziXY);
      expect(header2.redPlayer, header.redPlayer);
      expect(header2.blkPlayer, header.blkPlayer);
      expect(header2.playNodes, header.playNodes);
    });

    test('toBytes produces exactly 1024 bytes', () {
      final header = XqfHeader.fromBytes(validHeader);
      expect(header.toBytes().length, 1024);
    });
  });
}
