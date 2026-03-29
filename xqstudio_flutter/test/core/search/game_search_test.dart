// test/core/search/game_search_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/game_metadata.dart';
import 'package:xqstudio/core/models/play_node.dart';
import 'package:xqstudio/core/search/game_search.dart';
import 'package:xqstudio/core/search/search_criteria.dart';
import 'package:xqstudio/core/xqf/xqf_reader.dart';

void main() {
  group('GameSearch', () {
    late List<GameData> games;

    setUp(() {
      games = [
        _makeGame(
            redPlayer: '张三',
            blkPlayer: '李四',
            titleA: '五羊杯',
            result: GameResult.redWin),
        _makeGame(
            redPlayer: '王五',
            blkPlayer: '赵六',
            titleA: '全国赛',
            result: GameResult.blackWin),
        _makeGame(
            redPlayer: '张三',
            blkPlayer: '王五',
            titleA: '友谊赛',
            result: GameResult.draw),
      ];
    });

    test('empty criteria returns all', () {
      expect(GameSearch.search(games, const SearchCriteria()), games);
    });

    test('search by player name', () {
      final results =
          GameSearch.search(games, const SearchCriteria(playerName: '张三'));
      expect(results.length, 2);
    });

    test('search by title', () {
      final results =
          GameSearch.search(games, const SearchCriteria(title: '五羊'));
      expect(results.length, 1);
    });

    test('search by result', () {
      final results = GameSearch.search(
          games, SearchCriteria(result: GameResult.redWin));
      expect(results.length, 1);
    });

    test('no match returns empty', () {
      final results =
          GameSearch.search(games, const SearchCriteria(playerName: '不存在'));
      expect(results, isEmpty);
    });

    test('combined criteria', () {
      final results = GameSearch.search(
          games,
          SearchCriteria(
              playerName: '张三', result: GameResult.draw));
      expect(results.length, 1);
    });
  });
}

GameData _makeGame({
  String redPlayer = '',
  String blkPlayer = '',
  String titleA = '',
  GameResult result = GameResult.unknown,
}) {
  return GameData(
    metadata: GameMetadata(
        redPlayer: redPlayer,
        blkPlayer: blkPlayer,
        titleA: titleA,
        result: result),
    playTree: PlayNode.root(List<int>.from(kInitialPieceXY)),
    initialPieceXY: List<int>.from(kInitialPieceXY).sublist(1),
  );
}
