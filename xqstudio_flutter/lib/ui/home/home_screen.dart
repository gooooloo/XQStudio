import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xqstudio/core/models/game_metadata.dart';
import 'package:xqstudio/core/xqf/xqf_reader.dart';
import 'package:xqstudio/core/xqf/xqf_writer.dart';
import 'package:xqstudio/services/file_service.dart';
import 'package:xqstudio/state/game_provider.dart';
import 'package:xqstudio/ui/game/game_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final ctrl = gameState.controller;
    final redPlayer = ctrl.metadata?.redPlayer ?? '';
    final blkPlayer = ctrl.metadata?.blkPlayer ?? '';
    final title = (redPlayer.isNotEmpty || blkPlayer.isNotEmpty)
        ? '$redPlayer vs $blkPlayer'
        : 'XQStudio';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C3317),
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 16)),
        actions: [
          _AppBarButton(
            icon: Icons.note_add_outlined,
            label: '新建',
            onPressed: _newGame,
          ),
          _AppBarButton(
            icon: Icons.folder_open_outlined,
            label: '打开',
            onPressed: _openFile,
          ),
          _AppBarButton(
            icon: Icons.save_outlined,
            label: '保存',
            onPressed: _saveFile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              ref.read(gameProvider.notifier).goToPrev(),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              ref.read(gameProvider.notifier).goToNext(),
          const SingleActivator(LogicalKeyboardKey.home): () =>
              ref.read(gameProvider.notifier).goToFirst(),
          const SingleActivator(LogicalKeyboardKey.end): () =>
              ref.read(gameProvider.notifier).goToLast(),
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
              ref.read(gameProvider.notifier).undoMove(),
          const SingleActivator(LogicalKeyboardKey.keyO, control: true):
              _openFile,
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              _saveFile,
          const SingleActivator(LogicalKeyboardKey.keyN, control: true):
              _newGame,
        },
        child: const Focus(
          autofocus: true,
          child: GameScreen(),
        ),
      ),
    );
  }

  void _newGame() {
    ref.read(gameProvider.notifier).newGame();
  }

  Future<void> _openFile() async {
    final bytes = await FileService.openXqfFile();
    if (bytes != null) {
      final gameData = XqfReader.readXqf(bytes);
      ref.read(gameProvider.notifier).loadGameData(gameData);
    }
  }

  Future<void> _saveFile() async {
    final controller = ref.read(gameProvider).controller;
    final gameData = GameData(
      metadata: GameMetadata(),
      playTree: controller.root,
      initialPieceXY: List<int>.from(controller.root.qiziXY),
    );
    final bytes = XqfWriter.writeXqf(gameData);
    await FileService.saveXqfFile(bytes);
  }
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _AppBarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white70, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
    );
  }
}
