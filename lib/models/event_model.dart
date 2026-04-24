class EventModel {
  final int? id;
  final String triggerId;
  final String date;
  final int success;
  final String? reason;

  EventModel({
    this.id,
    required this.triggerId,
    required this.date,
    required this.success,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'triggerId': triggerId,
      'date': date,
      'success': success,
      'reason': reason,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'],
      triggerId: map['triggerId'],
      date: map['date'],
      success: map['success'],
      reason: map['reason'],
    );
  }
}