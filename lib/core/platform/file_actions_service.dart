import 'dart:io';

import 'package:flutter/services.dart';

class FileActionsService {
  const FileActionsService._();

  static const _channel = MethodChannel('app_catalogo/files');

  static Future<void> openPdf(String path) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Abrir PDF está disponible en Android.');
    }
    await _channel.invokeMethod<void>('openPdf', {'path': path});
  }

  static Future<void> sharePdf(String path) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Compartir PDF está disponible en Android.');
    }
    await _channel.invokeMethod<void>('sharePdf', {'path': path});
  }
}
