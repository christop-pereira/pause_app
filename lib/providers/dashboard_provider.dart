import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../core/constants.dart';

class DayStats {
  final String label;
  final int success;
  final int fail;
  DayStats({required this.label, required this.success, required this.fail});
  int get total => success + fail;
}

class DashboardProvider extends ChangeNotifier {
  int successCount = 0;
  int failCount = 0;
  int total = 0;
  Map<String, int> reasonCounts = {};
  List<DayStats> weekStats = [];

  Future<void> load() async {
    final allEvents = await AppDatabase.instance.getEvents();
    total = allEvents.length;
    successCount = allEvents.where((e) => (e['success'] as int) == 1).length;
    failCount = total - successCount;

    // Compte des raisons d'échec
    reasonCounts = {};
    for (final e in allEvents) {
      final r = e['reason'] as String?;
      if (r != null && r.isNotEmpty) {
        reasonCounts[r] = (reasonCounts[r] ?? 0) + 1;
      }
    }

    // Stats 7 derniers jours
    weekStats = [];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr = day.toIso8601String().substring(0, 10);
      final dayEvents = allEvents.where((e) {
        final d = (e['date'] as String?)?.substring(0, 10) ?? '';
        return d == dayStr;
      }).toList();

      final s = dayEvents.where((e) => (e['success'] as int) == 1).length;
      final f = dayEvents.length - s;

      weekStats.add(DayStats(
        label: AppConstants.weekDays[day.weekday - 1],
        success: s,
        fail: f,
      ));
    }

    notifyListeners();
  }

  double get rate => total == 0 ? 0 : (successCount / total) * 100;

  String get topReason {
    if (reasonCounts.isEmpty) return '-';
    return reasonCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}