import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/models/piece.dart';
import 'package:xqstudio/core/models/position.dart';

/// CustomPainter that draws the xiangqi board, pieces, and indicators.
///
/// The board is drawn with a margin/padding around the grid so that pieces
/// on the edges are fully visible. The grid itself is 8 cells wide × 9 cells
/// tall; the margin adds ~0.6 cells on each side.
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

  // The grid has 8 column gaps and 9 row gaps.
  // We add padding of ~0.6 cell on each side so edge pieces render fully.
  static const double padCells = 0.6;
  static const double totalCellsW = 8 + padCells * 2; // 9.2
  static const double totalCellsH = 9 + padCells * 2; // 10.2

  double _cellSize(Size size) {
    final cw = size.width / totalCellsW;
    final ch = size.height / totalCellsH;
    return cw < ch ? cw : ch;
  }

  Offset _origin(Size size) {
    final cs = _cellSize(size);
    final gridW = 8 * cs;
    final gridH = 9 * cs;
    return Offset((size.width - gridW) / 2, (size.height - gridH) / 2);
  }

  Offset _toScreen(int x, int y, Size size) {
    int sx = x;
    int sy = 9 - y;
    if (reversed) {
      sx = 8 - sx;
      sy = 9 - sy;
    }
    final o = _origin(size);
    final cs = _cellSize(size);
    return Offset(o.dx + sx * cs, o.dy + sy * cs);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintBoard(canvas, size);
    _paintRiverText(canvas, size);
    _paintIndicators(canvas, size);
    _paintPieces(canvas, size);
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return boardState != oldDelegate.boardState ||
        selectedXY != oldDelegate.selectedXY ||
        lastMoveFromXY != oldDelegate.lastMoveFromXY ||
        lastMoveToXY != oldDelegate.lastMoveToXY ||
        reversed != oldDelegate.reversed ||
        pieceImages != oldDelegate.pieceImages;
  }

  // --- Background ---

  void _paintBackground(Canvas canvas, Size size) {
    // Outer background
    final outerPaint = Paint()..color = const Color(0xFFD2B48C);
    canvas.drawRect(Offset.zero & size, outerPaint);

    // Inner board area with lighter wood color
    final cs = _cellSize(size);
    final o = _origin(size);
    final boardRect = Rect.fromLTWH(
      o.dx - cs * 0.5,
      o.dy - cs * 0.5,
      8 * cs + cs,
      9 * cs + cs,
    );
    final innerPaint = Paint()..color = const Color(0xFFF5DEB3);
    canvas.drawRect(boardRect, innerPaint);

    // Board border
    final borderPaint = Paint()
      ..color = const Color(0xFF5C3317)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(boardRect, borderPaint);
  }

  // --- Board grid ---

  void _paintBoard(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF5C3317)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Outer border of grid
    final tl = _toScreen(0, 9, size);
    final br = _toScreen(8, 0, size);
    canvas.drawRect(Rect.fromPoints(tl, br), linePaint);

    // Horizontal lines (inner 8 lines, top and bottom already drawn by border)
    for (var row = 1; row <= 8; row++) {
      canvas.drawLine(
        _toScreen(0, row, size),
        _toScreen(8, row, size),
        linePaint,
      );
    }

    // Vertical lines (inner 7 columns)
    for (var col = 1; col <= 7; col++) {
      // Break at river (Y=4 to Y=5)
      canvas.drawLine(
        _toScreen(col, 0, size),
        _toScreen(col, 4, size),
        linePaint,
      );
      canvas.drawLine(
        _toScreen(col, 5, size),
        _toScreen(col, 9, size),
        linePaint,
      );
    }

    // Palace diagonals
    final palacePaint = Paint()
      ..color = const Color(0xFF5C3317)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(_toScreen(3, 0, size), _toScreen(5, 2, size), palacePaint);
    canvas.drawLine(_toScreen(5, 0, size), _toScreen(3, 2, size), palacePaint);
    canvas.drawLine(_toScreen(3, 7, size), _toScreen(5, 9, size), palacePaint);
    canvas.drawLine(_toScreen(5, 7, size), _toScreen(3, 9, size), palacePaint);

    // Star markers
    final cs = _cellSize(size);
    final starLen = cs * 0.14;
    final starGap = cs * 0.07;
    final starPaint = Paint()
      ..color = const Color(0xFF5C3317)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final starPositions = [
      const Position(1, 2), const Position(7, 2),
      const Position(1, 7), const Position(7, 7),
      const Position(0, 3), const Position(2, 3), const Position(4, 3),
      const Position(6, 3), const Position(8, 3),
      const Position(0, 6), const Position(2, 6), const Position(4, 6),
      const Position(6, 6), const Position(8, 6),
    ];
    for (final pos in starPositions) {
      _drawStar(canvas, _toScreen(pos.x, pos.y, size), starLen, starGap,
          starPaint, pos.x);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double len, double gap,
      Paint paint, int bx) {
    for (final arm in [
      const Offset(-1, -1),
      const Offset(1, -1),
      const Offset(-1, 1),
      const Offset(1, 1),
    ]) {
      // Skip arms at board edges
      if ((bx == 0 && arm.dx < 0) || (bx == 8 && arm.dx > 0)) continue;

      canvas.drawLine(
        Offset(center.dx + arm.dx * gap, center.dy + arm.dy * gap),
        Offset(center.dx + arm.dx * (gap + len), center.dy + arm.dy * gap),
        paint,
      );
      canvas.drawLine(
        Offset(center.dx + arm.dx * gap, center.dy + arm.dy * gap),
        Offset(center.dx + arm.dx * gap, center.dy + arm.dy * (gap + len)),
        paint,
      );
    }
  }

  // --- River text ---

  void _paintRiverText(Canvas canvas, Size size) {
    final cs = _cellSize(size);
    final fontSize = cs * 0.45;
    final style = TextStyle(
      color: const Color(0xFF5C3317).withValues(alpha: 0.5),
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );

    // "楚 河" on the left side, "漢 界" on the right side
    final y4 = _toScreen(0, 4, size);
    final y5 = _toScreen(0, 5, size);
    final riverCenterY = (y4.dy + y5.dy) / 2;

    final leftText = TextPainter(
      text: TextSpan(text: '楚  河', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final rightText = TextPainter(
      text: TextSpan(text: '漢  界', style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final leftCenter = _toScreen(2, 4, size);
    final rightCenter = _toScreen(6, 4, size);

    leftText.paint(
      canvas,
      Offset(leftCenter.dx - leftText.width / 2,
          riverCenterY - leftText.height / 2),
    );
    rightText.paint(
      canvas,
      Offset(rightCenter.dx - rightText.width / 2,
          riverCenterY - rightText.height / 2),
    );
  }

  // --- Move indicators ---

  void _paintIndicators(Canvas canvas, Size size) {
    final cs = _cellSize(size);
    final radius = cs * 0.44;

    void drawIndicator(int xy, Color color, {double strokeWidth = 2.5}) {
      if (xy == kCapturedXY) return;
      final pos = Position.fromXY(xy);
      final center = _toScreen(pos.x, pos.y, size);
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, paint);
    }

    if (lastMoveFromXY != null) {
      drawIndicator(lastMoveFromXY!, const Color(0x6600AA00));
    }
    if (lastMoveToXY != null) {
      drawIndicator(lastMoveToXY!, const Color(0xBB00AA00), strokeWidth: 3.0);
    }
    if (selectedXY != null) {
      drawIndicator(selectedXY!, const Color(0xDDFF0000), strokeWidth: 3.0);
    }
  }

  // --- Pieces ---

  void _paintPieces(Canvas canvas, Size size) {
    final cs = _cellSize(size);
    final pieceRadius = cs * 0.44;

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
            center: center, width: pieceRadius * 2, height: pieceRadius * 2);
        canvas.drawImageRect(image, srcRect, dstRect, Paint());
      } else {
        _drawFallbackPiece(canvas, center, pieceRadius, side, type, isSelected);
      }
    }
  }

  void _drawFallbackPiece(Canvas canvas, Offset center, double radius,
      Side side, PieceType type, bool isSelected) {
    final isRed = side == Side.red;
    final pieceColor = isRed ? const Color(0xFFCC0000) : const Color(0xFF222222);

    // Shadow
    canvas.drawCircle(
      Offset(center.dx + 1.5, center.dy + 1.5),
      radius,
      Paint()..color = Colors.black26,
    );

    // Piece body — gradient-like appearance
    final bgPaint = Paint()
      ..color = const Color(0xFFFFF5E0)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Inner ring
    final innerRing = Paint()
      ..color = pieceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08;
    canvas.drawCircle(center, radius * 0.82, innerRing);

    // Outer border
    final borderPaint = Paint()
      ..color = pieceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1;
    canvas.drawCircle(center, radius, borderPaint);

    // Selection glow
    if (isSelected) {
      canvas.drawCircle(
        center,
        radius + 3,
        Paint()
          ..color = const Color(0xAAFF4444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }

    // Character
    final names = {
      PieceType.che: isRed ? '車' : '車',
      PieceType.ma: isRed ? '馬' : '馬',
      PieceType.xiang: isRed ? '相' : '象',
      PieceType.shi: isRed ? '仕' : '士',
      PieceType.shuai: isRed ? '帥' : '將',
      PieceType.pao: isRed ? '炮' : '砲',
      PieceType.bing: isRed ? '兵' : '卒',
    };

    final textPainter = TextPainter(
      text: TextSpan(
        text: names[type],
        style: TextStyle(
          color: pieceColor,
          fontSize: radius * 1.0,
          fontWeight: FontWeight.w900,
          fontFamily: 'serif',
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2),
    );
  }
}
