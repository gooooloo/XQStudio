import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xqstudio/core/models/play_node.dart';
import 'package:xqstudio/state/game_provider.dart';

/// Scrollable list showing all moves in the main line.
///
/// The current step is highlighted. Tapping a move navigates to that step.
class MoveListPanel extends ConsumerWidget {
  const MoveListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final ctrl = gameState.controller;

    // Walk the main line from root via lChild
    final moves = <PlayNode>[];
    var current = ctrl.root;
    while (current.lChild != null) {
      moves.add(current.lChild!);
      current = current.lChild!;
    }

    if (moves.isEmpty) {
      return const Center(child: Text('暂无走法'));
    }

    return ListView.builder(
      itemCount: moves.length,
      itemBuilder: (context, index) {
        final move = moves[index];
        final isCurrent = move.stepNo == ctrl.currentStep;
        return ListTile(
          dense: true,
          selected: isCurrent,
          title: Text('${move.stepNo}. ${move.strRec}'),
          onTap: () => ref.read(gameProvider.notifier).goToStep(move.stepNo),
        );
      },
    );
  }
}
