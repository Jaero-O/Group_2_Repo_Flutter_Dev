class ActionItem {
  final int? id;
  final String diseaseKeyword;
  final String severityTrigger;
  final String trendTrigger;
  final String title;
  final String description;
  final int iconCode;
  final String colorHex;
  final int priority;
  final bool isActive;

  const ActionItem({
    this.id,
    required this.diseaseKeyword,
    required this.severityTrigger,
    required this.trendTrigger,
    required this.title,
    required this.description,
    required this.iconCode,
    required this.colorHex,
    required this.priority,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'disease_keyword': diseaseKeyword,
      'severity_trigger': severityTrigger,
      'trend_trigger': trendTrigger,
      'title': title,
      'description': description,
      'icon_code': iconCode,
      'color_hex': colorHex,
      'priority': priority,
      'is_active': isActive ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory ActionItem.fromMap(Map<String, dynamic> map) {
    int parseInt(Object? value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    final idValue = map['id'];
    return ActionItem(
      id: idValue == null ? null : parseInt(idValue),
      diseaseKeyword: (map['disease_keyword']?.toString() ?? '').trim(),
      severityTrigger: (map['severity_trigger']?.toString() ?? 'all').trim(),
      trendTrigger: (map['trend_trigger']?.toString() ?? 'any').trim(),
      title: (map['title']?.toString() ?? '').trim(),
      description: (map['description']?.toString() ?? '').trim(),
      iconCode: parseInt(map['icon_code']),
      colorHex: (map['color_hex']?.toString() ?? '#2E7D32').trim(),
      priority: parseInt(map['priority'], fallback: 100),
      isActive: parseInt(map['is_active'], fallback: 1) == 1,
    );
  }
}
