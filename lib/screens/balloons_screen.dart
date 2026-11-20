// lib/screens/balloons_screen.dart
// Balloons: four balloons with letters float up. The child hears a letter
// and pops its balloon before it flies away. If it escapes, the same letter
// comes back on new balloons (no penalty). Each popped letter makes the
// next balloons a little faster.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../constants/hebrew_characters.dart';
import '../services/letter_audio.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../widgets/round_complete_dialog.dart';

class _Balloon {
  _Balloon(this.letter, this.x, this.y, this.color);

  final HebrewCharacter letter;
  final double x; // centre, as a fraction of the width
  double y; // top, as a fraction of the height (starts below the screen)
  final Color color;
  bool popped = false;
  bool wrong = false;
}

class BalloonsScreen extends StatefulWidget {
  const BalloonsScreen({super.key});

  @override
  State<BalloonsScreen> createState() => _BalloonsScreenState();
}

class _BalloonsScreenState extends State<BalloonsScreen>
    with SingleTickerProviderStateMixin {
  static const int targetsPerRound = 8;
  static const int pointsPerPop = 5;
  static const List<Color> _colors = [
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFFFA726),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
  ];

  final LetterAudio _audio = LetterAudio();
  final Random _random = Random();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  List<_Balloon> _balloons = [];
  HebrewCharacter? _target;
  int _found = 0;
  int _score = 0;
  bool _waveDone = false;
  bool _flewAway = false;

  double get _speed => 0.09 + 0.012 * _found; // screen heights per second

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    _newWave(newTarget: true);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _audio.dispose();
    super.dispose();
  }

  void _newWave({required bool newTarget}) {
    final letters = List.of(ProgressService.instance.playableLetters);
    if (letters.isEmpty) return;
    if (newTarget || _target == null) {
      final choices = letters.where((c) => c.id != _target?.id).toList();
      _target = (choices.isEmpty ? letters : choices)[
          _random.nextInt((choices.isEmpty ? letters : choices).length)];
    }
    final target = _target!;
    final others = letters.where((c) => c.id != target.id).toList()
      ..shuffle(_random);
    final lanes = [0.14, 0.38, 0.62, 0.86]..shuffle(_random);
    final colors = List.of(_colors)..shuffle(_random);
    final picked = [target, ...others.take(3)];
    _balloons = [
      for (var i = 0; i < picked.length; i++)
        _Balloon(picked[i], lanes[i], 1.05 + _random.nextDouble() * 0.35,
            colors[i]),
    ];
    _waveDone = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _audio.playLetter(target);
    });
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.5) return; // first frame, or the app was paused
    var escaped = false;
    for (final b in _balloons) {
      if (b.popped) continue;
      b.y -= _speed * dt;
      if (!_waveDone && b.letter.id == _target?.id && b.y < -0.3) {
        escaped = true;
      }
    }
    if (escaped) {
      // The right balloon flew away: same letter again, on new balloons.
      _flewAway = true;
      _newWave(newTarget: false);
    }
    setState(() {});
  }

  void _onTap(_Balloon b) {
    if (_waveDone || b.popped || b.wrong) return;
    if (b.letter.id == _target?.id) {
      ProgressService.instance.addStars(pointsPerPop);
      setState(() {
        b.popped = true;
        _waveDone = true;
        _flewAway = false;
        _found++;
        _score += pointsPerPop;
      });
      _afterPop();
    } else {
      setState(() => b.wrong = true);
      _audio.playTryAgain().then((finished) {
        final t = _target;
        if (finished && mounted && !_waveDone && t != null) {
          _audio.playLetter(t);
        }
      });
    }
  }

  Future<void> _afterPop() async {
    final t = _target!;
    await Future.wait<Object?>([
      _audio.playThenPraise([LetterAudio.letterAsset(t)]),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]);
    if (!mounted) return;
    if (_found >= targetsPerRound) {
      _ticker.stop();
      _audio.playRoundDone();
      showRoundCompleteDialog(
        context,
        score: _score,
        onPlayAgain: () {
          setState(() {
            _found = 0;
            _score = 0;
            _lastTick = Duration.zero;
            _newWave(newTarget: true);
          });
          _ticker.start();
        },
      );
      return;
    }
    setState(() => _newWave(newTarget: true));
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    return Directionality(
      textDirection: appDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFE3F2FD),
        appBar: AppBar(
          backgroundColor: Colors.lightBlue.shade700,
          foregroundColor: Colors.white,
          title: Text(
            '${tr('בלונים', 'Balloons')} · $_found/$targetsPerRound',
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _flewAway
                            ? tr(g('הבלון ברח! נסי שוב 🎈', 'הבלון ברח! נסה שוב 🎈'),
                                'It flew away! Try again 🎈')
                            : tr(g('פוצצי את הבלון של האות ששמעת',
                                    'פוצץ את הבלון של האות ששמעת'),
                                'Pop the balloon with the letter you hear'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed:
                          target == null ? null : () => _audio.playLetter(target),
                      icon: const Icon(Icons.volume_up),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    final size = min(w * 0.2, 110.0);
                    return ClipRect(
                      child: Stack(
                        children: [
                          for (final b in _balloons)
                            Positioned(
                              left: b.x * w - size / 2,
                              top: b.y * h,
                              width: size,
                              height: size * 1.6,
                              child: _balloon(b, size),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balloon(_Balloon b, double size) {
    if (b.popped) {
      return Align(
        alignment: Alignment.topCenter,
        child: Text('💥', style: TextStyle(fontSize: size * 0.8)),
      );
    }
    return GestureDetector(
      onTap: () => _onTap(b),
      child: AnimatedOpacity(
        opacity: b.wrong ? 0.3 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: Column(
          children: [
            Container(
              width: size,
              height: size * 1.15,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: b.wrong ? Colors.grey : b.color,
                borderRadius: BorderRadius.all(
                  Radius.elliptical(size / 2, size * 0.575),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              child: Text(
                b.letter.letter,
                style: TextStyle(
                  fontSize: size * 0.55,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Container(width: 2, height: size * 0.4, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
