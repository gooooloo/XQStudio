import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/ui/board/board_gesture_handler.dart';
import 'package:xqstudio/ui/board/board_painter.dart';

/// A widget that displays the xiangqi board and handles tap interactions.
class BoardWidget extends StatelessWidget {
  final BoardState boardState;
  final int? selectedXY;
  final int? lastMoveFromXY;
  final int? lastMoveToXY;
  final bool reversed;
  final void Function(int xy)? onTap;
  final Map<String, ui.Image> pieceImages;

  const BoardWidget({
    super.key,
    required this.boardState,
    this.selectedXY,
    this.lastMoveFromXY,
    this.lastMoveToXY,
    this.reversed = false,
    this.onTap,
    this.pieceImages = const {},
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 8 / 9, // 8 cell widths / 9 cell heights
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapUp: (details) {
              if (onTap == null) return;
              final pos = BoardGestureHandler.hitTest(
                details.localPosition,
                Size(constraints.maxWidth, constraints.maxHeight),
                reversed: reversed,
              );
              if (pos != null) {
                onTap!(pos.toXY());
              }
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: BoardPainter(
                boardState: boardState,
                selectedXY: selectedXY,
                lastMoveFromXY: lastMoveFromXY,
                lastMoveToXY: lastMoveToXY,
                reversed: reversed,
                pieceImages: pieceImages,
              ),
            ),
          );
        },
      ),
    );
  }
}
