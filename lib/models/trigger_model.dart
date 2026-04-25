class TriggerModel {
  final String id;
  final String type;
  final String label;
  final String? days;
  final String? time;
  final double? lat;
  final double? lng;
  final String? locationName;
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
    this.locationName,
    this.radius = 150,
    this.active = 1,
  });

  // copyWith avec sentinel pour distinguer "non passé" de "null voulu"
  TriggerModel copyWith({
    String? type,
    String? label,
    Object? days = _sentinel,
    Object? time = _sentinel,
    Object? lat = _sentinel,
    Object? lng = _sentinel,
    Object? locationName = _sentinel,
    double? radius,
    int? active,
  }) {
    return TriggerModel(
      id: id,
      type: type ?? this.type,
      label: label ?? this.label,
      days: days == _sentinel ? this.days : days as String?,
      time: time == _sentinel ? this.time : time as String?,
      lat: lat == _sentinel ? this.lat : lat as double?,
      lng: lng == _sentinel ? this.lng : lng as double?,
      locationName: locationName == _sentinel ? this.locationName : locationName as String?,
      radius: radius ?? this.radius,
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
      'locationName': locationName,
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
      locationName: map['locationName'],
      radius: (map['radius'] ?? 150).toDouble(),
      active: map['active'] ?? 1,
    );
  }
}

// Sentinel pour distinguer null explicite de "non fourni"
const Object _sentinel = Object();
