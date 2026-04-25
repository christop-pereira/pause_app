import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/pending_questionnaire_model.dart';

/// Maintient la liste des questionnaires en attente de débrief.
/// Tick toutes les 10s pour faire passer un pending de "future" à "due"
/// quand son dueAt est atteint, sans qu'on ait à attendre une action user.
class PendingProvider extends ChangeNotifier {
  List<PendingQuestionnaire> _all = [];
  Timer? _ticker;

  /// Pendings actifs (dueAt atteint) → ce sont eux qu'on montre dans le bandeau
  List<PendingQuestionnaire> get due =>
      _all.where((p) => p.isDue).toList();

  bool get hasDue => due.isNotEmpty;

  Future<void> load() async {
    final rows = await AppDatabase.instance.getAllPending();
    _all = rows.map(PendingQuestionnaire.fromMap).toList();
    notifyListeners();
  }

  /// Démarrage du ticker pour rafraîchir l'état "due" en continu
  void startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      // On notifie sans recharger la DB : isDue est calculé à la volée
      notifyListeners();
    });
  }

  void stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> remove(int id) async {
    await AppDatabase.instance.deletePending(id);
    _all.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Appelé après ajout en DB d'un nouveau pending par le FakeCallScreen
  Future<void> refresh() => load();

  @override
  void dispose() {
    stopTicker();
    super.dispose();
  }
}