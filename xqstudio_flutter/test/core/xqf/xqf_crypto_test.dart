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
        final keys = XqfCrypto.calculateSecurityKeys(version: 12, keyXY: 0, keyXYf: 0, keyXYt: 0, keysSum: 0);
        expect(keys.keyXY, 0);
      });

      test('version 12 with bKey=1 computes correctly', () {
        // (((((1*1)*3+9)*3+8)*2+1)*3+8)*1 = 275, & 0xFF = 19
        final keys = XqfCrypto.calculateSecurityKeys(version: 12, keyXY: 1, keyXYf: 1, keyXYt: 1, keysSum: 1);
        expect(keys.keyXY, 19);
      });

      test('version 18 with bKey=200 computes correctly', () {
        // Full integer computation then truncate:
        // (((((200*200)*3+9)*3+8)*2+1)*3+8)*200 = 432044200
        // 432044200 & 0xFF = ?
        // 432044200 / 256 = 1687672.65625
        // 432044200 - 1687672 * 256 = 432044200 - 431883264 = 160936
        // Still too big... 160936 / 256 = 628.65625
        // 160936 - 628 * 256 = 160936 - 160768 = 168
        final keys = XqfCrypto.calculateSecurityKeys(version: 18, keyXY: 200, keyXYf: 0, keyXYt: 0, keysSum: 0);
        expect(keys.keyXY, 168);
      });

      test('all 256 bKey values produce byte results', () {
        for (var b = 0; b < 256; b++) {
          final keys = XqfCrypto.calculateSecurityKeys(version: 18, keyXY: b, keyXYf: b, keyXYt: b, keysSum: b);
          expect(keys.keyXY, lessThanOrEqualTo(255));
          expect(keys.keyXY, greaterThanOrEqualTo(0));
        }
      });

      test('keyXYf depends on keyXY result (chained)', () {
        // KeyXY for bKey=1: 19
        // KeyXYf = derive(1) * KeyXY = 275 * 19 = 5225, & 0xFF = 5225 % 256 = 105
        final keys = XqfCrypto.calculateSecurityKeys(version: 18, keyXY: 1, keyXYf: 1, keyXYt: 0, keysSum: 0);
        expect(keys.keyXYf, 105);
      });

      test('keyRMKSize calculation', () {
        // wKey = keysSum * 256 + keyXY = 1 * 256 + 1 = 257
        // keyRMKSize = (257 % 32000) + 767 = 257 + 767 = 1024
        final keys = XqfCrypto.calculateSecurityKeys(version: 18, keyXY: 1, keyXYf: 0, keyXYt: 0, keysSum: 1);
        expect(keys.keyRMKSize, 1024);
      });
    });

    group('encrypt/decrypt (subtraction/addition)', () {
      test('encrypt then decrypt restores original', () {
        final original = Uint8List.fromList(List.generate(100, (i) => i * 3 + 7));
        final f32Keys = XqfCrypto.buildF32Keys(0x12, 0x34, 0x56, 0x78);
        final data = Uint8List.fromList(original);
        XqfCrypto.encrypt(data, f32Keys, streamOffset: 0);
        expect(data, isNot(equals(original)));
        XqfCrypto.decrypt(data, f32Keys, streamOffset: 0);
        expect(data, original);
      });

      test('stream offset affects key rotation', () {
        final data1 = Uint8List.fromList([0x42]);
        final data2 = Uint8List.fromList([0x42]);
        final f32Keys = XqfCrypto.buildF32Keys(0x12, 0x34, 0x56, 0x78);
        XqfCrypto.decrypt(data1, f32Keys, streamOffset: 0);
        XqfCrypto.decrypt(data2, f32Keys, streamOffset: 5);
        expect(data1[0], isNot(data2[0]));
      });

      test('decrypt uses subtraction (not XOR)', () {
        // If byte is 0x50 and key is 0x10, decrypt should give 0x50 - 0x10 = 0x40
        final data = Uint8List.fromList([0x50]);
        final f32Keys = List<int>.filled(32, 0x10);
        XqfCrypto.decrypt(data, f32Keys, streamOffset: 0);
        expect(data[0], 0x40);
      });

      test('encrypt uses addition (not XOR)', () {
        final data = Uint8List.fromList([0x40]);
        final f32Keys = List<int>.filled(32, 0x10);
        XqfCrypto.encrypt(data, f32Keys, streamOffset: 0);
        expect(data[0], 0x50);
      });

      test('byte wrapping on underflow', () {
        // 0x05 - 0x10 = -11, wraps to 0xF5
        final data = Uint8List.fromList([0x05]);
        final f32Keys = List<int>.filled(32, 0x10);
        XqfCrypto.decrypt(data, f32Keys, streamOffset: 0);
        expect(data[0], 0xF5);
      });

      test('byte wrapping on overflow', () {
        // 0xF5 + 0x10 = 261, wraps to 0x05
        final data = Uint8List.fromList([0xF5]);
        final f32Keys = List<int>.filled(32, 0x10);
        XqfCrypto.encrypt(data, f32Keys, streamOffset: 0);
        expect(data[0], 0x05);
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

      test('AND mask with key bytes', () {
        final keys = XqfCrypto.buildF32Keys(0x00, 0xFF, 0xFF, 0xFF);
        // First key: '[' & 0x00 = 0
        expect(keys[0], 0);
        // Second key: '(' & 0xFF = 0x28
        expect(keys[1], 0x28);
      });
    });
  });
}
