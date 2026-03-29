import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class FileService {
  static Future<Uint8List?> openXqfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xqf'],
      withData: true,
    );
    return result?.files.single.bytes;
  }

  static Future<void> saveXqfFile(Uint8List bytes,
      {String? suggestedName}) async {
    await FilePicker.platform.saveFile(
      dialogTitle: 'Save XQF File',
      fileName: suggestedName ?? 'untitled.xqf',
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: ['xqf'],
    );
  }
}
