// lib/screens/memory_screen.dart
// Memory game: flip cards and match each letter with its animal.

import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/hebrew_characters.dart';
import '../services/letter_audio.dart';
import '../services/progress_service.dart';
import '../widgets/round_complete_dialog.dart';

class _MemoryCard {
  _MemoryCard(this.character, this.isLetter);

  final HebrewCharacter character;
  final bool isLetter;
  bool faceUp = false;
  bool matched = false;
}

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  // Difficulty: name and number of pairs. "אלופה" = as many as she can
  // get (limited by the letters she has already met, up to 12 pairs).
  static const _levels = [('קל', 4), ('בינוני', 6), ('קשה', 8), ('אלופה', 12)];
  int _level = 3; // start at the hardest available
  static const int pointsPerPair = 5;

  final LetterAudio _audio = LetterAudio();
  final Random _random = Random();

  late List<_MemoryCard> _cards;
  final List<_MemoryCard> _open = [];
  bool _busy = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  void _newGame() {
    final pool = List.of(ProgressService.instance.playableLetters)
      ..shuffle(_random);
    final pairs = min(_levels[_level].$2, pool.length);
    final letters = pool.take(pairs);
    _cards = [
      for (final c in letters) ...[_MemoryCard(c, true), _MemoryCard(c, false)],
    ]..shuffle(_random);
    _open.clear();
    _busy = false;
    _score = 0;
  }

  void _onTap(_MemoryCard card) {
    if (_busy || card.faceUp || card.matched) return;

    setState(() {
      card.faceUp = true;
      _open.add(card);
    });
    if (card.isLetter) _audio.playLetter(card.character);

    if (_open.length < 2) return;

    final first = _open[0];
    final second = _open[1];

    if (first.character.id == second.character.id) {
      setState(() {
        first.matched = true;
        second.matched = true;
        _open.clear();
        _score += pointsPerPair;
      });
      ProgressService.instance.addStars(pointsPerPair);
      _audio.playLetterThenPraise(first.character);

      if (_cards.every((c) => c.matched)) {
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (!mounted) return;
          _audio.playRoundDone();
          showRoundCompleteDialog(
            context,
            score: _score,
            onPlayAgain: () => setState(_newGame),
          );
        });
      }
    } else {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          first.faceUp = false;
          second.faceUp = false;
          _open.clear();
          _busy = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3E5F5),
        appBar: AppBar(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          title: const Text('משחק זיכרון'),
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildLevelPicker(),
                const SizedBox(height: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 10.0;
                      final layout = _bestLayout(
                        _cards.length,
                        constraints.maxWidth,
                        constraints.maxHeight,
                        gap,
                      );
                      return Center(
                        child: SizedBox(
                          width: layout.cols * layout.w +
                              (layout.cols - 1) * gap,
                          child: Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final card in _cards)
                                SizedBox(
                                  width: layout.w,
                                  height: layout.h,
                                  child: _buildCard(card),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelPicker() {
    final available = ProgressService.instance.playableLetters.length;
    final lastLevel = _levels.length - 1;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _levels.length; i++)
          Builder(builder: (context) {
            final enabled = i == lastLevel || _levels[i].$2 <= available;
            final pairs = min(_levels[i].$2, available);
            return ChoiceChip(
              label: Text(
                enabled ? '${_levels[i].$1} · $pairs זוגות' : '${_levels[i].$1} 🔒',
                style: const TextStyle(fontSize: 16),
              ),
              selected: _level == i,
              onSelected: enabled
                  ? (_) => setState(() {
                        _level = i;
                        _newGame();
                      })
                  : null,
            );
          }),
      ],
    );
  }

  /// Picks the number of columns that gives the biggest cards
  /// while fitting every card on screen without scrolling.
  ({int cols, double w, double h}) _bestLayout(
    int count,
    double maxW,
    double maxH,
    double gap,
  ) {
    const aspect = 0.8; // card width / height
    var best = (cols: 2, w: 0.0, h: 0.0);
    for (var cols = 2; cols <= 8; cols++) {
      final rows = (count / cols).ceil();
      var w = (maxW - gap * (cols - 1)) / cols;
      var h = (maxH - gap * (rows - 1)) / rows;
      if (w <= 0 || h <= 0) continue;
      if (w / h > aspect) {
        w = h * aspect;
      } else {
        h = w / aspect;
      }
      if (w > best.w) best = (cols: cols, w: w, h: h);
    }
    return best;
  }

  Widget _buildCard(_MemoryCard card) {
    final showFace = card.faceUp || card.matched;

    Color background = Colors.purple;
    if (card.matched) {
      background = Colors.green.shade200;
    } else if (showFace) {
      background = Colors.white;
    }

    final String label = !showFace
        ? '?'
        : (card.isLetter ? card.character.letter : card.character.emoji);

    return GestureDetector(
      onTap: () => _onTap(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: FittedBox(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
              color: showFace ? Colors.deepOrange : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
