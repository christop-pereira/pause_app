import 'package:flutter/material.dart';
import '../database/app_database.dart';

class AppProvider extends ChangeNotifier {
  String userName = '';
  String audioPath = '';   // '' = utiliser le défaut
  String photoPath = '';   // '' = utiliser l'avatar par défaut
  bool isLoaded = false;

  Future<void> load() async {
    final user = await AppDatabase.instance.getUser();
    if (user != null) {
      userName = user['name'] ?? '';
      audioPath = user['audioPath'] ?? '';
      photoPath = user['photoPath'] ?? '';
    }
    isLoaded = true;
    notifyListeners();
  }

  bool get hasUser => userName.isNotEmpty;
  bool get hasAudio => audioPath.isNotEmpty;
  bool get hasPhoto => photoPath.isNotEmpty;

  /// Retourne le chemin audio effectif (custom ou défaut)
  String get effectiveAudioPath => audioPath;
  bool get useDefaultAudio => audioPath.isEmpty;

  Future<void> saveUser(String name, String? audio, {String? photo}) async {
    userName = name;
    audioPath = audio ?? '';
    if (photo != null) photoPath = photo;
    await AppDatabase.instance.saveUser(name, audio, photoPath: photo);
    notifyListeners();
  }

  Future<void> setAudio(String path) async {
    audioPath = path;
    await AppDatabase.instance.saveUser(userName, path);
    notifyListeners();
  }

  Future<void> clearAudio() async {
    audioPath = '';
    await AppDatabase.instance.saveUser(userName, null);
    notifyListeners();
  }

  Future<void> setName(String name) async {
    userName = name;
    await AppDatabase.instance.saveUser(name, audioPath.isEmpty ? null : audioPath);
    notifyListeners();
  }

  Future<void> setPhoto(String path) async {
    photoPath = path;
    await AppDatabase.instance.updateUserPhoto(path);
    notifyListeners();
  }

  Future<void> clearPhoto() async {
    photoPath = '';
    await AppDatabase.instance.updateUserPhoto(null);
    notifyListeners();
  }
}
