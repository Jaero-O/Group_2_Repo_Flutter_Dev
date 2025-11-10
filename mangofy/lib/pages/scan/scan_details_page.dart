import 'package:flutter/material.dart';

class ScanDetailsPage extends StatelessWidget {
  final String scanTitle;
  final String disease;
  final String dateScanned;

  const ScanDetailsPage({
    super.key,
    required this.scanTitle,
    required this.disease,
    required this.dateScanned,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(scanTitle),
        backgroundColor: Colors.green.shade400,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Details',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Disease Detected: $disease',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Date Scanned: $dateScanned',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Center(
              child: Icon(
                Icons.image,
                size: 120,
                color: Colors.green.shade300,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recommended Action:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '- Apply appropriate fungicide\n- Remove infected leaves\n- Monitor for recurrence',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
