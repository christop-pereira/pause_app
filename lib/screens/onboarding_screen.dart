import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
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
  String? _photoPath;
  int _step = 0;
  bool _saving = false;

  // Enregistrement
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  Duration _recordDuration = Duration.zero;
  bool _recordingFinished = false;

  @override
  void dispose() {
    _nameController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioPath = result.files.single.path;
        _audioName = result.files.single.name;
        _recordingFinished = false;
      });
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/pause_onboarding_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() { _isRecording = true; _recordingPath = path; _recordDuration = Duration.zero; _recordingFinished = false; });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording || !mounted) return false;
      setState(() => _recordDuration += const Duration(seconds: 1));
      return true;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordingFinished = path != null;
      if (path != null) { _recordingPath = path; _audioPath = path; _audioName = 'Message enregistré'; }
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final img = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (img != null) setState(() => _photoPath = img.path);
  }

  Future<void> _finish() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await context.read<AppProvider>().saveUser(
      _nameController.text.trim(),
      _audioPath,
      photo: _photoPath,
    );
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  String get _durationStr {
    final m = _recordDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_recordDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
              const SizedBox(height: 52),
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: const Center(child: Text('⏸', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _step == 0 ? _buildStep0() : _step == 1 ? _buildStep1() : _buildStep2(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bienvenue\nsur PAUSE', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.9, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          const Text('Une app pour reprendre le contrôle de tes comportements automatiques.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5)),
          const SizedBox(height: 40),
          const Text('COMMENT TU T\'APPELLES ?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          TextField(controller: _nameController, autofocus: true, textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              decoration: const InputDecoration(hintText: 'Ton prénom'),
              onSubmitted: (_) => _goNext()),
          const SizedBox(height: 24),
          PauButton(label: 'Continuer', onTap: _goNext, icon: Icons.arrow_forward_rounded),
        ],
      ),
    );
  }

  void _goNext() {
    if (_step == 0 && _nameController.text.trim().isEmpty) return;
    setState(() => _step++);
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Salut ${_nameController.text.trim()} 👋', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.7, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          const Text('Enregistre le message que tu entendras lors de chaque appel PAUSE.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5)),
          const SizedBox(height: 28),

          // Enregistrer maintenant
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isRecording ? AppTheme.danger.withOpacity(0.07) : AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isRecording ? AppTheme.danger.withOpacity(0.3) : AppTheme.border),
            ),
            child: Column(
              children: [
                Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: (_isRecording ? AppTheme.danger : AppTheme.primary).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_isRecording ? Icons.fiber_manual_record_rounded : Icons.mic_rounded,
                        color: _isRecording ? AppTheme.danger : AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_isRecording ? 'Enregistrement…' : 'Enregistrer maintenant',
                        style: TextStyle(color: _isRecording ? AppTheme.danger : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                    if (_isRecording) Text(_durationStr, style: TextStyle(color: AppTheme.danger.withOpacity(0.7), fontSize: 12)),
                  ])),
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: (_isRecording ? AppTheme.danger : AppTheme.primary).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: _isRecording ? AppTheme.danger : AppTheme.primary, size: 22),
                    ),
                  ),
                ]),
                if (_recordingFinished && !_isRecording && _audioName == 'Message enregistré') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 16),
                        SizedBox(width: 6),
                        Text('Enregistrement prêt', style: TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('— ou —', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          const SizedBox(height: 12),

          // Importer un fichier
          GestureDetector(
            onTap: _pickAudio,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_audioPath != null && _audioName != 'Message enregistré') ? AppTheme.success.withOpacity(0.07) : AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (_audioPath != null && _audioName != 'Message enregistré') ? AppTheme.success.withOpacity(0.3) : AppTheme.border),
              ),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_audioName != null && _audioName != 'Message enregistré' ? _audioName! : 'Importer un fichier',
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                  const Text('MP3, WAV, M4A…', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ])),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
              ]),
            ),
          ),
          const SizedBox(height: 28),
          PauButton(label: _audioPath != null ? 'Continuer' : 'Passer cette étape', onTap: _goNext,
              color: _audioPath != null ? AppTheme.primary : AppTheme.surfaceHigh,
              textColor: _audioPath != null ? Colors.white : AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Une dernière chose', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.7, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          const Text('Ajoute une photo de profil — elle apparaîtra lors de l\'appel PAUSE.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5)),
          const SizedBox(height: 32),
          Center(
            child: Stack(children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2)),
                child: ClipOval(
                  child: _photoPath != null
                      ? Image.file(File(_photoPath!), fit: BoxFit.cover)
                      : Image.asset('assets/images/avatar.png', fit: BoxFit.cover),
                ),
              ),
              Positioned(right: 0, bottom: 0,
                child: GestureDetector(
                  onTap: () => showModalBottomSheet(context: context, backgroundColor: AppTheme.surface,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(height: 16),
                      ListTile(leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                          title: const Text('Prendre une photo', style: TextStyle(color: AppTheme.textPrimary)),
                          onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.camera); }),
                      ListTile(leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
                          title: const Text('Galerie', style: TextStyle(color: AppTheme.textPrimary)),
                          onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.gallery); }),
                      const SizedBox(height: 8),
                    ]))),
                  child: Container(width: 30, height: 30,
                    decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, border: Border.all(color: AppTheme.bg, width: 2)),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 40),
          PauButton(label: 'C\'est parti !', onTap: _finish, isLoading: _saving, icon: Icons.check_rounded),
          if (_photoPath != null) ...[
            const SizedBox(height: 12),
            PauButton(label: 'Continuer sans photo', onTap: _finish, outlined: true, textColor: AppTheme.textSecondary),
          ] else ...[
            const SizedBox(height: 12),
            PauButton(label: 'Passer cette étape', onTap: _finish, outlined: true, textColor: AppTheme.textSecondary),
          ],
        ],
      ),
    );
  }
}
