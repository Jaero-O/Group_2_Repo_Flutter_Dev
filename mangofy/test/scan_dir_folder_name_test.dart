import 'package:flutter_test/flutter_test.dart';
import 'package:mangofy/model/scan_item.dart';

void main() {
  group('scanDirFolderName', () {
    test('returns basename for Pi-style paths', () {
      expect(
        scanDirFolderName('/home/pi/scans/Tree_A'),
        'Tree_A',
      );
    });

    test('ignores trailing separators and whitespace', () {
      expect(
        scanDirFolderName('  /home/pi/scans/Tree_B/  '),
        'Tree_B',
      );
    });

    test('normalizes backslashes', () {
      expect(
        scanDirFolderName(r'C:\pi\scans\Tree_C'),
        'Tree_C',
      );
    });

    test('returns empty string for empty values', () {
      expect(scanDirFolderName(''), '');
      expect(scanDirFolderName('   '), '');
      expect(scanDirFolderName('/'), '');
    });
  });
}
