// lib/services/progress_service.dart
// Remembers Yuli's progress on this device: stars, which letters are
// unlocked, which she has already met, and how well she knows each one.
//
// Learning path:
//  * letters open in groups of 5, in alphabet order
//  * a letter is "known" after 3 first-try correct answers
//    (a wrong pick lowers it by 1)
//  * when every open letter is known, the next group opens

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/hebrew_characters.dart';
import 'profile_service.dart';

class ProgressService extends ChangeNotifier {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  static const int groupSize = 5;
  static const int masteryGoal = 3;

  static const _kStars = 'stars';
  static const _kUnlocked = 'unlocked';
  static const _kIntroduced = 'introduced';
  static const _kMastery = 'mastery';

  final Random _random = Random();
  SharedPreferences? _prefs;
  String _prefix = ''; // 'p_<profileId>_' - each child has own progress

  int _stars = 0;
  int _unlockedCount = groupSize;
  final Set<String> _introduced = {};
  final Map<String, int> _mastery = {};

  // ---------- read ----------

  int get stars => _stars;
  int get unlockedCount => _unlockedCount;
  int get level => (_unlockedCount / groupSize).ceil();
  bool get isComplete => _unlockedCount >= activeLetters.length;

  List<HebrewCharacter> get unlockedLetters =>
      activeLetters.take(_unlockedCount).toList();

  /// Open letters she has not met yet in "Meet the letters".
  List<HebrewCharacter> get lettersToIntroduce =>
      unlockedLetters.where((c) => !_introduced.contains(c.id)).toList();

  /// Letters the games may use: open AND already met.
  List<HebrewCharacter> get playableLetters =>
      unlockedLetters.where((c) => _introduced.contains(c.id)).toList();

  bool isIntroduced(String id) => _introduced.contains(id);
  int masteryOf(String id) => _mastery[id] ?? 0;
  bool isMastered(String id) => masteryOf(id) >= masteryGoal;
  int get masteredCount =>
      activeLetters.where((c) => isMastered(c.id)).length;

  /// Picks letters for a round, preferring the ones she knows least.
  List<HebrewCharacter> pickRoundLetters(int count) {
    final keyed = [
      for (final c in playableLetters)
        (c, masteryOf(c.id) + _random.nextDouble() * 2),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return keyed.take(count).map((e) => e.$1).toList()..shuffle(_random);
  }

  // ---------- write ----------

  /// Keys of one child's progress. Hebrew keeps the original keys, so
  /// progress saved before English existed is untouched; English has its own.
  static String _prefixFor(String profileId, {required bool english}) =>
      english ? 'p_${profileId}_en_' : 'p_${profileId}_';

  /// Loads the progress of one child, in the language they learn now.
  Future<void> loadFor(String profileId) async {
    _prefix = _prefixFor(profileId,
        english: ProfileService.instance.isEnglish);
    _stars = 0;
    _unlockedCount = groupSize;
    _introduced.clear();
    _mastery.clear();
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      _stars = p.getInt('$_prefix$_kStars') ?? 0;
      _unlockedCount = (p.getInt('$_prefix$_kUnlocked') ?? groupSize)
          .clamp(groupSize, activeLetters.length)
          .toInt();
      _introduced.addAll(
          p.getStringList('$_prefix$_kIntroduced') ?? const <String>[]);
      final raw = p.getString('$_prefix$_kMastery');
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((k, v) => _mastery[k] = (v as num).toInt());
      }
    } catch (e) {
      debugPrint('Progress load failed: $e');
    }
    notifyListeners();
  }

  // ---------- per-child storage helpers ----------

  static const _allKeys = [_kStars, _kUnlocked, _kIntroduced, _kMastery];

  /// Progress saved by the older single-child version (no prefix).
  static bool hasLegacyProgress(SharedPreferences p) =>
      _allKeys.any(p.containsKey);

  static Future<void> migrateLegacy(SharedPreferences p, String id) async {
    final prefix = 'p_${id}_';
    final stars = p.getInt(_kStars);
    final unlocked = p.getInt(_kUnlocked);
    final introduced = p.getStringList(_kIntroduced);
    final mastery = p.getString(_kMastery);
    if (stars != null) await p.setInt('$prefix$_kStars', stars);
    if (unlocked != null) await p.setInt('$prefix$_kUnlocked', unlocked);
    if (introduced != null) {
      await p.setStringList('$prefix$_kIntroduced', introduced);
    }
    if (mastery != null) await p.setString('$prefix$_kMastery', mastery);
    for (final k in _allKeys) {
      await p.remove(k);
    }
  }

  static Future<void> deleteFor(String id) async {
    final p = await SharedPreferences.getInstance();
    for (final english in [false, true]) {
      final prefix = _prefixFor(id, english: english);
      for (final k in _allKeys) {
        await p.remove('$prefix$k');
      }
    }
  }

  void addStars(int amount) {
    _stars += amount;
    _changed();
  }

  void markIntroduced(String id) {
    if (_introduced.add(id)) _changed();
  }

  /// Returns true when this answer opened a new group of letters.
  bool recordCorrect(String id, {required bool firstTry}) {
    if (firstTry) _mastery[id] = masteryOf(id) + 1;
    final unlocked = _tryUnlock();
    _changed();
    return unlocked;
  }

  void recordMistake(String id) {
    final m = masteryOf(id);
    if (m > 0) {
      _mastery[id] = m - 1;
      _changed();
    }
  }

  Future<void> reset() async {
    _stars = 0;
    _unlockedCount = groupSize;
    _introduced.clear();
    _mastery.clear();
    notifyListeners();
    await _save();
  }

  // ---------- internal ----------

  bool _tryUnlock() {
    if (isComplete) return false;
    if (!unlockedLetters.every((c) => isMastered(c.id))) return false;
    _unlockedCount = min(_unlockedCount + groupSize, activeLetters.length);
    return true;
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null || _prefix.isEmpty) return;
    try {
      await p.setInt('$_prefix$_kStars', _stars);
      await p.setInt('$_prefix$_kUnlocked', _unlockedCount);
      await p.setStringList('$_prefix$_kIntroduced', _introduced.toList());
      await p.setString('$_prefix$_kMastery', jsonEncode(_mastery));
    } catch (e) {
      debugPrint('Progress save failed: $e');
    }
  }
}
