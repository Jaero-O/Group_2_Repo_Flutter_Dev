import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/qr_scanner_service.dart';
import '../services/local_db.dart';
import '../services/sync_service.dart';
import '../model/pi_qr_data.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  static const double _scanFrameSize = 280;
  static const Offset _scanFrameOffset = Offset(0, -48);

  final QrScannerService _scannerService = QrScannerService();

  Uint8List? _imageBytes;
  bool _scanned = false;
  String? _error;
  String? _status;
  double? _progressPercent;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCameraPermission();
    SyncService.instance.progressNotifier.addListener(_onProgressChanged);
  }

  void _onProgressChanged() {
    if (!mounted) return;
    final progress = SyncService.instance.progressNotifier.value;
    setState(() {
      _status = progress?.message;
      _progressPercent = progress?.percent;
    });
  }

  Future<void> _initCameraPermission() async {
    if (!mounted) return;
    final status = await Permission.camera.status;
    if (!mounted) return;
    setState(() {
      _cameraReady = status.isGranted;
    });
  }

  Future<bool> _requestCameraPermission() async {
    final result = await Permission.camera.request();
    if (!mounted) return false;
    setState(() {
      _cameraReady = result.isGranted;
    });
    return result.isGranted;
  }

  Future<bool> _ensureWifiPermissions() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      final nearby = await Permission.nearbyWifiDevices.request();
      final location = await Permission.locationWhenInUse.request();
      return nearby.isGranted && location.isGranted;
    }

    // Android 10–12 commonly require Location permission to access SSID / Wi‑Fi scan state.
    final location = await Permission.locationWhenInUse.request();
    return location.isGranted;
  }

  String _humanizeError(Object e) {
    final msg = e.toString();

    if (e is FormatException) {
      return e.message;
    }

    final lower = msg.toLowerCase();
    if (lower.contains('cleartext')) {
      return 'HTTP blocked. Cleartext HTTP traffic to the Pi is not permitted on this device.';
    }
    if (lower.contains('cannot read ssid')) {
      return 'Connected, but Android cannot read SSID. Turn ON Location services and grant Nearby Wi-Fi + Location permissions.';
    }
    if (lower.contains('ssid mismatch')) {
      return 'Connected to a different Wi-Fi than Pi-Proto-Net. Switch to Pi hotspot and retry.';
    }
    if (lower.contains('permission')) {
      return 'Missing permissions. Please grant Camera and Wi‑Fi permissions and try again.';
    }
    if (lower.contains('unable to reach pi hotspot') || lower.contains('not routing')) {
      return 'Connected to Wi‑Fi but not routing to Pi. Try turning off mobile data and retry.';
    }

    return 'Sync failed. ${msg.replaceFirst('Exception: ', '')}';
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;

    final raw = _scannerService.extractQrValue(capture);
    if (raw == null) return;

    setState(() => _scanned = true);

    try {
      setState(() {
        _status = 'Parsing QR…';
        _error = null;
        _progressPercent = null;
      });

      final qrData = PiQrData.fromRaw(raw);

      setState(() {
        _status = 'Requesting Wi‑Fi permission…';
      });
      final wifiOk = await _ensureWifiPermissions();
      if (!wifiOk) {
        throw Exception('Wi‑Fi permission denied');
      }

      // Automatically connect and sync with Pi when the QR is scanned.
      await SyncService.instance.syncFromPi(qrData);

      setState(() {
        _status = 'Loading imported result…';
        _progressPercent = null;
      });

      Uint8List? bytes;
      final id = int.tryParse(qrData.scanId ?? '');
      if (id != null) {
        final localScan = await LocalDb.instance.getScanById(id);
        if (localScan != null && localScan.imagePath.isNotEmpty) {
          bytes = await File(localScan.imagePath).readAsBytes();
        }
      }

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _error = null;
          _status = null;
          _progressPercent = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _humanizeError(e);
          _status = null;
          _progressPercent = null;
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _imageBytes = null;
      _scanned = false;
      _error = null;
      _status = null;
      _progressPercent = null;
    });
  }

  @override
  void dispose() {
    _scannerService.dispose();
    SyncService.instance.progressNotifier.removeListener(_onProgressChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _scanned ? _buildResult() : _buildScanner(),
      ),
    );
  }

  Widget _buildScanner() {
    if (!_cameraReady) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: Colors.green),
              const SizedBox(height: 12),
              const Text(
                'Camera permission is required to scan the Pi QR code.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _requestCameraPermission,
                child: const Text('Grant Camera Permission'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: openAppSettings,
                child: const Text('Open App Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _scannerService.controller,
          onDetect: _onDetect,
          fit: BoxFit.cover,
        ),
        _buildScannerOverlay(),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    const double cornerWidth = 5;
    const double cornerLength = 44;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _ScannerMaskPainter(frameSize: _scanFrameSize),
          ),
        ),
        Center(
          child: Transform.translate(
            offset: _scanFrameOffset,
            child: SizedBox(
              width: _scanFrameSize,
              height: _scanFrameSize,
              child: CustomPaint(
                painter: _QrGuidePainter(
                  color: Colors.greenAccent,
                  strokeWidth: cornerWidth,
                  cornerLength: cornerLength,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 72,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Align the QR code inside the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(blurRadius: 12, color: Colors.black54, offset: Offset(0, 1)),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The image will import automatically once scanned',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_off, color: Colors.orange, size: 60),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _reset, child: const Text('Try Again')),
          ],
        ),
      );
    }

    if (_status != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_progressPercent != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: LinearProgressIndicator(value: _progressPercent),
              )
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status!, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (_imageBytes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 56),
            const SizedBox(height: 12),
            const Text('Sync complete.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _reset, child: const Text('Scan Another')),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: Image.memory(_imageBytes!, fit: BoxFit.contain)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(onPressed: _reset, child: const Text('Scan Another')),
        ),
      ],
    );
  }
}

class _ScannerMaskPainter extends CustomPainter {
  final double frameSize;

  _ScannerMaskPainter({required this.frameSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color.fromRGBO(0, 0, 0, 0.45);
    final Rect outer = Rect.fromLTWH(0, 0, size.width, size.height);
    final Rect hole = Rect.fromCenter(
      center: size.center(const Offset(0, -48)),
      width: frameSize,
      height: frameSize,
    );

    final path = Path()
      ..addRect(outer)
      ..addRect(hole)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QrGuidePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  _QrGuidePainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double inset = strokeWidth / 2;
    final Rect rect = Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth);

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(cornerLength, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(0, cornerLength), paint);

    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight.translate(-cornerLength, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight.translate(0, cornerLength), paint);

    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(cornerLength, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(0, -cornerLength), paint);

    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(-cornerLength, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(0, -cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}