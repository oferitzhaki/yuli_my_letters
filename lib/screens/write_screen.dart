// lib/screens/write_screen.dart
// Free writing: Yuli hears a letter and writes it on an empty screen.
// The app recognises what she wrote. If the letter is among the closest
// matches, she succeeds; otherwise she gets a gentle hint (the faded
// letter appears) and tries again.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/hebrew_characters.dart';
import '../services/letter_audio.dart';
import '../services/letter_recognizer.dart';
import '../services/progress_service.dart';
import '../widgets/round_complete_dialog.dart';

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  static const int questionsPerRound = 5;
  static const int pointsPerLetter = 10;

  // Forgiving on purpose: the target only has to be among the 3 closest
  // letters (look-alikes like ד/ר count), and not wildly different.
  static const int topMatches = 3;
  static const double maxScore = 4.5;

  final LetterAudio _audio = LetterAudio();
  final LetterRecognizer _recognizer = LetterRecognizer.instance;

  late List<HebrewCharacter> _roundLetters;
  int _index = 0;
  int _score = 0;

  final List<List<Offset>> _strokes = [];
  bool _ready = false;
  bool _done = false;
  bool _showHint = false;
  bool _hadFailure = false;
  String? _message;
  Timer? _idleTimer;
  double _side = 300;

  HebrewCharacter get _current => _roundLetters[_index];

  @override
  void initState() {
    super.initState();
    _recognizer.prepare().then((_) {
      if (mounted) setState(() => _ready = true);
    });
    _startRound();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _audio.dispose();
    super.dispose();
  }

  void _startRound() {
    _roundLetters =
        ProgressService.instance.pickRoundLetters(questionsPerRound);
    _index = 0;
    _score = 0;
    _startLetter();
  }

  void _startLetter() {
    _idleTimer?.cancel();
    _strokes.clear();
    _done = false;
    _showHint = false;
    _hadFailure = false;
    _message = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _audio.playWritePrompt(_current);
    });
  }

  // ---------- drawing ----------

  void _onPanStart(DragStartDetails d) {
    if (_done) return;
    _idleTimer?.cancel();
    setState(() => _strokes.add([d.localPosition]));
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_done || _strokes.isEmpty) return;
    setState(() => _strokes.last.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails d) {
    if (_done) return;
    // After a short pause, check quietly: celebrate if it's right,
    // stay silent if not (she may still be adding strokes).
    _idleTimer?.cancel();
    _idleTimer = Timer(
      const Duration(milliseconds: 1500),
      () => _check(quietIfWrong: true),
    );
  }

  void _clear() {
    if (_done) return;
    _idleTimer?.cancel();
    setState(() {
      _strokes.clear();
      _message = null;
    });
  }

  double _inkLength() {
    var total = 0.0;
    for (final s in _strokes) {
      for (var i = 1; i < s.length; i++) {
        total += (s[i] - s[i - 1]).distance;
      }
    }
    return total;
  }

  // ---------- checking ----------

  void _check({bool quietIfWrong = false}) {
    _idleTimer?.cancel();
    if (!mounted || _done || !_ready || _strokes.isEmpty) return;

    if (_inkLength() < _side * 0.25) {
      if (!quietIfWrong) {
        setState(() => _message = 'נסי לכתוב אות גדולה יותר 🙂');
      }
      return;
    }

    final ranked = _recognizer.rank(_strokes);
    final position = ranked.indexWhere((r) => r.id == _current.id);
    final success = position >= 0 &&
        position < topMatches &&
        ranked[position].score <= maxScore;

    if (success) {
      _succeed();
    } else if (!quietIfWrong) {
      _fail();
    }
  }

  void _succeed() {
    final firstTry = !_hadFailure && !_showHint;
    setState(() {
      _done = true;
      _score += pointsPerLetter;
      _message = null;
    });
    final p = ProgressService.instance;
    p.addStars(pointsPerLetter);
    p.recordCorrect(_current.id, firstTry: firstTry);
    _advanceAfter(_audio.playLetterThenPraise(_current));
  }

  void _fail() {
    setState(() {
      _hadFailure = true;
      _showHint = true;
      _strokes.clear();
      _message = 'כמעט! הנה האות, נסי לכתוב אותה שוב';
    });
    _audio.playTryAgain().then((finished) {
      if (finished && mounted && !_done) _audio.playLetter(_current);
    });
  }

  Future<void> _advanceAfter(Future<bool> feedback) async {
    await Future.wait<Object?>([
      feedback,
      Future<void>.delayed(const Duration(milliseconds: 800)),
    ]);
    if (!mounted) return;
    if (_index + 1 >= _roundLetters.length) {
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
      _startLetter();
    });
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final text = _done
        ? '🎉 נכון! ${_current.letter}'
        : _message ?? 'כתבי את האות ששמעת ✍️';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCE4EC),
        appBar: AppBar(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          title: Text('כתיבה חופשית · ${_index + 1}/${_roundLetters.length}'),
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
              // No scrolling: the finger must draw, not scroll.
              _side = min(constraints.maxWidth - 32,
                      constraints.maxHeight - 200)
                  .clamp(200.0, 560.0)
                  .toDouble();

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 34,
                      width: _side,
                      child: FittedBox(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _done ? Colors.green : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: _side,
                      height: _side,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 12),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: CustomPaint(
                            size: Size(_side, _side),
                            painter: _WritePainter(
                              strokes: _strokes,
                              hintLetter:
                                  _showHint || _done ? _current.letter : null,
                              done: _done,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _done || !_ready ? null : _check,
                          icon: const Icon(Icons.check, size: 26),
                          label: Text(
                            _ready ? 'בדקי' : 'מכין...',
                            style: const TextStyle(fontSize: 20),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _done ? null : _clear,
                          icon: const Icon(Icons.refresh),
                          label: const Text('מחיקה',
                              style: TextStyle(fontSize: 17)),
                        ),
                        OutlinedButton.icon(
                          onPressed: _done || _showHint
                              ? null
                              : () => setState(() => _showHint = true),
                          icon: const Icon(Icons.lightbulb_outline),
                          label: const Text('רמז',
                              style: TextStyle(fontSize: 17)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _audio.playWritePrompt(_current),
                          icon: const Icon(Icons.volume_up),
                          label: const Text('שמעי',
                              style: TextStyle(fontSize: 17)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WritePainter extends CustomPainter {
  _WritePainter({
    required this.strokes,
    required this.hintLetter,
    required this.done,
  });

  final List<List<Offset>> strokes;
  final String? hintLetter;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    final hint = hintLetter;
    if (hint != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: hint,
          style: TextStyle(
            fontSize: size.width * 0.78,
            fontWeight: FontWeight.bold,
            color: done ? const Color(0xFFC8E6C9) : const Color(0xFFEEEEEE),
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(
        canvas,
        Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
      );
    }

    final paint = Paint()
      ..color = done ? Colors.green : Colors.pink
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          paint.strokeWidth / 2,
          Paint()..color = paint.color,
        );
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WritePainter oldDelegate) => true;
}
