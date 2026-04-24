import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../database/app_database.dart';
import '../models/event_model.dart';
import 'home_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  final String triggerId;

  const QuestionnaireScreen({super.key, required this.triggerId});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  bool? _success;
  String? _reason;
  bool _saving = false;

  Future<void> _save() async {
    if (_success == null) return;
    if (_success == false && _reason == null) return;

    setState(() => _saving = true);

    final event = EventModel(
      triggerId: widget.triggerId,
      date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      success: _success! ? 1 : 0,
      reason: _reason,
    );

    await AppDatabase.instance.insertEvent(event.toMap());
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('🎯', style: TextStyle(fontSize: 24))),
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
              const Text(
                'Sois honnête avec toi-même. Chaque réponse t\'aide à progresser.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 36),

              // Choix succès / échec
              Row(
                children: [
                  _outcomeCard(
                    emoji: '💪',
                    label: 'J\'ai résisté !',
                    color: AppTheme.success,
                    selected: _success == true,
                    onTap: () => setState(() { _success = true; _reason = null; }),
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

              // Raisons si échec
              if (_success == false) ...[
                const SizedBox(height: 28),
                const Text(
                  'QU\'EST-CE QUI S\'EST PASSÉ ?',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.8,
                    shrinkWrap: true,
                    children: List.generate(AppConstants.failReasons.length, (i) {
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
                              color: selected ? AppTheme.danger.withOpacity(0.5) : AppTheme.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                r,
                                style: TextStyle(
                                  color: selected ? AppTheme.danger : AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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

              // Bouton valider
              const SizedBox(height: 16),
              _canSave
                  ? _buildSaveButton()
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSave => _success == true || (_success == false && _reason != null);

  Widget _buildSaveButton() {
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
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text(
                  'Valider',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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