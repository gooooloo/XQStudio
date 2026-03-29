import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyReverseBoard = 'reverse_board';
  static const _keyAutoPlaySpeed = 'auto_play_speed';

  static Future<bool> getReverseBoard() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReverseBoard) ?? false;
  }

  static Future<void> setReverseBoard(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReverseBoard, value);
  }

  static Future<double> getAutoPlaySpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyAutoPlaySpeed) ?? 1.5;
  }

  static Future<void> setAutoPlaySpeed(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyAutoPlaySpeed, value);
  }
}
