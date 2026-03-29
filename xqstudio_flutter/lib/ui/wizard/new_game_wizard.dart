import 'package:flutter/material.dart';
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/game_metadata.dart';
import 'package:xqstudio/core/models/play_node.dart';
import 'package:xqstudio/core/xqf/xqf_reader.dart';

class NewGameWizard extends StatefulWidget {
  const NewGameWizard({super.key});

  static Future<GameData?> show(BuildContext context) {
    return showDialog<GameData>(
      context: context,
      builder: (_) => const NewGameWizard(),
    );
  }

  @override
  State<NewGameWizard> createState() => _NewGameWizardState();
}

class _NewGameWizardState extends State<NewGameWizard> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建棋谱'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('标准开局'),
            leading: const Icon(Icons.grid_on),
            onTap: () => Navigator.pop(context, _standardGame()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  GameData _standardGame() {
    return GameData(
      metadata: GameMetadata(),
      playTree: PlayNode.root(List<int>.from(kInitialPieceXY)),
      initialPieceXY: List<int>.from(kInitialPieceXY).sublist(1),
    );
  }
}
