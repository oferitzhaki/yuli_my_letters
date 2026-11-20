// lib/constants/syllables.dart
// Hebrew syllables: a letter with a vowel mark (ניקוד), e.g. בָּ בֵּ בִּ בּוֹ בּוּ.
// Audio: assets/audio/syl_<letterId>_<vowelId>.mp3, made by generate_audio.py
// with the SAME rules as syllableText() below - keep the two in step.

import 'hebrew_characters.dart';

class Vowel {
  const Vowel(this.id, this.hebrewName, this.sound);

  final String id; // a, e, i, o, u
  final String hebrewName; // קָמָץ ...
  final String sound; // how it sounds, in Latin letters
}

const List<Vowel> vowels = [
  Vowel('a', 'קָמָץ', 'a'),
  Vowel('e', 'צֵירֵה', 'e'),
  Vowel('i', 'חִירִיק', 'i'),
  Vowel('o', 'חוֹלָם', 'o'),
  Vowel('u', 'שׁוּרוּק', 'u'),
];

// Marks (Unicode combining characters).
const String _dagesh = 'ּ';
const String _shinDot = 'ׁ';
const String _kamatz = 'ָ';
const String _tsere = 'ֵ';
const String _hiriq = 'ִ';
const String _holamMale = 'וֹ'; // וֹ
const String _shuruk = 'וּ'; // וּ

/// ו is left out: with a vowel it reads as a vowel itself (וֹ, וּ).
bool hasSyllables(HebrewCharacter c) => c.id != 'vav';

/// The letter as it is read at the start of a syllable:
/// בּ כּ פּ with a dot (b, k, p), שׁ with the dot on the right (sh).
String _consonant(HebrewCharacter c) {
  switch (c.id) {
    case 'bet':
    case 'kaf':
    case 'pe':
      return '${c.letter}$_dagesh';
    case 'shin':
      return '${c.letter}$_shinDot';
    default:
      return c.letter;
  }
}

/// e.g. ('bet', 'u') -> בּוּ
String syllableText(HebrewCharacter c, String vowelId) {
  final base = _consonant(c);
  switch (vowelId) {
    case 'a':
      return '$base$_kamatz';
    case 'e':
      return '$base$_tsere';
    case 'i':
      return '$base$_hiriq';
    case 'o':
      return '$base$_holamMale';
    default:
      return '$base$_shuruk';
  }
}

String syllableId(HebrewCharacter c, String vowelId) => '${c.id}_$vowelId';
