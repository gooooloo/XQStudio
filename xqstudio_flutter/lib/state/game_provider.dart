// lib/state/game_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xqstudio/core/game/game_controller.dart';
import 'package:xqstudio/core/xqf/xqf_reader.dart';

class GameState {
  final GameController controller;
  final int version; // increment on every change to trigger rebuilds

  GameState(this.controller, this.version);
}

class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() => GameState(GameController(), 0);

  void makeMove(int fromXY, int toXY) {
    state.controller.makeMove(fromXY, toXY);
    state = GameState(state.controller, state.version + 1);
  }

  void undoMove() {
    state.controller.undoMove();
    state = GameState(state.controller, state.version + 1);
  }

  void redoMove() {
    state.controller.redoMove();
    state = GameState(state.controller, state.version + 1);
  }

  void goToFirst() {
    state.controller.goToFirst();
    state = GameState(state.controller, state.version + 1);
  }

  void goToLast() {
    state.controller.goToLast();
    state = GameState(state.controller, state.version + 1);
  }

  void goToNext() {
    state.controller.goToNext();
    state = GameState(state.controller, state.version + 1);
  }

  void goToPrev() {
    state.controller.goToPrev();
    state = GameState(state.controller, state.version + 1);
  }

  void goToStep(int step) {
    state.controller.goToStep(step);
    state = GameState(state.controller, state.version + 1);
  }

  void loadGameData(GameData gameData) {
    state = GameState(GameController.fromGameData(gameData), 0);
  }

  void newGame() {
    state = GameState(GameController(), 0);
  }

  void setRemark(String text) {
    state.controller.setRemark(text);
    state = GameState(state.controller, state.version + 1);
  }

  void deleteCurrentMove() {
    state.controller.deleteCurrentMove();
    state = GameState(state.controller, state.version + 1);
  }

  void switchVariation(int index) {
    state.controller.switchVariation(index);
    state = GameState(state.controller, state.version + 1);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
