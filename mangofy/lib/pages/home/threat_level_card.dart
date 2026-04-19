import 'package:flutter/material.dart';
import 'dart:math';

enum ThreatLevel { low, moderate, high, critical }

extension ThreatLevelStyle on ThreatLevel {
  String get label {
    switch (this) {
      case ThreatLevel.low:      return 'LOW';
      case ThreatLevel.moderate: return 'MODERATE';
      case ThreatLevel.high:     return 'HIGH';
      case ThreatLevel.critical: return 'CRITICAL';
    }
  }

  Color get foreground {
    switch (this) {
      case ThreatLevel.low:      return Colors.green;
      case ThreatLevel.moderate: return Colors.orange;
      case ThreatLevel.high:     return Colors.red;
      case ThreatLevel.critical: return const Color(0xFF8B0000);
    }
  }

  Color get background {
    switch (this) {
      case ThreatLevel.low:      return const Color(0xFFE6F4EA);
      case ThreatLevel.moderate: return const Color(0xFFFFF3E0);
      case ThreatLevel.high:     return const Color(0xFFFFE5E5);
      case ThreatLevel.critical: return const Color(0xFFFFCDD2);
    }
  }
}

class PrimaryThreatCard extends StatelessWidget {
  final String diseaseName;
  final String scientificName;
  final int activeCases;
  final ThreatLevel threatLevel;
  final double weeklyTrendPercent;
  final List<double> trendData;
  final String chartLabel;

  const PrimaryThreatCard({
    super.key,
    required this.diseaseName,
    required this.scientificName,
    required this.activeCases,
    required this.threatLevel,
    required this.weeklyTrendPercent,
    required this.trendData,
    this.chartLabel = '2-week case trend',
  });

  @override
  Widget build(BuildContext context) {
    final bool isTrendUp = weeklyTrendPercent >= 0;
    final Color trendColor = isTrendUp ? Colors.red : Colors.green;
    final IconData trendIcon = isTrendUp ? Icons.arrow_upward : Icons.arrow_downward;
    final String trendLabel =
        '${isTrendUp ? '+' : ''}${weeklyTrendPercent.toStringAsFixed(0)}% this week';

    // FIX: need at least 2 points to draw the chart
    final bool hasChartData = trendData.length >= 2;

    return Container(
      // FIX: removed margin — home_page handles spacing via SizedBox and padding
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diseaseName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scientificName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$activeCases',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: threatLevel.foreground,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'diseased scans (all-time)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: threatLevel.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  threatLevel.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: threatLevel.foreground,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    trendLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: trendColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // FIX: guard requires at least 2 points
          if (hasChartData)
            _TrendChart(
              dataPoints: trendData,
              label: chartLabel,
              color: threatLevel.foreground,
            ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<double> dataPoints;
  final String label;
  final Color color;

  const _TrendChart({
    required this.dataPoints,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: CustomPaint(
            painter: _TrendChartPainter(dataPoints: dataPoints, color: color),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  const _TrendChartPainter({required this.dataPoints, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final double minVal = dataPoints.reduce(min);
    final double maxVal = dataPoints.reduce(max);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    List<Offset> points = [];
    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i / (dataPoints.length - 1) * size.width;
      final double normalized = (dataPoints[i] - minVal) / range;
      final double y = size.height * 0.85 - normalized * (size.height * 0.75);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.7)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final point in points) {
      canvas.drawCircle(point, 3, Paint()..color = color.withOpacity(0.6));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter old) =>
      old.dataPoints != dataPoints || old.color != color;
}