// lib/screens/word_game_rounds.dart
// Builds the questions for "last letter" and "vowel marks", which both run
// on TextChoiceGameScreen, plus the vowel chart.

import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/hebrew_characters.dart';
import '../constants/syllables.dart';
import '../constants/words.dart';
import '../services/letter_audio.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../services/word_pools.dart';
import 'text_choice_game_screen.dart';

final Random _random = Random();

/// The picture, the word with its last letter hidden ("קו?"), and the
/// translation when the app speaks another language.
Widget _wordPrompt(WordItem w, {required bool hideLast}) {
  final shown = hideLast
      ? '${w.word.substring(0, w.word.length - 1)}?'
      : w.word;
  final translation = wordTranslationOf(w);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(w.emoji, style: const TextStyle(fontSize: 90)),
      Text(
        shown,
        textDirection: learnDirection,
        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
      ),
      if (translation != null)
        Text(
          translation,
          style: const TextStyle(fontSize: 30, color: Colors.black54),
        ),
    ],
  );
}

String _correctText(String text) =>
    tr('🎉 נכון! $text', '🎉 Correct! $text', '🎉 Corect! $text');

/// "Which letter does the word end with?" In Hebrew this is where the
/// final letters (ך ם ן ף ץ) are met: the answer for קוף is ף.
List<TextQuestion> lastLetterRound() {
  final words = lastLetterPool()..shuffle(_random);
  final known =
      ProgressService.instance.playableLetters.map((c) => c.letter).toList();
  final questions = <TextQuestion>[];
  for (final w in words.take(5)) {
        final answer = w.lastLetter;
        final wrong = <String>{};
        if (isFinalLetter(answer)) {
          // The regular form and another final letter: the real confusions.
          wrong.add(baseForm(answer));
          final otherFinals = finalToBase.keys.where((f) => f != answer).toList()
            ..shuffle(_random);
          wrong.add(otherFinals.first);
        }
        final pool = known.where((l) => l != answer && !wrong.contains(l)).toList()
          ..shuffle(_random);
        wrong.addAll(pool.take(3 - wrong.length));
        final options = [answer, ...wrong]..shuffle(_random);

        final nameAsset = LetterAudio.letterNameAsset(answer, characterFor(answer));
        final translation = wordTranslationOf(w);
        questions.add(TextQuestion(
          prompt: _wordPrompt(w, hideLast: true),
          options: options,
          answer: answer,
          promptSounds: [LetterAudio.wordAsset(w.id)],
          answerSounds: [if (nameAsset != null) nameAsset, LetterAudio.wordAsset(w.id)],
          doneText: _correctText(
              translation == null ? w.word : '${w.word} ($translation)'),
          note: isFinalLetter(answer)
              ? tr('$answer זו ${baseForm(answer)} סופית',
                  '$answer is the final form of ${baseForm(answer)}',
                  '$answer este forma finală a lui ${baseForm(answer)}')
              : null,
        ));
  }
  return questions;
}

/// "Which sound did you hear?" Half the questions keep the letter and
/// change the vowel (בָּ / בִּ / בּוּ), half keep the vowel and change the
/// letter (בָּ / דָּ / מָ).
List<TextQuestion> vowelRound() {
  final letters = syllableLetters()..shuffle(_random);
  if (letters.isEmpty) return const [];
  final questions = <TextQuestion>[];
  for (var q = 0; q < 6; q++) {
    final c = letters[q % letters.length];
    final vowel = vowels[_random.nextInt(vowels.length)];
    final answer = syllableText(c, vowel.id);
    final List<String> wrong;
    if (q.isEven || letters.length < 4) {
      final others = vowels.where((v) => v.id != vowel.id).toList()
        ..shuffle(_random);
      wrong = [for (final v in others.take(3)) syllableText(c, v.id)];
    } else {
      final others = letters.where((x) => x.id != c.id).toList()
        ..shuffle(_random);
      wrong = [for (final x in others.take(3)) syllableText(x, vowel.id)];
    }
    final asset = LetterAudio.syllableAsset(syllableId(c, vowel.id));
    questions.add(TextQuestion(
      prompt: const Icon(Icons.volume_up, size: 120, color: Colors.deepOrange),
      options: [answer, ...wrong]..shuffle(_random),
      answer: answer,
      promptSounds: [asset],
      answerSounds: [asset],
      doneText: _correctText(answer),
    ));
  }
  return questions;
}

// ---------- vowel chart ----------

bool _chartShownThisSession = false;

/// Shows the chart the first time the game is opened in this session.
Future<void> showVowelChartOnce(BuildContext context) async {
  if (_chartShownThisSession) return;
  _chartShownThisSession = true;
  await showVowelChart(context);
}

/// The five vowel marks on א, each tappable to hear it.
Future<void> showVowelChart(BuildContext context) {
  final audio = LetterAudio();
  final alef = hebrewCharacters.first;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Directionality(
      textDirection: appDirection,
      child: AlertDialog(
        title: Text(
          tr('הניקוד', 'The Vowel Marks', 'Semnele vocalelor'),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('הסימנים הקטנים אומרים איך קוראים את האות. לחצו לשמוע!',
                  'The little marks tell us how to read the letter. Tap to hear!',
                  'Semnele mici ne arată cum citim litera. Apasă ca să auzi!'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final v in vowels)
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => audio.playAsset(
                          LetterAudio.syllableAsset(syllableId(alef, v.id))),
                      child: Container(
                        width: 84,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              syllableText(alef, v.id),
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            Text(
                              uiLang == 'he' ? v.hebrewName : v.sound,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              tr('הבנתי! 👍', 'Got it! 👍', 'Am înțeles! 👍'),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    ),
  ).whenComplete(audio.dispose);
}
