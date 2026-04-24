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
  const AddTriggerScreen({super.key});

  @override
  State<AddTriggerScreen> createState() => _AddTriggerScreenState();
}

class _AddTriggerScreenState extends State<AddTriggerScreen> {
  TriggerType _type = TriggerType.time;
  final _labelController = TextEditingController();
  List<int> _selectedDays = [];
  TimeOfDay _time = TimeOfDay.now();
  double? _lat;
  double? _lng;
  String? _locationName;
  bool _saving = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _lat = result['lat'];
        _lng = result['lng'];
        _locationName = result['name'];
      });
    }
  }

  bool get _isValid {
    if (_labelController.text.trim().isEmpty) return false;
    if (_type == TriggerType.time || _type == TriggerType.both) {
      // Pas de validation supplémentaire pour l'heure
    }
    if (_type == TriggerType.location || _type == TriggerType.both) {
      if (_lat == null || _lng == null) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() => _saving = true);

    final typeStr = _type == TriggerType.time
        ? 'time'
        : _type == TriggerType.location
            ? 'location'
            : 'both';

    final trigger = TriggerModel(
      id: const Uuid().v4(),
      type: typeStr,
      label: _labelController.text.trim(),
      days: _selectedDays.isEmpty ? null : _selectedDays.join(','),
      time: (_type == TriggerType.time || _type == TriggerType.both)
          ? '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'
          : null,
      lat: _lat,
      lng: _lng,
    );

    await context.read<TriggerProvider>().add(trigger);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau trigger'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              _sectionTitle('Type de trigger'),
              const SizedBox(height: 12),
              _typeSelector(),
              const SizedBox(height: 28),

              // Label
              _sectionTitle('Nom du trigger'),
              const SizedBox(height: 12),
              TextField(
                controller: _labelController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: _type == TriggerType.location
                      ? 'Ex : McDo Lignon, Supermarché...'
                      : 'Ex : Pause café du soir, Trajet retour...',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 28),

              // Time section
              if (_type == TriggerType.time || _type == TriggerType.both) ...[
                _sectionTitle('Heure'),
                const SizedBox(height: 12),
                _timePicker(),
                const SizedBox(height: 20),
                _sectionTitle('Jours concernés'),
                const SizedBox(height: 4),
                const Text(
                  'Laisse vide pour tous les jours',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                DaySelector(
                  selectedDays: _selectedDays,
                  onChanged: (days) => setState(() => _selectedDays = days),
                ),
                const SizedBox(height: 28),
              ],

              // Location section
              if (_type == TriggerType.location || _type == TriggerType.both) ...[
                _sectionTitle('Lieu'),
                const SizedBox(height: 12),
                _locationPicker(),
                const SizedBox(height: 28),
              ],

              // Save button
              PauButton(
                label: 'Enregistrer le trigger',
                onTap: _isValid ? _save : null,
                isLoading: _saving,
                color: _isValid ? AppTheme.primary : AppTheme.surfaceHigh,
                textColor: _isValid ? Colors.white : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );

  Widget _typeSelector() {
    return Row(
      children: [
        _typeChip(TriggerType.time, Icons.access_time_rounded, 'Heure'),
        const SizedBox(width: 10),
        _typeChip(TriggerType.location, Icons.location_on_rounded, 'Lieu'),
        const SizedBox(width: 10),
        _typeChip(TriggerType.both, Icons.merge_type_rounded, 'Les deux'),
      ],
    );
  }

  Widget _typeChip(TriggerType t, IconData icon, String label) {
    final selected = _type == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withOpacity(0.15) : AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppTheme.primary : AppTheme.textSecondary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timePicker() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              _time.format(context),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.edit_rounded, color: AppTheme.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _locationPicker() {
    return GestureDetector(
      onTap: _pickLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _lat != null
              ? AppTheme.warning.withOpacity(0.08)
              : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _lat != null ? AppTheme.warning.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _lat != null ? Icons.location_on_rounded : Icons.add_location_outlined,
              color: _lat != null ? AppTheme.warning : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _locationName ?? 'Sélectionner un lieu',
                style: TextStyle(
                  color: _lat != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 15,
                  fontWeight: _lat != null ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}