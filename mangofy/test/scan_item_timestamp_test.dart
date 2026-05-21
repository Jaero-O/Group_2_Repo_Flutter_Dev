import 'package:flutter_test/flutter_test.dart';
import 'package:mangofy/model/scan_item.dart';

void main() {
  group('ScanItem.fromJson timestamp extraction', () {
    test('uses nested scan_detail timestamp when top-level is missing', () {
      final item = ScanItem.fromJson({
        'id': 42,
        'scan_detail': {
          'timestamp': '2026-04-04 14:12:12',
        },
        'classification': {
          'class': 'Healthy',
          'confidence': 0.99,
        },
        'reduced_image': '/images/leaf.jpg',
      });

      expect(item.timestamp, '2026-04-04T14:12:12.000Z');
    });

    test('falls back to nested scan_result timestamp', () {
      final item = ScanItem.fromJson({
        'database_id': 99,
        'scan_result': {
          'timestamp': '2026-04-05T01:02:03Z',
        },
        'classification': {
          'class': 'Anthracnose',
          'confidence': 0.62,
        },
        'scan_dir': '/tmp/scan_20260405_010203',
      });

      expect(item.timestamp, '2026-04-05T01:02:03.000Z');
    });

    test('prefers top-level scan_timestamp over nested values', () {
      final item = ScanItem.fromJson({
        'id': 123,
        'scan_timestamp': '2026-04-06T09:10:11Z',
        'scan_detail': {
          'timestamp': '2026-04-01T00:00:00Z',
        },
        'scan_result': {
          'timestamp': '2026-04-02T00:00:00Z',
        },
      });

      expect(item.timestamp, '2026-04-06T09:10:11.000Z');
    });
  });
}
