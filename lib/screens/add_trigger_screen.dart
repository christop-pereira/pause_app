import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/app_theme.dart';
import '../models/trigger_model.dart';
import '../providers/trigger_provider.dart';
import '../widgets/day_selector.dart';
import '../widgets/pau_button.dart';
import 'location_picker_screen.dart';

enum TriggerType { time, location, both }

class AddTriggerScreen extends StatefulWidget {
  final TriggerModel? existing;
  const AddTriggerScreen({super.key, this.existing});

  @override
  State<AddTriggerScreen> createState() => _AddTriggerScreenState();
}

class _AddTriggerScreenState extends State<AddTriggerScreen> {
  late TriggerType _type;
  late TextEditingController _labelController;
  late List<int> _selectedDays;
  late TimeOfDay _time;
  double? _lat;
  double? _lng;
  String? _locationName;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.type == 'location'
          ? TriggerType.location
          : e.type == 'both'
              ? TriggerType.both
              : TriggerType.time;
      _labelController = TextEditingController(text: e.label);
      _selectedDays = List<int>.from(e.daysList);
      if (e.time != null) {
        final parts = e.time!.split(':');
        _time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      } else {
        _time = TimeOfDay.now();
      }
      _lat = e.lat;
      _lng = e.lng;
      _locationName = e.locationName;
    } else {
      _type = TriggerType.time;
      _labelController = TextEditingController();
      _selectedDays = [];
      _time = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          timePickerTheme: const TimePickerThemeData(backgroundColor: AppTheme.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _lat,
          initialLng: _lng,
          initialName: _locationName,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _lat = result['lat'] as double?;
        _lng = result['lng'] as double?;
        _locationName = result['name'] as String?;
      });
    }
  }

  bool get _isValid {
    if (_labelController.text.trim().isEmpty) return false;
    if (_type == TriggerType.location || _type == TriggerType.both) {
      if (_lat == null || _lng == null) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);

    try {
      final typeStr = _type == TriggerType.time
          ? 'time'
          : _type == TriggerType.location
              ? 'location'
              : 'both';

      final timeStr = (_type == TriggerType.time || _type == TriggerType.both)
          ? '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'
          : null;

      final daysStr = _selectedDays.isEmpty ? null : _selectedDays.join(',');

      final provider = context.read<TriggerProvider>();

      if (_isEditing) {
        final updated = TriggerModel(
          id: widget.existing!.id,
          type: typeStr,
          label: _labelController.text.trim(),
          days: daysStr,
          time: timeStr,
          lat: _lat,
          lng: _lng,
          locationName: _locationName,
          active: widget.existing!.active,
        );
        await provider.update(updated);
      } else {
        final trigger = TriggerModel(
          id: const Uuid().v4(),
          type: typeStr,
          label: _labelController.text.trim(),
          days: daysStr,
          time: timeStr,
          lat: _lat,
          lng: _lng,
          locationName: _locationName,
        );
        await provider.add(trigger);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Supprimer ce trigger ?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('${widget.existing!.label} sera définitivement supprimé.',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<TriggerProvider>().delete(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le trigger' : 'Nouveau trigger'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                  onPressed: _confirmDelete,
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('TYPE DE TRIGGER'),
              const SizedBox(height: 12),
              _typeSelector(),
              const SizedBox(height: 28),

              _label('NOM DU TRIGGER'),
              const SizedBox(height: 12),
              TextField(
                controller: _labelController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: _type == TriggerType.location
                      ? 'Ex : McDo Lignon, Supermarché…'
                      : 'Ex : Pause café du soir…',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 28),

              if (_type == TriggerType.time || _type == TriggerType.both) ...[
                _label('HEURE'),
                const SizedBox(height: 12),
                _timePicker(),
                const SizedBox(height: 20),
                _label('JOURS CONCERNÉS'),
                const SizedBox(height: 4),
                const Text('Laisse vide pour tous les jours',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 12),
                DaySelector(
                  selectedDays: _selectedDays,
                  onChanged: (d) => setState(() => _selectedDays = d),
                ),
                const SizedBox(height: 28),
              ],

              if (_type == TriggerType.location || _type == TriggerType.both) ...[
                _label('LIEU'),
                const SizedBox(height: 12),
                _locationWidget(),
                const SizedBox(height: 28),
              ],

              PauButton(
                label: _saving
                    ? 'Enregistrement…'
                    : _isEditing
                        ? 'Enregistrer les modifications'
                        : 'Créer le trigger',
                onTap: _isValid && !_saving ? _save : null,
                isLoading: _saving,
                color: _isValid && !_saving ? AppTheme.primary : AppTheme.surfaceHigh,
                textColor: _isValid && !_saving ? Colors.white : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8));

  Widget _typeSelector() => Row(children: [
        _typeChip(TriggerType.time, Icons.access_time_rounded, 'Heure'),
        const SizedBox(width: 10),
        _typeChip(TriggerType.location, Icons.location_on_rounded, 'Lieu'),
        const SizedBox(width: 10),
        _typeChip(TriggerType.both, Icons.merge_type_rounded, 'Les deux'),
      ]);

  Widget _typeChip(TriggerType t, IconData icon, String lbl) {
    final sel = _type == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? AppTheme.primary.withOpacity(0.15) : AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? AppTheme.primary : AppTheme.border, width: sel ? 1.5 : 1),
          ),
          child: Column(children: [
            Icon(icon, color: sel ? AppTheme.primary : AppTheme.textSecondary, size: 20),
            const SizedBox(height: 4),
            Text(lbl,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sel ? AppTheme.primary : AppTheme.textSecondary)),
          ]),
        ),
      ),
    );
  }

  Widget _timePicker() => GestureDetector(
        onTap: _pickTime,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border)),
          child: Row(children: [
            const Icon(Icons.access_time_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(_time.format(context),
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.edit_rounded, color: AppTheme.textSecondary, size: 16),
          ]),
        ),
      );

  Widget _locationWidget() => GestureDetector(
        onTap: _pickLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: _lat != null ? AppTheme.warning.withOpacity(0.08) : AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _lat != null ? AppTheme.warning.withOpacity(0.4) : AppTheme.border),
          ),
          child: Row(children: [
            Icon(
                _lat != null ? Icons.location_on_rounded : Icons.add_location_outlined,
                color: _lat != null ? AppTheme.warning : AppTheme.textSecondary,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _locationName ?? 'Sélectionner sur la carte',
                style: TextStyle(
                    color: _lat != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: _lat != null ? FontWeight.w500 : FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ]),
        ),
      );
}
