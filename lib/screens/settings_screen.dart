import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
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

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  Duration _recordDuration = Duration.zero;
  bool _recordingFinished = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: context.read<AppProvider>().userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ── Permissions ───────────────────────────────────────

  Future<bool> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _snack('Permission microphone refusée', AppTheme.danger);
      return false;
    }
    return true;
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _snack('Permission caméra refusée', AppTheme.danger);
      return false;
    }
    return true;
  }

  Future<bool> _requestPhotosPermission() async {
    Permission perm;
    if (Platform.isIOS) {
      perm = Permission.photos;
    } else {
      perm = Permission.storage;
    }
    final status = await perm.request();
    // Sur Android 13+ photos permission peut être différente
    if (!status.isGranted) {
      if (Platform.isAndroid) {
        final photos = await Permission.photos.request();
        if (!photos.isGranted) {
          _snack('Permission photos refusée', AppTheme.danger);
          return false;
        }
      } else {
        _snack('Permission photos refusée', AppTheme.danger);
        return false;
      }
    }
    return true;
  }

  // ── Audio ─────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (!await _requestMicPermission()) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/pause_msg_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() {
      _isRecording = true;
      _recordingPath = path;
      _recordDuration = Duration.zero;
      _recordingFinished = false;
    });
    _tickDuration();
  }

  void _tickDuration() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRecording) return false;
      setState(() => _recordDuration += const Duration(seconds: 1));
      return true;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingFinished = path != null;
      if (path != null) _recordingPath = path;
    });
  }

  Future<void> _saveRecording() async {
    if (_recordingPath == null) return;
    await context.read<AppProvider>().setAudio(_recordingPath!);
    if (!mounted) return;
    setState(() { _recordingFinished = false; _recordingPath = null; _recordDuration = Duration.zero; });
    _snack('Message audio enregistré ✓', AppTheme.success);
  }

  Future<void> _pickAudioFile(AppProvider provider) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      await provider.setAudio(result.files.single.path!);
      if (mounted) _snack('Audio mis à jour ✓', AppTheme.success);
    }
  }

  // ── Photo ─────────────────────────────────────────────

  // Sur desktop (Windows/macOS/Linux), image_picker.pickImage(camera) renvoie
  // null silencieusement → l'app a l'air figée. On rabat sur le sélecteur de
  // fichier image et on prévient l'utilisateur. La caméra reste disponible
  // normalement sur Android et iOS.
  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  Future<void> _takePhoto(AppProvider provider) async {
    if (_isDesktop) {
      _snack('Caméra non supportée sur desktop — choisis un fichier image', AppTheme.textSecondary);
      await _pickImageFromFiles(provider);
      return;
    }
    if (!await _requestCameraPermission()) return;
    final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (img != null && mounted) {
      await provider.setPhoto(img.path);
      _snack('Photo mise à jour ✓', AppTheme.success);
    }
  }

  Future<void> _pickImageFromFiles(AppProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      dialogTitle: 'Choisir une photo de profil',
    );
    if (result != null && result.files.single.path != null && mounted) {
      await provider.setPhoto(result.files.single.path!);
      _snack('Photo mise à jour ✓', AppTheme.success);
    }
  }

  Future<void> _pickFromGallery(AppProvider provider) async {
    if (_isDesktop) {
      await _pickImageFromFiles(provider);
      return;
    }
    if (!await _requestPhotosPermission()) return;
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null && mounted) {
      await provider.setPhoto(img.path);
      _snack('Photo mise à jour ✓', AppTheme.success);
    }
  }

  void _showPhotoOptions(AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: const Text('Prendre une photo', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () { Navigator.pop(context); _takePhoto(provider); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
              title: const Text('Choisir depuis la galerie', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () { Navigator.pop(context); _pickFromGallery(provider); },
            ),
            if (provider.hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                title: const Text('Supprimer la photo', style: TextStyle(color: AppTheme.danger)),
                onTap: () {
                  Navigator.pop(context);
                  provider.clearPhoto();
                  _snack('Photo supprimée', AppTheme.textSecondary);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Nom ───────────────────────────────────────────────

  Future<void> _saveName(AppProvider provider) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await provider.setName(name);
    if (!mounted) return;
    setState(() => _editingName = false);
    _snack('Nom mis à jour ✓', AppTheme.success);
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String get _durationStr {
    final m = _recordDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_recordDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ─────────────────────────────────────────────

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
              const Text('Profil',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                      letterSpacing: -0.6, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              const Text('Personnalise ton expérience PAUSE',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 32),

              // ── Photo ──
              Center(
                child: Stack(children: [
                  GestureDetector(
                    onTap: () => _showPhotoOptions(provider),
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 2),
                      ),
                      child: ClipOval(
                        child: provider.hasPhoto
                            ? Image.file(File(provider.photoPath), fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset('assets/images/avatar.png', fit: BoxFit.cover))
                            : Image.asset('assets/images/avatar.png', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0, bottom: 0,
                    child: GestureDetector(
                      onTap: () => _showPhotoOptions(provider),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.bg, width: 2)),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 28),

              // ── Prénom ──
              _label('TON PRÉNOM'),
              const SizedBox(height: 10),
              _nameCard(provider),
              const SizedBox(height: 28),

              // ── Audio ──
              _label('MESSAGE AUDIO'),
              const SizedBox(height: 4),
              const Text('Ce message sera joué lors de chaque appel PAUSE',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),

              _recordCard(),
              const SizedBox(height: 10),

              _fileAudioCard(provider),

              if (!provider.hasAudio) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.15))),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 14),
                    SizedBox(width: 8),
                    Expanded(child: Text('Audio par défaut utilisé si aucun fichier configuré.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                  ]),
                ),
              ],
              const SizedBox(height: 28),

              // ── Test ──
              _label('TESTER'),
              const SizedBox(height: 10),
              PauButton(
                label: 'Simuler un appel PAUSE',
                icon: Icons.call_rounded,
                outlined: true,
                color: AppTheme.primary,
                onTap: () {
                  final id = triggerProvider.triggers.isNotEmpty
                      ? triggerProvider.triggers.first.id
                      : 'test';
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => FakeCallScreen(triggerId: id, triggerLabel: 'Test PAUSE'),
                  ));
                },
              ),
              const SizedBox(height: 32),

              // ── Stats ──
              _label('RÉCAPITULATIF'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('Triggers', '${triggerProvider.count}', Icons.bolt_rounded, AppTheme.primary),
                    Container(width: 1, height: 44, color: AppTheme.border),
                    _stat('Actifs', '${triggerProvider.activeCount}', Icons.check_circle_outline_rounded, AppTheme.success),
                  ],
                ),
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

  Widget _nameCard(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border)),
      child: _editingName
          ? Row(children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                      border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero),
                ),
              ),
              TextButton(onPressed: () => _saveName(provider), child: const Text('Sauvegarder')),
              TextButton(
                  onPressed: () => setState(() => _editingName = false),
                  child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary))),
            ])
          : Row(children: [
              Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11)),
                  child: const Center(child: Icon(Icons.person_rounded, color: AppTheme.primary, size: 18))),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.userName.isNotEmpty ? provider.userName : 'Non défini',
                  style: TextStyle(
                      color: provider.userName.isNotEmpty ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppTheme.textSecondary, size: 16),
                  onPressed: () => setState(() {
                        _editingName = true;
                        _nameController.text = provider.userName;
                      })),
            ]),
    );
  }

  Widget _recordCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isRecording ? AppTheme.danger.withOpacity(0.07) : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _isRecording ? AppTheme.danger.withOpacity(0.3) : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: (_isRecording ? AppTheme.danger : AppTheme.primary).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(
                  _isRecording ? Icons.fiber_manual_record_rounded : Icons.mic_rounded,
                  color: _isRecording ? AppTheme.danger : AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _isRecording ? 'Enregistrement en cours…' : 'Enregistrer un message',
                  style: TextStyle(
                      color: _isRecording ? AppTheme.danger : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (_isRecording)
                  Text(_durationStr,
                      style: TextStyle(color: AppTheme.danger.withOpacity(0.7), fontSize: 12)),
              ]),
            ),
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: (_isRecording ? AppTheme.danger : AppTheme.primary).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: _isRecording ? AppTheme.danger : AppTheme.primary, size: 22),
              ),
            ),
          ]),
          if (_recordingFinished && !_isRecording) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _saveRecording,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.success.withOpacity(0.4))),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.check_rounded, color: AppTheme.success, size: 16),
                      SizedBox(width: 6),
                      Text('Utiliser cet enregistrement',
                          style: TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _recordingFinished = false;
                  _recordingPath = null;
                  _recordDuration = Duration.zero;
                }),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 16),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _fileAudioCard(AppProvider provider) {
    return GestureDetector(
      onTap: () => _pickAudioFile(provider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: provider.hasAudio ? AppTheme.success.withOpacity(0.07) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: provider.hasAudio ? AppTheme.success.withOpacity(0.35) : AppTheme.border),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: (provider.hasAudio ? AppTheme.success : AppTheme.primary).withOpacity(0.12),
                borderRadius: BorderRadius.circular(11)),
            child: Icon(
                provider.hasAudio ? Icons.audio_file_rounded : Icons.upload_file_rounded,
                color: provider.hasAudio ? AppTheme.success : AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(provider.hasAudio ? 'Fichier audio configuré' : 'Importer un fichier audio',
                  style: TextStyle(
                      color: provider.hasAudio ? AppTheme.success : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(
                provider.hasAudio ? provider.audioPath.split('/').last : 'MP3, WAV, M4A…',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          if (provider.hasAudio)
            GestureDetector(
              onTap: () { provider.clearAudio(); _snack('Audio supprimé', AppTheme.textSecondary); },
              child: const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
              ),
            ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) => Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ]);
}