import 'package:flutter/material.dart';

import '../../model/action_item.dart';
import '../../services/local_db.dart';

class ActionLibraryPage extends StatefulWidget {
  const ActionLibraryPage({super.key});

  @override
  State<ActionLibraryPage> createState() => _ActionLibraryPageState();
}

class _ActionLibraryPageState extends State<ActionLibraryPage> {
  late Future<List<ActionItem>> _actionsFuture;

  static const List<String> _severityOptions = <String>[
    'all',
    'healthy',
    'early',
    'advanced',
  ];

  static const List<String> _trendOptions = <String>[
    'any',
    'improving',
    'stable',
    'worsening',
  ];

  static const List<Map<String, dynamic>> _iconOptions = <Map<String, dynamic>>[
    {'label': 'Science', 'icon': Icons.science_outlined},
    {'label': 'Prune', 'icon': Icons.content_cut},
    {'label': 'Water', 'icon': Icons.water_drop_outlined},
    {'label': 'Air', 'icon': Icons.air},
    {'label': 'Delete', 'icon': Icons.delete_outline},
    {'label': 'Clean', 'icon': Icons.cleaning_services_outlined},
    {'label': 'Shield', 'icon': Icons.shield_outlined},
    {'label': 'Eco', 'icon': Icons.eco},
  ];

  @override
  void initState() {
    super.initState();
    _actionsFuture = LocalDb.instance.getAllActions();
  }

  void _reload() {
    setState(() {
      _actionsFuture = LocalDb.instance.getAllActions();
    });
  }

  Future<void> _deleteAction(ActionItem item) async {
    if (item.id == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Action'),
          content: Text('Delete "${item.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;
    await LocalDb.instance.deleteAction(item.id!);
    _reload();
  }

  Future<void> _showActionEditor({ActionItem? existing}) async {
    final diseaseController = TextEditingController(
      text: existing?.diseaseKeyword ?? 'default',
    );
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final colorController = TextEditingController(
      text: existing?.colorHex ?? '#2E7D32',
    );
    final priorityController = TextEditingController(
      text: (existing?.priority ?? 100).toString(),
    );

    String severity = existing?.severityTrigger ?? 'all';
    String trend = existing?.trendTrigger ?? 'any';
    int iconCode = existing?.iconCode ?? Icons.science_outlined.codePoint;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Action' : 'Edit Action'),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: diseaseController,
                        decoration: const InputDecoration(
                          labelText: 'Disease keyword',
                          hintText: 'anthracnose / default',
                        ),
                      ),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: severity,
                        decoration: const InputDecoration(
                          labelText: 'Severity trigger',
                        ),
                        items: _severityOptions
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            severity = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: trend,
                        decoration: const InputDecoration(
                          labelText: 'Trend trigger',
                        ),
                        items: _trendOptions
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            trend = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: iconCode,
                        decoration: const InputDecoration(labelText: 'Icon'),
                        items: _iconOptions
                            .map(
                              (option) => DropdownMenuItem<int>(
                                value: (option['icon'] as IconData).codePoint,
                                child: Row(
                                  children: [
                                    Icon(option['icon'] as IconData, size: 18),
                                    const SizedBox(width: 8),
                                    Text(option['label'] as String),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            iconCode = value;
                          });
                        },
                      ),
                      TextField(
                        controller: colorController,
                        decoration: const InputDecoration(
                          labelText: 'Color hex',
                          hintText: '#2E7D32',
                        ),
                      ),
                      TextField(
                        controller: priorityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Priority (lower = first)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final disease = diseaseController.text.trim().toLowerCase();
                    final title = titleController.text.trim();
                    final description = descriptionController.text.trim();

                    if (disease.isEmpty ||
                        title.isEmpty ||
                        description.isEmpty) {
                      return;
                    }

                    final priority =
                        int.tryParse(priorityController.text.trim()) ?? 100;

                    await LocalDb.instance.upsertAction(
                      ActionItem(
                        id: existing?.id,
                        diseaseKeyword: disease,
                        severityTrigger: severity,
                        trendTrigger: trend,
                        title: title,
                        description: description,
                        iconCode: iconCode,
                        colorHex: colorController.text.trim().isEmpty
                            ? '#2E7D32'
                            : colorController.text.trim(),
                        priority: priority,
                        isActive: true,
                      ),
                    );

                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    diseaseController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    colorController.dispose();
    priorityController.dispose();

    if (saved == true) {
      _reload();
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

  String _labelForDisease(String key) {
    if (key == 'default') return 'General';
    if (key.isEmpty) return 'Unknown';
    return key
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part.substring(0, 1).toUpperCase() + part.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Action Library')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActionEditor(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ActionItem>>(
        future: _actionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final actions = snapshot.data ?? const <ActionItem>[];
          if (actions.isEmpty) {
            return const Center(child: Text('No actions yet.'));
          }

          final grouped = <String, List<ActionItem>>{};
          for (final action in actions) {
            grouped.putIfAbsent(action.diseaseKeyword, () => <ActionItem>[])
              ..add(action);
          }

          final keys = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: keys.length,
            itemBuilder: (context, groupIndex) {
              final key = keys[groupIndex];
              final group = grouped[key]!
                ..sort((a, b) => a.priority.compareTo(b.priority));

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labelForDisease(key),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...group.map((item) {
                      final itemColor = _colorFromHex(item.colorHex);
                      return Dismissible(
                        key: ValueKey(
                          item.id ?? '${item.title}_${item.priority}',
                        ),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          await _deleteAction(item);
                          return false;
                        },
                        child: Card(
                          child: ListTile(
                            onTap: () => _showActionEditor(existing: item),
                            leading: CircleAvatar(
                              backgroundColor: itemColor.withValues(
                                alpha: 0.15,
                              ),
                              child: Icon(
                                IconData(
                                  item.iconCode,
                                  fontFamily: 'MaterialIcons',
                                ),
                                color: itemColor,
                              ),
                            ),
                            title: Text(item.title),
                            subtitle: Text(
                              '${item.description}\nSeverity: ${item.severityTrigger} | Trend: ${item.trendTrigger}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.edit_outlined),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
