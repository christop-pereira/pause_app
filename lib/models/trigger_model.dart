class TriggerModel {
  final String id;
  final String type; // 'time', 'location', 'both'
  final String label;
  final String? days;   // ex: "0,1,4" (indices lundi=0..dim=6)
  final String? time;   // ex: "18:30"
  final double? lat;
  final double? lng;
  final double radius;
  final int active;

  TriggerModel({
    required this.id,
    required this.type,
    required this.label,
    this.days,
    this.time,
    this.lat,
    this.lng,
    this.radius = 150,
    this.active = 1,
  });

  TriggerModel copyWith({int? active}) {
    return TriggerModel(
      id: id,
      type: type,
      label: label,
      days: days,
      time: time,
      lat: lat,
      lng: lng,
      radius: radius,
      active: active ?? this.active,
    );
  }

  List<int> get daysList {
    if (days == null || days!.isEmpty) return [];
    return days!.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'label': label,
      'days': days,
      'time': time,
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'active': active,
    };
  }

  factory TriggerModel.fromMap(Map<String, dynamic> map) {
    return TriggerModel(
      id: map['id'],
      type: map['type'],
      label: map['label'],
      days: map['days'],
      time: map['time'],
      lat: map['lat'],
      lng: map['lng'],
      radius: (map['radius'] ?? 150).toDouble(),
      active: map['active'] ?? 1,
    );
  }
}