// lib/services/letter_audio.dart
// All sounds: letter names (<id>.mp3), words (animal_<id>.mp3)
// and spoken feedback (fb_*.mp3). Missing files fail silently.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/hebrew_characters.dart';

class LetterAudio {
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();

  // Every new request bumps this, so an older sequence knows it was
  // interrupted and stops instead of talking over the new one.
  int _token = 0;

  static const int _praiseCount = 4;
  static const int _tryAgainCount = 2;

  // ---------- single sounds ----------

  Future<void> playLetter(HebrewCharacter c) {
    _token++;
    return _play(_letter(c));
  }

  Future<void> playAnimal(HebrewCharacter c) {
    _token++;
    return _play(_word(c));
  }

  // ---------- sequences (complete when done or interrupted) ----------

  /// "אָלֶף ... אַרְיֵה"
  Future<bool> playLetterThenWord(HebrewCharacter c) =>
      _sequence([_letter(c), _word(c)]);

  /// "אָלֶף ... יופי יולי, הצלחת!"
  Future<bool> playLetterThenPraise(HebrewCharacter c) =>
      _sequence([_letter(c), _praise()]);

  /// "כמעט! נסי שוב" - returns true if it finished uninterrupted.
  Future<bool> playTryAgain() => _sequence(
      ['assets/audio/fb_try_${_random.nextInt(_tryAgainCount) + 1}.mp3']);

  Future<bool> playRoundDone({bool unlocked = false}) => _sequence([
        'assets/audio/fb_round.mp3',
        if (unlocked) 'assets/audio/fb_unlock.mp3',
      ]);

  /// "כתבי את האות ... בֵּית"
  Future<bool> playWritePrompt(HebrewCharacter c) =>
      _sequence(['assets/audio/fb_write.mp3', _letter(c)]);

  Future<bool> playIntroDone() =>
      _sequence(['assets/audio/fb_intro_done.mp3']);

  // ---------- internals ----------

  String _letter(HebrewCharacter c) => 'assets/audio/${c.id}.mp3';
  String _word(HebrewCharacter c) => 'assets/audio/animal_${c.id}.mp3';
  String _praise() =>
      'assets/audio/fb_praise_${_random.nextInt(_praiseCount) + 1}.mp3';

  Future<bool> _sequence(List<String> assets) async {
    final token = ++_token;
    for (var i = 0; i < assets.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 120));
        if (token != _token) return false;
      }
      await _playToEnd(assets[i]);
      if (token != _token) return false;
    }
    return true;
  }

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
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      // Missing file, timeout or interruption - just carry on.
    }
  }

  void dispose() => _player.dispose();
}
