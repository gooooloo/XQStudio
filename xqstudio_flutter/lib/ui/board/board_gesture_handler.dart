import 'dart:ui';

import 'package:xqstudio/core/models/position.dart';
import 'package:xqstudio/ui/board/board_painter.dart';

/// Converts tap pixel coordinates to board (x, y) coordinates.
class BoardGestureHandler {
  BoardGestureHandler._();

  /// Hit-test a tap at [tapPosition] within a board of [boardSize].
  ///
  /// Uses the same layout math as [BoardPainter] (with padding cells).
  /// Returns `null` if the tap is outside the board or too far from any point.
  static Position? hitTest(
    Offset tapPosition,
    Size boardSize, {
    bool reversed = false,
  }) {
    const totalCellsW = BoardPainter.totalCellsW;
    const totalCellsH = BoardPainter.totalCellsH;

    final cw = boardSize.width / totalCellsW;
    final ch = boardSize.height / totalCellsH;
    final cs = cw < ch ? cw : ch;

    final gridW = 8 * cs;
    final gridH = 9 * cs;
    final ox = (boardSize.width - gridW) / 2;
    final oy = (boardSize.height - gridH) / 2;

    // Convert tap to grid-relative coordinates
    final gx = (tapPosition.dx - ox) / cs;
    final gy = (tapPosition.dy - oy) / cs;

    // Snap to nearest intersection
    final sx = gx.round();
    final sy = gy.round();

    // Check bounds
    if (sx < 0 || sx > 8 || sy < 0 || sy > 9) return null;

    // Check proximity (within 0.5 cells)
    if ((gx - sx).abs() > 0.5 || (gy - sy).abs() > 0.5) return null;

    // Convert screen coords to board coords
    final x = reversed ? 8 - sx : sx;
    final y = reversed ? sy : 9 - sy;

    return Position(x, y);
  }
}
