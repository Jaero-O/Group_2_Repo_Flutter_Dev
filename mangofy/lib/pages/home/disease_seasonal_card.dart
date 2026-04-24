import 'package:flutter/material.dart';

// ── Seasonal data model ───────────────────────────────────────────────────────

class _DiseaseSeasonInfo {
  final String name;
  final String scientificName;
  final Color color;
  final List<int> peakMonths; // 1 = Jan … 12 = Dec
  final String mitigationTip;
  final IconData icon;

  const _DiseaseSeasonInfo({
    required this.name,
    required this.scientificName,
    required this.color,
    required this.peakMonths,
    required this.mitigationTip,
    required this.icon,
  });
}

// Peak months are based on tropical mango-growing conditions (Philippines / SE Asia).
const List<_DiseaseSeasonInfo> _kDiseaseSeasons = [
  _DiseaseSeasonInfo(
    name: 'Anthracnose',
    scientificName: 'Colletotrichum gloeosporioides',
    color: Color(0xFFE53935),
    // Wet-season flush (Jun–Oct) + flowering period (Jan–Mar)
    peakMonths: [1, 2, 3, 6, 7, 8, 9, 10],
    mitigationTip:
        'Apply copper-based fungicide at flowering and during wet season. '
        'Prune canopy for air circulation. Avoid overhead irrigation.',
    icon: Icons.spa,
  ),
  _DiseaseSeasonInfo(
    name: 'Powdery Mildew',
    scientificName: 'Oidium mangiferae',
    color: Color(0xFFFFAB00),
    // Dry-cool season, flowering (Nov–Mar)
    peakMonths: [11, 12, 1, 2, 3],
    mitigationTip:
        'Apply sulfur-based or systemic fungicide at panicle emergence. '
        'Monitor closely during cool, dry nights with warm days.',
    icon: Icons.cloud,
  ),
  _DiseaseSeasonInfo(
    name: 'Stem-end Rot',
    scientificName: 'Lasiodiplodia theobromae',
    color: Color(0xFF43A047),
    // Post-harvest rot; rainy season (Jun–Oct)
    peakMonths: [6, 7, 8, 9, 10],
    mitigationTip:
        'Harvest at correct maturity with long stems. '
        'Apply post-harvest hot-water treatment or fungicide dip. Handle gently.',
    icon: Icons.local_florist,
  ),
  _DiseaseSeasonInfo(
    name: 'Bacterial Canker',
    scientificName: 'Xanthomonas campestris pv. mangiferaeindicae',
    color: Color(0xFFFB8C00),
    // Rainy season (May–Oct)
    peakMonths: [5, 6, 7, 8, 9, 10],
    mitigationTip:
        'Apply copper-based bactericide before rainy season. '
        'Remove and destroy infected branches. Avoid wounding fruit and leaves.',
    icon: Icons.warning_amber,
  ),
  _DiseaseSeasonInfo(
    name: 'Die Back',
    scientificName: 'Lasiodiplodia theobromae',
    color: Color(0xFF8E24AA),
    // Rainy season (Jun–Oct)
    peakMonths: [6, 7, 8, 9, 10],
    mitigationTip:
        'Prune infected branches 15 cm below visible symptoms. '
        'Seal cut surfaces with Bordeaux paste. Improve field drainage before wet season.',
    icon: Icons.eco,
  ),
];

const List<String> _kMonthAbbr = [
  'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D',
];

// ── Public card ───────────────────────────────────────────────────────────────

class DiseaseSeasonalCard extends StatefulWidget {
  const DiseaseSeasonalCard({super.key});

  @override
  State<DiseaseSeasonalCard> createState() => _DiseaseSeasonalCardState();
}

class _DiseaseSeasonalCardState extends State<DiseaseSeasonalCard> {
  // Which disease rows are expanded to show the mitigation tip
  final Set<int> _expanded = {};

  void _toggle(int index) {
    setState(() {
      if (_expanded.contains(index)) {
        _expanded.remove(index);
      } else {
        _expanded.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = now.month; // 1–12

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Disease Seasonal Calendar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF555555),
            ),
          ),
        ),

        Container(
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
            children: [
              // ── Month header row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    // Left: disease label area placeholder
                    const SizedBox(width: 28),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(12, (i) {
                          final monthNum = i + 1;
                          final isCurrent = monthNum == currentMonth;
                          return SizedBox(
                            width: 22,
                            child: Text(
                              _kMonthAbbr[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrent
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isCurrent
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF9E9E9E),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

              // ── Disease rows ──
              ...List.generate(_kDiseaseSeasons.length, (index) {
                final disease = _kDiseaseSeasons[index];
                final isPeakNow = disease.peakMonths.contains(currentMonth);
                final isExpanded = _expanded.contains(index);
                final isLast = index == _kDiseaseSeasons.length - 1;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _toggle(index),
                      borderRadius: isLast
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            )
                          : BorderRadius.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Disease name + peak badge ──
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: disease.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    disease.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F1F1F),
                                    ),
                                  ),
                                ),
                                if (isPeakNow)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: disease.color.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: disease.color.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 6,
                                          color: disease.color,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Peak Now',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: disease.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: const Color(0xFFBDBDBD),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // ── 12-month grid ──
                            _MonthGrid(
                              disease: disease,
                              currentMonth: currentMonth,
                            ),

                            // ── Mitigation tip (expandable) ──
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 220),
                              crossFadeState: isExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: const SizedBox(height: 0),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: disease.color.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: disease.color.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.tips_and_updates_outlined,
                                        size: 15,
                                        color: disease.color,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Mitigation',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: disease.color,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              disease.mitigationTip,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF424242),
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (!isLast)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF0F0F0),
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),

        // ── Legend ──
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 10),
          child: Row(
            children: [
              _LegendDot(color: const Color(0xFF2E7D32), label: 'Current month'),
              const SizedBox(width: 16),
              _LegendDot(
                color: const Color(0xFFBDBDBD),
                label: 'Peak season',
                isPeak: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Month grid ────────────────────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  final _DiseaseSeasonInfo disease;
  final int currentMonth;

  const _MonthGrid({required this.disease, required this.currentMonth});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(12, (i) {
        final monthNum = i + 1;
        final isPeak = disease.peakMonths.contains(monthNum);
        final isCurrent = monthNum == currentMonth;
        final isCurrentAndPeak = isPeak && isCurrent;

        Color bgColor;
        Color borderColor;
        Color textColor;

        if (isCurrentAndPeak) {
          bgColor = disease.color;
          borderColor = const Color(0xFF2E7D32);
          textColor = Colors.white;
        } else if (isPeak) {
          bgColor = disease.color.withValues(alpha: 0.18);
          borderColor = disease.color.withValues(alpha: 0.5);
          textColor = disease.color;
        } else if (isCurrent) {
          bgColor = const Color(0xFFE8F5E9);
          borderColor = const Color(0xFF2E7D32);
          textColor = const Color(0xFF2E7D32);
        } else {
          bgColor = const Color(0xFFF5F5F5);
          borderColor = Colors.transparent;
          textColor = const Color(0xFFBDBDBD);
        }

        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            _kMonthAbbr[i],
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        );
      }),
    );
  }
}

// ── Legend dot ────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isPeak;

  const _LegendDot({
    required this.color,
    required this.label,
    this.isPeak = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: isPeak
              ? BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE53935).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                )
              : BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
        ),
      ],
    );
  }
}
