import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  final QrScannerService _scannerService = QrScannerService();

  Uint8List? _imageBytes;
  bool _scanned = false;
  String? _error;

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;

    final raw = _scannerService.extractQrValue(capture);
    if (raw == null) return;

    setState(() => _scanned = true);

    try {
      final qrData = PiQrData.fromRaw(raw);

      // Automatically connect and sync with Pi when the QR is scanned.
      await SyncService.instance.syncFromPi(qrData);

      final localScan = await LocalDb.instance.getScanById(int.parse(qrData.scanId));
      if (localScan == null) throw Exception('Imported scan not found locally');

      final bytes = await File(localScan.imagePath).readAsBytes();

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Sync failed: $e';
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _imageBytes = null;
      _scanned = false;
      _error = null;
    });
  }

  @override
  void dispose() {
    _scannerService.dispose();
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
    const double frameSize = 280;
    const double cornerWidth = 5;
    const double cornerLength = 44;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _ScannerMaskPainter(frameSize: frameSize),
          ),
        ),
        Center(
          child: Transform.translate(
            offset: const Offset(0, -48),
            child: SizedBox(
              width: frameSize,
              height: frameSize,
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

    if (_imageBytes == null) {
      return const Center(child: CircularProgressIndicator());
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