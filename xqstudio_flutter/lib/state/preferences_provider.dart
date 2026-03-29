// lib/state/preferences_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppPreferences {
  final bool reverseBoard;
  final double autoPlaySpeed;

  const AppPreferences({
    this.reverseBoard = false,
    this.autoPlaySpeed = 1.5,
  });

  AppPreferences copyWith({bool? reverseBoard, double? autoPlaySpeed}) {
    return AppPreferences(
      reverseBoard: reverseBoard ?? this.reverseBoard,
      autoPlaySpeed: autoPlaySpeed ?? this.autoPlaySpeed,
    );
  }
}

class PreferencesNotifier extends Notifier<AppPreferences> {
  @override
  AppPreferences build() => const AppPreferences();

  void toggleReverseBoard() {
    state = state.copyWith(reverseBoard: !state.reverseBoard);
  }

  void setAutoPlaySpeed(double speed) {
    state = state.copyWith(autoPlaySpeed: speed);
  }
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, AppPreferences>(
  PreferencesNotifier.new,
);
