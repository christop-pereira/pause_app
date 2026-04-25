import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../database/app_database.dart';
import '../models/event_model.dart';
import '../models/pending_questionnaire_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/pending_provider.dart';
import '../services/notification_service.dart';

/// Écran de débrief multi-questionnaires.
/// Prend la liste des pendings dus au moment d'ouvrir l'écran et les fait
/// remplir un par un, avec une progression "1/3", "2/3"...
/// Quand tous sont traités, ferme et revient au HomeScreen.
class DebriefScreen extends StatefulWidget {
  const DebriefScreen({super.key});

  @override
  State<DebriefScreen> createState() => _DebriefScreenState();
}

class _DebriefScreenState extends State<DebriefScreen> {
  late List<PendingQuestionnaire> _queue;
  int _index = 0;

  bool? _success;
  String? _reason;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // On capture la liste à l'ouverture pour avoir une queue stable
    _queue = List.of(context.read<PendingProvider>().due);
  }

  PendingQuestionnaire get _current => _queue[_index];

  void _resetForNext() {
    setState(() {
      _success = null;
      _reason = null;
      _saving = false;
    });
  }

  Future<void> _save() async {
    if (_success == null) return;
    if (_success == false && _reason == null) return;

    setState(() => _saving = true);

    final p = _current;

    final event = EventModel(
      triggerId: p.triggerId,
      date: DateFormat('yyyy-MM-dd HH:mm').format(p.dueAt),
      success: _success! ? 1 : 0,
      reason: _reason,
    );

    await AppDatabase.instance.insertEvent(event.toMap());

    // Retire de la file et de la DB
    if (mounted) {
      await context.read<PendingProvider>().remove(p.id);
    }
    // Annule la notif système éventuellement encore en attente
    NotificationService.instance.cancel(100000 + p.id);

    if (!mounted) return;

    if (_index + 1 < _queue.length) {
      setState(() => _index += 1);
      _resetForNext();
    } else {
      // Tout traité → on rafraîchit le dashboard et on sort
      if (mounted) {
        await context.read<DashboardProvider>().load();
      }
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _skipAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Reporter à plus tard ?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Tes débriefs en attente resteront accessibles depuis l\'écran d\'accueil.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Plus tard',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final total = _queue.length;
    final p = _current;
    final timeStr = DateFormat('HH:mm').format(p.dueAt);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header avec progression ──
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                        child: Text('🎯', style: TextStyle(fontSize: 24))),
                  ),
                  const Spacer(),
                  if (total > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        '${_index + 1} / $total',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textSecondary),
                    onPressed: _skipAll,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Comment ça s\'est\npassé ?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                  height: 1.2,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Contexte du moment débriefé
              Text(
                'Moment de $timeStr · ${p.triggerLabel}',
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.5),
              ),
              const SizedBox(height: 36),

              // ── Choix succès / échec ──
              Row(
                children: [
                  _outcomeCard(
                    emoji: '💪',
                    label: 'J\'ai résisté !',
                    color: AppTheme.success,
                    selected: _success == true,
                    onTap: () => setState(() {
                      _success = true;
                      _reason = null;
                    }),
                  ),
                  const SizedBox(width: 12),
                  _outcomeCard(
                    emoji: '😔',
                    label: 'J\'ai craqué',
                    color: AppTheme.danger,
                    selected: _success == false,
                    onTap: () => setState(() => _success = false),
                  ),
                ],
              ),

              if (_success == false) ...[
                const SizedBox(height: 28),
                const Text(
                  'QU\'EST-CE QUI S\'EST PASSÉ ?',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.8,
                    shrinkWrap: true,
                    children: List.generate(
                        AppConstants.failReasons.length, (i) {
                      final r = AppConstants.failReasons[i];
                      final emoji = AppConstants.failReasonsEmoji[i];
                      final selected = _reason == r;
                      return GestureDetector(
                        onTap: () => setState(() => _reason = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.danger.withOpacity(0.15)
                                : AppTheme.surfaceHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.danger.withOpacity(0.5)
                                  : AppTheme.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(emoji,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                r,
                                style: TextStyle(
                                  color: selected
                                      ? AppTheme.danger
                                      : AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ] else
                const Spacer(),

              const SizedBox(height: 16),
              if (_canSave) _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSave =>
      _success == true || (_success == false && _reason != null);

  Widget _buildSaveButton() {
    final isLast = _index + 1 >= _queue.length;
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _success == true ? AppTheme.success : AppTheme.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(
                  isLast ? 'Valider' : 'Suivant',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _outcomeCard({
    required String emoji,
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : AppTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}