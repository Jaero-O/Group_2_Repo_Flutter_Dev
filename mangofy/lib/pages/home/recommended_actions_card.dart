import 'package:flutter/material.dart';
import '../../model/scan_summary_model.dart';

class RecommendedActionsCard extends StatelessWidget {
  final ScanSummary summary;

  const RecommendedActionsCard({super.key, required this.summary});

  static const List<Map<String, dynamic>> _actions = [
    {
      'icon': Icons.science_outlined,
      'color': Color(0xFF06850C),
      'title': 'Apply Fungicide',
      'desc': 'Use neem oil or sulfur-based spray on affected areas.',
    },
    {
      'icon': Icons.water_drop_outlined,
      'color': Color(0xFF85D133),
      'title': 'Improve Drainage',
      'desc': 'Avoid water accumulation near roots.',
    },
    {
      'icon': Icons.delete_outline,
      'color': Color(0xFFA5E358),
      'title': 'Remove Infected Leaves',
      'desc': 'Dispose of affected leaves properly.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final int totalDiseased = summary.moderateCount + summary.severeCount;

    if (totalDiseased == 0) return const SizedBox.shrink();

    return Card(
      color: const Color(0xFFFAFAFA),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _actions.asMap().entries.map((entry) {
            final int index = entry.key;
            final Map<String, dynamic> action = entry.value;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action['title'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action['desc'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF777777),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (index < _actions.length - 1)
                  const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}