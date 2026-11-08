import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> clearPrivateFiles() async {
  try {
    final temp = await getTemporaryDirectory();
    for (final name in ['orientia_exports', 'share_plus']) {
      final dir = Directory('${temp.path}/$name');
      if (await dir.exists()) {
        for (final entry in dir.listSync(followLinks: false)) {
          if (entry is File &&
              entry.uri.pathSegments.last.startsWith('orientia_')) {
            await entry.delete();
          }
        }
      }
    }
  } catch (_) {
    /* A platform without a temporary directory cannot retain these files. */
  }
}

Future<void> shareReport(Uint8List bytes, String name, String mime,
    {bool Function()? stillAuthorized}) async {
  if (stillAuthorized?.call() == false) return;
  if (!RegExp(r'^orientia_[a-zA-Z0-9_-]+\.(pdf|csv|xlsx)$').hasMatch(name)) {
    throw const FormatException('Nom de fichier invalide');
  }
  final base = await getTemporaryDirectory();
  final folder = Directory('${base.path}/orientia_exports');
  await folder.create(recursive: true);
  final file = File('${folder.path}/$name');
  try {
    await file.writeAsBytes(bytes, flush: true);
    if (stillAuthorized?.call() == false) return;
    await Share.shareXFiles([XFile(file.path, mimeType: mime)],
        fileNameOverrides: [name]);
  } finally {
    if (await file.exists()) await file.delete();
    await clearPrivateFiles();
  }
}
