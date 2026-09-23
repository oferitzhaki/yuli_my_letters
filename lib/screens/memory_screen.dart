// lib/screens/memory_screen.dart
// Memory game: flip cards and match each letter with its animal.

import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/hebrew_characters.dart';
import '../services/letter_audio.dart';
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
  static const int pairs = 4;
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
    final letters = (List.of(hebrewCharacters)..shuffle(_random)).take(pairs);
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
      _audio.playLetter(first.character);

      if (_cards.every((c) => c.matched)) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          showRoundCompleteDialog(
            context,
            score: _score,
            onPlayAgain: () => setState(_newGame),
          );
        });
      }
    } else {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 1200), () {
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    const Text(
                      'מצאי כל אות עם התמונה שלה',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                      children: _cards.map(_buildCard).toList(),
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
