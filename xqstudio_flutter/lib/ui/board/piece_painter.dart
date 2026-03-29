import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Loads piece PNG images from assets and provides them keyed by name.
///
/// Key format: `"red_1"`, `"red_1_sel"`, `"blk_3"`, etc.
class PieceImageLoader {
  PieceImageLoader._();

  static Future<Map<String, ui.Image>> loadAll() async {
    final keys = <String>[];
    for (final side in ['red', 'blk']) {
      for (var i = 1; i <= 7; i++) {
        keys.add('${side}_$i');
        keys.add('${side}_${i}_sel');
      }
    }

    final map = <String, ui.Image>{};
    await Future.wait(keys.map((key) async {
      final data = await rootBundle.load('assets/images/pieces/$key.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      map[key] = frame.image;
    }));
    return map;
  }
}
