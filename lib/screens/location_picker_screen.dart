import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/app_theme.dart';
import '../widgets/pau_button.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialName;

  const LocationPickerScreen({super.key, this.initialLat, this.initialLng, this.initialName});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _selectedPoint;
  String _placeName = '';
  bool _loadingLocation = true;
  bool _searchLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedPoint = LatLng(widget.initialLat!, widget.initialLng!);
      _placeName = widget.initialName ?? '';
      _loadingLocation = false;
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        setState(() {
          _selectedPoint = const LatLng(46.2044, 6.1432); // Genève par défaut
          _loadingLocation = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _selectedPoint = point;
        _loadingLocation = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(point, 16);
      });
      await _reverseGeocode(point);
    } catch (_) {
      setState(() {
        _selectedPoint = const LatLng(46.2044, 6.1432);
        _loadingLocation = false;
      });
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json&accept-language=fr';
      final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'PauseApp/2.0'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final parts = <String>[];
        if (addr['amenity'] != null) parts.add(addr['amenity']);
        else if (addr['shop'] != null) parts.add(addr['shop']);
        else if (addr['road'] != null) parts.add(addr['road']);
        if (addr['city'] != null) parts.add(addr['city']);
        else if (addr['town'] != null) parts.add(addr['town']);
        else if (addr['village'] != null) parts.add(addr['village']);
        if (mounted) setState(() => _placeName = parts.isNotEmpty ? parts.join(', ') : 'Lieu sélectionné');
      }
    } catch (_) {
      if (mounted) setState(() => _placeName = 'Lieu sélectionné');
    }
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().length < 3) {
      setState(() { _searchResults = []; _showResults = false; });
      return;
    }
    setState(() => _searchLoading = true);
    try {
      final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&accept-language=fr';
      final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'PauseApp/2.0'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _searchResults = data.cast<Map<String, dynamic>>();
          _showResults = _searchResults.isNotEmpty;
        });
      }
    } catch (_) {}
    setState(() => _searchLoading = false);
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat'].toString()) ?? 0;
    final lng = double.tryParse(result['lon'].toString()) ?? 0;
    final point = LatLng(lat, lng);
    setState(() {
      _selectedPoint = point;
      _placeName = result['display_name']?.toString().split(',').take(2).join(', ') ?? 'Lieu';
      _searchController.text = _placeName;
      _showResults = false;
    });
    _mapController.move(point, 16);
  }

  void _onMapTap(TapPosition _, LatLng point) {
    setState(() { _selectedPoint = point; _placeName = ''; });
    _reverseGeocode(point);
  }

  void _confirm() {
    if (_selectedPoint == null) return;
    Navigator.pop(context, {
      'lat': _selectedPoint!.latitude,
      'lng': _selectedPoint!.longitude,
      'name': _placeName.isNotEmpty ? _placeName : 'Lieu sélectionné',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Choisir un lieu'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: _loadingLocation
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                SizedBox(height: 14),
                Text('Localisation en cours…', style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ))
          : Stack(
              children: [
                // Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPoint ?? const LatLng(46.2044, 6.1432),
                    initialZoom: 15,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.pause.app',
                    ),
                    if (_selectedPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint!,
                            width: 60,
                            height: 60,
                            child: Column(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 10)],
                                  ),
                                ),
                                Container(width: 2, height: 12, color: AppTheme.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (_selectedPoint != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _selectedPoint!,
                            radius: 150,
                            useRadiusInMeter: true,
                            color: AppTheme.primary.withOpacity(0.1),
                            borderColor: AppTheme.primary.withOpacity(0.4),
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                  ],
                ),

                // Barre de recherche (top)
                Positioned(
                  top: 14,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)],
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 14),
                              child: Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                                decoration: const InputDecoration(
                                  hintText: 'Rechercher un lieu…',
                                  border: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                onChanged: _searchPlace,
                              ),
                            ),
                            if (_searchLoading)
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                              )
                            else if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() { _searchResults = []; _showResults = false; });
                                },
                              ),
                          ],
                        ),
                      ),
                      if (_showResults) ...[
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)],
                          ),
                          child: Column(
                            children: _searchResults.map((r) {
                              final name = r['display_name']?.toString().split(',').take(3).join(', ') ?? '';
                              return InkWell(
                                onTap: () => _selectSearchResult(r),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.place_rounded, color: AppTheme.textSecondary, size: 16),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Panel bas
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(top: BorderSide(color: AppTheme.border)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 14),
                        if (_selectedPoint != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppTheme.warning, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _placeName.isNotEmpty ? _placeName : 'Chargement…',
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const SizedBox(width: 26),
                              Text(
                                'Rayon de détection : 150m',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          PauButton(label: 'Confirmer ce lieu', onTap: _confirm, icon: Icons.check_rounded),
                        ] else ...[
                          const Text('Touche la carte pour placer un repère', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
