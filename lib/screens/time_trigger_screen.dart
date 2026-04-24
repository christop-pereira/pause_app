import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/trigger_model.dart';
import '../providers/trigger_provider.dart';
import 'package:provider/provider.dart';

class TimeTriggerScreen extends StatefulWidget {
  const TimeTriggerScreen({super.key});

  @override
  State<TimeTriggerScreen> createState() => _TimeTriggerScreenState();
}

class _TimeTriggerScreenState extends State<TimeTriggerScreen> {
  TimeOfDay time = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TriggerProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Trigger Heure")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          TextButton(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );

              if (picked != null) {
                setState(() => time = picked);
              }
            },
            child: Text("Heure: ${time.format(context)}"),
          ),
          ElevatedButton(
            onPressed: () {
              final trigger = TriggerModel(
                id: const Uuid().v4(),
                type: "time",
                label: "Trigger ${time.format(context)}",
                time: "${time.hour}:${time.minute}",
              );

              provider.add(trigger);
              Navigator.pop(context);
            },
            child: const Text("Sauvegarder"),
          ),
        ],
      ),
    );
  }
}