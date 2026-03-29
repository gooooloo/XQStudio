import 'dart:typed_data';
import 'package:enough_convert/enough_convert.dart';

const _codec = GbkCodec(allowInvalid: true);

String decodeGB2312(Uint8List bytes) => _codec.decode(bytes);

Uint8List encodeGB2312(String text) => Uint8List.fromList(_codec.encode(text));
