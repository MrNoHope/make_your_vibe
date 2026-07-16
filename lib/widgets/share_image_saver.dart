import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Future<String?> saveRepaintBoundaryAsPng({  // Tạo và lưu hình ảnh chứa thông tin album để chia sẻ
  required GlobalKey boundaryKey,
  required String fileName,
}) async {
  await WidgetsBinding.instance.endOfFrame;
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    throw StateError('Không tạo được ảnh mã chia sẻ.');
  }

  final image = await boundary.toImage(pixelRatio: 3);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('Không tạo được dữ liệu ảnh mã chia sẻ.');
    }

    return FilePicker.saveFile(
      dialogTitle: 'Lưu ảnh mã chia sẻ',
      fileName: _safePngName(fileName),
      type: FileType.custom,
      allowedExtensions: const ['png'],
      bytes: data.buffer.asUint8List(),
    );
  } finally {
    image.dispose();
  }
}

String _safePngName(String value) {
  final base = value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return '${base.isEmpty ? 'make_your_vibe_share' : base}.png';
}
