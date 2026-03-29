import 'package:flutter/material.dart';

const List<String> _kTips = [
  '使用左右方向键或底部导航栏在棋步间前进/后退。',
  '点击变招列表中的棋步可以切换至对应变招分支。',
  '长按棋盘上的棋子可以查看其合法走法。',
  '通过"文件 → 属性"可以编辑棋谱的标题、棋手等信息。',
  '通过"文件 → 导出"可以将棋谱导出为文字图示。',
];

class TipsDialog extends StatelessWidget {
  const TipsDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const TipsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('使用技巧'),
      content: SizedBox(
        width: 360,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _kTips.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}. ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(child: Text(_kTips[i])),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
