import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/trigger_model.dart';
import 'notification_service.dart';

class SchedulerService {
  SchedulerService._();
  static final SchedulerService instance = SchedulerService._();

  Future<void> init() async {
    tzdata.initializeTimeZones();
  }

  /// Reprogramme toutes les notifications pour les triggers actifs de type heure
  Future<void> rescheduleAll(List<TriggerModel> triggers) async {
    await NotificationService.instance.cancelAll();

    int notifId = 100;
    for (final trigger in triggers) {
      if (trigger.active == 0) continue;
      if (trigger.type == 'location') continue;
      if (trigger.time == null) continue;

      final parts = trigger.time!.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      final days = trigger.daysList;
      if (days.isEmpty) {
        // Chaque jour
        await _scheduleForDays(notifId, trigger.label, List.generate(7, (i) => i), hour, minute);
        notifId += 7;
      } else {
        await _scheduleForDays(notifId, trigger.label, days, hour, minute);
        notifId += days.length;
      }
    }
  }

  Future<void> _scheduleForDays(int baseId, String label, List<int> days, int hour, int minute) async {
    for (int i = 0; i < days.length; i++) {
      final dayIndex = days[i]; // 0=lundi..6=dimanche
      // Flutter: weekday 1=lundi..7=dimanche, tz weekday: 1=lundi..7=dimanche
      final targetWeekday = dayIndex + 1;
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      // Ajuste au bon jour de la semaine
      while (scheduled.weekday != targetWeekday) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }

      try {
        await NotificationService.instance.scheduleAt(
          baseId + i,
          'PAUSE ⏸',
          label,
          scheduled,
        );
      } catch (_) {
        // Ignore scheduling errors (simulateur, permissions, etc.)
      }
    }
  }

  /// Déclenche immédiatement un trigger pour test
  Future<void> triggerNow(String label) async {
    await NotificationService.instance.showNow('PAUSE ⏸', label);
  }
}