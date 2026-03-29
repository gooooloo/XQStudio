import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xqstudio/state/game_provider.dart';

/// Panel for viewing and editing remarks on the current move.
class RemarkPanel extends ConsumerStatefulWidget {
  const RemarkPanel({super.key});

  @override
  ConsumerState<RemarkPanel> createState() => _RemarkPanelState();
}

class _RemarkPanelState extends ConsumerState<RemarkPanel> {
  final _controller = TextEditingController();
  int _lastVersion = -1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final ctrl = gameState.controller;

    // Sync text field when game state changes (navigation, etc.)
    if (gameState.version != _lastVersion) {
      final remark = ctrl.getRemark();
      if (_controller.text != remark) {
        _controller.text = remark;
      }
      _lastVersion = gameState.version;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          hintText: '输入注释...',
          border: OutlineInputBorder(),
        ),
        onChanged: (text) {
          ref.read(gameProvider.notifier).setRemark(text);
        },
      ),
    );
  }
}
