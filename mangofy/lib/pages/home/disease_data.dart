import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: const DiseaseDistributionCard(),
          ),
        ),
      ),
    );
  }
}

// ── Data model ──────────────────────────────────────────────────────────────

class DiseaseData {
  final String name;
  final int count;
  final Color color;

  const DiseaseData({
    required this.name,
    required this.count,
    required this.color,
  });
}

class SeverityBadge {
  final String label;
  final Color bg;
  final Color text;

  const SeverityBadge({
    required this.label,
    required this.bg,
    required this.text,
  });
}

// ── Root card ────────────────────────────────────────────────────────────────

class DiseaseDistributionCard extends StatelessWidget {
  const DiseaseDistributionCard({
    super.key,
    this.totalCases = 100,
    this.diseases = defaultDiseases,
  });

  final int totalCases;
  final List<DiseaseData> diseases;

  static const List<DiseaseData> defaultDiseases = [
    DiseaseData(name: 'Anthracnose',    count: 55, color: Color(0xFFE53935)),
    DiseaseData(name: 'Powdery Mildew', count: 25, color: Color(0xFFFFD600)),
    DiseaseData(name: 'Stem-end Rot',   count: 15, color: Color(0xFF43A047)),
    DiseaseData(name: 'Others',         count: 5,  color: Color(0xFFBDBDBD)),
  ];

  static const List<Color> _fallbackColors = [
    Color(0xFFE53935),
    Color(0xFFFFD600),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
  ];

  static Color colorForDisease(String name, int index) {
    final lower = name.toLowerCase();
    if (lower.contains('healthy')) return const Color(0xFF1B5E20);
    if (lower.contains('anthracnose')) return const Color(0xFFE53935);
    if (lower.contains('powdery mildew')) return const Color(0xFFFFD600);
    if (lower.contains('rot')) return const Color(0xFF43A047);
    if (lower.contains('die back')) return const Color(0xFF8E24AA);
    if (lower.contains('canker')) return const Color(0xFFFB8C00);
    return _fallbackColors[index % _fallbackColors.length];
  }

  static const List<SeverityBadge> badges = [
    SeverityBadge(
      label: 'Low',
      bg:   Color(0xFFD6F5D6),
      text: Color(0xFF2E7D32),
    ),
    SeverityBadge(
      label: 'Moderate',
      bg:   Color(0xFFFFF9C4),
      text: Color(0xFFF9A825),
    ),
    SeverityBadge(
      label: 'High',
      bg:   Color(0xFFFFCDD2),
      text: Color(0xFFC62828),
    ),
    SeverityBadge(
      label: 'Low',
      bg:   Color(0xFFD6F5D6),
      text: Color(0xFF2E7D32),
    ),
  ];

  static const List<_StatItem> defaultStats = [
    _StatItem(value: '247', label: 'Total Scans'),
    _StatItem(value: '101', label: 'Healthy'),
    _StatItem(value: '134', label: 'Diseased'),
  ];

  @override
  Widget build(BuildContext context) {
    final int total = totalCases > 0 ? totalCases : diseases.fold(0, (sum, item) => sum + item.count);
    final int healthyCount = diseases
        .firstWhere(
          (item) => item.name.toLowerCase() == 'healthy',
          orElse: () => DiseaseData(name: 'Healthy', count: 0, color: const Color(0xFF1B5E20)),
        )
        .count;
    final int diseasedCount = total - healthyCount;
    final List<_StatItem> stats = [
      _StatItem(value: total.toString(), label: 'Total Scans'),
      _StatItem(value: healthyCount.toString(), label: 'Healthy'),
      _StatItem(value: diseasedCount.toString(), label: 'Diseased'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disease Distribution',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Total + Donut ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: total count + legend
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                            height: 1,
                          ),
                        ),
                        const Text(
                          'TOTAL CASES',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF757575),
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Legend rows
                        for (int i = 0; i < diseases.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                _SeverityPill(badge: badges[i % badges.length]),
                                const SizedBox(width: 8),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: diseases[i].color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    diseases[i].name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF212121),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Right: donut chart
                  Align(
                    alignment: Alignment.topRight,
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          diseases: diseases,
                          total: total,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Stats row ──
              Row(
                children: stats
                    .map(
                      (s) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _StatCard(item: s),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Severity pill ─────────────────────────────────────────────────────────────

class _SeverityPill extends StatelessWidget {
  final SeverityBadge badge;
  const _SeverityPill({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: badge.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        width: 84,
        child: Center(
          child: Text(
            badge.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badge.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatItem {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF388E3C),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Donut chart painter ───────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<DiseaseData> diseases;
  final int total;

  const _DonutPainter({required this.diseases, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0 || diseases.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 22.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -math.pi / 2;
    const double gap = 0.04;

    for (final d in diseases) {
      final sweep = (d.count / total) * 2 * math.pi;
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        sweep - gap,
        false,
        Paint()
          ..color = d.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}