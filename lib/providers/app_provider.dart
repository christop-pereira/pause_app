import 'package:flutter/material.dart';
import '../database/app_database.dart';

class AppProvider extends ChangeNotifier {
  String userName = '';
  String audioPath = '';
  bool isLoaded = false;

  Future<void> load() async {
    final user = await AppDatabase.instance.getUser();
    if (user != null) {
      userName = user['name'] ?? '';
      audioPath = user['audioPath'] ?? '';
    }
    isLoaded = true;
    notifyListeners();
  }

  bool get hasUser => userName.isNotEmpty;
  bool get hasAudio => audioPath.isNotEmpty;

  Future<void> saveUser(String name, String? audio) async {
    userName = name;
    audioPath = audio ?? '';
    await AppDatabase.instance.saveUser(name, audio);
    notifyListeners();
  }

  Future<void> setAudio(String path) async {
    audioPath = path;
    await AppDatabase.instance.saveUser(userName, path);
    notifyListeners();
  }

  Future<void> setName(String name) async {
    userName = name;
    await AppDatabase.instance.saveUser(name, audioPath.isEmpty ? null : audioPath);
    notifyListeners();
  }
}