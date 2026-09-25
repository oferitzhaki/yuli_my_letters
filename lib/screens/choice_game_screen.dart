// lib/screens/choice_game_screen.dart
// Shared engine for the "one prompt, four choices" games.
// Each game only decides what the prompt and the options look like,
// and which sound the prompt plays.

import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/hebrew_characters.dart';
import '../services/letter_audio.dart';
import '../services/progress_service.dart';
import '../widgets/round_complete_dialog.dart';

typedef CharacterWidgetBuilder = Widget Function(HebrewCharacter c);
typedef CharacterSound = Future<void> Function(
    LetterAudio audio, HebrewCharacter c);

class ChoiceGameScreen extends StatefulWidget {
  const ChoiceGameScreen({
    super.key,
    required this.title,
    required this.instruction,
    required this.promptBuilder,
    required this.optionBuilder,
    required this.playPrompt,
    this.questionsPerRound = 5,
    this.pointsPerCorrect = 5,
  });

  final String title;
  final String instruction;
  final CharacterWidgetBuilder promptBuilder;
  final CharacterWidgetBuilder optionBuilder;
  final CharacterSound playPrompt;
  final int questionsPerRound;
  final int pointsPerCorrect;

  @override
  State<ChoiceGameScreen> createState() => _ChoiceGameScreenState();
}

class _ChoiceGameScreenState extends State<ChoiceGameScreen> {
  final LetterAudio _audio = LetterAudio();
  final Random _random = Random();

  late List<HebrewCharacter> _roundLetters;
  late List<HebrewCharacter> _options;
  final Set<String> _wrongPicks = {};
  int _questionIndex = 0;
  int _score = 0;
  bool _answeredCorrectly = false;
  bool _unlockedThisRound = false;

  ProgressService get _progress => ProgressService.instance;

  HebrewCharacter get _current => _roundLetters[_questionIndex];

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  void _startRound() {
    _roundLetters = _progress.pickRoundLetters(widget.questionsPerRound);
    _unlockedThisRound = false;
    _questionIndex = 0;
    _score = 0;
    _prepareQuestion();
  }

  void _prepareQuestion() {
    final others = _progress.playableLetters
        .where((c) => c.id != _current.id)
        .toList()
      ..shuffle(_random);
    _options = [_current, ...others.take(3)]..shuffle(_random);
    _wrongPicks.clear();
    _answeredCorrectly = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPrompt());
  }

  void _playPrompt() {
    if (!mounted) return;
    widget.playPrompt(_audio, _current);
  }

  void _onOptionTap(HebrewCharacter option) {
    if (_answeredCorrectly || _wrongPicks.contains(option.id)) return;

    if (option.id == _current.id) {
      final firstTry = _wrongPicks.isEmpty;
      _progress.addStars(widget.pointsPerCorrect);
      if (_progress.recordCorrect(_current.id, firstTry: firstTry)) {
        _unlockedThisRound = true;
      }
      setState(() {
        _answeredCorrectly = true;
        _score += widget.pointsPerCorrect;
      });
      _advanceAfter(_audio.playLetterThenPraise(_current));
    } else {
      if (_wrongPicks.isEmpty) _progress.recordMistake(_current.id);
      setState(() => _wrongPicks.add(option.id));
      // "Almost! Try again", then the question again as a hint.
      _audio.playTryAgain().then((finished) {
        if (finished && mounted && !_answeredCorrectly) _playPrompt();
      });
    }
  }

  /// Waits for the praise to finish (and at least a moment), then moves on.
  Future<void> _advanceAfter(Future<bool> feedback) async {
    await Future.wait<Object?>([
      feedback,
      Future<void>.delayed(const Duration(milliseconds: 800)),
    ]);
    _nextQuestion();
  }

  void _nextQuestion() {
    if (!mounted) return;
    if (_questionIndex + 1 >= _roundLetters.length) {
      _audio.playRoundDone(unlocked: _unlockedThisRound);
      showRoundCompleteDialog(
        context,
        score: _score,
        unlockedNew: _unlockedThisRound,
        onPlayAgain: () => setState(_startRound),
      );
      return;
    }
    setState(() {
      _questionIndex++;
      _prepareQuestion();
    });
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
          title: Text(
            '${widget.title} · ${_questionIndex + 1}/${_roundLetters.length}',
          ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Size everything from the available space so the whole game
              // fits on one screen (phone, tablet or browser) without scrolling.
              const gap = 12.0;
              final width = min(constraints.maxWidth - 32, 460.0);
              final height = constraints.maxHeight;
              final promptSize = (height * 0.22).clamp(90.0, 170.0).toDouble();
              // instruction + button + feedback line + gaps + padding
              const fixedParts = 36.0 + 52.0 + 36.0 + 5 * gap + 24.0;
              final gridHeight = height - promptSize - fixedParts;
              final cell = min((width - gap) / 2, (gridHeight - gap) / 2)
                  .clamp(70.0, 200.0)
                  .toDouble();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 36,
                        width: width,
                        child: FittedBox(
                          child: Text(
                            widget.instruction,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: gap),
                      GestureDetector(
                        onTap: _playPrompt,
                        child: Container(
                          width: promptSize,
                          height: promptSize,
                          padding: EdgeInsets.all(promptSize * 0.12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 12),
                            ],
                          ),
                          child: FittedBox(
                            child: widget.promptBuilder(_current),
                          ),
                        ),
                      ),
                      const SizedBox(height: gap),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _playPrompt,
                          icon: const Icon(Icons.volume_up, size: 28),
                          label: const Text(
                            'שמעי שוב',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: gap),
                      SizedBox(
                        width: cell * 2 + gap,
                        child: Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: _options
                              .map((o) => SizedBox(
                                    width: cell,
                                    height: cell,
                                    child: _buildOption(o),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: gap),
                      SizedBox(
                        height: 36,
                        width: width,
                        child: _answeredCorrectly
                            ? FittedBox(
                                child: Text(
                                  '🎉 נכון! ${_current.letter} · ${_current.emoji} ${_current.animalName}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              )
                            : null,
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: FittedBox(child: widget.optionBuilder(option)),
          ),
        ),
      ),
    );
  }
}
