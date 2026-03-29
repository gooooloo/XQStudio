import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xqstudio/state/game_provider.dart';

/// Toolbar with first / prev / next / last / delete navigation buttons.
class GameNavigationToolbar extends ConsumerWidget {
  const GameNavigationToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final ctrl = gameState.controller;
    final notifier = ref.read(gameProvider.notifier);
    final atFirst = ctrl.currentStep == 0;
    final atLast = ctrl.currentNode.lChild == null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page),
          tooltip: '起始',
          onPressed: atFirst ? null : notifier.goToFirst,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: '上一步',
          onPressed: atFirst ? null : notifier.goToPrev,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: '下一步',
          onPressed: atLast ? null : notifier.goToNext,
        ),
        IconButton(
          icon: const Icon(Icons.last_page),
          tooltip: '末尾',
          onPressed: atLast ? null : notifier.goToLast,
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: '删除',
          onPressed: atFirst ? null : () => notifier.deleteCurrentMove(),
        ),
      ],
    );
  }
}
