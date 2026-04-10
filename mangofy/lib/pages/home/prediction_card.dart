import 'package:flutter/material.dart';
import 'dart:math';

class PredictionCard extends StatelessWidget {
  final double spreadRisk; // 0.0 - 1.0
  final double humidityRisk; // 0.0 - 1.0
  final double recovery; // 0.0 - 1.0
  final String insightText;

  const PredictionCard({
    super.key,
    this.spreadRisk = 0.0,
    this.humidityRisk = 0.0,
    this.recovery = 0.0,
    this.insightText =
        'Scan a leaf to generate the 30-day prediction for your crop.',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- MOVED OUTSIDE: 30-Day Prediction Title ---
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            '30-Day Prediction',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF555555),
            ),
          ),
        ),

        // Main Card
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
              // Gauge row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _GaugeItem(
                    value: spreadRisk,
                    label: 'Spread Risk',
                    color: const Color(0xFF2E7D32),
                  ),
                  _GaugeItem(
                    value: humidityRisk,
                    label: 'Humidity Risk',
                    color: const Color(0xFFFFCC00),
                  ),
                  _GaugeItem(
                    value: recovery,
                    label: 'Recovery',
                    color: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 24),

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
                    // Using an Icon as a fallback if the image is missing
                    Image.asset(
                      'images/mangoleaves.png',
                      height: 70,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => 
                        const Icon(Icons.eco, size: 50, color: Colors.green),
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

class _GaugeItem extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String label;
  final Color color;

  const _GaugeItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final int percent = (value * 100).round();

    return Column(
      children: [
        SizedBox(
          width: 90,
          height: 54, // half-circle height
          child: CustomPaint(
            painter: _SemiCircleGaugePainter(
              value: value,
              color: color,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _SemiCircleGaugePainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final Color color;

  const _SemiCircleGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 10.0;
    final Offset center = Offset(size.width / 2, size.height);
    final double radius = size.width / 2 - strokeWidth / 2;

    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    canvas.drawArc(
      arcRect,
      pi, // start at left (180°)
      pi, // sweep 180°
      false,
      Paint()
        ..color = Colors.grey[300]!
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Filled arc
    canvas.drawArc(
      arcRect,
      pi,
      pi * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SemiCircleGaugePainter old) =>
      old.value != value || old.color != color;
}