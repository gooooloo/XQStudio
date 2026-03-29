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
/// - Wide (>800px): board on left, tabbed panel on right.
/// - Narrow (<=800px): board on top, tabbed panel on bottom.
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
      // Select a piece if there's one at this position
      final pieceIndex = ctrl.currentBoard.pieceIndexAt(xy);
      if (pieceIndex != 0) {
        // Only select own pieces
        final isRed = Piece.sideOf(pieceIndex) == Side.red;
        if ((ctrl.isRedTurn && isRed) || (!ctrl.isRedTurn && !isRed)) {
          setState(() => _selectedXY = xy);
        }
      }
    } else {
      // Try to move
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
        final isWide = constraints.maxWidth > 800;
        final board = BoardWidget(
          boardState: ctrl.currentBoard,
          selectedXY: _selectedXY,
          lastMoveFromXY:
              ctrl.currentNode.xyf != 0 ? ctrl.currentNode.xyf : null,
          lastMoveToXY:
              ctrl.currentNode.xyt != 0 ? ctrl.currentNode.xyt : null,
          onTap: _onBoardTap,
        );
        final panels = _buildPanels();

        if (isWide) {
          return Row(
            children: [
              Expanded(child: Center(child: board)),
              SizedBox(width: 300, child: panels),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(child: Center(child: board)),
              SizedBox(height: 250, child: panels),
            ],
          );
        }
      },
    );
  }

  Widget _buildPanels() {
    return const Column(
      children: [
        GameNavigationToolbar(),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
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
    );
  }
}
