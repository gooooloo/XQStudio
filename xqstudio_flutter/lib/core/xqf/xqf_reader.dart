import 'dart:typed_data';

import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/game_metadata.dart';
import 'package:xqstudio/core/models/play_node.dart';
import 'package:xqstudio/core/xqf/xqf_crypto.dart';
import 'package:xqstudio/core/xqf/xqf_header.dart';
import 'package:xqstudio/utils/gb2312_codec.dart';

/// Complete parsed result from an XQF file.
class GameData {
  final GameMetadata metadata;
  final PlayNode playTree; // root node (step 0)
  final List<int> initialPieceXY; // 32-element piece positions (1-based)

  GameData({
    required this.metadata,
    required this.playTree,
    required this.initialPieceXY,
  });
}

/// Reads XQF binary data and produces a [GameData].
///
/// Ported from `dTXQFile.iLoadXQFile` in XQFileRW.pas.
class XqfReader {
  XqfReader._();

  /// Parse an XQF file from raw bytes.
  static GameData readXqf(Uint8List bytes) {
    // 1. Parse header (first 1024 bytes, read with zero keys = no stream decryption)
    final header = XqfHeader.fromBytes(bytes);

    // 2. Validate keys checksum: keysSum + keyXY + keyXYf + keyXYt == 0 (mod 256)
    final keyCheck =
        (header.keysSum + header.keyXY + header.keyXYf + header.keyXYt) & 0xFF;
    if (keyCheck != 0) {
      throw FormatException('XQF key checksum failed: $keyCheck');
    }

    // 3. Derive security keys
    final secKeys = XqfCrypto.calculateSecurityKeys(
      version: header.version,
      keyXY: header.keyXY,
      keyXYf: header.keyXYf,
      keyXYt: header.keyXYt,
      keysSum: header.keysSum,
    );

    // 4. Decrypt piece positions from header
    final pieceXY = _decryptPiecePositions(header, secKeys.keyXY);

    // 5. Build metadata
    final metadata = _buildMetadata(header);

    // 6. Build root node
    final root = PlayNode(
      stepNo: header.playStepNo,
      strRec: '==========',
      xyf: 0,
      xyt: header.whoPlay == 1 ? 0xFF : 0,
      qiziXY: List<int>.from(pieceXY),
    );

    // 7. Read move tree from pTreePos
    if (bytes.length > XqfHeader.headerSize) {
      // Build F32Keys for stream decryption of move data
      final f32Keys = XqfCrypto.buildF32Keys(
        (header.keysSum & header.keyMask) | header.keyOrA,
        (header.keyXY & header.keyMask) | header.keyOrB,
        (header.keyXYf & header.keyMask) | header.keyOrC,
        (header.keyXYt & header.keyMask) | header.keyOrD,
      );

      final reader = _StreamReader(
        bytes: bytes,
        offset: XqfHeader.headerSize,
        f32Keys: f32Keys,
        streamOffset: XqfHeader.headerSize,
      );

      _readPlayNode(reader, root, header.version, secKeys);
    }

    return GameData(
      metadata: metadata,
      playTree: root,
      initialPieceXY: pieceXY,
    );
  }

  /// Decrypt piece positions from the header.
  ///
  /// Ported from iLoadXQFile lines 412-429.
  /// For version >= 12: circular permutation then subtract KeyXY.
  /// For version < 12: just copy (keys are 0 for version <= 10).
  static List<int> _decryptPiecePositions(XqfHeader header, int keyXY) {
    // qiziXY in header is 0-based (32 elements), but Delphi uses 1-based.
    // We keep our list 1-based (index 0 unused) matching kInitialPieceXY.
    final result = List<int>.filled(33, 0); // index 0 unused

    if (header.version >= 12) {
      // Circular permutation: result[((i + keyXY) % 32) + 1] = header.qiziXY[i]
      // where i is 0-based index into header's 32-byte array,
      // mapping to 1-based Delphi: Delphi i=1..32, header.QiziXY[i]
      // In Delphi: QiziXY[((i + KeyXY) mod 32) + 1] := XQFHead.QiziXY[i]
      // where i goes 1..32. Our header.qiziXY is 0-based (0..31).
      for (var i = 0; i < 32; i++) {
        final delphiI = i + 1; // 1-based
        final destIndex = ((delphiI + keyXY) % 32) + 1;
        result[destIndex] = header.qiziXY[i];
      }
    } else {
      for (var i = 0; i < 32; i++) {
        result[i + 1] = header.qiziXY[i];
      }
    }

    // Subtract keyXY, cap at 89
    for (var i = 1; i <= 32; i++) {
      result[i] = (result[i] - keyXY) & 0xFF;
      if (result[i] > 89) result[i] = kCapturedXY;
    }

    return result;
  }

  static GameMetadata _buildMetadata(XqfHeader header) {
    return GameMetadata(
      titleA: header.titleA,
      titleB: header.titleB,
      matchName: header.matchName,
      matchTime: header.matchTime,
      matchAddr: header.matchAddr,
      redPlayer: header.redPlayer,
      blkPlayer: header.blkPlayer,
      timeRule: header.timeRule,
      redTime: header.redTime,
      blkTime: header.blkTime,
      rmkWriter: header.rmkWriter,
      author: header.author,
      result: _parseResult(header.playResult),
      whoPlay: _parseWhoPlay(header.whoPlay),
    );
  }

  static GameResult _parseResult(int value) {
    switch (value) {
      case 1:
        return GameResult.redWin;
      case 2:
        return GameResult.blackWin;
      case 3:
        return GameResult.draw;
      default:
        return GameResult.unknown;
    }
  }

  static WhoPlay _parseWhoPlay(int value) {
    switch (value) {
      case 0:
        return WhoPlay.red;
      case 1:
        return WhoPlay.black;
      default:
        return WhoPlay.red;
    }
  }

  /// Recursively read a play node from the stream.
  ///
  /// Ported from `dInsertPNintoPlayTree` in XQFileRW.pas.
  static void _readPlayNode(
    _StreamReader reader,
    PlayNode node,
    int version,
    SecurityKeys secKeys,
  ) {
    // Read base fields: XYf(1), XYt(1), ChildTag(1), Reserved(1) = 4 bytes
    final base = reader.readDecrypted(4);
    final xyf = base[0];
    final xyt = base[1];
    var childTag = base[2];
    // base[3] is Reserved, ignored

    int remarkSize = 0;

    if (version <= 0x0A) {
      // Old format: reinterpret ChildTag
      var b = 0;
      if ((childTag & 0xF0) != 0) b = b | 0x80;
      if ((childTag & 0x0F) != 0) b = b | 0x40;
      childTag = b;
      // Always read RemarkSize (4 bytes)
      final rmkBytes = reader.readDecrypted(4);
      remarkSize = _readUint32LE(rmkBytes, 0);
    } else {
      // New format: mask to top 3 bits
      childTag = childTag & 0xE0;
      if ((childTag & 0x20) != 0) {
        final rmkBytes = reader.readDecrypted(4);
        remarkSize = _readUint32LE(rmkBytes, 0);
      }
    }

    // Decrypt move positions
    if (node.lastStepNode != null) {
      // Not the root node
      node.xyf = (xyf - 0x18 - secKeys.keyXYf) & 0xFF;
      node.xyt = (xyt - 0x20 - secKeys.keyXYt) & 0xFF;
      node.stepNo = node.lastStepNode!.stepNo + 1;
      node.qiziXY = List<int>.from(node.lastStepNode!.qiziXY);
      // Note: strRec would be computed by sGetPlayRecStr, skip for now
    } else {
      // Root node
      node.xyf = 0;
      // xyt already set based on whoPlay
    }

    // Decrypt and read remark
    if (remarkSize > 0) {
      remarkSize = (remarkSize - secKeys.keyRMKSize) & 0xFFFFFFFF;
    }
    if (remarkSize > 0 && remarkSize < 0x80000000) {
      final remarkBytes = reader.readDecrypted(remarkSize);
      final remarkText = decodeGB2312(Uint8List.fromList(remarkBytes));
      // Split by newlines to match Delphi TStringList behavior
      node.remark = remarkText.split('\r\n');
    }

    // Recurse into children
    if ((childTag & 0x80) != 0) {
      // Has left child (next move in main line)
      final child = PlayNode(
        stepNo: 0,
        strRec: '',
        xyf: 0,
        xyt: 0,
        qiziXY: List<int>.from(node.qiziXY),
        lastStepNode: node,
      );
      node.setLChild(child);
      _readPlayNode(reader, child, version, secKeys);
    }

    if ((childTag & 0x40) != 0) {
      // Has right child (variation)
      final sibling = PlayNode(
        stepNo: 0,
        strRec: '',
        xyf: 0,
        xyt: 0,
        qiziXY: List<int>.from(node.qiziXY),
        lastStepNode: node.lastStepNode,
        lParent: node,
      );
      node.setRChild(sibling);
      _readPlayNode(reader, sibling, version, secKeys);
    }
  }

  static int _readUint32LE(List<int> bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }
}

/// Helper to read from the byte stream with F32Keys decryption,
/// tracking position for the key rotation.
class _StreamReader {
  final Uint8List bytes;
  int _pos;
  final List<int> f32Keys;
  int _streamOffset;

  _StreamReader({
    required this.bytes,
    required int offset,
    required this.f32Keys,
    required int streamOffset,
  })  : _pos = offset,
        _streamOffset = streamOffset;

  /// Read [count] bytes, decrypt them using F32Keys at current stream position.
  List<int> readDecrypted(int count) {
    final data = Uint8List.fromList(bytes.sublist(_pos, _pos + count));
    XqfCrypto.decrypt(data, f32Keys, streamOffset: _streamOffset);
    _pos += count;
    _streamOffset += count;
    return data;
  }
}
