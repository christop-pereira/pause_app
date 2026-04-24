import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import '../services/audio_service.dart';
import 'questionnaire_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Lancer la sonnerie
    AudioService.startRingtone();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callTimer?.cancel();
    AudioService.stopRingtone();
    AudioService.stop();
    super.dispose();
  }

  Future<void> _accept() async {
    await AudioService.stopRingtone();
    setState(() { _inCall = true; _audioPlaying = true; });

    // Démarrer le timer
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });

    // Jouer l'audio de l'utilisateur
    final audioPath = context.read<AppProvider>().audioPath;
    if (audioPath.isNotEmpty) {
      try {
        await AudioService.playFile(audioPath);
      } catch (_) {}
    }

    // Après 5 sec minimum, proposer de terminer
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) setState(() => _audioPlaying = false);
  }

  void _decline() {
    Navigator.pop(context);
  }

  void _endCall() {
    _callTimer?.cancel();
    AudioService.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionnaireScreen(triggerId: widget.triggerId),
      ),
    );
  }

  String get _callDuration {
    final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: SafeArea(
        child: _inCall ? _buildInCall() : _buildRinging(),
      ),
    );
  }

  Widget _buildRinging() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 80),
          // Avatar animé
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.3),
                    AppTheme.primary.withOpacity(0.05),
                  ],
                ),
                border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 2),
              ),
              child: const Center(
                child: Text('⏸', style: TextStyle(fontSize: 52)),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'PAUSE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.triggerLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Appel entrant...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _callButton(
                icon: Icons.call_end_rounded,
                color: AppTheme.danger,
                label: 'Ignorer',
                onTap: _decline,
              ),
              _callButton(
                icon: Icons.call_rounded,
                color: AppTheme.success,
                label: 'Répondre',
                onTap: _accept,
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildInCall() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.success.withOpacity(0.1),
              border: Border.all(color: AppTheme.success.withOpacity(0.3), width: 2),
            ),
            child: const Center(
              child: Text('⏸', style: TextStyle(fontSize: 52)),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'PAUSE',
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            _callDuration,
            style: TextStyle(color: AppTheme.success.withOpacity(0.8), fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          if (_audioPlaying)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.graphic_eq_rounded, color: AppTheme.success, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Message en cours...',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
              ],
            ),
          const Spacer(),
          // Bouton raccrocher
          GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.danger,
                boxShadow: [BoxShadow(color: AppTheme.danger.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
              ),
              child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Raccrocher', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _callButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 20, spreadRadius: 2)],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}