import 'package:flutter/material.dart';
import 'scan_details_page.dart'; 

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      'Scan History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryCard(
                        title: 'Total Scans',
                        value: '120',
                        color: Colors.green.shade400,
                        icon: Icons.qr_code_scanner,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        title: 'Healthy',
                        value: '95',
                        color: Colors.teal.shade400,
                        icon: Icons.eco,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        title: 'Infected',
                        value: '25',
                        color: Colors.red.shade400,
                        icon: Icons.local_florist,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 1,
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.sort),
                          label: const Text('Sort'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 1,
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView.builder(
                        itemCount: 20,
                        itemBuilder: (context, index) {
                          final scanTitle = 'Leaf Scan #${index + 1}';
                          final disease = 'Anthracnose';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.image, size: 40),
                              title: Text(scanTitle),
                              subtitle: Text('Detected: $disease'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScanDetailsPage(
                                      scanTitle: scanTitle,
                                      disease: disease,
                                      dateScanned: 'October 29, 2025',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        elevation: 4,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
