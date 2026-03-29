// lib/ui/search/search_screen.dart

import 'package:flutter/material.dart';
import 'package:xqstudio/core/models/game_metadata.dart';
import 'package:xqstudio/core/search/game_search.dart';
import 'package:xqstudio/core/search/search_criteria.dart';
import 'package:xqstudio/core/xqf/xqf_reader.dart';

/// Search dialog that filters a list of [GameData] by player name, title,
/// and result. Returns the selected [GameData] when the user taps a result.
class SearchScreen extends StatefulWidget {
  final List<GameData> games;

  const SearchScreen({super.key, required this.games});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _playerCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  GameResult? _selectedResult;
  List<GameData> _results = [];
  bool _searched = false;

  @override
  void dispose() {
    _playerCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _doSearch() {
    final criteria = SearchCriteria(
      playerName: _playerCtrl.text.trim().isEmpty ? null : _playerCtrl.text.trim(),
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      result: _selectedResult,
    );
    setState(() {
      _results = GameSearch.search(widget.games, criteria);
      _searched = true;
    });
  }

  void _reset() {
    _playerCtrl.clear();
    _titleCtrl.clear();
    setState(() {
      _selectedResult = null;
      _results = [];
      _searched = false;
    });
  }

  String _resultLabel(GameResult r) {
    switch (r) {
      case GameResult.redWin:
        return '红胜';
      case GameResult.blackWin:
        return '黑胜';
      case GameResult.draw:
        return '和棋';
      case GameResult.unknown:
        return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('搜索棋局')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _playerCtrl,
                  decoration: const InputDecoration(
                    labelText: '棋手姓名',
                    hintText: '红方或黑方棋手',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: '对局标题',
                    hintText: '标题A或标题B',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<GameResult?>(
                  value: _selectedResult,
                  decoration: const InputDecoration(
                    labelText: '对局结果',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('不限')),
                    ...GameResult.values.map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(_resultLabel(r)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedResult = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _doSearch,
                        icon: const Icon(Icons.search),
                        label: const Text('搜索'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _reset,
                      child: const Text('重置'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_searched)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '找到 ${_results.length} 条记录',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          Expanded(
            child: _searched && _results.isEmpty
                ? const Center(child: Text('没有找到匹配的棋局'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final game = _results[index];
                      final meta = game.metadata;
                      final title = meta.titleA.isNotEmpty
                          ? meta.titleA
                          : meta.titleB.isNotEmpty
                              ? meta.titleB
                              : '（无标题）';
                      return ListTile(
                        title: Text(title),
                        subtitle: Text(
                          '${meta.redPlayer} vs ${meta.blkPlayer}  '
                          '${_resultLabel(meta.result)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).pop(game),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
