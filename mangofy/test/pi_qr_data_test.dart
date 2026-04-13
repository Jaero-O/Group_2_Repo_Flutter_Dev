import 'package:flutter_test/flutter_test.dart';
import 'package:mangofy/model/pi_qr_data.dart';

void main() {
  group('PiQrData.fromJson', () {
    test('parses full URL endpoint fields only (no base_url)', () {
      final json = {
        'ssid': 'Pi-Proto-Net',
        'password': 'prototype_pass',
        'status_url': 'http://192.168.4.1:5000/api/status',
        'db_download_url': 'http://192.168.4.1:5000/api/db/download',
        'scan_bundle_url': 'http://192.168.4.1:5000/api/scan/123/bundle',
        'scan_id': '123',
        'issued_at': '2023-01-01T00:00:00Z',
      };

      final data = PiQrData.fromJson(json);

      expect(data.ssid, 'Pi-Proto-Net');
      expect(data.password, 'prototype_pass');
      expect(data.baseUrl, 'http://192.168.4.1:5000');
      expect(data.endpoints.statusPath, '/api/status');
      expect(data.endpoints.dbDownloadPath, '/api/db/download');
      expect(data.endpoints.scanBundlePathTemplate, '/api/scan/123/bundle');
      expect(data.scanId, '123');
    });

    test('falls back to defaults when db/bundle endpoints missing', () {
      final json = {
        'ssid': 'Pi-Proto-Net',
        'password': 'prototype_pass',
        'base_url': 'http://192.168.4.1:5000',
        'status_url': 'http://192.168.4.1:5000/api/status',
        'scan_id': '123',
        'issued_at': '2023-01-01T00:00:00Z',
      };

      final data = PiQrData.fromJson(json);

      expect(data.endpoints.dbDownloadPath, '/api/db/download');
      expect(data.endpoints.scanBundlePathTemplate, '/api/scan/{id}/bundle');
    });

    test('handles concrete bundle URL without template placeholder', () {
      final json = {
        'ssid': 'Pi-Proto-Net',
        'password': 'prototype_pass',
        'base_url': 'http://192.168.4.1:5000',
        'scan_bundle_url': 'http://192.168.4.1:5000/api/scan/456/bundle',
        'scan_id': '456',
        'issued_at': '2023-01-01T00:00:00Z',
      };

      final data = PiQrData.fromJson(json);

      expect(data.endpoints.resolveBundlePath('456'), '/api/scan/456/bundle');
    });

    test('derives baseUrl from full URL endpoint when base_url missing', () {
      final json = {
        'ssid': 'Pi-Proto-Net',
        'password': 'prototype_pass',
        'status_url': 'http://192.168.4.1:5000/api/status',
        'scan_id': '123',
        'issued_at': '2023-01-01T00:00:00Z',
      };

      final data = PiQrData.fromJson(json);

      expect(data.baseUrl, 'http://192.168.4.1:5000');
    });

    test('throws on malformed endpoint URLs', () {
      final json = {
        'ssid': 'Pi-Proto-Net',
        'password': 'prototype_pass',
        'base_url': 'http://192.168.4.1:5000',
        'status_url': 'not-a-url',
        'scan_id': '123',
        'issued_at': '2023-01-01T00:00:00Z',
      };

      expect(() => PiQrData.fromJson(json), throwsFormatException);
    });

    test('throws on missing required fields', () {
      final json = {
        'password': 'prototype_pass',
        'base_url': 'http://192.168.4.1:5000',
        'issued_at': '2023-01-01T00:00:00Z',
      };

      expect(() => PiQrData.fromJson(json), throwsFormatException);
    });
  });

  group('PiQrEndpoints.resolveBundlePath', () {
    test('resolves template with {id}', () {
      final endpoints = PiQrEndpoints(scanBundlePathTemplate: '/api/scan/{id}/bundle');
      expect(endpoints.resolveBundlePath('789'), '/api/scan/789/bundle');
    });

    test('returns concrete path unchanged when no {id}', () {
      final endpoints = PiQrEndpoints(scanBundlePathTemplate: '/api/scan/789/bundle');
      expect(endpoints.resolveBundlePath('999'), '/api/scan/789/bundle');
    });
  });
}