// lib/constants/hebrew_characters.dart
// Each letter is paired with a familiar word that STARTS with it and has an
// unambiguous picture (a 4-year-old should name the picture the same way).
// `id` matches assets/audio/<id>.mp3 and assets/audio/animal_<id>.mp3

class HebrewCharacter {
  final String id;
  final String letter;
  final String animalName; // the word for the picture
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
  HebrewCharacter(id: 'vav', letter: 'ו', animalName: 'ורד', emoji: '🌹'),
  HebrewCharacter(id: 'zayin', letter: 'ז', animalName: 'זברה', emoji: '🦓'),
  HebrewCharacter(id: 'het', letter: 'ח', animalName: 'חתול', emoji: '🐱'),
  HebrewCharacter(id: 'tet', letter: 'ט', animalName: 'טרקטור', emoji: '🚜'),
  HebrewCharacter(id: 'yod', letter: 'י', animalName: 'יד', emoji: '✋'),
  HebrewCharacter(id: 'kaf', letter: 'כ', animalName: 'כלב', emoji: '🐕'),
  HebrewCharacter(id: 'lamed', letter: 'ל', animalName: 'לימון', emoji: '🍋'),
  HebrewCharacter(id: 'mem', letter: 'מ', animalName: 'מכונית', emoji: '🚗'),
  HebrewCharacter(id: 'nun', letter: 'נ', animalName: 'נחש', emoji: '🐍'),
  HebrewCharacter(id: 'samekh', letter: 'ס', animalName: 'סוס', emoji: '🐴'),
  HebrewCharacter(id: 'ayin', letter: 'ע', animalName: 'עכבר', emoji: '🐭'),
  HebrewCharacter(id: 'pe', letter: 'פ', animalName: 'פיל', emoji: '🐘'),
  HebrewCharacter(id: 'tsadi', letter: 'צ', animalName: 'צב', emoji: '🐢'),
  HebrewCharacter(id: 'qof', letter: 'ק', animalName: 'קוף', emoji: '🐵'),
  HebrewCharacter(id: 'resh', letter: 'ר', animalName: 'רכבת', emoji: '🚂'),
  HebrewCharacter(id: 'shin', letter: 'ש', animalName: 'שמש', emoji: '☀️'),
  HebrewCharacter(id: 'tav', letter: 'ת', animalName: 'תפוח', emoji: '🍎'),
];
