import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/pau_button.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  String? _audioPath;
  String? _audioName;
  int _step = 0;
  bool _saving = false;

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioPath = result.files.single.path;
        _audioName = result.files.single.name;
      });
    }
  }

  Future<void> _finish() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await context.read<AppProvider>().saveUser(
      _nameController.text.trim(),
      _audioPath,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Logo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Text('⏸', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step == 0 ? _buildStep0() : _buildStep1(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bienvenue\nsur PAUSE',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -1,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Une application pour reprendre le contrôle\nde tes comportements automatiques.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 48),
        const Text(
          'Comment tu t\'appelles ?',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
          decoration: const InputDecoration(hintText: 'Ton prénom'),
          onSubmitted: (_) => _goStep1(),
        ),
        const SizedBox(height: 28),
        PauButton(
          label: 'Continuer',
          onTap: _goStep1,
          icon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }

  void _goStep1() {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _step = 1);
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salut ${_nameController.text.trim()} 👋',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Enregistre un message audio que tu entendras\nlors de chaque appel PAUSE.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ex : "Stop. Respire. Est-ce que tu as vraiment faim ?"',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 36),
        // Audio picker card
        GestureDetector(
          onTap: _pickAudio,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _audioPath != null
                  ? AppTheme.success.withOpacity(0.08)
                  : AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _audioPath != null
                    ? AppTheme.success.withOpacity(0.4)
                    : AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (_audioPath != null ? AppTheme.success : AppTheme.primary)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _audioPath != null
                        ? Icons.check_circle_outline_rounded
                        : Icons.mic_none_rounded,
                    color: _audioPath != null ? AppTheme.success : AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _audioPath != null ? 'Fichier sélectionné' : 'Choisir un fichier audio',
                        style: TextStyle(
                          color: _audioPath != null ? AppTheme.success : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _audioName ?? 'MP3, WAV, M4A...',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
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
        const SizedBox(height: 32),
        PauButton(
          label: _audioPath != null ? 'C\'est parti !' : 'Passer cette étape',
          onTap: _finish,
          isLoading: _saving,
          color: _audioPath != null ? AppTheme.primary : AppTheme.surfaceHigh,
          textColor: _audioPath != null ? Colors.white : AppTheme.textSecondary,
        ),
        if (_audioPath != null) ...[
          const SizedBox(height: 12),
          PauButton(
            label: 'Changer le fichier',
            onTap: _pickAudio,
            outlined: true,
          ),
        ],
      ],
    );
  }
}