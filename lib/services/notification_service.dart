import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'pause_channel';
  static const _channelName = 'PAUSE';

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(
      android: android,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await plugin.initialize(settings);
  }

  Future<void> showNow(String title, String body) async {
    await plugin.show(
      0, title, body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Planifie une notification à une heure précise (TZDateTime)
  Future<void> scheduleAt(int id, String title, String body, tz.TZDateTime when) async {
    await plugin.zonedSchedule(
      id, title, body, when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Notification "comment ça s'est passé ?" à T+5min après un appel.
  /// Best-effort : si l'OS bloque, le bandeau in-app prend le relai.
  Future<void> scheduleDebriefAt({required int id, required DateTime when}) async {
    try {
      // Offset par 100000 pour ne pas collisionner avec les triggers programmés
      final notifId = 100000 + id;
      final tzWhen = tz.TZDateTime.from(when, tz.local);
      await plugin.zonedSchedule(
        notifId,
        'Comment ça s\'est passé ?',
        'Prends 30 secondes pour faire le point sur ton dernier moment.',
        tzWhen,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId, _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Sur desktop ou si la perm n'est pas accordée, on swallow l'erreur :
      // le bandeau in-app reste le mécanisme principal.
    }
  }

  Future<void> cancelAll() async {
    await plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await plugin.cancel(id);
  }
}