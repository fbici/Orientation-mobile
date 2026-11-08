import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

Future<void> clearPrivateFiles() async {}
Future<void> shareReport(Uint8List bytes, String name, String mime,
    {bool Function()? stillAuthorized}) async {
  if (stillAuthorized?.call() == false) return;
  await Share.shareXFiles([XFile.fromData(bytes, mimeType: mime)],
      fileNameOverrides: [name]);
}
