import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/trigger_model.dart';
import '../providers/trigger_provider.dart';
import '../screens/add_trigger_screen.dart';

class TriggerTile extends StatelessWidget {
  final TriggerModel trigger;

  const TriggerTile({super.key, required this.trigger});

  String get _subtitle {
    if (trigger.type == 'time' || trigger.type == 'both') {
      final days = trigger.daysList;
      final daysLabel = days.isEmpty ? 'Tous les jours' : days.map((i) => AppConstants.weekDays[i]).join(', ');
      final time = trigger.time ?? '';
      final locPart = (trigger.type == 'both' && trigger.locationName != null) ? ' · ${trigger.locationName}' : '';
      return '$daysLabel · $time$locPart';
    }
    return trigger.locationName ?? 'Détection de position';
  }

  IconData get _icon {
    switch (trigger.type) {
      case 'location': return Icons.location_on_rounded;
      case 'both': return Icons.merge_type_rounded;
      default: return Icons.access_time_rounded;
    }
  }

  Color get _iconColor {
    switch (trigger.type) {
      case 'location': return AppTheme.warning;
      case 'both': return AppTheme.primary;
      default: return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TriggerProvider>();
    final isActive = trigger.active == 1;

    return Dismissible(
      key: Key(trigger.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Supprimer ?', style: TextStyle(color: AppTheme.textPrimary)),
            content: Text('${trigger.label} sera supprimé.', style: const TextStyle(color: AppTheme.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: AppTheme.danger))),
            ],
          ),
        );
      },
      onDismissed: (_) => provider.delete(trigger.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 22),
      ),
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTriggerScreen(existing: trigger)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isActive ? AppTheme.border : AppTheme.border.withOpacity(0.4)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: _iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(_icon, color: _iconColor, size: 20),
              ),
              title: Text(trigger.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(_subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ),
              trailing: Switch(
                value: isActive,
                onChanged: (_) => provider.toggleActive(trigger.id),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
