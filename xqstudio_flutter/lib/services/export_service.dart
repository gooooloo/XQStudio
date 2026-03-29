import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/models/piece.dart';

/// Generates a text-art representation of the board.
///
/// Ported from `dMakeQiTuText` in the original Delphi source.
class ExportService {
  ExportService._();

  /// Generate a text diagram of [board].
  ///
  /// If [reversed] is true, the board is rendered from Black's perspective
  /// (Black pieces at the bottom).
  static String generateBoardDiagram(BoardState board, {bool reversed = false}) {
    final buf = StringBuffer();
    for (var y = 9; y >= 0; y--) {
      for (var x = 0; x <= 8; x++) {
        final bx = reversed ? 8 - x : x;
        final by = reversed ? 9 - y : y;
        final idx = board.pieceIndexAt(bx * 10 + by);
        if (idx == 0) {
          buf.write(y == 4 || y == 5 ? ' - ' : ' + ');
        } else {
          final side = Piece.sideOf(idx);
          final type = Piece.typeOf(idx);
          final name = _pieceName(type, side);
          buf.write(' $name ');
        }
      }
      buf.writeln();
      if (y == 5) {
        buf.writeln('  ＝＝＝＝＝＝＝＝＝');
      }
    }
    return buf.toString();
  }

  static String _pieceName(PieceType type, Side side) {
    const redNames = {
      PieceType.che: '車',
      PieceType.ma: '馬',
      PieceType.xiang: '相',
      PieceType.shi: '仕',
      PieceType.shuai: '帥',
      PieceType.pao: '炮',
      PieceType.bing: '兵',
    };
    const blkNames = {
      PieceType.che: '車',
      PieceType.ma: '馬',
      PieceType.xiang: '象',
      PieceType.shi: '士',
      PieceType.shuai: '將',
      PieceType.pao: '砲',
      PieceType.bing: '卒',
    };
    return side == Side.red ? redNames[type]! : blkNames[type]!;
  }
}
