import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerService {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );

  /// Returns the raw string value from the first detected QR barcode.
  String? extractQrValue(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      if (barcode.format == BarcodeFormat.qrCode && barcode.rawValue != null) {
        return barcode.rawValue;
      }
    }
    return null;
  }

  void dispose() {
    controller.dispose();
  }
}