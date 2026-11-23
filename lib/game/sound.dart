import 'package:audioplayers/audioplayers.dart';

/// Lightweight audio manager. Every call is wrapped so a missing audio plugin
/// (tests, desktop without audio) can never crash the game.
class RaceAudio {
  bool enabled = true;
  AudioPlayer? _engine;
  bool _engineOn = false;

  Future<void> startEngine() async {
    if (!enabled || _engineOn) return;
    _engineOn = true;
    try {
      final p = _engine ??= AudioPlayer();
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(.35);
      await p.play(AssetSource('audio/engine.wav'));
    } catch (_) {
      _engineOn = false;
    }
  }

  void updateEngine(double rate, double volume) {
    if (!_engineOn) return;
    try {
      _engine?.setPlaybackRate(rate.clamp(.6, 2.0).toDouble()).catchError((_) {});
      _engine?.setVolume(volume.clamp(0.0, 1.0).toDouble()).catchError((_) {});
    } catch (_) {}
  }

  Future<void> stopEngine() async {
    _engineOn = false;
    try {
      await _engine?.stop();
    } catch (_) {}
  }

  void play(String name, {double volume = 1}) {
    if (!enabled) return;
    try {
      final p = AudioPlayer();
      p.play(AssetSource('audio/$name.wav'), volume: volume).catchError((_) {});
      p.onPlayerComplete.first.then((_) => p.dispose()).catchError((_) {});
    } catch (_) {}
  }

  Future<void> dispose() async {
    _engineOn = false;
    try {
      await _engine?.dispose();
    } catch (_) {}
    _engine = null;
  }
}
