import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/game_metadata.dart';
import 'package:xqstudio/core/xqf/xqf_crypto.dart';
import 'package:xqstudio/core/xqf/xqf_header.dart';
import 'package:xqstudio/core/xqf/xqf_reader.dart';
import 'package:xqstudio/utils/gb2312_codec.dart';

/// Build a minimal 1024-byte XQF header with the given parameters.
/// Returns the raw bytes that XqfHeader.fromBytes() can parse.
Uint8List _buildHeader({
  int version = 18,
  int keyMask = 0,
  int keyOrA = 0,
  int keyOrB = 0,
  int keyOrC = 0,
  int keyOrD = 0,
  int keysSum = 0,
  int keyXY = 0,
  int keyXYf = 0,
  int keyXYt = 0,
  List<int>? qiziXY,
  int playStepNo = 0,
  int whoPlay = 0,
  int playResult = 0,
  int playNodes = 0,
  int pTreePos = 1024,
  String titleA = '',
  String redPlayer = '',
  String blkPlayer = '',
  String matchName = '',
}) {
  final bytes = Uint8List(XqfHeader.headerSize);
  final bd = ByteData.sublistView(bytes);

  // Signature
  bd.setUint16(0, 0x5158, Endian.little);
  bytes[2] = version;
  bytes[3] = keyMask;
  bd.setUint32(4, 0, Endian.little); // productId
  bytes[8] = keyOrA;
  bytes[9] = keyOrB;
  bytes[10] = keyOrC;
  bytes[11] = keyOrD;
  bytes[12] = keysSum;
  bytes[13] = keyXY;
  bytes[14] = keyXYf;
  bytes[15] = keyXYt;

  // qiziXY: 32 bytes at offset 16
  final positions = qiziXY ?? List<int>.filled(32, 0xFF);
  for (var i = 0; i < 32; i++) {
    bytes[16 + i] = positions[i] & 0xFF;
  }

  bd.setUint16(48, playStepNo, Endian.little);
  bytes[50] = whoPlay;
  bytes[51] = playResult;
  bd.setUint32(52, playNodes, Endian.little);
  bd.setUint32(56, pTreePos, Endian.little);

  // Write Delphi short strings
  _writeDelphiString(bytes, 80, titleA, 63);
  _writeDelphiString(bytes, 304, redPlayer, 15);
  _writeDelphiString(bytes, 320, blkPlayer, 15);
  _writeDelphiString(bytes, 208, matchName, 63);

  return bytes;
}

void _writeDelphiString(Uint8List bytes, int offset, String value, int maxLen) {
  if (value.isEmpty) {
    bytes[offset] = 0;
    return;
  }
  final encoded = encodeGB2312(value);
  final len = encoded.length > maxLen ? maxLen : encoded.length;
  bytes[offset] = len;
  for (var i = 0; i < len; i++) {
    bytes[offset + 1 + i] = encoded[i];
  }
}

/// Encrypt piece positions as the save routine does (XQFileRW.pas:624-637).
/// Takes 1-based pieceXY (33 elements, index 0 unused) and returns
/// 0-based 32-element encrypted array for the header.
List<int> _encryptPiecePositions(List<int> pieceXY, int keyXY) {
  // In save: XQFHead.QiziXY[i] := XQPlayTree.QiziXY[((i + KeyXY) mod 32) + 1]
  // where i goes 1..32 (Delphi). Our output is 0-based (0..31).
  final encrypted = List<int>.filled(32, 0);
  for (var i = 0; i < 32; i++) {
    final delphiI = i + 1;
    final srcIndex = ((delphiI + keyXY) % 32) + 1;
    var val = pieceXY[srcIndex];
    // Captured pieces get random value >= 90
    if (val == kCapturedXY) val = 90;
    // Add keyXY
    encrypted[i] = (val + keyXY) & 0xFF;
  }
  return encrypted;
}

/// Build an encrypted move record for version > 10.
/// Returns the raw bytes that the stream reader will decrypt.
Uint8List _buildMoveRecord({
  required int xyf,
  required int xyt,
  required int keyXYf,
  required int keyXYt,
  required int keyRMKSize,
  bool hasLChild = false,
  bool hasRChild = false,
  String? remark,
  required List<int> f32Keys,
  required int streamOffset,
  bool isRoot = false,
}) {
  final parts = <int>[];

  // Encrypt source/destination
  int encXYf, encXYt;
  if (isRoot) {
    // Save routine writes 'X' and 'Q' for root
    encXYf = 0x58; // 'X'
    encXYt = 0x51; // 'Q'
  } else {
    encXYf = (xyf + 0x18 + keyXYf) & 0xFF;
    encXYt = (xyt + 0x20 + keyXYt) & 0xFF;
  }

  var childTag = 0;
  if (hasLChild) childTag |= 0x80;
  if (hasRChild) childTag |= 0x40;

  Uint8List? remarkBytes;
  if (remark != null && remark.isNotEmpty) {
    remarkBytes = encodeGB2312(remark);
    childTag |= 0x20;
  }

  // Base 4 bytes: XYf, XYt, ChildTag, Reserved
  parts.addAll([encXYf, encXYt, childTag, 0]);

  // If has remark, add encrypted RemarkSize (4 bytes LE) + remark content
  if (remarkBytes != null) {
    final encSize = (remarkBytes.length + keyRMKSize) & 0xFFFFFFFF;
    parts.add(encSize & 0xFF);
    parts.add((encSize >> 8) & 0xFF);
    parts.add((encSize >> 16) & 0xFF);
    parts.add((encSize >> 24) & 0xFF);
    parts.addAll(remarkBytes);
  }

  // Now encrypt the whole thing with F32Keys
  final data = Uint8List.fromList(parts);
  XqfCrypto.encrypt(data, f32Keys, streamOffset: streamOffset);
  return data;
}

/// Build a version 10 (no-encryption) move record.
Uint8List _buildMoveRecordV10({
  required int xyf,
  required int xyt,
  bool hasLChild = false,
  bool hasRChild = false,
  String? remark,
  bool isRoot = false,
}) {
  final parts = <int>[];

  int encXYf, encXYt;
  if (isRoot) {
    encXYf = 0x58;
    encXYt = 0x51;
  } else {
    // No key encryption for v10 (keys are all 0)
    encXYf = (xyf + 0x18) & 0xFF;
    encXYt = (xyt + 0x20) & 0xFF;
  }

  // V10 ChildTag: uses F0/0F pattern
  var childTag = 0;
  if (hasLChild) childTag |= 0xF0;
  if (hasRChild) childTag |= 0x0F;

  parts.addAll([encXYf, encXYt, childTag, 0]);

  // V10 always writes RemarkSize
  Uint8List? remarkBytes;
  int remarkSize = 0;
  if (remark != null && remark.isNotEmpty) {
    remarkBytes = encodeGB2312(remark);
    remarkSize = remarkBytes.length;
  }
  parts.add(remarkSize & 0xFF);
  parts.add((remarkSize >> 8) & 0xFF);
  parts.add((remarkSize >> 16) & 0xFF);
  parts.add((remarkSize >> 24) & 0xFF);

  if (remarkBytes != null) {
    parts.addAll(remarkBytes);
  }

  // V10: F32Keys are all zero (SetKeyBytes(0,0,0,0)), so no stream encryption
  return Uint8List.fromList(parts);
}

void main() {
  group('XqfReader', () {
    test('reads empty game (header only, no moves)', () {
      // Version 10, no encryption, all pieces captured
      final headerBytes = _buildHeader(
        version: 10,
        qiziXY: List<int>.filled(32, 0xFF),
        pTreePos: 1024,
      );

      final gameData = XqfReader.readXqf(headerBytes);

      expect(gameData.playTree.stepNo, 0);
      expect(gameData.playTree.xyf, 0);
      expect(gameData.playTree.xyt, 0);
      expect(gameData.playTree.lChild, isNull);
      expect(gameData.playTree.rChild, isNull);
      expect(gameData.metadata.whoPlay, WhoPlay.red);
      // All pieces should be captured (0xFF) since header has 0xFF
      // and version 10 means keyXY=0, so 0xFF - 0 = 0xFF > 89 -> 0xFF
      for (var i = 1; i <= 32; i++) {
        expect(gameData.initialPieceXY[i], kCapturedXY);
      }
    });

    test('reads no-encryption game (version 10) with one move', () {
      // Build header for version 10
      // Use initial positions (no encryption needed)
      final piecePositions = List<int>.filled(32, 0);
      for (var i = 0; i < 32; i++) {
        piecePositions[i] = kInitialPieceXY[i + 1]; // 1-based to 0-based
      }

      final headerBytes = _buildHeader(
        version: 10,
        qiziXY: piecePositions,
        whoPlay: 0, // red plays first
      );

      // Build move tree: root -> one move (Pao 72 -> 74, i.e. 炮二平五)
      // Root node
      final rootRecord = _buildMoveRecordV10(
        xyf: 0,
        xyt: 0,
        hasLChild: true,
        isRoot: true,
      );

      // Child: move from 72 to 74
      final moveRecord = _buildMoveRecordV10(
        xyf: 72,
        xyt: 74,
        hasLChild: false,
        hasRChild: false,
      );

      // Combine header + root + move
      final allBytes = Uint8List.fromList([
        ...headerBytes,
        ...rootRecord,
        ...moveRecord,
      ]);

      final gameData = XqfReader.readXqf(allBytes);

      // Verify root
      expect(gameData.playTree.xyf, 0);
      expect(gameData.playTree.xyt, 0);
      expect(gameData.playTree.lChild, isNotNull);

      // Verify move
      final move = gameData.playTree.lChild!;
      expect(move.xyf, 72);
      expect(move.xyt, 74);
      expect(move.stepNo, 1);
      expect(move.lChild, isNull);
      expect(move.rChild, isNull);

      // Verify piece positions
      expect(gameData.initialPieceXY[1], kInitialPieceXY[1]); // Red Che
    });

    test('reads encrypted game (version 18) with one move', () {
      // Use known key values
      const rawKeyXY = 30;
      const rawKeyXYf = 50;
      const rawKeyXYt = 70;
      // keysSum must satisfy: (keysSum + keyXY + keyXYf + keyXYt) & 0xFF == 0
      const keysSum = (256 - rawKeyXY - rawKeyXYf - rawKeyXYt) & 0xFF;

      // Derive security keys
      final secKeys = XqfCrypto.calculateSecurityKeys(
        version: 18,
        keyXY: rawKeyXY,
        keyXYf: rawKeyXYf,
        keyXYt: rawKeyXYt,
        keysSum: keysSum,
      );

      // Encrypt initial piece positions
      final encryptedPositions =
          _encryptPiecePositions(kInitialPieceXY, secKeys.keyXY);

      // Header keys
      const keyMask = 0xFF;
      const keyOrA = 0x10;
      const keyOrB = 0x20;
      const keyOrC = 0x30;
      const keyOrD = 0x40;

      final headerBytes = _buildHeader(
        version: 18,
        keyMask: keyMask,
        keyOrA: keyOrA,
        keyOrB: keyOrB,
        keyOrC: keyOrC,
        keyOrD: keyOrD,
        keysSum: keysSum,
        keyXY: rawKeyXY,
        keyXYf: rawKeyXYf,
        keyXYt: rawKeyXYt,
        qiziXY: encryptedPositions,
        whoPlay: 0,
      );

      // Build F32Keys for stream encryption of move data
      final f32Keys = XqfCrypto.buildF32Keys(
        (keysSum & keyMask) | keyOrA,
        (rawKeyXY & keyMask) | keyOrB,
        (rawKeyXYf & keyMask) | keyOrC,
        (rawKeyXYt & keyMask) | keyOrD,
      );

      // Build encrypted root node
      var offset = XqfHeader.headerSize;
      final rootRecord = _buildMoveRecord(
        xyf: 0,
        xyt: 0,
        keyXYf: secKeys.keyXYf,
        keyXYt: secKeys.keyXYt,
        keyRMKSize: secKeys.keyRMKSize,
        hasLChild: true,
        f32Keys: f32Keys,
        streamOffset: offset,
        isRoot: true,
      );
      offset += rootRecord.length;

      // Build encrypted move: Pao from 72 to 74
      final moveRecord = _buildMoveRecord(
        xyf: 72,
        xyt: 74,
        keyXYf: secKeys.keyXYf,
        keyXYt: secKeys.keyXYt,
        keyRMKSize: secKeys.keyRMKSize,
        f32Keys: f32Keys,
        streamOffset: offset,
      );

      final allBytes = Uint8List.fromList([
        ...headerBytes,
        ...rootRecord,
        ...moveRecord,
      ]);

      final gameData = XqfReader.readXqf(allBytes);

      // Verify piece positions were decrypted correctly
      for (var i = 1; i <= 32; i++) {
        expect(gameData.initialPieceXY[i], kInitialPieceXY[i],
            reason: 'piece $i position mismatch');
      }

      // Verify move
      expect(gameData.playTree.lChild, isNotNull);
      final move = gameData.playTree.lChild!;
      expect(move.xyf, 72);
      expect(move.xyt, 74);
      expect(move.stepNo, 1);
    });

    test('reads game with remark attached to a move', () {
      // Version 10, no encryption for simplicity
      final piecePositions = List<int>.filled(32, 0xFF);
      final headerBytes = _buildHeader(
        version: 10,
        qiziXY: piecePositions,
      );

      const remarkText = 'Good move!';

      final rootRecord = _buildMoveRecordV10(
        xyf: 0,
        xyt: 0,
        hasLChild: true,
        isRoot: true,
      );

      final moveRecord = _buildMoveRecordV10(
        xyf: 72,
        xyt: 74,
        remark: remarkText,
      );

      final allBytes = Uint8List.fromList([
        ...headerBytes,
        ...rootRecord,
        ...moveRecord,
      ]);

      final gameData = XqfReader.readXqf(allBytes);
      final move = gameData.playTree.lChild!;
      expect(move.remark, isNotNull);
      expect(move.remark!.join('\r\n'), remarkText);
    });

    test('reads game with variations (right child)', () {
      // Version 10, no encryption
      final headerBytes = _buildHeader(
        version: 10,
        qiziXY: List<int>.filled(32, 0xFF),
      );

      // Root -> move1 (has right sibling: variation)
      //              -> move1_var
      final rootRecord = _buildMoveRecordV10(
        xyf: 0,
        xyt: 0,
        hasLChild: true,
        isRoot: true,
      );

      // Main line move: 72->74, has a variation sibling
      final move1 = _buildMoveRecordV10(
        xyf: 72,
        xyt: 74,
        hasRChild: true,
      );

      // Variation: 12->14
      final move1Var = _buildMoveRecordV10(
        xyf: 12,
        xyt: 14,
      );

      final allBytes = Uint8List.fromList([
        ...headerBytes,
        ...rootRecord,
        ...move1,
        ...move1Var,
      ]);

      final gameData = XqfReader.readXqf(allBytes);
      final mainMove = gameData.playTree.lChild!;
      expect(mainMove.xyf, 72);
      expect(mainMove.xyt, 74);
      expect(mainMove.rChild, isNotNull);

      final variation = mainMove.rChild!;
      expect(variation.xyf, 12);
      expect(variation.xyt, 14);
    });

    test('reads game with both left and right children', () {
      // Version 10
      final headerBytes = _buildHeader(
        version: 10,
        qiziXY: List<int>.filled(32, 0xFF),
      );

      // Root -> move1 (has lchild and rchild)
      //           |-> move2 (lchild continuation)
      //           |-> move1_var (rchild variation)
      final rootRecord = _buildMoveRecordV10(
        xyf: 0, xyt: 0, hasLChild: true, isRoot: true,
      );
      final move1 = _buildMoveRecordV10(
        xyf: 72, xyt: 74, hasLChild: true, hasRChild: true,
      );
      // Depth-first: lchild is read first
      final move2 = _buildMoveRecordV10(xyf: 17, xyt: 47);
      // Then rchild
      final move1Var = _buildMoveRecordV10(xyf: 12, xyt: 14);

      final allBytes = Uint8List.fromList([
        ...headerBytes,
        ...rootRecord,
        ...move1,
        ...move2,
        ...move1Var,
      ]);

      final gameData = XqfReader.readXqf(allBytes);
      final m1 = gameData.playTree.lChild!;
      expect(m1.xyf, 72);
      expect(m1.lChild, isNotNull);
      expect(m1.lChild!.xyf, 17);
      expect(m1.rChild, isNotNull);
      expect(m1.rChild!.xyf, 12);
    });

    test('reads metadata from header', () {
      final headerBytes = _buildHeader(
        version: 10,
        qiziXY: List<int>.filled(32, 0xFF),
        whoPlay: 1, // black
        playResult: 3, // draw
        redPlayer: 'RedStar',
        blkPlayer: 'BlackHole',
        matchName: 'Championship',
      );

      final gameData = XqfReader.readXqf(headerBytes);
      expect(gameData.metadata.whoPlay, WhoPlay.black);
      expect(gameData.metadata.result, GameResult.draw);
      expect(gameData.metadata.redPlayer, 'RedStar');
      expect(gameData.metadata.blkPlayer, 'BlackHole');
      expect(gameData.metadata.matchName, 'Championship');

      // When whoPlay=1 (black), root xyt should be 0xFF
      expect(gameData.playTree.xyt, 0xFF);
    });

    test('rejects invalid key checksum', () {
      final headerBytes = _buildHeader(
        version: 18,
        keysSum: 10,
        keyXY: 20,
        keyXYf: 30,
        keyXYt: 40,
        // Sum = 100, not 0 mod 256
      );

      expect(
        () => XqfReader.readXqf(headerBytes),
        throwsFormatException,
      );
    });

    test('reads encrypted game with remark', () {
      const rawKeyXY = 5;
      const rawKeyXYf = 10;
      const rawKeyXYt = 15;
      const keysSum = (256 - rawKeyXY - rawKeyXYf - rawKeyXYt) & 0xFF;

      final secKeys = XqfCrypto.calculateSecurityKeys(
        version: 18,
        keyXY: rawKeyXY,
        keyXYf: rawKeyXYf,
        keyXYt: rawKeyXYt,
        keysSum: keysSum,
      );

      final encPositions =
          _encryptPiecePositions(kInitialPieceXY, secKeys.keyXY);

      const keyMask = 0xAA;
      const keyOrA = 0x11;
      const keyOrB = 0x22;
      const keyOrC = 0x33;
      const keyOrD = 0x44;

      final headerBytes = _buildHeader(
        version: 18,
        keyMask: keyMask,
        keyOrA: keyOrA,
        keyOrB: keyOrB,
        keyOrC: keyOrC,
        keyOrD: keyOrD,
        keysSum: keysSum,
        keyXY: rawKeyXY,
        keyXYf: rawKeyXYf,
        keyXYt: rawKeyXYt,
        qiziXY: encPositions,
      );

      final f32Keys = XqfCrypto.buildF32Keys(
        (keysSum & keyMask) | keyOrA,
        (rawKeyXY & keyMask) | keyOrB,
        (rawKeyXYf & keyMask) | keyOrC,
        (rawKeyXYt & keyMask) | keyOrD,
      );

      var offset = XqfHeader.headerSize;
      final rootRecord = _buildMoveRecord(
        xyf: 0,
        xyt: 0,
        keyXYf: secKeys.keyXYf,
        keyXYt: secKeys.keyXYt,
        keyRMKSize: secKeys.keyRMKSize,
        hasLChild: true,
        f32Keys: f32Keys,
        streamOffset: offset,
        isRoot: true,
      );
      offset += rootRecord.length;

      const remarkStr = 'Opening cannon';
      final moveRecord = _buildMoveRecord(
        xyf: 72,
        xyt: 74,
        keyXYf: secKeys.keyXYf,
        keyXYt: secKeys.keyXYt,
        keyRMKSize: secKeys.keyRMKSize,
        remark: remarkStr,
        f32Keys: f32Keys,
        streamOffset: offset,
      );

      final allBytes = Uint8List.fromList([
        ...headerBytes,
        ...rootRecord,
        ...moveRecord,
      ]);

      final gameData = XqfReader.readXqf(allBytes);
      final move = gameData.playTree.lChild!;
      expect(move.xyf, 72);
      expect(move.xyt, 74);
      expect(move.remark, isNotNull);
      expect(move.remark!.join('\r\n'), remarkStr);
    });
  });
}
