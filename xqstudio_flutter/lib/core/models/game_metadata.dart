// lib/core/models/game_metadata.dart

enum GameResult { unknown, redWin, blackWin, draw }
enum WhoPlay { red, black, none, pause }

class GameMetadata {
  String titleA;
  String titleB;
  String matchName;
  String matchTime;
  String matchAddr;
  String redPlayer;
  String blkPlayer;
  String timeRule;
  String redTime;
  String blkTime;
  String rmkWriter;
  String author;
  GameResult result;
  WhoPlay whoPlay;

  GameMetadata({
    this.titleA = '',
    this.titleB = '',
    this.matchName = '',
    this.matchTime = '',
    this.matchAddr = '',
    this.redPlayer = '',
    this.blkPlayer = '',
    this.timeRule = '',
    this.redTime = '',
    this.blkTime = '',
    this.rmkWriter = '',
    this.author = '',
    this.result = GameResult.unknown,
    this.whoPlay = WhoPlay.red,
  });
}
