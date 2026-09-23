// lib/constants/hebrew_characters.dart
// 22 Hebrew letters, each paired with an animal whose name STARTS with that letter.
// `id` matches the audio file name: assets/audio/<id>.mp3

class HebrewCharacter {
  final String id;
  final String letter;
  final String animalName;
  final String emoji;

  const HebrewCharacter({
    required this.id,
    required this.letter,
    required this.animalName,
    required this.emoji,
  });
}

const List<HebrewCharacter> hebrewCharacters = [
  HebrewCharacter(id: 'alef', letter: 'א', animalName: 'אריה', emoji: '🦁'),
  HebrewCharacter(id: 'bet', letter: 'ב', animalName: 'ברווז', emoji: '🦆'),
  HebrewCharacter(id: 'gimel', letter: 'ג', animalName: 'גמל', emoji: '🐪'),
  HebrewCharacter(id: 'dalet', letter: 'ד', animalName: 'דג', emoji: '🐟'),
  HebrewCharacter(id: 'he', letter: 'ה', animalName: 'היפופוטם', emoji: '🦛'),
  HebrewCharacter(id: 'vav', letter: 'ו', animalName: 'ורוור', emoji: '🐦'),
  HebrewCharacter(id: 'zayin', letter: 'ז', animalName: 'זאב', emoji: '🐺'),
  HebrewCharacter(id: 'het', letter: 'ח', animalName: 'חתול', emoji: '🐱'),
  HebrewCharacter(id: 'tet', letter: 'ט', animalName: 'טווס', emoji: '🦚'),
  HebrewCharacter(id: 'yod', letter: 'י', animalName: 'יונה', emoji: '🕊️'),
  HebrewCharacter(id: 'kaf', letter: 'כ', animalName: 'כלב', emoji: '🐕'),
  HebrewCharacter(id: 'lamed', letter: 'ל', animalName: 'לטאה', emoji: '🦎'),
  HebrewCharacter(id: 'mem', letter: 'מ', animalName: 'מדוזה', emoji: '🪼'),
  HebrewCharacter(id: 'nun', letter: 'נ', animalName: 'נמר', emoji: '🐆'),
  HebrewCharacter(id: 'samekh', letter: 'ס', animalName: 'סוס', emoji: '🐴'),
  HebrewCharacter(id: 'ayin', letter: 'ע', animalName: 'עכבר', emoji: '🐭'),
  HebrewCharacter(id: 'pe', letter: 'פ', animalName: 'פיל', emoji: '🐘'),
  HebrewCharacter(id: 'tsadi', letter: 'צ', animalName: 'צב', emoji: '🐢'),
  HebrewCharacter(id: 'qof', letter: 'ק', animalName: 'קוף', emoji: '🐵'),
  HebrewCharacter(id: 'resh', letter: 'ר', animalName: 'רקון', emoji: '🦝'),
  HebrewCharacter(id: 'shin', letter: 'ש', animalName: 'שועל', emoji: '🦊'),
  HebrewCharacter(id: 'tav', letter: 'ת', animalName: 'תרנגול', emoji: '🐓'),
];
