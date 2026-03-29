import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/models/piece.dart';

/// Generates and parses Chinese xiangqi move notation strings.
///
/// Ported from Delphi `sGetPlayRecStr` in XQDataT.pas.
/// Format: [piece name][column][direction][distance or target column]
/// Example: 炮二平五, 马八进七
class MoveNotation {
  MoveNotation._();

  // Piece names by type for Red side.
  static const _redPieceNames = {
    PieceType.che: '车',
    PieceType.ma: '马',
    PieceType.xiang: '相',
    PieceType.shi: '士',
    PieceType.shuai: '帅',
    PieceType.pao: '炮',
    PieceType.bing: '兵',
  };

  // Piece names by type for Black side.
  static const _blkPieceNames = {
    PieceType.che: '车',
    PieceType.ma: '马',
    PieceType.xiang: '象',
    PieceType.shi: '士',
    PieceType.shuai: '将',
    PieceType.pao: '炮',
    PieceType.bing: '卒',
  };

  // All piece name characters (for parsing).
  static const _allPieceChars = {
    '车', '马', '相', '士', '帅', '炮', '兵', '象', '将', '卒',
  };

  // Position prefix characters for disambiguation.
  static const _positionPrefixes = ['前', '后', '中', '二', '三', '四'];

  /// Red column number: column X → Chinese numeral (right-to-left).
  /// Column 0 = 九, column 8 = 一.
  /// Matches Delphi: sGetRedLine(iX) = dCREDNUM[9-iX] (when bRL=false).
  static String _redCol(int x) => kRedNum[9 - x];

  /// Black column number: column X → fullwidth digit (left-to-right).
  /// Column 0 = １, column 8 = ９.
  /// Matches Delphi: sGetBlkLine(iX) = dCBLKNUM[iX+1] (when bRL=false).
  /// Note: kBlkNum is in reverse order vs Delphi's dCBLKNUM, so we use
  /// kBlkNum[9-x] instead of kBlkNum[x+1].
  static String _blkCol(int x) => kBlkNum[9 - x];

  /// Get column string for a given side and column X.
  static String _colStr(Side side, int x) =>
      side == Side.red ? _redCol(x) : _blkCol(x);

  /// Get distance string for a given side and absolute distance.
  /// For red: kRedNum[dist] directly (一=1, 二=2, ...).
  /// For black: Delphi uses dCBLKNUM[dist] where dCBLKNUM[1]='１'.
  /// Since kBlkNum is reversed, we use kBlkNum[10-dist].
  static String _distStr(Side side, int dist) =>
      side == Side.red ? kRedNum[dist] : kBlkNum[10 - dist];

  /// Generate Chinese notation for a move.
  /// Returns null if the piece at [fromXY] is not found.
  static String? generateNotation(BoardState board, int fromXY, int toXY) {
    final pieceIndex = board.pieceIndexAt(fromXY);
    if (pieceIndex == 0) return null;

    final side = Piece.sideOf(pieceIndex);
    final type = Piece.typeOf(pieceIndex);
    final xf = fromXY ~/ 10;
    final yf = fromXY % 10;
    final xt = toXY ~/ 10;
    final yt = toXY % 10;
    final dy = yt - yf;
    final db = dy.abs();

    // Build piece name + column.
    final pieceName =
        side == Side.red ? _redPieceNames[type]! : _blkPieceNames[type]!;
    var prefix = pieceName + _colStr(side, xf);

    // Disambiguation for pieces that can share a column.
    prefix = _disambiguate(board, pieceIndex, side, type, xf, yf, pieceName);

    // Direction and distance/target column.
    String dirAndDist;
    if (dy == 0) {
      // Horizontal move (平).
      dirAndDist = '平${_colStr(side, xt)}';
    } else {
      // Determine forward vs backward based on side.
      final isForward = side == Side.red ? dy > 0 : dy < 0;
      final dir = isForward ? '进' : '退';

      if (_isStraightMover(type)) {
        // Straight-moving pieces: distance = |dy|.
        dirAndDist = '$dir${_distStr(side, db)}';
      } else {
        // Diagonal pieces (ma, xiang, shi): target column.
        dirAndDist = '$dir${_colStr(side, xt)}';
      }
    }

    return '$prefix$dirAndDist';
  }

  /// Whether this piece type uses distance (vs target column) for 进/退.
  static bool _isStraightMover(PieceType type) =>
      type == PieceType.che ||
      type == PieceType.pao ||
      type == PieceType.bing ||
      type == PieceType.shuai;

  /// Build the piece prefix with disambiguation if needed.
  static String _disambiguate(BoardState board, int pieceIndex, Side side,
      PieceType type, int xf, int yf, String pieceName) {
    if (type == PieceType.bing) {
      return _disambiguateBing(board, side, xf, yf, pieceName);
    }

    // For non-pawn pieces, find the other piece of the same sub-type.
    // The Delphi code pairs pieces: (1,9), (2,8), (10,11) for red;
    // (17,25), (18,24), (26,27) for black.
    final otherIndex = _pairIndex(pieceIndex);
    if (otherIndex == 0) {
      // No pair (shuai has no pair) — no disambiguation needed.
      return '$pieceName${_colStr(side, xf)}';
    }

    final otherXY = board.pieceXY(otherIndex);
    if (otherXY == kCapturedXY) {
      // Other piece captured, no disambiguation.
      return '$pieceName${_colStr(side, xf)}';
    }

    final otherX = otherXY ~/ 10;
    final otherY = otherXY % 10;

    if (otherX != xf) {
      // Not in same column, no disambiguation.
      return '$pieceName${_colStr(side, xf)}';
    }

    // Same column — use 前/后.
    // Red: front = higher Y (closer to black side).
    // Black: front = lower Y (closer to red side).
    final isFront = side == Side.red ? yf > otherY : yf < otherY;
    final posPrefix = isFront ? '前' : '后';
    return '$posPrefix$pieceName';
  }

  /// Get the paired piece index for disambiguation.
  /// Returns 0 if no pair exists (e.g., king).
  static int _pairIndex(int index) {
    // Red pairs: 1↔9, 2↔8, 3↔7, 4↔6, 10↔11
    // Black pairs: 17↔25, 18↔24, 19↔23, 20↔22, 26↔27
    const pairs = {
      1: 9, 9: 1, // che
      2: 8, 8: 2, // ma
      3: 7, 7: 3, // xiang
      4: 6, 6: 4, // shi
      10: 11, 11: 10, // pao
      17: 25, 25: 17, // che
      18: 24, 24: 18, // ma
      19: 23, 23: 19, // xiang
      20: 22, 22: 20, // shi
      26: 27, 27: 26, // pao
    };
    return pairs[index] ?? 0;
  }

  /// Disambiguate pawns (兵/卒) in the same column.
  static String _disambiguateBing(
      BoardState board, Side side, int xf, int yf, String pieceName) {
    // Count same-side pawns in the same column.
    // Red pawns: indices 12-16. Black pawns: indices 28-32.
    final firstPawn = side == Side.red ? 12 : 28;
    final lastPawn = side == Side.red ? 16 : 32;

    // Collect Y positions of alive pawns in column xf, sorted by
    // "front" order (Red: high Y first, Black: low Y first).
    final pawnsInCol = <({int index, int y})>[];
    for (var i = firstPawn; i <= lastPawn; i++) {
      final xy = board.pieceXY(i);
      if (xy == kCapturedXY) continue;
      final px = xy ~/ 10;
      if (px != xf) continue;
      pawnsInCol.add((index: i, y: xy % 10));
    }

    if (pawnsInCol.length <= 1) {
      return '$pieceName${_colStr(side, xf)}';
    }

    // Sort: Red front = higher Y first; Black front = lower Y first.
    if (side == Side.red) {
      pawnsInCol.sort((a, b) => b.y.compareTo(a.y));
    } else {
      pawnsInCol.sort((a, b) => a.y.compareTo(b.y));
    }

    // Find position of current pawn (1-based from front).
    var pos = 0;
    for (var i = 0; i < pawnsInCol.length; i++) {
      if (pawnsInCol[i].y == yf) {
        pos = i + 1;
        break;
      }
    }

    final total = pawnsInCol.length;
    return _pawnPositionPrefix(pos, total, pieceName);
  }

  /// Generate position prefix for multi-pawn disambiguation.
  static String _pawnPositionPrefix(int pos, int total, String pieceName) {
    if (total == 2) {
      return pos == 1 ? '前$pieceName' : '后$pieceName';
    }
    if (total == 3) {
      switch (pos) {
        case 1:
          return '前$pieceName';
        case 2:
          return '中$pieceName';
        case 3:
          return '后$pieceName';
      }
    }
    // 4 or 5 pawns.
    if (pos == 1) return '前$pieceName';
    if (pos == total) return '后$pieceName';
    // Middle positions use ordinal numbers.
    final ordinals = ['', '', '二', '三', '四'];
    return '${ordinals[pos]}$pieceName';
  }

  /// Parse Chinese notation back to from/to XY positions.
  /// Returns null if notation cannot be parsed.
  static ({int fromXY, int toXY})? parseNotation(
      BoardState board, Side side, String notation) {
    if (notation.length < 4) return null;

    // Parse the notation into components.
    String? posPrefix; // 前/后/中/二/三/四
    String pieceName;
    String colOrPrefix;
    String direction;
    String target;

    // Check for position prefix (前/后/中/二/三/四).
    final firstChar = notation[0];
    int offset = 0;
    if (_positionPrefixes.contains(firstChar)) {
      posPrefix = firstChar;
      offset = 1;
    }

    // Piece name.
    pieceName = notation[offset];
    if (!_allPieceChars.contains(pieceName)) return null;
    offset += 1;

    // Column or nothing (for disambiguated pieces, column is omitted in prefix form).
    if (posPrefix != null) {
      // No column after piece name for 前车/后车 etc.
      // Next is direction + target.
      direction = notation[offset];
      target = notation.substring(offset + 1);
      colOrPrefix = '';
    } else {
      // Normal form: piece + column + direction + target.
      colOrPrefix = notation[offset];
      offset += 1;
      direction = notation[offset];
      target = notation.substring(offset + 1);
    }

    if (target.isEmpty) return null;

    // Determine piece type from name.
    final type = _pieceTypeFromName(pieceName);
    if (type == null) return null;

    // Find the piece.
    int? fromXY;
    if (posPrefix != null) {
      fromXY = _findPieceByPosition(board, side, type, posPrefix, pieceName);
    } else {
      final col = _parseCol(side, colOrPrefix);
      if (col == null) return null;
      fromXY = _findPieceByCol(board, side, type, col);
    }

    if (fromXY == null) return null;

    final xf = fromXY ~/ 10;
    final yf = fromXY % 10;

    // Parse direction and compute target.
    int toXY;
    if (direction == '平') {
      final targetCol = _parseCol(side, target);
      if (targetCol == null) return null;
      toXY = targetCol * 10 + yf;
    } else if (direction == '进' || direction == '退') {
      final isForward = direction == '进';
      if (_isStraightMover(type)) {
        // Distance.
        final dist = _parseNum(side, target);
        if (dist == null) return null;
        final dySign =
            (side == Side.red ? 1 : -1) * (isForward ? 1 : -1);
        toXY = xf * 10 + yf + dySign * dist;
      } else {
        // Target column for diagonal movers.
        final targetCol = _parseCol(side, target);
        if (targetCol == null) return null;
        final dx = targetCol - xf;
        final da = dx.abs();

        // Compute dy from piece movement rules.
        int db;
        if (type == PieceType.ma) {
          // Ma: L-shape. da+db=3, one is 1 and other is 2.
          db = 3 - da;
        } else {
          // Xiang or Shi: diagonal, da==db.
          db = da;
        }

        final dySign =
            (side == Side.red ? 1 : -1) * (isForward ? 1 : -1);
        toXY = targetCol * 10 + yf + dySign * db;
      }
    } else {
      return null;
    }

    return (fromXY: fromXY, toXY: toXY);
  }

  /// Map piece character to PieceType.
  static PieceType? _pieceTypeFromName(String name) {
    switch (name) {
      case '车':
        return PieceType.che;
      case '马':
        return PieceType.ma;
      case '相':
      case '象':
        return PieceType.xiang;
      case '士':
        return PieceType.shi;
      case '帅':
      case '将':
        return PieceType.shuai;
      case '炮':
        return PieceType.pao;
      case '兵':
      case '卒':
        return PieceType.bing;
      default:
        return null;
    }
  }

  /// Parse a column string to column index (0-8).
  static int? _parseCol(Side side, String s) {
    if (side == Side.red) {
      final idx = kRedNum.indexOf(s);
      if (idx < 1) return null;
      return 9 - idx; // _redCol(x) = kRedNum[9-x] → x = 9-idx
    } else {
      final idx = kBlkNum.indexOf(s);
      if (idx < 1) return null;
      return 9 - idx; // _blkCol(x) = kBlkNum[9-x] → x = 9-idx
    }
  }

  /// Parse a number/distance string to integer value (1-9).
  static int? _parseNum(Side side, String s) {
    if (side == Side.red) {
      final idx = kRedNum.indexOf(s);
      return idx >= 1 ? idx : null;
    } else {
      final idx = kBlkNum.indexOf(s);
      if (idx < 1) return null;
      return 10 - idx; // _distStr uses kBlkNum[10-dist] → dist = 10-idx
    }
  }

  /// Find a piece at a specific column.
  static int? _findPieceByCol(
      BoardState board, Side side, PieceType type, int col) {
    final start = side == Side.red ? 1 : 17;
    final end = side == Side.red ? 16 : 32;

    for (var i = start; i <= end; i++) {
      if (Piece.typeOf(i) != type) continue;
      final xy = board.pieceXY(i);
      if (xy == kCapturedXY) continue;
      if (xy ~/ 10 == col) return xy;
    }
    return null;
  }

  /// Find a piece by position prefix (前/后/中/二/三/四).
  static int? _findPieceByPosition(
      BoardState board, Side side, PieceType type, String posPrefix,
      String pieceName) {
    final start = side == Side.red ? 1 : 17;
    final end = side == Side.red ? 16 : 32;

    // Collect all alive pieces of this type, grouped by column.
    final piecesInCols = <int, List<({int index, int y})>>{};
    for (var i = start; i <= end; i++) {
      if (Piece.typeOf(i) != type) continue;
      final xy = board.pieceXY(i);
      if (xy == kCapturedXY) continue;
      final x = xy ~/ 10;
      final y = xy % 10;
      piecesInCols.putIfAbsent(x, () => []);
      piecesInCols[x]!.add((index: i, y: y));
    }

    // Find columns with multiple pieces.
    for (final entry in piecesInCols.entries) {
      final pieces = entry.value;
      if (pieces.length < 2) continue;

      // Sort: front first.
      if (side == Side.red) {
        pieces.sort((a, b) => b.y.compareTo(a.y));
      } else {
        pieces.sort((a, b) => a.y.compareTo(b.y));
      }

      final total = pieces.length;
      int targetPos;

      if (total == 2) {
        targetPos = posPrefix == '前' ? 1 : 2;
      } else if (total == 3) {
        switch (posPrefix) {
          case '前':
            targetPos = 1;
          case '中':
            targetPos = 2;
          case '后':
            targetPos = 3;
          default:
            continue;
        }
      } else {
        // 4-5 pawns.
        switch (posPrefix) {
          case '前':
            targetPos = 1;
          case '后':
            targetPos = total;
          case '二':
            targetPos = 2;
          case '三':
            targetPos = 3;
          case '四':
            targetPos = 4;
          default:
            continue;
        }
      }

      if (targetPos <= pieces.length) {
        final p = pieces[targetPos - 1];
        return entry.key * 10 + p.y;
      }
    }

    return null;
  }
}
