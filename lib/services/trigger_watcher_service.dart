import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../database/app_database.dart';
import '../models/trigger_model.dart';

class TriggerWatcherService {
  TriggerWatcherService._();
  static final TriggerWatcherService instance = TriggerWatcherService._();

  StreamSubscription<Position>? _positionSub;
  Timer? _secondTimer;

  // Clé = triggerId_YYYY-MM-DD_HH:mm  → un trigger ne fire qu'une seule fois pour
  // un couple (jour, minute) donné. La présence de la date dans la clé garantit
  // qu'un trigger à 09:00 peut se redéclencher chaque jour à 09:00.
  final Set<String> _firedKeys = {};

  void Function(String triggerId, String triggerLabel)? onTrigger;

  // Idempotent : appelable plusieurs fois sans casser quoi que ce soit.
  // Idéal pour un singleton qui peut être démarré depuis plusieurs HomeScreen
  // au cours du cycle de vie de l'app (hot reload, pushAndRemoveUntil, etc.).
  void start() {
    if (_secondTimer == null) _startSecondTimer();
    if (_positionSub == null) _startLocationWatch();
  }

  void stop() {
    _secondTimer?.cancel();
    _secondTimer = null;
    _positionSub?.cancel();
    _positionSub = null;
  }

  // ── Timer seconde ──────────────────────────────────────
  // Tick chaque seconde. On lit la DB à chaque tick (SQLite local, pas cher).
  // L'anti-doublon est entièrement géré par _firedKeys → si l'utilisateur ajoute
  // ou modifie un trigger en cours de minute, le watcher voit l'état à jour à la
  // seconde près.
  void _startSecondTimer() {
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkTimeTriggers(DateTime.now());
    });
  }

  Future<void> _checkTimeTriggers(DateTime now) async {
    final todayWeekday = now.weekday - 1; // 0=lun..6=dim
    final dayStr = now.toIso8601String().substring(0, 10);
    final currentMinute =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    try {
      final triggers = await AppDatabase.instance.getTriggers();
      for (final raw in triggers) {
        final t = TriggerModel.fromMap(raw);
        if (t.active == 0) continue;
        if (t.type == 'location') continue;
        if (t.time == null) continue;
        if (t.daysList.isNotEmpty && !t.daysList.contains(todayWeekday)) continue;
        if (t.time != currentMinute) continue;

        // Anti-doublon : une seule fois par jour+heure programmée
        final key = '${t.id}_${dayStr}_$currentMinute';
        if (_firedKeys.contains(key)) continue;
        _firedKeys.add(key);

        onTrigger?.call(t.id, t.label);
      }
    } catch (_) {}

    // Nettoyage : on garde uniquement les clés du jour courant
    _firedKeys.removeWhere((k) => !k.contains(dayStr));
  }

  // ── Localisation ──────────────────────────────────────
  void _startLocationWatch() {
    try {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen(
        (pos) => _checkLocationTriggers(pos.latitude, pos.longitude),
        onError: (_) {},
      );
    } catch (_) {}
  }

  Future<void> _checkLocationTriggers(double lat, double lng) async {
    final now = DateTime.now();
    final dayStr = now.toIso8601String().substring(0, 10);
    // Anti-doublon GPS : une fois par tranche de 10 min, par trigger
    final tenMinKey = now.toIso8601String().substring(0, 15);

    try {
      final triggers = await AppDatabase.instance.getTriggers();
      for (final raw in triggers) {
        final t = TriggerModel.fromMap(raw);
        if (t.active == 0) continue;
        if (t.type == 'time') continue;
        if (t.lat == null || t.lng == null) continue;

        final dist = Geolocator.distanceBetween(lat, lng, t.lat!, t.lng!);
        if (dist > t.radius) continue;

        final key = '${t.id}_$tenMinKey';
        if (_firedKeys.contains(key)) continue;
        _firedKeys.add(key);

        onTrigger?.call(t.id, t.label);
      }
    } catch (_) {}

    // Nettoyage aussi côté localisation pour ne pas accumuler indéfiniment
    _firedKeys.removeWhere((k) => !k.contains(dayStr));
  }
}