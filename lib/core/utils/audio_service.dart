import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Handles SFX, background music, and haptic feedback.
class AudioService {
  AudioService()
      : _sfx = AudioPlayer(playerId: 'sfx'),
        _music = AudioPlayer(playerId: 'music');

  final AudioPlayer _sfx;
  final AudioPlayer _music;

  bool soundEnabled = true;
  bool musicEnabled = true;
  bool hapticsEnabled = true;
  bool _musicPlaying = false;

  Future<void> init() async {
    await _sfx.setReleaseMode(ReleaseMode.stop);
    await _music.setReleaseMode(ReleaseMode.loop);
    await _music.setVolume(0.32);
  }

  Future<void> syncSettings({
    required bool sound,
    required bool music,
    required bool haptics,
  }) async {
    soundEnabled = sound;
    musicEnabled = music;
    hapticsEnabled = haptics;
    if (musicEnabled) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> startMusic() async {
    if (!musicEnabled || _musicPlaying) return;
    try {
      await _music.play(AssetSource('audio/bgm.wav'));
      _musicPlaying = true;
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
    _musicPlaying = false;
  }

  Future<void> _playSfx(String asset) async {
    if (!soundEnabled) return;
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> playMerge() => _playSfx('audio/merge.wav');

  Future<void> playWrong() async {
    await _playSfx('audio/wrong.wav');
    await hapticError();
  }

  Future<void> playWordComplete() async {
    await _playSfx('audio/word_complete.wav');
    await hapticWordComplete();
  }

  Future<void> playWin() async {
    await _playSfx('audio/win.wav');
    await hapticSuccess();
  }

  Future<void> playTimeout() async {
    await _playSfx('audio/timeout.wav');
    await hapticTimeout();
  }

  Future<void> playFail() async {
    await _playSfx('audio/fail.wav');
    await hapticFail();
  }

  Future<void> playPop() => _playSfx('audio/pop.wav');

  Future<void> hapticMerge() async {
    if (!hapticsEnabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> hapticWordComplete() async {
    if (!hapticsEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> hapticSuccess() async {
    if (!hapticsEnabled) return;
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  Future<void> hapticError() async {
    if (!hapticsEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> hapticTimeout() async {
    if (!hapticsEnabled) return;
    await HapticFeedback.vibrate();
  }

  Future<void> hapticFail() async {
    if (!hapticsEnabled) return;
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  Future<void> dispose() async {
    await _sfx.dispose();
    await _music.dispose();
  }
}
