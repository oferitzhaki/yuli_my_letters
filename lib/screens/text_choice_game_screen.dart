// lib/screens/text_choice_game_screen.dart
// A game with a question and four WRITTEN answers (letters, final letters
// or syllables), used by "last letter" and "vowel marks". Each game only
// builds its questions; this screen runs the round.

import 'dart:math';

import 'package:flutter/material.dart';

import '../services/letter_audio.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../widgets/round_complete_dialog.dart';

class TextQuestion {
  const TextQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    required this.promptSounds,
    required this.answerSounds,
    required this.doneText,
    this.note,
  });

  /// What is shown in the big box (a picture, a speaker icon...).
  final Widget prompt;

  /// The four answers as written; one of them is [answer].
  final List<String> options;
  final String answer;

  /// Played at the start, on "listen again" and after a wrong answer.
  final List<String> promptSounds;

  /// Played before the praise when the answer is right.
  final List<String> answerSounds;

  /// Shown after a right answer, e.g. "🎉 Correct! קוף".
  final String doneText;

  /// Optional extra line, e.g. "ף is the final form of פ".
  final String? note;
}

class TextChoiceGameScreen extends StatefulWidget {
  const TextChoiceGameScreen({
    super.key,
    required this.title,
    required this.instruction,
    required this.makeRound,
    required this.color,
    this.pointsPerCorrect = 5,
    this.helpButton,
    this.beforeStart,
  });

  final String title;
  final String instruction;
  final List<TextQuestion> Function() makeRound;
  final Color color;
  final int pointsPerCorrect;

  /// Optional button in the top bar (e.g. the vowel chart).
  final Widget Function(BuildContext context)? helpButton;

  /// Optional step before the first question (e.g. show the vowel chart).
  final Future<void> Function(BuildContext context)? beforeStart;

  @override
  State<TextChoiceGameScreen> createState() => _TextChoiceGameScreenState();
}

class _TextChoiceGameScreenState extends State<TextChoiceGameScreen> {
  final LetterAudio _audio = LetterAudio();

  late List<TextQuestion> _questions;
  int _index = 0;
  int _score = 0;
  final Set<int> _wrongPicks = {};
  bool _answered = false;

  TextQuestion get _current => _questions[_index];

  @override
  void initState() {
    super.initState();
    _questions = widget.makeRound();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final before = widget.beforeStart;
      if (before != null) await before(context);
      _playPrompt();
    });
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  void _startRound() {
    _questions = widget.makeRound();
    _index = 0;
    _score = 0;
    _wrongPicks.clear();
    _answered = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPrompt());
  }

  void _playPrompt() {
    if (!mounted || _questions.isEmpty) return;
    _audio.playAll(_current.promptSounds);
  }

  void _onTap(int i) {
    if (_answered || _wrongPicks.contains(i)) return;
    if (_current.options[i] == _current.answer) {
      ProgressService.instance.addStars(widget.pointsPerCorrect);
      setState(() {
        _answered = true;
        _score += widget.pointsPerCorrect;
      });
      _advanceAfter(_audio.playThenPraise(_current.answerSounds));
    } else {
      setState(() => _wrongPicks.add(i));
      _audio.playTryAgain().then((finished) {
        if (finished && mounted && !_answered) _playPrompt();
      });
    }
  }

  Future<void> _advanceAfter(Future<bool> feedback) async {
    await Future.wait<Object?>([
      feedback,
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (!mounted) return;
    if (_index + 1 >= _questions.length) {
      _audio.playRoundDone();
      showRoundCompleteDialog(
        context,
        score: _score,
        onPlayAgain: () => setState(_startRound),
      );
      return;
    }
    setState(() {
      _index++;
      _wrongPicks.clear();
      _answered = false;
    });
    _playPrompt();
  }

  @override
  Widget build(BuildContext context) {
    final help = widget.helpButton;
    return Directionality(
      textDirection: appDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FF),
        appBar: AppBar(
          backgroundColor: widget.color,
          foregroundColor: Colors.white,
          title: Text(
            _questions.isEmpty
                ? widget.title
                : '${widget.title} · ${_index + 1}/${_questions.length}',
          ),
          actions: [
            if (help != null) help(context),
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
          child: _questions.isEmpty
              ? const SizedBox.shrink()
              : LayoutBuilder(builder: _buildBody),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BoxConstraints constraints) {
    // Everything sized from the screen so it fits without scrolling.
    const gap = 12.0;
    final width = min(constraints.maxWidth - 32, 460.0);
    final height = constraints.maxHeight;
    final promptSize = (height * 0.24).clamp(100.0, 190.0).toDouble();
    const fixedParts = 36.0 + 52.0 + 60.0 + 5 * gap + 24.0;
    final gridHeight = height - promptSize - fixedParts;
    final cell = min((width - gap) / 2, (gridHeight - gap) / 2)
        .clamp(64.0, 180.0)
        .toDouble();
    final q = _current;

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
                width: promptSize * 1.3,
                height: promptSize,
                padding: EdgeInsets.all(promptSize * 0.08),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 12),
                  ],
                ),
                child: FittedBox(child: q.prompt),
              ),
            ),
            const SizedBox(height: gap),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _playPrompt,
                icon: const Icon(Icons.volume_up, size: 28),
                label: Text(
                  tr(g('שמעי שוב', 'שמע שוב'), 'Listen again'),
                  style: const TextStyle(fontSize: 18),
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
                children: [
                  for (var i = 0; i < q.options.length; i++)
                    SizedBox(width: cell, height: cell, child: _option(i)),
                ],
              ),
            ),
            const SizedBox(height: gap),
            SizedBox(
              height: 60,
              width: width,
              child: _answered
                  ? Column(
                      children: [
                        Expanded(
                          child: FittedBox(
                            child: Text(
                              q.doneText,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                        if (q.note != null)
                          Expanded(
                            child: FittedBox(
                              child: Text(
                                q.note!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(int i) {
    final q = _current;
    final isWrong = _wrongPicks.contains(i);
    final isRight = _answered && q.options[i] == q.answer;
    Color background = Colors.white;
    if (isRight) {
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
          onTap: () => _onTap(i),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: FittedBox(
              child: Text(
                q.options[i],
                textDirection: learnDirection,
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
