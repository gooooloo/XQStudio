// lib/core/search/search_criteria.dart

import 'package:xqstudio/core/models/game_metadata.dart';

class SearchCriteria {
  final String? playerName;
  final String? title;
  final GameResult? result;
  final String? openingMoves;

  const SearchCriteria({
    this.playerName,
    this.title,
    this.result,
    this.openingMoves,
  });

  bool get isEmpty =>
      playerName == null &&
      title == null &&
      result == null &&
      openingMoves == null;
}
