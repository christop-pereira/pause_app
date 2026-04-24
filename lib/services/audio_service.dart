import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static final AudioPlayer _ringtone = AudioPlayer();

  static Future<void> playFile(String path) async {
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  static Future<void> playAsset(String assetPath) async {
    await _player.stop();
    await _player.play(AssetSource(assetPath));
  }

  static Future<void> startRingtone() async {
    await _ringtone.setReleaseMode(ReleaseMode.loop);
    // Utilise un asset ou un son système
    try {
      await _ringtone.play(AssetSource('audio/ringtone.mp3'));
    } catch (_) {
      // Pas de ringtone asset disponible, pas grave
    }
  }

  static Future<void> stopRingtone() async {
    await _ringtone.stop();
  }

  static Future<void> stop() async {
    await _player.stop();
  }

  static Future<Duration?> getDuration(String path) async {
    final p = AudioPlayer();
    await p.setSource(DeviceFileSource(path));
    final d = await p.getDuration();
    await p.dispose();
    return d;
  }
}