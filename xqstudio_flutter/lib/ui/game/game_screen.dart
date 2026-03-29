import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xqstudio/core/models/piece.dart';
import 'package:xqstudio/state/game_provider.dart';
import 'package:xqstudio/ui/board/board_widget.dart';
import 'package:xqstudio/ui/game/move_list_panel.dart';
import 'package:xqstudio/ui/game/navigation_toolbar.dart';
import 'package:xqstudio/ui/game/remark_panel.dart';
import 'package:xqstudio/ui/game/variation_panel.dart';

/// Main game screen with responsive layout.
///
/// - Wide (>700px): board on left, panel on right.
/// - Narrow (<=700px): board on top, panel on bottom.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  int? _selectedXY;

  void _onBoardTap(int xy) {
    final gameState = ref.read(gameProvider);
    final ctrl = gameState.controller;

    if (_selectedXY == null) {
      final pieceIndex = ctrl.currentBoard.pieceIndexAt(xy);
      if (pieceIndex != 0) {
        final isRed = Piece.sideOf(pieceIndex) == Side.red;
        if ((ctrl.isRedTurn && isRed) || (!ctrl.isRedTurn && !isRed)) {
          setState(() => _selectedXY = xy);
        }
      }
    } else {
      // Try to re-select own piece
      final pieceIndex = ctrl.currentBoard.pieceIndexAt(xy);
      if (pieceIndex != 0) {
        final isRed = Piece.sideOf(pieceIndex) == Side.red;
        if ((ctrl.isRedTurn && isRed) || (!ctrl.isRedTurn && !isRed)) {
          setState(() => _selectedXY = xy);
          return;
        }
      }
      ref.read(gameProvider.notifier).makeMove(_selectedXY!, xy);
      setState(() => _selectedXY = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final ctrl = gameState.controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final board = BoardWidget(
          boardState: ctrl.currentBoard,
          selectedXY: _selectedXY,
          lastMoveFromXY:
              ctrl.currentNode.xyf != 0 ? ctrl.currentNode.xyf : null,
          lastMoveToXY:
              ctrl.currentNode.xyt != 0 ? ctrl.currentNode.xyt : null,
          onTap: _onBoardTap,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Board takes up the left side
              Expanded(
                flex: 3,
                child: Container(
                  color: const Color(0xFFD2B48C),
                  child: board,
                ),
              ),
              // Right panel
              SizedBox(
                width: 320,
                child: _buildPanels(),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  color: const Color(0xFFD2B48C),
                  child: board,
                ),
              ),
              SizedBox(height: 280, child: _buildPanels()),
            ],
          );
        }
      },
    );
  }

  Widget _buildPanels() {
    return Container(
      color: const Color(0xFFFAF0E6),
      child: const Column(
        children: [
          SizedBox(height: 4),
          GameNavigationToolbar(),
          Divider(height: 1),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Color(0xFF5C3317),
                    indicatorColor: Color(0xFF5C3317),
                    tabs: [
                      Tab(text: '走法'),
                      Tab(text: '变着'),
                      Tab(text: '注释'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        MoveListPanel(),
                        VariationPanel(),
                        RemarkPanel(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
