import 'dart:math';
import 'dart:typed_data';

import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/game_metadata.dart';
import 'package:xqstudio/core/models/play_node.dart';
import 'package:xqstudio/core/xqf/xqf_crypto.dart';
import 'package:xqstudio/core/xqf/xqf_header.dart';
import 'package:xqstudio/core/xqf/xqf_reader.dart';
import 'package:xqstudio/utils/gb2312_codec.dart';

/// Writes a [GameData] to XQF binary format.
///
/// Inverse of [XqfReader]. Ported from `dTXQFile.iSaveXQFile` in XQFileRW.pas.
class XqfWriter {
  XqfWriter._();

  static final _random = Random();

  /// Serialize a [GameData] to XQF bytes that [XqfReader.readXqf] can parse.
  static Uint8List writeXqf(GameData gameData) {
    // 1. Generate random encryption keys
    final keyXYRaw = _random.nextInt(254) + 1;
    final keyXYfRaw = _random.nextInt(254) + 1;
    final keyXYtRaw = _random.nextInt(254) + 1;
    final keysSum = (256 - keyXYRaw - keyXYfRaw - keyXYtRaw) & 0xFF;

    final keyMask = _random.nextInt(256) | 0xAA;
    final keyOrA = _random.nextInt(256);
    final keyOrB = _random.nextInt(256);
    final keyOrC = _random.nextInt(256);
    final keyOrD = (256 - keyOrA - keyOrB - keyOrC) & 0xFF;

    // 2. Derive security keys
    final secKeys = XqfCrypto.calculateSecurityKeys(
      version: kFileVersion,
      keyXY: keyXYRaw,
      keyXYf: keyXYfRaw,
      keyXYt: keyXYtRaw,
      keysSum: keysSum,
    );

    // 3. Encrypt piece positions
    // initialPieceXY may be 33 elements (1-based, index 0 unused) from the reader,
    // or 32 elements (0-based) if constructed manually. Normalize to 1-based (33 elements).
    final pieceXY = List<int>.filled(33, 0);
    if (gameData.initialPieceXY.length == 33) {
      for (var i = 1; i <= 32; i++) {
        pieceXY[i] = gameData.initialPieceXY[i];
      }
    } else {
      for (var i = 0; i < 32; i++) {
        pieceXY[i + 1] = gameData.initialPieceXY[i];
      }
    }

    // Encrypt: apply keyXY offset, handle captured pieces, then circular permutation.
    // Inverse of reader's _decryptPiecePositions.
    //
    // Reader does:
    //   result[((i+1 + keyXY) % 32) + 1] = header.qiziXY[i]  (for i=0..31, version>=12)
    //   result[j] = (result[j] - keyXY) & 0xFF; cap at 89
    //
    // Writer (Delphi iSaveXQFile):
    //   XQFHead.QiziXY[i] = QiziXY[((i + KeyXY) mod 32) + 1]  (i=1..32)
    //   if captured ($FF), replace with 90+random
    //   XQFHead.QiziXY[i] = XQFHead.QiziXY[i] + KeyXY
    final encQiziXY = List<int>.filled(32, 0);
    for (var i = 1; i <= 32; i++) {
      encQiziXY[i - 1] = pieceXY[((i + secKeys.keyXY) % 32) + 1];
    }
    for (var i = 0; i < 32; i++) {
      if (encQiziXY[i] == kCapturedXY) {
        encQiziXY[i] = 90 + _random.nextInt(155);
      }
      encQiziXY[i] = (encQiziXY[i] + secKeys.keyXY) & 0xFF;
    }

    // 4. Determine metadata values
    final whoPlay = gameData.metadata.whoPlay == WhoPlay.black ? 1 : 0;
    final playResult = _encodeResult(gameData.metadata.result);

    // 5. Count nodes
    final nodeCount = _countNodes(gameData.playTree);

    // 6. Build header
    final header = XqfHeader(
      signature: XqfHeader.xqfSignature,
      version: kFileVersion,
      keyMask: keyMask,
      productId: 0,
      keyOrA: keyOrA,
      keyOrB: keyOrB,
      keyOrC: keyOrC,
      keyOrD: keyOrD,
      keysSum: keysSum,
      keyXY: keyXYRaw,
      keyXYf: keyXYfRaw,
      keyXYt: keyXYtRaw,
      qiziXY: encQiziXY,
      playStepNo: gameData.playTree.stepNo,
      whoPlay: whoPlay,
      playResult: playResult,
      playNodes: nodeCount,
      pTreePos: XqfHeader.headerSize,
      reserved1: Uint8List(4),
      codes: List<int>.filled(8, 0),
      titleA: gameData.metadata.titleA,
      titleB: gameData.metadata.titleB,
      matchName: gameData.metadata.matchName,
      matchTime: gameData.metadata.matchTime,
      matchAddr: gameData.metadata.matchAddr,
      redPlayer: gameData.metadata.redPlayer,
      blkPlayer: gameData.metadata.blkPlayer,
      timeRule: gameData.metadata.timeRule,
      redTime: gameData.metadata.redTime,
      blkTime: gameData.metadata.blkTime,
      reservedh: '',
      rmkWriter: gameData.metadata.rmkWriter,
      author: gameData.metadata.author,
      reserved2: Uint8List(16),
      reserved3: Uint8List(512),
    );

    final headerBytes = header.toBytes();

    // 7. Serialize move tree with stream encryption
    final f32Keys = XqfCrypto.buildF32Keys(
      (keysSum & keyMask) | keyOrA,
      (keyXYRaw & keyMask) | keyOrB,
      (keyXYfRaw & keyMask) | keyOrC,
      (keyXYtRaw & keyMask) | keyOrD,
    );

    final treeWriter = _StreamWriter(
      f32Keys: f32Keys,
      streamOffset: XqfHeader.headerSize,
    );

    _writePlayNode(treeWriter, gameData.playTree, secKeys);

    // 8. Concatenate
    final treeBytes = treeWriter.toBytes();
    final result = Uint8List(headerBytes.length + treeBytes.length);
    result.setRange(0, headerBytes.length, headerBytes);
    result.setRange(headerBytes.length, result.length, treeBytes);
    return result;
  }

  static int _encodeResult(GameResult result) {
    switch (result) {
      case GameResult.redWin:
        return 1;
      case GameResult.blackWin:
        return 2;
      case GameResult.draw:
        return 3;
      case GameResult.unknown:
        return 0;
    }
  }

  static int _countNodes(PlayNode node) {
    var count = 1;
    if (node.lChild != null) count += _countNodes(node.lChild!);
    if (node.rChild != null) count += _countNodes(node.rChild!);
    return count;
  }

  /// Recursively serialize a play node.
  ///
  /// Ported from `dSavePlayNodeIntoXQFile` in XQFileRW.pas.
  static void _writePlayNode(
    _StreamWriter writer,
    PlayNode node,
    SecurityKeys secKeys,
  ) {
    int xyf, xyt;

    if (node.lastStepNode == null) {
      // Root node: write 'X', 'Q' as marker (Delphi convention)
      xyf = 0x58; // 'X'
      xyt = 0x51; // 'Q'
    } else {
      // Encrypt move coordinates
      xyf = (node.xyf + 0x18 + secKeys.keyXYf) & 0xFF;
      xyt = (node.xyt + 0x20 + secKeys.keyXYt) & 0xFF;
    }

    var childTag = _random.nextInt(256) & 0x1F; // random low 5 bits
    if (node.lChild != null) childTag |= 0x80;
    if (node.rChild != null) childTag |= 0x40;

    final reserved = _random.nextInt(256);

    // Prepare remark
    Uint8List? remarkBytes;
    if (node.remark != null && node.remark!.isNotEmpty) {
      final remarkText = node.remark!.join('\r\n');
      remarkBytes = encodeGB2312(remarkText);
    }

    final hasRemark = remarkBytes != null && remarkBytes.isNotEmpty;

    if (hasRemark) {
      childTag |= 0x20;
      final remarkSize = (remarkBytes.length + secKeys.keyRMKSize) & 0xFFFFFFFF;

      // Write 4 base bytes + 4 remark size bytes = 8 bytes
      final rec = Uint8List(8);
      rec[0] = xyf & 0xFF;
      rec[1] = xyt & 0xFF;
      rec[2] = childTag & 0xFF;
      rec[3] = reserved & 0xFF;
      rec[4] = remarkSize & 0xFF;
      rec[5] = (remarkSize >> 8) & 0xFF;
      rec[6] = (remarkSize >> 16) & 0xFF;
      rec[7] = (remarkSize >> 24) & 0xFF;
      writer.writeEncrypted(rec);

      // Write remark content
      writer.writeEncrypted(Uint8List.fromList(remarkBytes));
    } else {
      // Write 4 base bytes only (no remark size)
      final rec = Uint8List(4);
      rec[0] = xyf & 0xFF;
      rec[1] = xyt & 0xFF;
      rec[2] = childTag & 0xFF;
      rec[3] = reserved & 0xFF;
      writer.writeEncrypted(rec);
    }

    // Recurse: left child first, then right child
    if (node.lChild != null) {
      _writePlayNode(writer, node.lChild!, secKeys);
    }
    if (node.rChild != null) {
      _writePlayNode(writer, node.rChild!, secKeys);
    }
  }
}

/// Helper to build encrypted byte stream for move tree data.
class _StreamWriter {
  final List<int> f32Keys;
  int _streamOffset;
  final _buffer = BytesBuilder(copy: false);

  _StreamWriter({
    required this.f32Keys,
    required int streamOffset,
  }) : _streamOffset = streamOffset;

  void writeEncrypted(Uint8List data) {
    final encrypted = Uint8List.fromList(data);
    XqfCrypto.encrypt(encrypted, f32Keys, streamOffset: _streamOffset);
    _buffer.add(encrypted);
    _streamOffset += data.length;
  }

  Uint8List toBytes() => _buffer.toBytes();
}
