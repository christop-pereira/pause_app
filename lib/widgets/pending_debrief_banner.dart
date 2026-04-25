import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/pending_provider.dart';
import '../screens/debrief_screen.dart';

/// Bandeau qui apparaît en haut du HomeScreen quand au moins un questionnaire
/// est dû. Adaptif : "Comment ça s'est passé ?" pour 1 moment, "X moments à
/// débriefer" pour plusieurs. Un seul tap suffit pour ouvrir le débrief.
class PendingDebriefBanner extends StatelessWidget {
  const PendingDebriefBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<PendingProvider>();
    if (!pending.hasDue) return const SizedBox.shrink();

    final count = pending.due.length;
    final isMulti = count > 1;
    final title = isMulti
        ? '$count moments à débriefer'
        : 'Comment ça s\'est passé ?';
    final subtitle = isMulti
        ? 'Prends quelques minutes pour faire le point'
        : 'Prends 30 secondes pour faire le point';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDebrief(context),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.18),
                  AppTheme.primary.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.35),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🎯', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDebrief(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DebriefScreen()),
    );
  }
}