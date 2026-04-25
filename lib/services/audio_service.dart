import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static final AudioPlayer _ringtone = AudioPlayer();

  static bool _ringtoneActive = false;

  /// Joue un fichier audio (message utilisateur)
  static Future<void> playFile(String path) async {
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  /// Joue l'audio par défaut depuis les assets
  static Future<void> playDefaultAudio() async {
    await _player.stop();
    await _player.play(AssetSource('audio/default_pause.mp3'));
  }

  /// Joue soit le fichier custom soit le défaut
  static Future<void> playAudio(String? customPath) async {
    if (customPath != null && customPath.isNotEmpty) {
      await playFile(customPath);
    } else {
      await playDefaultAudio();
    }
  }

  /// Écouter la fin de la piste
  static void onComplete(void Function() callback) {
    _player.onPlayerComplete.listen((_) => callback());
  }

  /// Sonnerie en boucle
  static Future<void> startRingtone() async {
    if (_ringtoneActive) return;
    _ringtoneActive = true;
    await _ringtone.setReleaseMode(ReleaseMode.loop);
    try {
      await _ringtone.play(AssetSource('audio/ringtone.mp3'));
    } catch (_) {
      // pas de fichier ringtone, silence OK
    }
  }

  static Future<void> stopRingtone() async {
    _ringtoneActive = false;
    await _ringtone.stop();
  }

  static Future<void> stop() async {
    await _player.stop();
  }

  static Stream get onComplete$ => _player.onPlayerComplete;
}
