import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/app_theme.dart';
import '../services/location_service.dart';
import '../widgets/pau_button.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  Position? _position;
  String? _placeName;
  bool _loading = true;
  String? _error;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() { _loading = true; _error = null; });
    try {
      final pos = await LocationService.getCurrent();
      final name = await LocationService.getPlaceName(pos.latitude, pos.longitude);
      setState(() {
        _position = pos;
        _placeName = name;
        _nameController.text = name;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _confirm() {
    if (_position == null) return;
    Navigator.pop(context, {
      'lat': _position!.latitude,
      'lng': _position!.longitude,
      'name': _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : _placeName ?? 'Lieu',
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un lieu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? _buildLoading()
              : _error != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
          SizedBox(height: 16),
          Text('Récupération de ta position...', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_off_rounded, color: AppTheme.danger, size: 48),
          const SizedBox(height: 16),
          const Text('Localisation impossible', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          PauButton(label: 'Réessayer', onTap: _getLocation, width: 160),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Position card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.my_location_rounded, color: AppTheme.success, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Position actuelle détectée', style: TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _getLocation,
                child: const Text('Rafraîchir', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Name field
        const Text(
          'NOM DU LIEU',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        const Text(
          'Personnalise le nom pour te repérer facilement',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Ex : McDo Lignon, Supermarché Casino...',
            prefixIcon: Icon(Icons.location_on_rounded, color: AppTheme.warning, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Un rayon de 150m autour de ce point déclenchera l\'appel PAUSE.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        PauButton(
          label: 'Confirmer ce lieu',
          onTap: _confirm,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }
}