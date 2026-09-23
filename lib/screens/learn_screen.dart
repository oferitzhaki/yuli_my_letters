// lib/screens/learn_screen.dart
// "See & Match": a letter is shown and spoken; Yuli taps the animal
// whose name starts with that letter.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/hebrew_characters.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  static const int questionsPerRound = 5; // short rounds suit a 4-year-old
  static const int pointsPerCorrect = 5;

  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();

  late List<HebrewCharacter> _roundLetters;
  late List<HebrewCharacter> _options;
  final Set<String> _wrongPicks = {};
  int _questionIndex = 0;
  int _score = 0;
  bool _answeredCorrectly = false;

  HebrewCharacter get _current => _roundLetters[_questionIndex];

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _startRound() {
    _roundLetters = (List.of(hebrewCharacters)..shuffle(_random))
        .take(questionsPerRound)
        .toList();
    _questionIndex = 0;
    _score = 0;
    _prepareQuestion();
  }

  void _prepareQuestion() {
    final others = hebrewCharacters
        .where((c) => c.id != _current.id)
        .toList()
      ..shuffle(_random);
    _options = [_current, ...others.take(3)]..shuffle(_random);
    _wrongPicks.clear();
    _answeredCorrectly = false;
    // Speak the letter as soon as the new question is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _playLetter());
  }

  Future<void> _playLetter() async {
    if (!mounted) return;
    try {
      await _player.stop();
      await _player.setAsset('assets/audio/${_current.id}.mp3');
      _player.play();
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  void _onOptionTap(HebrewCharacter option) {
    if (_answeredCorrectly || _wrongPicks.contains(option.id)) return;

    if (option.id == _current.id) {
      setState(() {
        _answeredCorrectly = true;
        _score += pointsPerCorrect;
      });
      _playLetter(); // hear it once more as reinforcement
      Future.delayed(const Duration(milliseconds: 1800), _nextQuestion);
    } else {
      // Gentle feedback: fade the wrong animal and replay the letter as a hint.
      setState(() => _wrongPicks.add(option.id));
      _playLetter();
    }
  }

  void _nextQuestion() {
    if (!mounted) return;
    if (_questionIndex + 1 >= _roundLetters.length) {
      _showRoundComplete();
      return;
    }
    setState(() {
      _questionIndex++;
      _prepareQuestion();
    });
  }

  void _showRoundComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            '🎉 כל הכבוד יולי!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28),
          ),
          content: Text(
            'צברת $_score נקודות ⭐',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('הביתה 🏠', style: TextStyle(fontSize: 18)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(_startRound);
              },
              child: const Text('עוד סיבוב 🔄', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF3E0),
        appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          title: Text('שאלה ${_questionIndex + 1} מתוך ${_roundLetters.length}'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '⭐ $_score',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    const Text(
                      'איזו חיה מתחילה באות הזו?',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // The letter itself - tap it to hear it again.
                    GestureDetector(
                      onTap: _playLetter,
                      child: Container(
                        width: 200,
                        height: 200,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 12),
                          ],
                        ),
                        child: Text(
                          _current.letter,
                          style: const TextStyle(
                            fontSize: 130,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _playLetter,
                      icon: const Icon(Icons.volume_up, size: 32),
                      label: const Text('שמעי שוב', style: TextStyle(fontSize: 20)),
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

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: _options.map(_buildOption).toList(),
                    ),

                    const SizedBox(height: 16),
                    if (_answeredCorrectly)
                      Text(
                        '🎉 נכון! ${_current.animalName} ${_current.emoji}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(HebrewCharacter option) {
    final isWrong = _wrongPicks.contains(option.id);
    final isCorrect = _answeredCorrectly && option.id == _current.id;

    Color background = Colors.white;
    if (isCorrect) {
      background = Colors.green.shade200;
    } else if (isWrong) {
      background = Colors.grey.shade300;
    }

    return AnimatedOpacity(
      opacity: isWrong ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: background,
        elevation: isWrong ? 0 : 4,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _onOptionTap(option),
          child: Center(
            child: Text(option.emoji, style: const TextStyle(fontSize: 72)),
          ),
        ),
      ),
    );
  }
}
