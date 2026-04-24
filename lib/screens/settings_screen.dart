import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import '../providers/trigger_provider.dart';
import '../screens/fake_call_screen.dart';
import '../widgets/pau_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  bool _editingName = false;

  @override
  void initState() {
    super.initState();
    final name = context.read<AppProvider>().userName;
    _nameController = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio(AppProvider provider) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      await provider.setAudio(result.files.single.path!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio mis à jour ✓'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveName(AppProvider provider) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await provider.setName(name);
    setState(() => _editingName = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom mis à jour ✓'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _testCall(BuildContext context, TriggerProvider triggers) {
    final id = triggers.triggers.isNotEmpty ? triggers.triggers.first.id : 'test';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FakeCallScreen(triggerId: id, triggerLabel: 'Test PAUSE'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final triggerProvider = context.watch<TriggerProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profil',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text('Personnalise ton expérience PAUSE', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 32),

              // Profile card
              _sectionLabel('TON PRÉNOM'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: _editingName
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              autofocus: true,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Ton prénom',
                                border: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _saveName(provider),
                            child: const Text('Sauvegarder'),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _editingName = false),
                            child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Icon(Icons.person_rounded, color: AppTheme.primary, size: 20)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              provider.userName.isNotEmpty ? provider.userName : 'Non défini',
                              style: TextStyle(
                                color: provider.userName.isNotEmpty ? AppTheme.textPrimary : AppTheme.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: AppTheme.textSecondary, size: 18),
                            onPressed: () => setState(() => _editingName = true),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 28),

              // Audio
              _sectionLabel('MESSAGE AUDIO'),
              const SizedBox(height: 4),
              const Text(
                'Ce message sera joué lors de chaque appel PAUSE',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _pickAudio(provider),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: provider.hasAudio
                        ? AppTheme.success.withOpacity(0.07)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: provider.hasAudio
                          ? AppTheme.success.withOpacity(0.35)
                          : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (provider.hasAudio ? AppTheme.success : AppTheme.primary).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          provider.hasAudio ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: provider.hasAudio ? AppTheme.success : AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.hasAudio ? 'Audio configuré' : 'Aucun audio sélectionné',
                              style: TextStyle(
                                color: provider.hasAudio ? AppTheme.success : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (provider.hasAudio)
                              Text(
                                provider.audioPath.split('/').last,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Test call
              _sectionLabel('TESTER'),
              const SizedBox(height: 10),
              PauButton(
                label: 'Simuler un appel PAUSE',
                icon: Icons.call_rounded,
                onTap: () => _testCall(context, triggerProvider),
                outlined: true,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Permet de tester le faux appel et ton message audio.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Stats résumé
              _sectionLabel('RÉCAPITULATIF'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem('Triggers', '${triggerProvider.count}', Icons.bolt_rounded, AppTheme.primary),
                    _divider(),
                    _summaryItem('Actifs', '${triggerProvider.activeCount}', Icons.check_circle_outline_rounded, AppTheme.success),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(
    t,
    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
  );

  Widget _summaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 48, color: AppTheme.border);
}