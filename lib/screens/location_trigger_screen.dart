import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/trigger_model.dart';
import '../providers/trigger_provider.dart';
import '../services/location_service.dart';
import 'package:provider/provider.dart';

class LocationTriggerScreen extends StatefulWidget {
  const LocationTriggerScreen({super.key});

  @override
  State<LocationTriggerScreen> createState() => _LocationTriggerScreenState();
}

class _LocationTriggerScreenState extends State<LocationTriggerScreen> {
  Position? position;

  Future<void> getLocation() async {
    position = await LocationService.getCurrent();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TriggerProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Trigger Lieu")),
      body: Column(
        children: [
          Text(position == null
              ? "Chargement..."
              : "Lat: ${position!.latitude}"),
          ElevatedButton(
            onPressed: () {
              if (position == null) return;

              final trigger = TriggerModel(
                id: const Uuid().v4(),
                type: "location",
                label: "Lieu trigger",
                lat: position!.latitude,
                lng: position!.longitude,
              );

              provider.add(trigger);
              Navigator.pop(context);
            },
            child: const Text("Sauvegarder lieu"),
          ),
        ],
      ),
    );
  }
}