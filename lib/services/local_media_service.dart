import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalMediaService {
  Future<String> pickAndCopy({
    required FileType type,
    required String folder,
  }) async {
    final result = await FilePicker.pickFiles(
      type: type,
      allowMultiple: false,
    );
    if (result == null) return '';

    final source = result.files.single.path;
    if (source == null) {
      throw Exception('Không đọc được file đã chọn.');
    }
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, folder));
    await directory.create(recursive: true);
    final extension = p.extension(source);
    final target = p.join(
      directory.path,
      '${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    await File(source).copy(target);
    return target;
  }

  Future<void> delete(String path) async {
    if (path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
