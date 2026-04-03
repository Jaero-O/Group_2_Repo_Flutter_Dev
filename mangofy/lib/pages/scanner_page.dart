import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_scanner_service.dart';
import '../services/pi_api.dart'; 
import '../services/local_db.dart'; 
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
      // 1. Parse the JSON from the QR code
      final qrData = PiQrData.fromRaw(raw);

      /* // 2. DISABLED FOR VPN USAGE
      // We comment this out because connectPiHotspot() forces the phone 
      // to join a Wi-Fi network, which drops the Mobile Data required for the VPN.
      
      final connected = await HotspotService.instance.connectPiHotspot();
      if (!connected) throw Exception("Could not connect to Pi-Proto-Net");
      */

      // 3. Fetch the full scan data from the Pi API (now using VPN IP)
      // Check if Pi is actually reachable over VPN first
      final isAvailable = await PiApi.instance.checkStatus();
      if (!isAvailable) {
        throw Exception("Pi not reachable at 192.168.196.139. Check ZeroTier!");
      }

      final remoteScan = await PiApi.instance.getScan(qrData.scanId);

      // 4. Save the record into local SQL database
      await LocalDb.instance.upsertScan(remoteScan);

      // 5. Download the image
      final imagePath = await PiApi.instance.downloadImage(remoteScan);
      final file = File(imagePath);
      final bytes = await file.readAsBytes();

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _error = null;
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'VPN Sync failed: $e';
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
      appBar: AppBar(title: const Text('Scan Mango Leaf (VPN Mode)')),
      body: _scanned ? _buildResult() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return MobileScanner(
      controller: _scannerService.controller,
      onDetect: _onDetect,
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