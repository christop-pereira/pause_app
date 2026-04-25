import '../models/trigger_model.dart';

class SchedulerService {
  SchedulerService._();
  static final SchedulerService instance = SchedulerService._();

  Future<void> init() async {
    // Rien à initialiser - timezone géré séparément si besoin
  }

 Future<void> rescheduleAll(List<TriggerModel> triggers) async {
    return;
  }
}
