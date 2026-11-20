// lib/screens/build_word_screen.dart
// "Build a word": see and hear a picture word, then tap its letters in
// order. The slots fill in the direction the alphabet is written (right to
// left in Hebrew). Shorter words come first. In Hebrew the last tile can be
// a final letter (ף in קוף), with its regular form (פ) as a trap.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/words.dart';
import '../services/letter_audio.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../services/word_pools.dart';
import '../widgets/round_complete_dialog.dart';

class BuildWordScreen extends StatefulWidget {
  const BuildWordScreen({super.key});

  @override
  State<BuildWordScreen> createState() => _BuildWordScreenState();
}

class _BuildWordScreenState extends State<BuildWordScreen> {
  static const int wordsPerRound = 5;
  static const int pointsPerWord = 10;

  final LetterAudio _audio = LetterAudio();
  final Random _random = Random();

  late List<WordItem> _words;
  int _index = 0;
  int _score = 0;

  late List<String> _tiles; // letters to tap: the word's letters + extras
  final Set<int> _usedTiles = {};
  int _filled = 0; // how many slots are done
  int? _wrongTile; // flashes red for a moment
  int? _hintTile; // glows after "hint"
  bool _done = false;
  Timer? _flash;

  WordItem get _word => _words[_index];

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void dispose() {
    _flash?.cancel();
    _audio.dispose();
    super.dispose();
  }

  void _startRound() {
    // Shortest words first: pick from the shorter half of what she can spell.
    final pool = buildWordPool()
      ..shuffle(_random)
      ..sort((a, b) => a.word.length.compareTo(b.word.length));
    final easy = pool.take(max(wordsPerRound + 3, pool.length ~/ 2)).toList()
      ..shuffle(_random);
    _words = easy.take(wordsPerRound).toList()
      ..sort((a, b) => a.word.length.compareTo(b.word.length));
    _index = 0;
    _score = 0;
    if (_words.isNotEmpty) _startWord();
  }

  void _startWord() {
    final letters = _word.letters;
    final extras = <String>{};
    final last = letters.last;
    if (isFinalLetter(last)) extras.add(baseForm(last)); // ף -> also פ
    final known = ProgressService.instance.playableLetters
        .map((c) => c.letter)
        .where((l) => !letters.contains(l) && !extras.contains(l))
        .toList()
      ..shuffle(_random);
    extras.addAll(known.take(2 - min(2, extras.length)));
    _tiles = [...letters, ...extras]..shuffle(_random);
    _usedTiles.clear();
    _filled = 0;
    _wrongTile = null;
    _hintTile = null;
    _done = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _playWord());
  }

  void _playWord() {
    if (!mounted || _words.isEmpty) return;
    _audio.playAsset(LetterAudio.wordAsset(_word.id));
  }

  void _onTile(int i) {
    if (_done || _usedTiles.contains(i)) return;
    final needed = _word.letters[_filled];
    final letter = _tiles[i];
    if (letter == needed) {
      final nameAsset = LetterAudio.letterNameAsset(letter, characterFor(letter));
      setState(() {
        _usedTiles.add(i);
        _filled++;
        _hintTile = null;
        _wrongTile = null;
      });
      if (_filled == _word.letters.length) {
        _finishWord();
      } else if (nameAsset != null) {
        _audio.playAsset(nameAsset);
      }
    } else {
      _flash?.cancel();
      setState(() => _wrongTile = i);
      _flash = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _wrongTile = null);
      });
      _audio.playTryAgain();
    }
  }

  void _hint() {
    if (_done) return;
    final needed = _word.letters[_filled];
    for (var i = 0; i < _tiles.length; i++) {
      if (!_usedTiles.contains(i) && _tiles[i] == needed) {
        setState(() => _hintTile = i);
        break;
      }
    }
    _playWord();
  }

  Future<void> _finishWord() async {
    ProgressService.instance.addStars(pointsPerWord);
    setState(() {
      _done = true;
      _score += pointsPerWord;
    });
    await Future.wait<Object?>([
      _audio.playThenPraise([LetterAudio.wordAsset(_word.id)]),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (!mounted) return;
    if (_index + 1 >= _words.length) {
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
      _startWord();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: appDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFE0F7FA),
        appBar: AppBar(
          backgroundColor: Colors.cyan.shade700,
          foregroundColor: Colors.white,
          title: Text(
            _words.isEmpty
                ? tr('בונים מילה', 'Build a Word')
                : '${tr('בונים מילה', 'Build a Word')} · ${_index + 1}/${_words.length}',
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
          child: _words.isEmpty
              ? const SizedBox.shrink()
              : LayoutBuilder(builder: _buildBody),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BoxConstraints constraints) {
    final w = _word;
    final width = min(constraints.maxWidth - 32, 520.0);
    final slot = min((width - 10 * (w.letters.length - 1)) / w.letters.length, 90.0);
    final tile = min((width - 12 * 3) / 4, 84.0);
    final translation = wordTranslationOf(w);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              Text(
                _done
                    ? tr('🎉 נכון! ${w.word}', '🎉 Correct! ${w.word}',
                        '🎉 Corect! ${w.word}')
                    : tr(g('לחצי על האותיות לפי הסדר', 'לחץ על האותיות לפי הסדר'),
                        'Tap the letters in order'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _done ? Colors.green : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // The picture - tap to hear the word again.
              GestureDetector(
                onTap: _playWord,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 12),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(w.emoji, style: const TextStyle(fontSize: 90)),
                      if (translation != null)
                        Text(
                          translation,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // The slots, filled in reading order.
              Directionality(
                textDirection: learnDirection,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < w.letters.length; i++)
                      Container(
                        width: slot,
                        height: slot * 1.15,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i < _filled
                              ? (_done ? Colors.green.shade100 : Colors.white)
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: i == _filled && !_done
                                ? Colors.cyan.shade700
                                : Colors.black26,
                            width: i == _filled && !_done ? 3 : 1.5,
                          ),
                        ),
                        child: i < _filled
                            ? FittedBox(
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Text(
                                    w.letters[i],
                                    style: const TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // The letters to tap.
              Directionality(
                textDirection: learnDirection,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < _tiles.length; i++)
                      _tileButton(i, tile),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _playWord,
                    icon: const Icon(Icons.volume_up),
                    label: Text(tr(g('שמעי', 'שמע'), 'Listen'),
                        style: const TextStyle(fontSize: 17)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _done ? null : _hint,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: Text(tr('רמז', 'Hint'),
                        style: const TextStyle(fontSize: 17)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileButton(int i, double size) {
    final used = _usedTiles.contains(i);
    Color color = Colors.white;
    if (_wrongTile == i) color = Colors.red.shade200;
    if (_hintTile == i) color = Colors.yellow.shade300;
    return AnimatedOpacity(
      opacity: used ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: color,
          elevation: used ? 0 : 4,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: used ? null : () => _onTile(i),
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  _tiles[i],
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
