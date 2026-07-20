import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  AudioService(this._player);

  final AudioPlayer _player;
  bool soundEnabled = true;
  bool hapticsEnabled = true;

  Future<void> playMerge() async {
    if (!soundEnabled) return;
    try {
      await _player.play(AssetSource('audio/merge.mp3'));
    } catch (_) {}
  }

  Future<void> playWrong() async {
    if (!soundEnabled) return;
    try {
      await _player.play(AssetSource('audio/wrong.mp3'));
    } catch (_) {}
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> playWin() async {
    if (!soundEnabled) return;
    try {
      await _player.play(AssetSource('audio/win.mp3'));
    } catch (_) {}
  }

  Future<void> playPop() async {
    if (!soundEnabled) return;
    try {
      await _player.play(AssetSource('audio/pop.mp3'));
    } catch (_) {}
  }

  Future<void> playFail() async {
    if (!soundEnabled) return;
    try {
      await _player.play(AssetSource('audio/fail.mp3'));
    } catch (_) {}
  }
}
