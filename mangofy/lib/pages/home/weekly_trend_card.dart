import 'package:flutter/material.dart';

class OutbreakPredictionCard extends StatelessWidget {
  final String insightText;
  final List<double>? weeklyData;
  final int? peakOverride;
  final int? latestOverride;

  const OutbreakPredictionCard({
    super.key,
    this.insightText =
        'Scan a leaf to build a weekly trend for outbreak prediction.',
    this.weeklyData,
    this.peakOverride,
    this.latestOverride,
  });

  @override
  Widget build(BuildContext context) {
    final List<double> data = weeklyData ?? [];

    final int peak = peakOverride ??
        (data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b).toInt());
    final int latest = latestOverride ??
        (data.isEmpty ? 0 : data.last.toInt());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- MOVED OUTSIDE: Outbreak Prediction Timeline Text ---
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'Weekly Trend',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF555555),
            ),
          ),
        ),

        // The Main Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDE7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end, // Aligned to end since Trend text is gone
                      children: [
                        // --- REMOVED: "Weekly Trend" Text ---
                        Text(
                          'Peak: $peak  Latest: $latest',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _BarChartPainter(data: data),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // INSIGHT label
              const Text(
                'I N S I G H T',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5,
                  color: Colors.black45,
                ),
              ),

              const SizedBox(height: 10),

              // Insight box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        insightText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                    // Note: Ensure images/mangoleaves.png exists in your pubspec.yaml
                    Image.asset(
                      'images/mangoleaves.png',
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.eco, size: 40, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;

  const _BarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final int count = data.length;
    final double totalSpacing = size.width * 0.04 * (count - 1);
    final double barWidth = (size.width - totalSpacing) / count;
    final double spacing = count > 1 ? totalSpacing / (count - 1) : 0;
    final double radius = 6;

    for (int i = 0; i < count; i++) {
      final bool isLast = i == count - 1;
      final double heightFactor = (data[i] / maxVal).clamp(0.05, 1.0);
      final double barHeight = size.height * heightFactor;
      final double x = i * (barWidth + spacing);
      final double y = size.height - barHeight;

      final RRect rRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
      );

      canvas.drawRRect(
        rRect,
        Paint()
          ..color = isLast
              ? const Color(0xFF2E7D32)  // dark green — latest bar
              : const Color(0xFF81C784), // light green — other bars
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => old.data != data;
}