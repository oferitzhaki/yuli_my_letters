// lib/constants/english_characters.dart
// English ABC (capital letters), each with a familiar picture word that
// STARTS with the letter. Ids get an "en_" prefix so their audio files
// never clash with the Hebrew ones: assets/audio/en_a.mp3 and
// assets/audio/animal_en_a.mp3.

import 'hebrew_characters.dart';

const List<HebrewCharacter> englishCharacters = [
  HebrewCharacter(id: 'en_a', letter: 'A', animalName: 'Apple', emoji: '🍎'),
  HebrewCharacter(id: 'en_b', letter: 'B', animalName: 'Ball', emoji: '⚽'),
  HebrewCharacter(id: 'en_c', letter: 'C', animalName: 'Cat', emoji: '🐱'),
  HebrewCharacter(id: 'en_d', letter: 'D', animalName: 'Dog', emoji: '🐶'),
  HebrewCharacter(id: 'en_e', letter: 'E', animalName: 'Egg', emoji: '🥚'),
  HebrewCharacter(id: 'en_f', letter: 'F', animalName: 'Fish', emoji: '🐟'),
  HebrewCharacter(id: 'en_g', letter: 'G', animalName: 'Grapes', emoji: '🍇'),
  HebrewCharacter(id: 'en_h', letter: 'H', animalName: 'Hat', emoji: '🎩'),
  HebrewCharacter(id: 'en_i', letter: 'I', animalName: 'Ice cream', emoji: '🍦'),
  HebrewCharacter(id: 'en_j', letter: 'J', animalName: 'Juice', emoji: '🧃'),
  HebrewCharacter(id: 'en_k', letter: 'K', animalName: 'Kite', emoji: '🪁'),
  HebrewCharacter(id: 'en_l', letter: 'L', animalName: 'Lion', emoji: '🦁'),
  HebrewCharacter(id: 'en_m', letter: 'M', animalName: 'Moon', emoji: '🌙'),
  HebrewCharacter(id: 'en_n', letter: 'N', animalName: 'Nose', emoji: '👃'),
  HebrewCharacter(id: 'en_o', letter: 'O', animalName: 'Orange', emoji: '🍊'),
  HebrewCharacter(id: 'en_p', letter: 'P', animalName: 'Pig', emoji: '🐷'),
  HebrewCharacter(id: 'en_q', letter: 'Q', animalName: 'Queen', emoji: '👸'),
  HebrewCharacter(id: 'en_r', letter: 'R', animalName: 'Rabbit', emoji: '🐰'),
  HebrewCharacter(id: 'en_s', letter: 'S', animalName: 'Sun', emoji: '☀️'),
  HebrewCharacter(id: 'en_t', letter: 'T', animalName: 'Tree', emoji: '🌳'),
  HebrewCharacter(id: 'en_u', letter: 'U', animalName: 'Umbrella', emoji: '☂️'),
  HebrewCharacter(id: 'en_v', letter: 'V', animalName: 'Van', emoji: '🚐'),
  HebrewCharacter(id: 'en_w', letter: 'W', animalName: 'Watermelon', emoji: '🍉'),
  HebrewCharacter(id: 'en_x', letter: 'X', animalName: 'X-ray', emoji: '🩻'),
  HebrewCharacter(id: 'en_y', letter: 'Y', animalName: 'Yo-yo', emoji: '🪀'),
  HebrewCharacter(id: 'en_z', letter: 'Z', animalName: 'Zebra', emoji: '🦓'),
];
