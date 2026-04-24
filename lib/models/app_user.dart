class AppUser {
  final int? id;
  final String name;
  final String? audioPath;

  AppUser({this.id, required this.name, this.audioPath});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'audioPath': audioPath};

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'],
    name: map['name'],
    audioPath: map['audioPath'],
  );
}