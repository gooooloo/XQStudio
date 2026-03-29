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

  /// Key derivation formula from XQFileRW.pas:498-503.
  /// Delphi computes as 32-bit Integer, truncates to Byte on assignment.
  static int _deriveKey(int bKey) {
    final v = (((((bKey * bKey) * 3 + 9) * 3 + 8) * 2 + 1) * 3 + 8) * bKey;
    return v & 0xFF;
  }

  static SecurityKeys calculateSecurityKeys({
    required int version,
    required int keyXY,
    required int keyXYf,
    required int keyXYt,
    required int keysSum,
  }) {
    if (version <= 10) return const SecurityKeys(0, 0, 0, 0);
    final kXY = _deriveKey(keyXY);
    final kXYf = (_deriveKey(keyXYf) * kXY) & 0xFF;
    final kXYt = (_deriveKey(keyXYt) * kXYf) & 0xFF;
    final wKey = keysSum * 256 + keyXY;
    final kRMKSize = (wKey % 32000) + 767;
    return SecurityKeys(kXY, kXYf, kXYt, kRMKSize);
  }

  static List<int> buildF32Keys(int b1, int b2, int b3, int b4) {
    final keys = List<int>.filled(32, 0);
    final mask = [b1, b2, b3, b4];
    for (var i = 0; i < 32; i++) {
      keys[i] = _copyrightStr.codeUnitAt(i) & mask[i % 4];
    }
    return keys;
  }

  /// Decrypt using SUBTRACTION. Port of dTXqfStream.Read (XQFileRW.pas:221-227).
  static void decrypt(Uint8List data, List<int> f32Keys, {required int streamOffset}) {
    for (var i = 0; i < data.length; i++) {
      final keyByte = f32Keys[(streamOffset + i) % 32];
      data[i] = (data[i] - keyByte) & 0xFF;
    }
  }

  /// Encrypt using ADDITION. Port of dTXqfStream.Write (XQFileRW.pas:252-257).
  static void encrypt(Uint8List data, List<int> f32Keys, {required int streamOffset}) {
    for (var i = 0; i < data.length; i++) {
      final keyByte = f32Keys[(streamOffset + i) % 32];
      data[i] = (data[i] + keyByte) & 0xFF;
    }
  }
}
