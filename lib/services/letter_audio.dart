// lib/services/letter_audio.dart
// Plays letter names (assets/audio/<id>.mp3) and word names
// (assets/audio/animal_<id>.mp3). Missing files fail silently.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/hebrew_characters.dart';

class LetterAudio {
  final AudioPlayer _player = AudioPlayer();

  // Each new request bumps this, so an older "letter then word"
  // sequence knows it was interrupted and stops.
  int _token = 0;

  Future<void> playLetter(HebrewCharacter c) {
    _token++;
    return _play(_letterAsset(c));
  }

  Future<void> playAnimal(HebrewCharacter c) {
    _token++;
    return _play(_wordAsset(c));
  }

  /// "אָלֶף ... אַרְיֵה" - used when meeting a new letter.
  Future<void> playLetterThenWord(HebrewCharacter c) async {
    final token = ++_token;
    await _playToEnd(_letterAsset(c));
    if (token != _token) return;
    await Future.delayed(const Duration(milliseconds: 350));
    if (token != _token) return;
    await _play(_wordAsset(c));
  }

  String _letterAsset(HebrewCharacter c) => 'assets/audio/${c.id}.mp3';
  String _wordAsset(HebrewCharacter c) => 'assets/audio/animal_${c.id}.mp3';

  Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.setAsset(asset);
      _player.play();
    } catch (e) {
      debugPrint('Audio error ($asset): $e');
    }
  }

  Future<void> _playToEnd(String asset) async {
    try {
      await _player.stop();
      await _player.setAsset(asset);
      _player.play();
      await _player.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed)
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      // Timeout or interruption - just continue.
    }
  }

  void dispose() => _player.dispose();
}
