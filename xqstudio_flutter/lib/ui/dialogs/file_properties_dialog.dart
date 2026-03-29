import 'package:flutter/material.dart';
import 'package:xqstudio/core/models/game_metadata.dart';

class FilePropertiesDialog extends StatefulWidget {
  final GameMetadata metadata;

  const FilePropertiesDialog({super.key, required this.metadata});

  static Future<GameMetadata?> show(
    BuildContext context,
    GameMetadata metadata,
  ) {
    return showDialog<GameMetadata>(
      context: context,
      builder: (_) => FilePropertiesDialog(metadata: metadata),
    );
  }

  @override
  State<FilePropertiesDialog> createState() => _FilePropertiesDialogState();
}

class _FilePropertiesDialogState extends State<FilePropertiesDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleACtrl;
  late final TextEditingController _titleBCtrl;
  late final TextEditingController _matchNameCtrl;
  late final TextEditingController _matchTimeCtrl;
  late final TextEditingController _matchAddrCtrl;
  late final TextEditingController _redPlayerCtrl;
  late final TextEditingController _blkPlayerCtrl;
  late final TextEditingController _timeRuleCtrl;
  late final TextEditingController _redTimeCtrl;
  late final TextEditingController _blkTimeCtrl;
  late final TextEditingController _rmkWriterCtrl;
  late final TextEditingController _authorCtrl;
  late GameResult _result;

  @override
  void initState() {
    super.initState();
    final m = widget.metadata;
    _titleACtrl = TextEditingController(text: m.titleA);
    _titleBCtrl = TextEditingController(text: m.titleB);
    _matchNameCtrl = TextEditingController(text: m.matchName);
    _matchTimeCtrl = TextEditingController(text: m.matchTime);
    _matchAddrCtrl = TextEditingController(text: m.matchAddr);
    _redPlayerCtrl = TextEditingController(text: m.redPlayer);
    _blkPlayerCtrl = TextEditingController(text: m.blkPlayer);
    _timeRuleCtrl = TextEditingController(text: m.timeRule);
    _redTimeCtrl = TextEditingController(text: m.redTime);
    _blkTimeCtrl = TextEditingController(text: m.blkTime);
    _rmkWriterCtrl = TextEditingController(text: m.rmkWriter);
    _authorCtrl = TextEditingController(text: m.author);
    _result = m.result;
  }

  @override
  void dispose() {
    _titleACtrl.dispose();
    _titleBCtrl.dispose();
    _matchNameCtrl.dispose();
    _matchTimeCtrl.dispose();
    _matchAddrCtrl.dispose();
    _redPlayerCtrl.dispose();
    _blkPlayerCtrl.dispose();
    _timeRuleCtrl.dispose();
    _redTimeCtrl.dispose();
    _blkTimeCtrl.dispose();
    _rmkWriterCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(
        context,
        GameMetadata(
          titleA: _titleACtrl.text,
          titleB: _titleBCtrl.text,
          matchName: _matchNameCtrl.text,
          matchTime: _matchTimeCtrl.text,
          matchAddr: _matchAddrCtrl.text,
          redPlayer: _redPlayerCtrl.text,
          blkPlayer: _blkPlayerCtrl.text,
          timeRule: _timeRuleCtrl.text,
          redTime: _redTimeCtrl.text,
          blkTime: _blkTimeCtrl.text,
          rmkWriter: _rmkWriterCtrl.text,
          author: _authorCtrl.text,
          result: _result,
          whoPlay: widget.metadata.whoPlay,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('棋谱属性'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('标题 A', _titleACtrl),
                _field('标题 B', _titleBCtrl),
                _field('比赛名称', _matchNameCtrl),
                _field('比赛时间', _matchTimeCtrl),
                _field('比赛地点', _matchAddrCtrl),
                _field('红方棋手', _redPlayerCtrl),
                _field('黑方棋手', _blkPlayerCtrl),
                _field('用时规则', _timeRuleCtrl),
                _field('红方用时', _redTimeCtrl),
                _field('黑方用时', _blkTimeCtrl),
                _field('注释者', _rmkWriterCtrl),
                _field('作者', _authorCtrl),
                const SizedBox(height: 8),
                DropdownButtonFormField<GameResult>(
                  initialValue: _result,
                  decoration: const InputDecoration(labelText: '结果'),
                  items: const [
                    DropdownMenuItem(
                      value: GameResult.unknown,
                      child: Text('未知'),
                    ),
                    DropdownMenuItem(
                      value: GameResult.redWin,
                      child: Text('红胜'),
                    ),
                    DropdownMenuItem(
                      value: GameResult.blackWin,
                      child: Text('黑胜'),
                    ),
                    DropdownMenuItem(
                      value: GameResult.draw,
                      child: Text('和棋'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _result = v);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
