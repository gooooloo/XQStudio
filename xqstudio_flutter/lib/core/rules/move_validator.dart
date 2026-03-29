import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/models/piece.dart';
import 'package:xqstudio/core/models/position.dart';
import 'package:xqstudio/core/rules/king_safety.dart';

/// Validates whether a move is legal according to xiangqi rules.
///
/// Ported from Delphi `sGetPlayRecStr` in XQDataT.pas (lines 115-555).
class MoveValidator {
  MoveValidator._();

  /// Valid destination XY values for red Xiang (elephant).
  static const _redXiangPositions = {02, 20, 24, 42, 60, 64, 82};

  /// Valid destination XY values for black Xiang (elephant).
  static const _blkXiangPositions = {07, 25, 29, 47, 65, 69, 87};

  /// Valid destination XY values for red Shi (advisor).
  static const _redShiPositions = {30, 32, 41, 50, 52};

  /// Valid destination XY values for black Shi (advisor).
  static const _blkShiPositions = {37, 39, 48, 57, 59};

  /// Valid destination XY values for red Shuai (king).
  static const _redShuaiPositions = {30, 31, 32, 40, 41, 42, 50, 51, 52};

  /// Valid destination XY values for black Jiang (king).
  static const _blkJiangPositions = {37, 38, 39, 47, 48, 49, 57, 58, 59};

  /// Check if moving from [fromXY] to [toXY] is a legal move on [board].
  static bool isValidMove(BoardState board, int fromXY, int toXY) {
    if (fromXY == toXY) return false;

    final pieceIndex = board.pieceIndexAt(fromXY);
    if (pieceIndex == 0) return false;

    // Can't capture own piece.
    final targetIndex = board.pieceIndexAt(toXY);
    if (targetIndex != 0 &&
        Piece.sideOf(targetIndex) == Piece.sideOf(pieceIndex)) {
      return false;
    }

    final type = Piece.typeOf(pieceIndex);
    final side = Piece.sideOf(pieceIndex);
    final from = Position.fromXY(fromXY);
    final to = Position.fromXY(toXY);
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final da = dx.abs();
    final db = dy.abs();
    final isCapture = targetIndex != 0;

    bool valid;
    switch (type) {
      case PieceType.che:
        valid = _validateChe(board, from, to, dx, dy, da, db);
      case PieceType.ma:
        valid = _validateMa(board, from, to, dx, dy, da, db);
      case PieceType.xiang:
        valid = _validateXiang(board, from, to, dx, dy, da, db, side);
      case PieceType.shi:
        valid = _validateShi(from, to, da, db, side);
      case PieceType.shuai:
        valid = _validateShuai(from, to, dx, dy, da, db, side);
      case PieceType.pao:
        valid = _validatePao(board, from, to, dx, dy, da, db, isCapture);
      case PieceType.bing:
        valid = _validateBing(from, to, da, db, dy, side);
    }

    if (!valid) return false;

    // After move, check king-facing rule.
    final newBoard = board.movePiece(fromXY, toXY);
    return !KingSafety.kingsAreFacing(newBoard);
  }

  /// Che (Rook/车): moves in straight lines, cannot jump over pieces.
  static bool _validateChe(
      BoardState board, Position from, Position to,
      int dx, int dy, int da, int db) {
    // Must move along exactly one axis.
    if (dx != 0 && dy != 0) return false;

    // Count pieces in path (excluding endpoints).
    final count = _countPiecesInPath(board, from, da, db, dx, dy);
    return count == 0;
  }

  /// Ma (Knight/马): L-shape with hobbled-leg check.
  static bool _validateMa(
      BoardState board, Position from, Position to,
      int dx, int dy, int da, int db) {
    // Must be an L-shape: one axis 1, other axis 2.
    if (!((da == 1 && db == 2) || (da == 2 && db == 1))) return false;

    // Hobbled leg (蹩马腿): check the adjacent square in the longer direction.
    int legX = 0, legY = 0;
    if (da > db) {
      legX = dx ~/ 2; // dx is +-2, so dx~/2 is +-1
    } else {
      legY = dy ~/ 2;
    }

    final legXY = (from.x + legX) * 10 + (from.y + legY);
    if (board.pieceIndexAt(legXY) != 0) return false;

    return true;
  }

  /// Xiang (Elephant/象): diagonal 2 squares, blocked by eye, can't cross river.
  static bool _validateXiang(
      BoardState board, Position from, Position to,
      int dx, int dy, int da, int db, Side side) {
    // Must move exactly 2 diagonally.
    if (da != 2 || db != 2) return false;

    // Must land on valid Xiang positions (implicitly enforces river constraint).
    final toXY = to.toXY();
    if (side == Side.red && !_redXiangPositions.contains(toXY)) return false;
    if (side == Side.black && !_blkXiangPositions.contains(toXY)) return false;

    // Eye block (塞象眼): check the center of the diagonal.
    final eyeXY = (from.x + dx ~/ 2) * 10 + (from.y + dy ~/ 2);
    if (board.pieceIndexAt(eyeXY) != 0) return false;

    return true;
  }

  /// Shi (Advisor/士): diagonal 1 within palace.
  static bool _validateShi(
      Position from, Position to, int da, int db, Side side) {
    if (da != 1 || db != 1) return false;

    final toXY = to.toXY();
    if (side == Side.red && !_redShiPositions.contains(toXY)) return false;
    if (side == Side.black && !_blkShiPositions.contains(toXY)) return false;

    return true;
  }

  /// Shuai/Jiang (King/将帅): orthogonal 1 within palace.
  static bool _validateShuai(
      Position from, Position to,
      int dx, int dy, int da, int db, Side side) {
    // Must move exactly 1 step orthogonally: one axis 0, other axis 1.
    if (!((da == 0 && db == 1) || (da == 1 && db == 0))) return false;

    final toXY = to.toXY();
    if (side == Side.red && !_redShuaiPositions.contains(toXY)) return false;
    if (side == Side.black && !_blkJiangPositions.contains(toXY)) return false;

    return true;
  }

  /// Pao (Cannon/炮): moves like Rook when not capturing;
  /// must jump exactly 1 piece (screen) to capture.
  static bool _validatePao(
      BoardState board, Position from, Position to,
      int dx, int dy, int da, int db, bool isCapture) {
    // Must move along exactly one axis.
    if (dx != 0 && dy != 0) return false;

    final count = _countPiecesInPath(board, from, da, db, dx, dy);

    if (isCapture) {
      // To capture, must jump exactly 1 screen.
      return count == 1;
    } else {
      // Non-capture move: path must be clear.
      return count == 0;
    }
  }

  /// Bing/Zu (Pawn/兵卒): forward only before river; forward or sideways after.
  static bool _validateBing(
      Position from, Position to, int da, int db, int dy, Side side) {
    // Must move exactly 1 step, orthogonally only.
    if (!((da == 0 && db == 1) || (da == 1 && db == 0))) return false;

    if (side == Side.red) {
      // Red moves forward (dy > 0). Before river (y <= 4): forward only.
      // After river (y >= 5): forward or sideways but not backward.
      if (da == 0 && dy != 1) return false; // vertical must be forward
      if (da == 1 && from.y <= 4) return false; // sideways only after river
    } else {
      // Black moves forward (dy < 0). Before river (y >= 5): forward only.
      // After river (y <= 4): forward or sideways but not backward.
      if (da == 0 && dy != -1) return false; // vertical must be forward
      if (da == 1 && from.y >= 5) return false; // sideways only after river
    }

    return true;
  }

  /// Count pieces between [from] and destination (exclusive of both endpoints).
  /// Works for straight-line moves (horizontal or vertical).
  static int _countPiecesInPath(
      BoardState board, Position from, int da, int db, int dx, int dy) {
    int count = 0;

    if (da > 0) {
      // Horizontal movement.
      final step = dx > 0 ? 1 : -1;
      for (var i = 1; i < da; i++) {
        final xy = (from.x + i * step) * 10 + from.y;
        if (board.pieceIndexAt(xy) != 0) count++;
      }
    } else {
      // Vertical movement.
      final step = dy > 0 ? 1 : -1;
      for (var i = 1; i < db; i++) {
        final xy = from.x * 10 + (from.y + i * step);
        if (board.pieceIndexAt(xy) != 0) count++;
      }
    }

    return count;
  }
}
