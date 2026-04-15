import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/qr_scanner_service.dart';
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
        _status = 'Finalizing import…';
        _progressPercent = null;
      });

      final diagnostics = SyncService.instance.diagnosticsNotifier.value;
      final importedScans = diagnostics?.scansFetched ?? 0;
      final importedImages = diagnostics?.imagesDownloaded ?? 0;
      final failures = diagnostics?.failures ?? 0;

      if (mounted) {
        await _showImportCompleteModal(
          scans: importedScans,
          images: importedImages,
          failures: failures,
        );
        if (mounted && failures == 0) {
          Navigator.of(context).pop(true);
        } else if (mounted) {
          _reset();
        }
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
      _scanned = false;
      _error = null;
      _status = null;
      _progressPercent = null;
    });
  }

  Future<void> _showImportCompleteModal({
    required int scans,
    required int images,
    required int failures,
  }) async {
    if (!mounted) return;

    final success = failures == 0;
    final statusText = success
        ? 'Import complete.'
        : 'Imported with $failures issues.';

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: _ImportResultDialog(
            success: success,
            scans: scans,
            images: images,
            failures: failures,
            statusText: statusText,
          ),
        );
      },
    );
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
      final percent = _progressPercent ?? 0.0;
      final clampedPercent = percent.clamp(0.0, 1.0);
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_download_rounded, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              Text(
                'Importing Scans',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              if (_progressPercent != null)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: clampedPercent,
                        minHeight: 10,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        backgroundColor: const Color(0xFFE8F5E9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(clampedPercent * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                        fontSize: 15,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.8),
                ),
              const SizedBox(height: 12),
              Text(
                _status!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(),
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

class _ImportResultDialog extends StatefulWidget {
  final bool success;
  final int scans;
  final int images;
  final int failures;
  final String statusText;

  const _ImportResultDialog({
    required this.success,
    required this.scans,
    required this.images,
    required this.failures,
    required this.statusText,
  });

  @override
  State<_ImportResultDialog> createState() => _ImportResultDialogState();
}

class _ImportResultDialogState extends State<_ImportResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.success ? Icons.check_circle : Icons.warning_amber_rounded,
                color: widget.success ? Colors.green : Colors.orange,
                size: 84,
              ),
              const SizedBox(height: 12),
              Text(
                widget.success ? 'Import Successful' : 'Import Completed with Issues',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                widget.statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text('Scans imported: ${widget.scans}'),
              Text('Images downloaded: ${widget.images}'),
              if (widget.failures > 0) Text('Failed items: ${widget.failures}'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}