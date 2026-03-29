import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xqstudio/state/game_provider.dart';

/// Panel showing available variations at the current position.
class VariationPanel extends ConsumerWidget {
  const VariationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final ctrl = gameState.controller;
    final variations = ctrl.nextVariations;

    if (variations.isEmpty) {
      return const Center(child: Text('无变着'));
    }

    return ListView.builder(
      itemCount: variations.length,
      itemBuilder: (context, index) {
        final node = variations[index];
        final isMain = index == 0;
        return ListTile(
          dense: true,
          leading: isMain
              ? const Icon(Icons.arrow_forward, size: 16)
              : const Icon(Icons.subdirectory_arrow_right, size: 16),
          title: Text(node.strRec),
          subtitle: isMain ? const Text('主线') : Text('变着 $index'),
          onTap: () {
            // Navigate to the next move, then switch to the desired variation
            final notifier = ref.read(gameProvider.notifier);
            notifier.goToNext();
            if (index > 0) {
              notifier.switchVariation(index);
            }
          },
        );
      },
    );
  }
}
