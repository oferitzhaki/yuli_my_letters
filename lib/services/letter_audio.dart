// lib/services/letter_audio.dart
// All sounds: letter names (<id>.mp3), words (animal_<id>.mp3),
// spoken feedback in girl/boy form (fb_*.mp3) and the child's name
// as recorded by a parent. Missing files fail silently.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/hebrew_characters.dart';
import 'profile_service.dart';

class LetterAudio {
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();

  // Every new request bumps this, so an older sequence knows it was
  // interrupted and stops instead of talking over the new one.
  int _token = 0;

  // ---------- single sounds ----------

  Future<void> playLetter(HebrewCharacter c) {
    _token++;
    return _play(_letter(c));
  }

  Future<void> playAnimal(HebrewCharacter c) {
    _token++;
    return _play(_word(c));
  }

  /// Plays any recording given as a data: URL (e.g. a name preview).
  Future<void> playUrl(String url) {
    _token++;
    return _play(url);
  }

  // ---------- sequences (complete when done or interrupted) ----------

  /// "אָלֶף ... אַרְיֵה"
  Future<bool> playLetterThenWord(HebrewCharacter c) =>
      _sequence([_letter(c), _word(c)]);

  /// "אָלֶף ... (name) ... יופי, הצלחת!" - the name about half the time.
  Future<bool> playLetterThenPraise(HebrewCharacter c) => _sequence([
        _letter(c),
        if (_name != null && _random.nextBool()) _name!,
        _praise(),
      ]);

  /// "כמעט! נסי שוב" - returns true if it finished uninterrupted.
  Future<bool> playTryAgain() =>
      _sequence(['assets/audio/fb_try_${_g}_${_random.nextInt(2) + 1}.mp3']);

  Future<bool> playRoundDone({bool unlocked = false}) => _sequence([
        if (_name != null) _name!,
        'assets/audio/fb_round_$_g.mp3',
        if (unlocked) 'assets/audio/fb_unlock_$_g.mp3',
      ]);

  Future<bool> playIntroDone() => _sequence([
        if (_name != null) _name!,
        'assets/audio/fb_intro_done_n.mp3',
      ]);

  /// "כתבי את האות ... בֵּית"
  Future<bool> playWritePrompt(HebrewCharacter c) =>
      _sequence(['assets/audio/fb_write_$_g.mp3', _letter(c)]);

  // ---------- internals ----------

  String get _g => ProfileService.instance.isBoy ? 'm' : 'f';
  String? get _name => ProfileService.instance.voiceUrl;

  String _letter(HebrewCharacter c) => 'assets/audio/${c.id}.mp3';
  String _word(HebrewCharacter c) => 'assets/audio/animal_${c.id}.mp3';

  String _praise() {
    final options = [
      'assets/audio/fb_praise_n_1.mp3',
      'assets/audio/fb_praise_n_2.mp3',
      'assets/audio/fb_praise_${_g}_1.mp3',
      'assets/audio/fb_praise_${_g}_2.mp3',
    ];
    return options[_random.nextInt(options.length)];
  }

  Future<bool> _sequence(List<String> sources) async {
    final token = ++_token;
    for (var i = 0; i < sources.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 120));
        if (token != _token) return false;
      }
      await _playToEnd(sources[i]);
      if (token != _token) return false;
    }
    return true;
  }

  Future<void> _load(String source) async {
    await _player.stop();
    if (source.startsWith('data:')) {
      await _player.setUrl(source);
    } else {
      await _player.setAsset(source);
    }
  }

  Future<void> _play(String source) async {
    try {
      await _load(source);
      _player.play();
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  Future<void> _playToEnd(String source) async {
    try {
      await _load(source);
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
