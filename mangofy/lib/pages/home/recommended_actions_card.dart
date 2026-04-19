import 'package:flutter/material.dart';

import '../../model/action_item.dart';
import '../../model/scan_summary_model.dart';
import '../../services/local_db.dart';
import 'action_library_page.dart';

class RecommendedActionsCard extends StatefulWidget {
  final ScanSummary summary;
  final String primaryDisease;
  final String trendDirection;

  const RecommendedActionsCard({
    super.key,
    required this.summary,
    required this.primaryDisease,
    required this.trendDirection,
  });

  @override
  State<RecommendedActionsCard> createState() => _RecommendedActionsCardState();
}

class _RecommendedActionsCardState extends State<RecommendedActionsCard> {
  late Future<List<ActionItem>> _actionsFuture;

  @override
  void initState() {
    super.initState();
    _actionsFuture = _loadActions();
  }

  @override
  void didUpdateWidget(covariant RecommendedActionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryDisease != widget.primaryDisease ||
        oldWidget.trendDirection != widget.trendDirection ||
        oldWidget.summary.healthyCount != widget.summary.healthyCount ||
        oldWidget.summary.earlyStageCount != widget.summary.earlyStageCount ||
        oldWidget.summary.advancedStageCount !=
            widget.summary.advancedStageCount) {
      setState(() {
        _actionsFuture = _loadActions();
      });
    }
  }

  Future<List<ActionItem>> _loadActions() async {
    final disease = widget.primaryDisease.trim().toLowerCase();
    final severity = _resolveSeverityTrigger(widget.summary);
    final trend = _normalizeTrend(widget.trendDirection);

    var actions = await LocalDb.instance.getActionsForContext(
      disease: disease.isEmpty ? 'default' : disease,
      severityTrigger: severity,
      trendTrigger: trend,
    );

    if (actions.isEmpty) {
      actions = await LocalDb.instance.getActionsForContext(
        disease: 'default',
        severityTrigger: 'all',
        trendTrigger: 'any',
      );
    }

    if (actions.length > 4) {
      return actions.take(4).toList(growable: false);
    }
    return actions;
  }

  String _resolveSeverityTrigger(ScanSummary summary) {
    final advanced = summary.advancedStageCount;
    final early = summary.earlyStageCount;
    final healthy = summary.healthyCount;

    if (advanced >= early && advanced >= healthy && advanced > 0) {
      return 'advanced';
    }
    if (early >= healthy && early > 0) {
      return 'early';
    }
    return 'healthy';
  }

  String _normalizeTrend(String trendDirection) {
    final normalized = trendDirection.trim().toLowerCase();
    switch (normalized) {
      case 'worsening':
      case 'stable':
      case 'improving':
        return normalized;
      default:
        return 'any';
    }
  }

  Color _colorFromHex(String hex) {
    final raw = hex.trim().replaceFirst('#', '');
    if (raw.length != 6) {
      return const Color(0xFF2E7D32);
    }
    final value = int.tryParse(raw, radix: 16);
    if (value == null) {
      return const Color(0xFF2E7D32);
    }
    return Color(0xFF000000 + value);
  }

  Future<void> _openActionLibrary() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActionLibraryPage()),
    );
    if (!mounted) return;
    setState(() {
      _actionsFuture = _loadActions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ActionItem>>(
      future: _actionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox(
            height: 210,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final actions = snapshot.data ?? const <ActionItem>[];

        return Card(
          color: const Color(0xFFFAFAFA),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Action Library Suggestions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit action library',
                      onPressed: _openActionLibrary,
                      icon: const Icon(Icons.edit_note_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (actions.isEmpty)
                  const Text(
                    'No matching actions available for this trend. Add actions in the library.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
                  )
                else
                  ...actions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final color = _colorFromHex(item.colorHex);

                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                IconData(
                                  item.iconCode,
                                  fontFamily: 'MaterialIcons',
                                ),
                                color: color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.description,
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
                        if (index < actions.length - 1)
                          const Divider(
                            height: 24,
                            thickness: 1,
                            color: Color(0xFFEEEEEE),
                          ),
                      ],
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
