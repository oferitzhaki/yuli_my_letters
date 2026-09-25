// lib/screens/trace_screen.dart
// Tracing: a big faded letter; Yuli draws over it with her finger.
//
// How success is detected: the letter is also drawn off-screen onto a small
// grid. After every stroke we measure
//   coverage = how much of the letter she has coloured
//   accuracy = how much of her drawing is on (or next to) the letter
// Both above the goal -> success. Scribbling everywhere fails accuracy.

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../constants/hebrew_characters.dart';
import '../services/letter_audio.dart';
import '../services/progress_service.dart';
import '../widgets/round_complete_dialog.dart';
import '../services/profile_service.dart';

// Lenient on purpose - she is 4. Raise these to make it stricter.
const double _coverageGoal = 0.75;
const double _accuracyGoal = 0.65;
const int _grid = 64;

void _paintLetter(Canvas canvas, double side, String letter, Color color) {
  final tp = TextPainter(
    text: TextSpan(
      text: letter,
      style: TextStyle(
        fontSize: side * 0.78,
        fontWeight: FontWeight.bold,
        color: color,
        height: 1.0,
      ),
    ),
    textDirection: appDirection,
  )..layout();
  tp.paint(canvas, Offset((side - tp.width) / 2, (side - tp.height) / 2));
}

class TraceScreen extends StatefulWidget {
  const TraceScreen({super.key});

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen> {
  static const int questionsPerRound = 5;
  static const int pointsPerLetter = 10;

  final LetterAudio _audio = LetterAudio();

  late List<HebrewCharacter> _roundLetters;
  int _index = 0;
  int _score = 0;

  final List<List<Offset>> _strokes = [];
  List<bool>? _mask; // letter pixels on the grid
  List<bool>? _near; // letter pixels, slightly thickened
  int _maskCount = 0;
  double _coverage = 0;
  bool _offTrack = false;
  bool _done = false;
  double _side = 300;

  HebrewCharacter get _current => _roundLetters[_index];

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
    _roundLetters =
        ProgressService.instance.pickRoundLetters(questionsPerRound);
    _index = 0;
    _score = 0;
    _startLetter();
  }

  void _startLetter() {
    _strokes.clear();
    _mask = null;
    _near = null;
    _maskCount = 0;
    _coverage = 0;
    _offTrack = false;
    _done = false;
    final letter = _current.letter;
    _buildMask(letter).then((_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _audio.playLetter(_current);
    });
  }

  // ---------- mask ----------

  Future<void> _buildMask(String letter) async {
    // On the web the Hebrew font may still be loading, so retry a few
    // times until the letter actually shows up on the grid.
    for (var attempt = 0; attempt < 8; attempt++) {
      final mask = await _renderMask(letter);
      final count = mask.where((b) => b).length;
      if (!mounted || letter != _current.letter) return;
      if (count >= 20) {
        setState(() {
          _mask = mask;
          _maskCount = count;
          _near = _dilate(mask, 3);
        });
        return;
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  Future<List<bool>> _renderMask(String letter) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _paintLetter(canvas, _grid.toDouble(), letter, Colors.black);
    final image = await recorder.endRecording().toImage(_grid, _grid);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) return List<bool>.filled(_grid * _grid, false);
    final bytes = data.buffer.asUint8List();
    return List<bool>.generate(_grid * _grid, (i) => bytes[i * 4 + 3] > 60);
  }

  List<bool> _dilate(List<bool> mask, int r) {
    final out = List<bool>.filled(_grid * _grid, false);
    for (var y = 0; y < _grid; y++) {
      for (var x = 0; x < _grid; x++) {
        if (!mask[y * _grid + x]) continue;
        for (var dy = -r; dy <= r; dy++) {
          for (var dx = -r; dx <= r; dx++) {
            final nx = x + dx, ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= _grid || ny >= _grid) continue;
            out[ny * _grid + nx] = true;
          }
        }
      }
    }
    return out;
  }

  // ---------- drawing ----------

  void _onPanStart(DragStartDetails d) {
    if (_done) return;
    setState(() => _strokes.add([d.localPosition]));
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_done || _strokes.isEmpty) return;
    setState(() => _strokes.last.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails d) {
    if (_done) return;
    _evaluate();
  }

  void _clear() {
    if (_done) return;
    setState(() {
      _strokes.clear();
      _coverage = 0;
      _offTrack = false;
    });
  }

  void _evaluate() {
    final mask = _mask;
    final near = _near;
    if (mask == null || near == null || _maskCount == 0) return;

    final touched = List<bool>.filled(_grid * _grid, false);
    final scale = _grid / _side;
    final brush = max(2, (_grid * 0.045).round());
    var samples = 0;
    var hits = 0;

    for (final stroke in _strokes) {
      for (var i = 0; i < stroke.length; i++) {
        final a = stroke[i];
        final b = i + 1 < stroke.length ? stroke[i + 1] : a;
        final steps = max(1, ((b - a).distance * scale * 2).ceil());
        for (var s = 0; s < steps; s++) {
          final p = Offset.lerp(a, b, s / steps)! * scale;
          final cx = p.dx.floor();
          final cy = p.dy.floor();
          samples++;
          if (cx < 0 || cy < 0 || cx >= _grid || cy >= _grid) continue;
          if (near[cy * _grid + cx]) hits++;
          for (var dy = -brush; dy <= brush; dy++) {
            for (var dx = -brush; dx <= brush; dx++) {
              if (dx * dx + dy * dy > brush * brush) continue;
              final nx = cx + dx, ny = cy + dy;
              if (nx < 0 || ny < 0 || nx >= _grid || ny >= _grid) continue;
              touched[ny * _grid + nx] = true;
            }
          }
        }
      }
    }

    var covered = 0;
    for (var i = 0; i < mask.length; i++) {
      if (mask[i] && touched[i]) covered++;
    }
    final coverage = covered / _maskCount;
    final accuracy = samples == 0 ? 0.0 : hits / samples;

    setState(() {
      _coverage = coverage;
      _offTrack = samples > 30 && accuracy < _accuracyGoal;
    });

    if (coverage >= _coverageGoal && accuracy >= _accuracyGoal) {
      _succeed();
    }
  }

  void _succeed() {
    setState(() {
      _done = true;
      _score += pointsPerLetter;
    });
    ProgressService.instance.addStars(pointsPerLetter);
    _advanceAfter(_audio.playLetterThenPraise(_current));
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
    return Directionality(
      textDirection: appDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8EAF6),
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          title: Text(
            '${tr('מעקב אחרי האות', 'Trace the Letter')} · ${_index + 1}/${_roundLetters.length}',
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
              // No scrolling here: the finger must draw, not scroll.
              _side = min(constraints.maxWidth - 32, constraints.maxHeight - 190)
                  .clamp(200.0, 560.0)
                  .toDouble();
              final progress = (_coverage / _coverageGoal).clamp(0.0, 1.0);

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 34,
                      width: _side,
                      child: FittedBox(
                        child: Text(
                          _done
                              ? tr('🎉 נכון! ${_current.letter}', '🎉 Correct! ${_current.letter}')
                              : _offTrack
                                  ? tr(
                                      g('נסי לצייר רק על האות האפורה 🙂',
                                          'נסה לצייר רק על האות האפורה 🙂'),
                                      'Try to draw only on the grey letter 🙂')
                                  : tr(
                                      g('ציירי על האות באצבע ✏️',
                                          'צייר על האות באצבע ✏️'),
                                      'Trace the letter with your finger ✏️'),
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
                            painter: _TracePainter(
                              letter: _current.letter,
                              strokes: _strokes,
                              done: _done,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: _side,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 14,
                          backgroundColor: Colors.white,
                          color: _done ? Colors.green : Colors.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _done ? null : _clear,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            tr('מחיקה', 'Clear'),
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _audio.playLetter(_current),
                          icon: const Icon(Icons.volume_up),
                          label: Text(
                            tr(g('שמעי', 'שמע'), 'Listen'),
                            style: TextStyle(fontSize: 18),
                          ),
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

class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.letter,
    required this.strokes,
    required this.done,
  });

  final String letter;
  final List<List<Offset>> strokes;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    _paintLetter(
      canvas,
      size.width,
      letter,
      done ? const Color(0xFFC8E6C9) : const Color(0xFFE0E0E0),
    );

    final paint = Paint()
      ..color = done ? Colors.green : Colors.deepOrange
      ..strokeWidth = size.width * 0.08
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
  bool shouldRepaint(covariant _TracePainter oldDelegate) => true;
}
