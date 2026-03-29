// lib/core/search/game_search.dart

import 'package:xqstudio/core/search/search_criteria.dart';
import 'package:xqstudio/core/xqf/xqf_reader.dart';

class GameSearch {
  static List<GameData> search(List<GameData> games, SearchCriteria criteria) {
    if (criteria.isEmpty) return games;
    return games.where((g) => _matches(g, criteria)).toList();
  }

  static bool _matches(GameData game, SearchCriteria criteria) {
    if (criteria.playerName != null) {
      final name = criteria.playerName!.toLowerCase();
      if (!game.metadata.redPlayer.toLowerCase().contains(name) &&
          !game.metadata.blkPlayer.toLowerCase().contains(name)) return false;
    }
    if (criteria.title != null) {
      final title = criteria.title!.toLowerCase();
      if (!game.metadata.titleA.toLowerCase().contains(title) &&
          !game.metadata.titleB.toLowerCase().contains(title)) return false;
    }
    if (criteria.result != null && game.metadata.result != criteria.result) {
      return false;
    }
    return true;
  }
}
