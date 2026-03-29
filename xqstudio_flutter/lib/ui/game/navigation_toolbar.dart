import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xqstudio/state/game_provider.dart';

/// Toolbar with navigation buttons styled like the original XQStudio.
class GameNavigationToolbar extends ConsumerWidget {
  const GameNavigationToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final ctrl = gameState.controller;
    final notifier = ref.read(gameProvider.notifier);
    final atFirst = ctrl.currentStep == 0;
    final atLast = ctrl.currentNode.lChild == null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavButton(
            icon: Icons.skip_previous,
            label: '首步',
            onPressed: atFirst ? null : notifier.goToFirst,
          ),
          _NavButton(
            icon: Icons.navigate_before,
            label: '前步',
            onPressed: atFirst ? null : notifier.goToPrev,
          ),
          _NavButton(
            icon: Icons.navigate_next,
            label: '后步',
            onPressed: atLast ? null : notifier.goToNext,
          ),
          _NavButton(
            icon: Icons.skip_next,
            label: '末步',
            onPressed: atLast ? null : notifier.goToLast,
          ),
          const SizedBox(width: 16),
          _NavButton(
            icon: Icons.delete_outline,
            label: '删除',
            onPressed: atFirst ? null : () => notifier.deleteCurrentMove(),
          ),
          const Spacer(),
          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8D5B5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '第 ${ctrl.currentStep} / ${ctrl.totalSteps} 步',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5C3317),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _NavButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 28,
            color: onPressed != null
                ? const Color(0xFF5C3317)
                : const Color(0xFFBBAA99),
          ),
        ),
      ),
    );
  }
}
