// lib/services/letter_audio.dart
// Plays letter names (assets/audio/<id>.mp3) and animal names
// (assets/audio/animal_<id>.mp3). Missing files fail silently.

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/hebrew_characters.dart';

class LetterAudio {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playLetter(HebrewCharacter c) =>
      _play('assets/audio/${c.id}.mp3');

  Future<void> playAnimal(HebrewCharacter c) =>
      _play('assets/audio/animal_${c.id}.mp3');

  Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.setAsset(asset);
      _player.play();
    } catch (e) {
      debugPrint('Audio error ($asset): $e');
    }
  }

  void dispose() => _player.dispose();
}
