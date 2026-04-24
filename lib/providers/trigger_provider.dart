import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/trigger_model.dart';
import '../services/scheduler_service.dart';

class TriggerProvider extends ChangeNotifier {
  List<TriggerModel> triggers = [];

  Future<void> load() async {
    final data = await AppDatabase.instance.getTriggers();
    triggers = data.map((e) => TriggerModel.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> add(TriggerModel trigger) async {
    await AppDatabase.instance.insertTrigger(trigger.toMap());
    await load();
    await _reschedule();
  }

  Future<void> toggleActive(String id) async {
    final t = triggers.firstWhere((t) => t.id == id);
    final newActive = t.active == 1 ? 0 : 1;
    await AppDatabase.instance.updateTriggerActive(id, newActive);
    await load();
    await _reschedule();
  }

  Future<void> delete(String id) async {
    await AppDatabase.instance.deleteTrigger(id);
    await load();
    await _reschedule();
  }

  Future<void> _reschedule() async {
    await SchedulerService.instance.rescheduleAll(triggers);
  }

  int get count => triggers.length;
  int get activeCount => triggers.where((t) => t.active == 1).length;
}