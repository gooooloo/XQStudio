import 'dart:typed_data';
import 'package:xqstudio/utils/gb2312_codec.dart';

/// XQF file header — a 1024-byte packed record matching the Delphi `dTXQFHead`.
class XqfHeader {
  static const int headerSize = 1024;
  static const int xqfSignature = 0x5158; // "XQ"

  final int signature; // Word at offset 0
  final int version; // Byte at offset 2
  final int keyMask; // Byte at offset 3
  final int productId; // DWord at offset 4
  final int keyOrA; // Byte at offset 8
  final int keyOrB; // Byte at offset 9
  final int keyOrC; // Byte at offset 10
  final int keyOrD; // Byte at offset 11
  final int keysSum; // Byte at offset 12
  final int keyXY; // Byte at offset 13
  final int keyXYf; // Byte at offset 14
  final int keyXYt; // Byte at offset 15
  final List<int> qiziXY; // 32 bytes at offset 16
  final int playStepNo; // Word at offset 48
  final int whoPlay; // Byte at offset 50
  final int playResult; // Byte at offset 51
  final int playNodes; // DWord at offset 52
  final int pTreePos; // DWord at offset 56
  final Uint8List reserved1; // 4 bytes at offset 60
  final List<int> codes; // 8 Words (16 bytes) at offset 64
  final String titleA; // String[63] at offset 80
  final String titleB; // String[63] at offset 144
  final String matchName; // String[63] at offset 208
  final String matchTime; // String[15] at offset 272
  final String matchAddr; // String[15] at offset 288
  final String redPlayer; // String[15] at offset 304
  final String blkPlayer; // String[15] at offset 320
  final String timeRule; // String[63] at offset 336
  final String redTime; // String[15] at offset 400
  final String blkTime; // String[15] at offset 416
  final String reservedh; // String[31] at offset 432
  final String rmkWriter; // String[15] at offset 464
  final String author; // String[15] at offset 480
  final Uint8List reserved2; // 16 bytes at offset 496
  final Uint8List reserved3; // 512 bytes at offset 512

  XqfHeader({
    required this.signature,
    required this.version,
    required this.keyMask,
    required this.productId,
    required this.keyOrA,
    required this.keyOrB,
    required this.keyOrC,
    required this.keyOrD,
    required this.keysSum,
    required this.keyXY,
    required this.keyXYf,
    required this.keyXYt,
    required this.qiziXY,
    required this.playStepNo,
    required this.whoPlay,
    required this.playResult,
    required this.playNodes,
    required this.pTreePos,
    required this.reserved1,
    required this.codes,
    required this.titleA,
    required this.titleB,
    required this.matchName,
    required this.matchTime,
    required this.matchAddr,
    required this.redPlayer,
    required this.blkPlayer,
    required this.timeRule,
    required this.redTime,
    required this.blkTime,
    required this.reservedh,
    required this.rmkWriter,
    required this.author,
    required this.reserved2,
    required this.reserved3,
  });

  /// Parse a 1024-byte XQF header from raw bytes.
  factory XqfHeader.fromBytes(Uint8List bytes) {
    if (bytes.length < headerSize) {
      throw FormatException(
        'XQF header too short: ${bytes.length} bytes (need $headerSize)',
      );
    }

    final bd = ByteData.sublistView(bytes, 0, headerSize);

    final sig = bd.getUint16(0, Endian.little);
    if (sig != xqfSignature) {
      throw FormatException(
        'Invalid XQF signature: 0x${sig.toRadixString(16)} (expected 0x5158)',
      );
    }

    return XqfHeader(
      signature: sig,
      version: bytes[2],
      keyMask: bytes[3],
      productId: bd.getUint32(4, Endian.little),
      keyOrA: bytes[8],
      keyOrB: bytes[9],
      keyOrC: bytes[10],
      keyOrD: bytes[11],
      keysSum: bytes[12],
      keyXY: bytes[13],
      keyXYf: bytes[14],
      keyXYt: bytes[15],
      qiziXY: List<int>.from(bytes.sublist(16, 48)),
      playStepNo: bd.getUint16(48, Endian.little),
      whoPlay: bytes[50],
      playResult: bytes[51],
      playNodes: bd.getUint32(52, Endian.little),
      pTreePos: bd.getUint32(56, Endian.little),
      reserved1: Uint8List.fromList(bytes.sublist(60, 64)),
      codes: List<int>.generate(
        8,
        (i) => bd.getUint16(64 + i * 2, Endian.little),
      ),
      titleA: _readDelphiString(bytes, 80, 63),
      titleB: _readDelphiString(bytes, 144, 63),
      matchName: _readDelphiString(bytes, 208, 63),
      matchTime: _readDelphiString(bytes, 272, 15),
      matchAddr: _readDelphiString(bytes, 288, 15),
      redPlayer: _readDelphiString(bytes, 304, 15),
      blkPlayer: _readDelphiString(bytes, 320, 15),
      timeRule: _readDelphiString(bytes, 336, 63),
      redTime: _readDelphiString(bytes, 400, 15),
      blkTime: _readDelphiString(bytes, 416, 15),
      reservedh: _readDelphiString(bytes, 432, 31),
      rmkWriter: _readDelphiString(bytes, 464, 15),
      author: _readDelphiString(bytes, 480, 15),
      reserved2: Uint8List.fromList(bytes.sublist(496, 512)),
      reserved3: Uint8List.fromList(bytes.sublist(512, 1024)),
    );
  }

  /// Serialize this header back to exactly 1024 bytes.
  Uint8List toBytes() {
    final bytes = Uint8List(headerSize);
    final bd = ByteData.sublistView(bytes);

    bd.setUint16(0, signature, Endian.little);
    bytes[2] = version;
    bytes[3] = keyMask;
    bd.setUint32(4, productId, Endian.little);
    bytes[8] = keyOrA;
    bytes[9] = keyOrB;
    bytes[10] = keyOrC;
    bytes[11] = keyOrD;
    bytes[12] = keysSum;
    bytes[13] = keyXY;
    bytes[14] = keyXYf;
    bytes[15] = keyXYt;

    for (var i = 0; i < 32; i++) {
      bytes[16 + i] = qiziXY[i];
    }

    bd.setUint16(48, playStepNo, Endian.little);
    bytes[50] = whoPlay;
    bytes[51] = playResult;
    bd.setUint32(52, playNodes, Endian.little);
    bd.setUint32(56, pTreePos, Endian.little);

    bytes.setRange(60, 64, reserved1);

    for (var i = 0; i < 8; i++) {
      bd.setUint16(64 + i * 2, codes[i], Endian.little);
    }

    _writeDelphiString(bytes, 80, titleA, 63);
    _writeDelphiString(bytes, 144, titleB, 63);
    _writeDelphiString(bytes, 208, matchName, 63);
    _writeDelphiString(bytes, 272, matchTime, 15);
    _writeDelphiString(bytes, 288, matchAddr, 15);
    _writeDelphiString(bytes, 304, redPlayer, 15);
    _writeDelphiString(bytes, 320, blkPlayer, 15);
    _writeDelphiString(bytes, 336, timeRule, 63);
    _writeDelphiString(bytes, 400, redTime, 15);
    _writeDelphiString(bytes, 416, blkTime, 15);
    _writeDelphiString(bytes, 432, reservedh, 31);
    _writeDelphiString(bytes, 464, rmkWriter, 15);
    _writeDelphiString(bytes, 480, author, 15);

    bytes.setRange(496, 512, reserved2);
    bytes.setRange(512, 1024, reserved3);

    return bytes;
  }

  /// Read a Delphi `String[N]` from [bytes] at [offset].
  ///
  /// Delphi short strings store the length in byte 0, followed by up to
  /// [maxLen] content bytes. Total storage is maxLen + 1.
  static String _readDelphiString(Uint8List bytes, int offset, int maxLen) {
    final len = bytes[offset];
    final actualLen = len > maxLen ? maxLen : len;
    if (actualLen == 0) return '';
    final content = bytes.sublist(offset + 1, offset + 1 + actualLen);
    return decodeGB2312(content);
  }

  /// Write a Delphi `String[N]` into [bytes] at [offset].
  ///
  /// Encodes [value] as GB2312, writes length byte then content,
  /// truncating to [maxLen] bytes if necessary.
  static void _writeDelphiString(
    Uint8List bytes,
    int offset,
    String value,
    int maxLen,
  ) {
    final encoded = encodeGB2312(value);
    final len = encoded.length > maxLen ? maxLen : encoded.length;
    bytes[offset] = len;
    for (var i = 0; i < len; i++) {
      bytes[offset + 1 + i] = encoded[i];
    }
  }
}
