// lib/services/word_pools.dart
// Which words and letters the harder games may use for the child who is
// playing: only words made of letters the child has already met.

import '../constants/english_characters.dart';
import '../constants/hebrew_characters.dart';
import '../constants/similar_letters.dart';
import '../constants/syllables.dart';
import '../constants/words.dart';
import 'profile_service.dart';
import 'progress_service.dart';

/// The word list for the alphabet the child learns.
List<WordItem> get activeWords =>
    ProfileService.instance.learnsEnglish ? englishWords : hebrewWords;

Set<String> _knownLetters() =>
    ProgressService.instance.playableLetters.map((c) => c.letter).toSet();

/// "Last letter": words whose last letter (or its regular form) is known.
List<WordItem> lastLetterPool() {
  final known = _knownLetters();
  return activeWords
      .where((w) => known.contains(baseForm(w.lastLetter)))
      .toList();
}

/// "Build a word": words made only of known letters.
List<WordItem> buildWordPool() {
  final known = _knownLetters();
  return activeWords
      .where((w) => w.letters.every((l) => known.contains(baseForm(l))))
      .toList();
}

/// Vowel marks: known Hebrew letters that take a vowel (not ו).
List<HebrewCharacter> syllableLetters() =>
    ProgressService.instance.playableLetters.where(hasSyllables).toList();

/// The letter object for a written letter (א or A), or null for a final
/// letter, which has no letter object of its own.
HebrewCharacter? characterFor(String letter) {
  for (final c in [...hebrewCharacters, ...englishCharacters]) {
    if (c.letter == letter) return c;
  }
  return null;
}

/// Letters that look like [c], taken from the alphabet being learned.
List<HebrewCharacter> lookalikesOf(
  HebrewCharacter c, {
  bool smallLetters = false,
}) {
  final map = smallLetters ? lowercaseLookalikes : lookalikes;
  final similar = map[c.letter] ?? const <String>[];
  return activeLetters.where((x) => similar.contains(x.letter)).toList();
}

/// The word in the language the app speaks, e.g. דג -> "pește".
/// Null when the child learns in their own language.
String? wordTranslationOf(WordItem w) {
  if (uiLang == ProfileService.instance.learnLanguage) return null;
  return w.translations[uiLang];
}
