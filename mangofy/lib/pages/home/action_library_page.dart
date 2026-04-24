import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String _normalizeSeverityOption(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (_severityOptions.contains(value)) return value;
    if (value == 'moderate' || value == 'mid') return 'early';
    if (value == 'high' || value == 'severe' || value == 'critical') {
      return 'advanced';
    }
    return 'all';
  }

  String _normalizeTrendOption(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (_trendOptions.contains(value)) return value;
    if (value == 'any' || value.isEmpty) return 'any';
    return 'any';
  }

  int _normalizeIconOption(int? codePoint) {
    final fallback = Icons.science_outlined.codePoint;
    if (codePoint == null) return fallback;
    final contains = _iconOptions.any(
      (option) => (option['icon'] as IconData).codePoint == codePoint,
    );
    return contains ? codePoint : fallback;
  }

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

  ButtonStyle _secondaryButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _actionButtonStyle(Color backgroundColor) {
    return TextButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Future<void> _deleteAction(ActionItem item) async {
    if (item.id == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          content: SizedBox(
            width: MediaQuery.of(dialogContext).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Delete "${item.title}"?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to delete this action?\nThis action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: _secondaryButtonStyle(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: _actionButtonStyle(Colors.red),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDelete != true) return;
    await LocalDb.instance.deleteAction(item.id!);
    _reload();
  }

  Future<void> _showActionEditor({ActionItem? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _ActionEditorDialog(
          existing: existing,
          initialSeverity: _normalizeSeverityOption(existing?.severityTrigger),
          initialTrend: _normalizeTrendOption(existing?.trendTrigger),
          initialIconCode: _normalizeIconOption(existing?.iconCode),
          severityOptions: _severityOptions,
          trendOptions: _trendOptions,
          iconOptions: _iconOptions,
          secondaryButtonStyleBuilder: _secondaryButtonStyle,
          actionButtonStyleBuilder: _actionButtonStyle,
        );
      },
    );

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Action Library'),
      ),
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
                          color: Colors.white,
                          child: ListTile(
                            onTap: () => _showActionEditor(existing: item),
                            onLongPress: () => _deleteAction(item),
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

class _ActionEditorDialog extends StatefulWidget {
  final ActionItem? existing;
  final String initialSeverity;
  final String initialTrend;
  final int initialIconCode;
  final List<String> severityOptions;
  final List<String> trendOptions;
  final List<Map<String, dynamic>> iconOptions;
  final ButtonStyle Function() secondaryButtonStyleBuilder;
  final ButtonStyle Function(Color) actionButtonStyleBuilder;

  const _ActionEditorDialog({
    required this.existing,
    required this.initialSeverity,
    required this.initialTrend,
    required this.initialIconCode,
    required this.severityOptions,
    required this.trendOptions,
    required this.iconOptions,
    required this.secondaryButtonStyleBuilder,
    required this.actionButtonStyleBuilder,
  });

  @override
  State<_ActionEditorDialog> createState() => _ActionEditorDialogState();
}

class _ActionEditorDialogState extends State<_ActionEditorDialog> {
  late final TextEditingController _diseaseController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _colorController;
  late final TextEditingController _priorityController;

  late String _severity;
  late String _trend;
  late int _iconCode;

  @override
  void initState() {
    super.initState();
    _diseaseController = TextEditingController(
      text: widget.existing?.diseaseKeyword ?? 'default',
    );
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.existing?.description ?? '',
    );
    _colorController = TextEditingController(
      text: widget.existing?.colorHex ?? '#2E7D32',
    );
    _priorityController = TextEditingController(
      text: (widget.existing?.priority ?? 100).toString(),
    );

    _severity = widget.initialSeverity;
    _trend = widget.initialTrend;
    _iconCode = widget.initialIconCode;
  }

  @override
  void dispose() {
    _diseaseController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2.5),
      ),
    );
  }

  Future<void> _onSave() async {
    final disease = _diseaseController.text.trim().toLowerCase();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (disease.isEmpty || title.isEmpty || description.isEmpty) {
      return;
    }

    final priority = int.tryParse(_priorityController.text.trim()) ?? 100;

    await LocalDb.instance.upsertAction(
      ActionItem(
        id: widget.existing?.id,
        diseaseKeyword: disease,
        severityTrigger: _severity,
        trendTrigger: _trend,
        title: title,
        description: description,
        iconCode: _iconCode,
        colorHex: _colorController.text.trim().isEmpty
            ? '#2E7D32'
            : _colorController.text.trim(),
        priority: priority,
        isActive: true,
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: null,
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'Add Action' : 'Edit Action',
                textAlign: TextAlign.left,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
              ),
              const SizedBox(height: 2),
              Text(
                'Set action details for disease mitigation',
                textAlign: TextAlign.left,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _diseaseController,
                decoration: _inputDecoration(
                  label: 'Disease keyword',
                  hint: 'anthracnose / default',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: _inputDecoration(label: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration(label: 'Description'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _severity,
                decoration: _inputDecoration(label: 'Severity trigger'),
                items: widget.severityOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _severity = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _trend,
                decoration: _inputDecoration(label: 'Trend trigger'),
                items: widget.trendOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _trend = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _iconCode,
                decoration: _inputDecoration(label: 'Icon'),
                items: widget.iconOptions
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
                  setState(() {
                    _iconCode = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _colorController,
                decoration: _inputDecoration(label: 'Color hex', hint: '#2E7D32'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priorityController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(label: 'Priority (lower = first)'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: widget.secondaryButtonStyleBuilder(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: _onSave,
                      style: widget.actionButtonStyleBuilder(const Color(0xFF4CAF50)),
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
