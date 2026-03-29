import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/models/position.dart';

/// Checks whether the two kings are illegally facing each other
/// on the same column with no intervening pieces.
class KingSafety {
  KingSafety._();

  /// Returns true if the red Shuai (index 5) and black Jiang (index 21)
  /// are on the same column with no pieces between them.
  static bool kingsAreFacing(BoardState board) {
    final redXY = board.pieceXY(5);
    final blkXY = board.pieceXY(21);
    if (redXY == kCapturedXY || blkXY == kCapturedXY) return false;

    final redPos = Position.fromXY(redXY);
    final blkPos = Position.fromXY(blkXY);
    if (redPos.x != blkPos.x) return false;

    final minY = (redPos.y < blkPos.y ? redPos.y : blkPos.y) + 1;
    final maxY = redPos.y > blkPos.y ? redPos.y : blkPos.y;

    for (var y = minY; y < maxY; y++) {
      if (board.pieceIndexAt(redPos.x * 10 + y) != 0) return false;
    }
    return true;
  }
}
