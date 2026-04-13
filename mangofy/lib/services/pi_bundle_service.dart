import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PiBundleService {
  PiBundleService._();
  static final PiBundleService instance = PiBundleService._();

  Future<String> extractZipBundle({required String zipPath, required String scanId}) async {
    final docs = await getApplicationDocumentsDirectory();
    final destDir = Directory(p.join(docs.path, 'pi_bundles', scanId));
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    final input = InputFileStream(zipPath);
    try {
      final archive = ZipDecoder().decodeBuffer(input);
      await extractArchiveToDisk(archive, destDir.path);
      return destDir.path;
    } finally {
      await input.close();
    }
  }
}
