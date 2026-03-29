import 'package:flutter/services.dart';

class ClipboardService {
  static Future<void> copyMoveList(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<String?> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}
