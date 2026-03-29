import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/ui/board/board_gesture_handler.dart';
import 'package:xqstudio/ui/board/board_painter.dart';

/// A widget that displays the xiangqi board and handles tap interactions.
///
/// Uses the full available space and centers the board with proper padding.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute the largest board that fits, maintaining aspect ratio.
        // The board's internal aspect ratio accounts for padding cells.
        const totalW = BoardPainter.totalCellsW; // 9.2
        const totalH = BoardPainter.totalCellsH; // 10.2
        const aspectRatio = totalW / totalH;

        double boardW = constraints.maxWidth;
        double boardH = boardW / aspectRatio;
        if (boardH > constraints.maxHeight) {
          boardH = constraints.maxHeight;
          boardW = boardH * aspectRatio;
        }

        return Center(
          child: SizedBox(
            width: boardW,
            height: boardH,
            child: GestureDetector(
              onTapUp: (details) {
                if (onTap == null) return;
                final pos = BoardGestureHandler.hitTest(
                  details.localPosition,
                  Size(boardW, boardH),
                  reversed: reversed,
                );
                if (pos != null) onTap!(pos.toXY());
              },
              child: CustomPaint(
                size: Size(boardW, boardH),
                painter: BoardPainter(
                  boardState: boardState,
                  selectedXY: selectedXY,
                  lastMoveFromXY: lastMoveFromXY,
                  lastMoveToXY: lastMoveToXY,
                  reversed: reversed,
                  pieceImages: pieceImages,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
