// lib/screens/letter_intro_screen.dart
// "Meet the letters": one letter at a time, big, with its picture.
// Plays the letter name and then the word, e.g. "אָלֶף ... אַרְיֵה".
// When the app speaks another language than the one being learned, it
// also shows and plays the translation ("leu") and how the letter
// sounds in the child's letters ("Se citește: B"), and the first time
// explains which way the new alphabet is read.

import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/hebrew_characters.dart';
import '../services/letter_audio.dart';
import '../services/progress_service.dart';
import '../services/profile_service.dart';

class LetterIntroScreen extends StatefulWidget {
  const LetterIntroScreen({super.key});

  @override
  State<LetterIntroScreen> createState() => _LetterIntroScreenState();
}

class _LetterIntroScreenState extends State<LetterIntroScreen> {
  final LetterAudio _audio = LetterAudio();
  late final List<HebrewCharacter> _letters;
  int _index = 0;

  HebrewCharacter get _current => _letters[_index];
  bool get _isLast => _index == _letters.length - 1;

  @override
  void initState() {
    super.initState();
    final p = ProgressService.instance;
    // New letters if there are any, otherwise a review of all open letters.
    _letters = p.lettersToIntroduce.isNotEmpty
        ? p.lettersToIntroduce
        : p.unlockedLetters;
    // Very first letter, and the new alphabet runs the other way.
    final firstTime = !p.isIntroduced(activeLetters.first.id);
    if (firstTime && learnDirection != appDirection) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _explainDirection();
        if (mounted) _announce();
      });
    } else {
      _showCurrent();
    }
  }

  /// "In Hebrew we read and write from right to left", with the first
  /// letters laid out that way and an arrow.
  Future<void> _explainDirection() {
    final rtl = learnDirection == TextDirection.rtl;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: appDirection,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Directionality(
                textDirection: learnDirection,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final c in activeLetters.take(3))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          c.letter,
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(rtl ? '⬅️' : '➡️', style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                rtl
                    ? tr(
                        'בעברית קוראים וכותבים מימין לשמאל',
                        'In Hebrew we read and write from right to left',
                        'În ebraică citim și scriem de la dreapta la stânga')
                    : tr(
                        'באנגלית קוראים וכותבים משמאל לימין',
                        'In English we read and write from left to right',
                        'În engleză citim și scriem de la stânga la dreapta'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                tr('הבנתי! 👍', 'Got it! 👍', 'Am înțeles! 👍'),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  void _showCurrent() {
    // After the frame: updating progress notifies the menu behind us,
    // which must not happen while this screen is still being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _announce();
    });
  }

  void _announce() {
    ProgressService.instance.markIntroduced(_current.id);
    _audio.playLetterThenWord(_current);
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    setState(() => _index++);
    _showCurrent();
  }

  void _previous() {
    if (_index == 0) return;
    setState(() => _index--);
    _showCurrent();
  }

  void _finish() {
    _audio.playIntroDone();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: appDirection,
        child: AlertDialog(
          title: Text(
            tr(
                '🎉 כל הכבוד ${ProfileService.instance.name}!',
                '🎉 Great job, ${ProfileService.instance.name}!',
                '🎉 Bravo, ${ProfileService.instance.name}!'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28),
          ),
          content: Text(
            tr(
                'הכרת ${_letters.length} אותיות.\nעכשיו אפשר לשחק איתן!',
                "You met ${_letters.length} letters.\nNow let's play with them!",
                'Ai cunoscut ${roCount(_letters.length, 'literă', 'litere')}.\nAcum hai să ne jucăm cu ele!'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: Text(tr('למשחקים 🎮', 'To the games 🎮'),
                  style: const TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: appDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F5E9),
        appBar: AppBar(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          title: Text(
            '${tr(g('הכירי את האותיות', 'הכר את האותיות'), 'Meet the Letters')} · ${_index + 1}/${_letters.length}',
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final w = constraints.maxWidth;
              final letterSize =
                  min(h * 0.34, w * 0.6).clamp(120.0, 280.0).toDouble();
              final pictureHeight = (h * 0.16).clamp(70.0, 140.0).toDouble();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      // The letter - tap to hear its name.
                      GestureDetector(
                        onTap: () => _audio.playLetter(_current),
                        child: Container(
                          width: letterSize,
                          height: letterSize,
                          padding: EdgeInsets.all(letterSize * 0.1),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 14),
                            ],
                          ),
                          child: FittedBox(
                            child: Text(
                              _current.letter,
                              style: const TextStyle(
                                fontSize: 200,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // How it sounds in the child's letters: "Se citește: Ț".
                      if (soundHintOf(_current) != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              '${tr('נשמעת כמו', 'Sounds like', 'Se citește')}: '
                              '${soundHintOf(_current)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // The picture and word - tap to hear the word.
                      GestureDetector(
                        onTap: () => _audio.playWordWithTranslation(_current),
                        child: Container(
                          height: pictureHeight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: FittedBox(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _current.emoji,
                                  style: const TextStyle(fontSize: 80),
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _current.animalName,
                                      style: const TextStyle(
                                        fontSize: 56,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // The word in the child's own language.
                                    if (translationOf(_current) != null)
                                      Text(
                                        translationOf(_current)!,
                                        style: const TextStyle(
                                          fontSize: 40,
                                          color: Colors.black54,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: () => _audio.playLetterThenWord(_current),
                        icon: const Icon(Icons.volume_up, size: 28),
                        label: Text(
                          tr(g('שמעי שוב', 'שמע שוב'), 'Listen again'),
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_index > 0) ...[
                            OutlinedButton(
                              onPressed: _previous,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                tr('הקודמת', 'Back'),
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          FilledButton.icon(
                            onPressed: _next,
                            // arrow_forward flips automatically in RTL
                            icon: Icon(
                              _isLast ? Icons.check : Icons.arrow_forward,
                              size: 28,
                            ),
                            label: Text(
                              _isLast
                                  ? tr('סיימתי!', 'Done!')
                                  : tr('הבאה', 'Next'),
                              style: const TextStyle(fontSize: 22),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
