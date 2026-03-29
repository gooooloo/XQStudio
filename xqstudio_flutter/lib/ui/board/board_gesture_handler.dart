import 'dart:ui';

import 'package:xqstudio/core/models/position.dart';

/// Converts tap pixel coordinates to board (x, y) coordinates.
class BoardGestureHandler {
  BoardGestureHandler._();

  /// Convert a tap position to board coordinates.
  ///
  /// The board grid spans the full [boardSize] with 8 cell widths (9 columns)
  /// and 9 cell heights (10 rows). Returns `null` if the tap is too far from
  /// any grid intersection (> 0.5 cells away).
  ///
  /// When [reversed] is true the board is viewed from Black's perspective,
  /// so coordinates are flipped.
  static Position? hitTest(
    Offset tapPosition,
    Size boardSize, {
    bool reversed = false,
  }) {
    final cellWidth = boardSize.width / 8;
    final cellHeight = boardSize.height / 9;

    // Map pixel to fractional grid coordinates.
    final fx = tapPosition.dx / cellWidth;
    final fy = tapPosition.dy / cellHeight;

    // Round to nearest intersection.
    final gx = fx.round();
    final gy = fy.round();

    // Reject if too far from intersection (> 0.5 cell).
    if ((fx - gx).abs() > 0.5 || (fy - gy).abs() > 0.5) return null;

    // Reject out-of-range.
    if (gx < 0 || gx > 8 || gy < 0 || gy > 9) return null;

    // Screen Y=0 is the top of the widget.
    // In normal (Red-at-bottom) orientation, screen top = board Y=9.
    int x = gx;
    int y = 9 - gy;

    if (reversed) {
      x = 8 - x;
      y = 9 - y;
    }

    return Position(x, y);
  }
}
