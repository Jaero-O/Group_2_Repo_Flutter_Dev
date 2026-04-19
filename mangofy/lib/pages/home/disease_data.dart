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

// ── Root card ────────────────────────────────────────────────────────────────

class DiseaseDistributionCard extends StatefulWidget {
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
    DiseaseData(name: 'Bacterial Canker', count: 5, color: Color(0xFFFB8C00)),
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

  @override
  State<DiseaseDistributionCard> createState() => _DiseaseDistributionCardState();
}

class _DiseaseDistributionCardState extends State<DiseaseDistributionCard> {
  final Set<int> _selectedDiseaseIndices = <int>{};

  void _onDiseaseSelected(int index) {
    setState(() {
      if (_selectedDiseaseIndices.contains(index)) {
        _selectedDiseaseIndices.remove(index);
      } else {
        _selectedDiseaseIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.totalCases > 0
        ? widget.totalCases
        : widget.diseases.fold(0, (sum, item) => sum + item.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Disease Distribution',
                  style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555555),
                ),
              ),
            ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
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
                  // Left: total count
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
                          diseases: widget.diseases,
                          total: total,
                          selectedIndices: _selectedDiseaseIndices,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: widget.diseases
                        .asMap()
                        .entries
                        .map(
                          (entry) => SizedBox(
                            width: itemWidth,
                            child: _LegendItem(
                              disease: entry.value,
                              total: total,
                              isSelected: _selectedDiseaseIndices.contains(
                                entry.key,
                              ),
                              hasActiveSelection:
                                  _selectedDiseaseIndices.isNotEmpty,
                              onTap: () => _onDiseaseSelected(entry.key),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final DiseaseData disease;
  final int total;
  final bool isSelected;
  final bool hasActiveSelection;
  final VoidCallback onTap;

  const _LegendItem({
    required this.disease,
    required this.total,
    required this.isSelected,
    required this.hasActiveSelection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double percent = total > 0 ? (disease.count / total) * 100 : 0;
    final shouldGrayOut = hasActiveSelection && !isSelected;
    const lightGray = Color(0xFFCDCDCD);
    final markerColor = shouldGrayOut ? lightGray : disease.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE8F5E9)
                : shouldGrayOut
                ? const Color(0xFFF1F1F1)
                : const Color(0xFFF7FAF7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? disease.color : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1F1F1F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${disease.count} cases (${percent.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Donut chart painter ───────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<DiseaseData> diseases;
  final int total;
  final Set<int> selectedIndices;

  const _DonutPainter({
    required this.diseases,
    required this.total,
    required this.selectedIndices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0 || diseases.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const double baseStrokeWidth = 22.0;
    final safeRadius = radius - (baseStrokeWidth / 2) - 1;

    double startAngle = -math.pi / 2;
    const double gap = 0.04;
    const lightGray = Color(0xFFCDCDCD);

    for (int i = 0; i < diseases.length; i++) {
      final d = diseases[i];
      final sweep = (d.count / total) * 2 * math.pi;

      final isSelected = selectedIndices.contains(i);
      final shouldGrayOut = selectedIndices.isNotEmpty && !isSelected;
        final segmentColor = shouldGrayOut ? lightGray : d.color;

      final strokeWidth = baseStrokeWidth;
      final rect = Rect.fromCircle(
        center: center,
        radius: safeRadius,
      );

      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        sweep - gap,
        false,
        Paint()
          ..color = segmentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) {
    return old.diseases != diseases ||
        old.total != total ||
        old.selectedIndices.length != selectedIndices.length ||
        !old.selectedIndices.containsAll(selectedIndices) ||
        !selectedIndices.containsAll(old.selectedIndices);
  }
}