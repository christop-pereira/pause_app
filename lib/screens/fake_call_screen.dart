import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../database/app_database.dart';
import '../providers/app_provider.dart';
import '../providers/pending_provider.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';

class FakeCallScreen extends StatefulWidget {
  final String triggerId;
  final String triggerLabel;

  const FakeCallScreen({
    super.key,
    required this.triggerId,
    this.triggerLabel = 'PAUSE',
  });

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen>
    with TickerProviderStateMixin {
  bool _inCall = false;
  bool _audioPlaying = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  Timer? _callTimer;
  int _callSeconds = 0;
  StreamSubscription? _completeSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    AudioService.startRingtone();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callTimer?.cancel();
    _completeSub?.cancel();
    AudioService.stopRingtone();
    AudioService.stop();
    super.dispose();
  }

  Future<void> _accept() async {
    await AudioService.stopRingtone();

    setState(() {
      _inCall = true;
      _audioPlaying = true;
    });

    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });

    // Écouter la fin de l'audio → raccrocher automatiquement
    _completeSub = AudioService.onComplete$.listen((_) {
      if (!mounted) return;
      setState(() => _audioPlaying = false);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _endCall();
      });
    });

    final audioPath = context.read<AppProvider>().audioPath;
    await AudioService.playAudio(audioPath.isEmpty ? null : audioPath);
  }

  // Délai avant que le débrief n'apparaisse à l'utilisateur.
  // Le moment de faiblesse doit être passé pour que la réflexion soit honnête.
  static const _debriefDelay = Duration(minutes: 5);

  Future<void> _schedulePendingDebrief() async {
    final dueAt = DateTime.now().add(_debriefDelay);
    final pendingId = await AppDatabase.instance.insertPending(
      triggerId: widget.triggerId,
      triggerLabel: widget.triggerLabel,
      dueAt: dueAt,
    );
    // Notif système comme rappel à T+5min — best effort, on n'attend pas
    // le résultat. Si elle n'arrive pas (perm refusée, OS qui dort), le
    // bandeau dans l'app prend le relai dès la prochaine ouverture.
    NotificationService.instance.scheduleDebriefAt(
      id: pendingId,
      when: dueAt,
    );
    // Met à jour le provider pour que le bandeau apparaisse quand le user
    // revient sur le HomeScreen
    if (mounted) {
      await context.read<PendingProvider>().refresh();
    }
  }

  Future<void> _decline() async {
    await _schedulePendingDebrief();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _endCall() async {
    _callTimer?.cancel();
    _completeSub?.cancel();
    AudioService.stop();
    await _schedulePendingDebrief();
    if (!mounted) return;
    // Retour au HomeScreen — pas de pushReplacement vers le questionnaire.
    // Le débrief s'affichera via le bandeau quand le dueAt sera atteint.
    Navigator.pop(context);
  }

  String get _callDuration {
    final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: _inCall ? _buildInCall(provider) : _buildRinging(provider),
        ),
      ),
    );
  }

  // ── Sonnerie ────────────────────────────────────────────
  Widget _buildRinging(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        ScaleTransition(
          scale: _pulseAnim,
          child: _avatar(provider, 120),
        ),
        const SizedBox(height: 28),
        const Text(
          'PAUSE',
          style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        Text(
          widget.triggerLabel,
          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Appel entrant…',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
        ),
        const Spacer(),
        // Boutons répondre / refuser
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _callButton(
                icon: Icons.call_end_rounded,
                color: AppTheme.danger,
                label: 'Ignorer',
                onTap: _decline,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.18),
              _callButton(
                icon: Icons.call_rounded,
                color: AppTheme.success,
                label: 'Répondre',
                onTap: _accept,
              ),
            ],
          ),
        ),
        const SizedBox(height: 56),
      ],
    );
  }

  // ── En communication ──────────────────────────────────
  Widget _buildInCall(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        _avatar(provider, 110),
        const SizedBox(height: 24),
        const Text(
          'PAUSE',
          style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        Text(
          _callDuration,
          style: TextStyle(
              color: AppTheme.success.withOpacity(0.8),
              fontSize: 18,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 14),
        if (_audioPlaying)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.graphic_eq_rounded,
                  color: AppTheme.success, size: 18),
              const SizedBox(width: 6),
              Text(
                'Message en cours…',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55), fontSize: 13),
              ),
            ],
          ),
        const Spacer(),
        // Bouton raccrocher centré
        GestureDetector(
          onTap: _endCall,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.danger,
              boxShadow: [
                BoxShadow(
                    color: AppTheme.danger.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 2)
              ],
            ),
            child: const Icon(Icons.call_end_rounded,
                color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 10),
        const Text('Raccrocher',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 56),
      ],
    );
  }

  // ── Avatar ────────────────────────────────────────────
  // Aligné sur le rendu du SettingsScreen :
  // - photo perso → Image.file en cover, fallback sur l'avatar par défaut si KO
  // - sans photo → l'avatar par défaut remplit tout le cercle (BoxFit.cover)
  Widget _avatar(AppProvider provider, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            Border.all(color: AppTheme.primary.withOpacity(0.35), width: 2),
      ),
      child: ClipOval(
        child: provider.hasPhoto
            ? Image.file(
                File(provider.photoPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Image.asset('assets/images/avatar.png', fit: BoxFit.cover),
              )
            : Image.asset('assets/images/avatar.png', fit: BoxFit.cover),
      ),
    );
  }

  // ── Bouton d'appel ────────────────────────────────────
  Widget _callButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2)
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 9),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }
}