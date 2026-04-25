class PendingQuestionnaire {
  final int id;
  final String triggerId;
  final String triggerLabel;
  final DateTime dueAt;
  final DateTime createdAt;

  PendingQuestionnaire({
    required this.id,
    required this.triggerId,
    required this.triggerLabel,
    required this.dueAt,
    required this.createdAt,
  });

  bool get isDue => DateTime.now().isAfter(dueAt) || DateTime.now().isAtSameMomentAs(dueAt);

  Duration get timeUntilDue => dueAt.difference(DateTime.now());

  factory PendingQuestionnaire.fromMap(Map<String, dynamic> m) => PendingQuestionnaire(
        id: m['id'] as int,
        triggerId: m['triggerId'] as String,
        triggerLabel: m['triggerLabel'] as String,
        dueAt: DateTime.fromMillisecondsSinceEpoch(m['dueAt'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
      );
}