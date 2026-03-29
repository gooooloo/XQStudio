import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/models/piece.dart';
import 'package:xqstudio/core/models/position.dart';

/// CustomPainter that draws the xiangqi board, pieces, and indicators.
class BoardPainter extends CustomPainter {
  final BoardState boardState;
  final int? selectedXY;
  final int? lastMoveFromXY;
  final int? lastMoveToXY;
  final bool reversed;
  final Map<String, ui.Image> pieceImages;

  BoardPainter({
    required this.boardState,
    this.selectedXY,
    this.lastMoveFromXY,
    this.lastMoveToXY,
    this.reversed = false,
    this.pieceImages = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintBoard(canvas, size);
    _paintIndicators(canvas, size);
    _paintPieces(canvas, size);
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return boardState != oldDelegate.boardState ||
        selectedXY != oldDelegate.selectedXY ||
        lastMoveFromXY != oldDelegate.lastMoveFromXY ||
        lastMoveToXY != oldDelegate.lastMoveToXY ||
        reversed != oldDelegate.reversed;
  }

  // --- Coordinate helpers ---

  double _cellWidth(Size size) => size.width / 8;
  double _cellHeight(Size size) => size.height / 9;

  /// Convert board (x, y) to screen pixel offset.
  Offset _toScreen(int x, int y, Size size) {
    int sx = x;
    int sy = 9 - y; // screen Y=0 is top = board Y=9
    if (reversed) {
      sx = 8 - sx;
      sy = 9 - sy;
    }
    return Offset(sx * _cellWidth(size), sy * _cellHeight(size));
  }

  // --- Background ---

  void _paintBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF0D9B5); // light wood
    canvas.drawRect(Offset.zero & size, paint);
  }

  // --- Board grid ---

  void _paintBoard(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final cw = _cellWidth(size);
    // _cellHeight not needed here; vertical spacing is derived from _toScreen.

    // Horizontal lines (10 rows).
    for (var row = 0; row <= 9; row++) {
      final p = _toScreen(0, row, size);
      final q = _toScreen(8, row, size);
      canvas.drawLine(p, q, linePaint);
    }

    // Vertical lines.
    for (var col = 0; col <= 8; col++) {
      if (col == 0 || col == 8) {
        // Edge columns: full line.
        canvas.drawLine(
            _toScreen(col, 0, size), _toScreen(col, 9, size), linePaint);
      } else {
        // Inner columns: break at river (Y=4 to Y=5).
        canvas.drawLine(
            _toScreen(col, 0, size), _toScreen(col, 4, size), linePaint);
        canvas.drawLine(
            _toScreen(col, 5, size), _toScreen(col, 9, size), linePaint);
      }
    }

    // Palace diagonals.
    // Red palace: (3,0)-(5,2)
    canvas.drawLine(_toScreen(3, 0, size), _toScreen(5, 2, size), linePaint);
    canvas.drawLine(_toScreen(5, 0, size), _toScreen(3, 2, size), linePaint);
    // Black palace: (3,7)-(5,9)
    canvas.drawLine(_toScreen(3, 7, size), _toScreen(5, 9, size), linePaint);
    canvas.drawLine(_toScreen(5, 7, size), _toScreen(3, 9, size), linePaint);

    // Star markers (small crosses) at cannon and pawn positions.
    final starPositions = [
      // Cannons
      const Position(1, 2), const Position(7, 2),
      const Position(1, 7), const Position(7, 7),
      // Red pawns
      const Position(0, 3), const Position(2, 3), const Position(4, 3),
      const Position(6, 3), const Position(8, 3),
      // Black pawns
      const Position(0, 6), const Position(2, 6), const Position(4, 6),
      const Position(6, 6), const Position(8, 6),
    ];

    final starLen = cw * 0.12;
    final starGap = cw * 0.06;
    for (final pos in starPositions) {
      final c = _toScreen(pos.x, pos.y, size);
      _drawStar(canvas, c, starLen, starGap, linePaint, pos.x, pos.y);
    }
  }

  /// Draw a small cross marker at [center]. Omits arms that would go off-board.
  void _drawStar(Canvas canvas, Offset center, double len, double gap,
      Paint paint, int bx, int by) {
    // Four quadrants: top-left, top-right, bottom-left, bottom-right.
    // Each quadrant draws two short lines (horizontal + vertical).
    final arms = <Offset>[
      const Offset(-1, -1), // top-left (screen)
      const Offset(1, -1), // top-right
      const Offset(-1, 1), // bottom-left
      const Offset(1, 1), // bottom-right
    ];

    for (final arm in arms) {
      // Skip arms on board edges.
      final nx = bx + arm.dx.toInt();
      final ny = by - arm.dy.toInt(); // screen Y is inverted
      if (nx < 0 || nx > 8 || ny < 0 || ny > 9) continue;

      // Horizontal segment.
      canvas.drawLine(
        Offset(center.dx + arm.dx * gap, center.dy + arm.dy * gap),
        Offset(
            center.dx + arm.dx * (gap + len), center.dy + arm.dy * gap),
        paint,
      );
      // Vertical segment.
      canvas.drawLine(
        Offset(center.dx + arm.dx * gap, center.dy + arm.dy * gap),
        Offset(
            center.dx + arm.dx * gap, center.dy + arm.dy * (gap + len)),
        paint,
      );
    }
  }

  // --- Move indicators ---

  void _paintIndicators(Canvas canvas, Size size) {
    final cw = _cellWidth(size);
    final radius = cw * 0.42;

    void drawIndicator(int xy, Color color) {
      if (xy == kCapturedXY) return;
      final pos = Position.fromXY(xy);
      final center = _toScreen(pos.x, pos.y, size);
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, paint);
    }

    if (lastMoveFromXY != null) {
      drawIndicator(lastMoveFromXY!, const Color(0x8800AA00));
    }
    if (lastMoveToXY != null) {
      drawIndicator(lastMoveToXY!, const Color(0xCC00AA00));
    }
    if (selectedXY != null) {
      drawIndicator(selectedXY!, const Color(0xCCFF0000));
    }
  }

  // --- Pieces ---

  void _paintPieces(Canvas canvas, Size size) {
    final cw = _cellWidth(size);
    final pieceRadius = cw * 0.42;

    for (var i = 1; i <= 32; i++) {
      final xy = boardState.pieceXY(i);
      if (xy == kCapturedXY) continue;

      final pos = Position.fromXY(xy);
      final center = _toScreen(pos.x, pos.y, size);
      final side = Piece.sideOf(i);
      final type = Piece.typeOf(i);
      final imageIndex = type.index + 1;
      final sidePrefix = side == Side.red ? 'red' : 'blk';
      final isSelected = selectedXY != null && selectedXY == xy;
      final suffix = isSelected ? '_sel' : '';
      final key = '${sidePrefix}_$imageIndex$suffix';

      final image = pieceImages[key];
      if (image != null) {
        final srcRect = Rect.fromLTWH(
            0, 0, image.width.toDouble(), image.height.toDouble());
        final dstRect = Rect.fromCenter(
            center: center,
            width: pieceRadius * 2,
            height: pieceRadius * 2);
        canvas.drawImageRect(image, srcRect, dstRect, Paint());
      } else {
        // Fallback: draw a simple circle with text.
        _drawFallbackPiece(canvas, center, pieceRadius, side, type);
      }
    }
  }

  void _drawFallbackPiece(Canvas canvas, Offset center, double radius,
      Side side, PieceType type) {
    final bgPaint = Paint()
      ..color = const Color(0xFFFFF8DC)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = side == Side.red ? Colors.red : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius, borderPaint);

    final names = {
      PieceType.che: side == Side.red ? '车' : '車',
      PieceType.ma: side == Side.red ? '马' : '馬',
      PieceType.xiang: side == Side.red ? '相' : '象',
      PieceType.shi: side == Side.red ? '仕' : '士',
      PieceType.shuai: side == Side.red ? '帅' : '將',
      PieceType.pao: side == Side.red ? '炮' : '砲',
      PieceType.bing: side == Side.red ? '兵' : '卒',
    };

    final textPainter = TextPainter(
      text: TextSpan(
        text: names[type],
        style: TextStyle(
          color: side == Side.red ? Colors.red : Colors.black,
          fontSize: radius * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
          center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }
}
