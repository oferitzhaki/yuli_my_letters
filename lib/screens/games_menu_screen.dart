// lib/screens/games_menu_screen.dart
// Progress header, "Meet the letters", and the games ordered by difficulty.

import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import '../services/profile_service.dart';
import '../services/word_pools.dart';
import 'balloons_screen.dart';
import 'build_word_screen.dart';
import 'choice_game_screen.dart';
import 'letter_intro_screen.dart';
import 'memory_screen.dart';
import 'text_choice_game_screen.dart';
import 'trace_screen.dart';
import 'word_game_rounds.dart';
import 'write_screen.dart';

const TextStyle _promptLetter = TextStyle(
  fontSize: 130,
  fontWeight: FontWeight.bold,
  color: Colors.deepOrange,
);
const TextStyle _optionLetter = TextStyle(
  fontSize: 80,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);
const TextStyle _promptEmoji = TextStyle(fontSize: 110);
const TextStyle _optionEmoji = TextStyle(fontSize: 72);

class _GameInfo {
  const _GameInfo({
    required this.level,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.builder,
    this.isOpen,
  });

  final int level;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final WidgetBuilder builder;

  /// Extra condition for the harder games: enough known letters/words.
  final bool Function()? isOpen;
}

List<_GameInfo> _games() => [
      _GameInfo(
        level: 1,
        emoji: '🦁',
        title: tr('רואים ומתאימים', 'See & Match'),
        subtitle: tr('רואים אות ובוחרים תמונה', 'See a letter, pick a picture'),
        color: Colors.orange,
        builder: (_) => ChoiceGameScreen(
          title: tr('רואים ומתאימים', 'See & Match'),
          instruction:
              tr('מה מתחיל באות הזו?', 'What starts with this letter?'),
          promptBuilder: (c) => Text(c.letter, style: _promptLetter),
          optionBuilder: (c) => Text(c.emoji, style: _optionEmoji),
          playPrompt: (audio, c) => audio.playLetter(c),
        ),
      ),
      _GameInfo(
        level: 2,
        emoji: '👂',
        title: tr('שומעים ובוחרים', 'Listen & Choose'),
        subtitle: tr('שומעים אות ומוצאים אותה', 'Hear a letter and find it'),
        color: Colors.blue,
        builder: (_) => ChoiceGameScreen(
          title: tr('שומעים ובוחרים', 'Listen & Choose'),
          instruction: tr('איזו אות שמעת?', 'Which letter did you hear?'),
          promptBuilder: (_) => const Icon(
            Icons.volume_up,
            size: 120,
            color: Colors.deepOrange,
          ),
          optionBuilder: (c) => Text(c.letter, style: _optionLetter),
          playPrompt: (audio, c) => audio.playLetter(c),
        ),
      ),
      _GameInfo(
        level: 3,
        emoji: '🔤',
        title: tr('באיזו אות מתחיל?', 'First Letter'),
        subtitle:
            tr('רואים תמונה ובוחרים אות', 'See a picture, pick its letter'),
        color: Colors.teal,
        builder: (_) => ChoiceGameScreen(
          title: tr('באיזו אות מתחיל?', 'First Letter'),
          instruction:
              tr('באיזו אות זה מתחיל?', 'Which letter does it start with?'),
          promptBuilder: (c) => Text(c.emoji, style: _promptEmoji),
          optionBuilder: (c) => Text(c.letter, style: _optionLetter),
          playPrompt: (audio, c) => audio.playAnimal(c),
        ),
      ),
      _GameInfo(
        level: 4,
        emoji: '🧠',
        title: tr('משחק זיכרון', 'Memory Game'),
        subtitle:
            tr('מוצאים זוגות של אות ותמונה', 'Match letters and pictures'),
        color: Colors.purple,
        builder: (_) => const MemoryScreen(),
      ),
      _GameInfo(
        level: 5,
        emoji: '✏️',
        title: tr('מעקב אחרי האות', 'Trace the Letter'),
        subtitle:
            tr('מציירים את האות באצבע', 'Trace the letter with your finger'),
        color: Colors.indigo,
        builder: (_) => const TraceScreen(),
      ),
      _GameInfo(
        level: 6,
        emoji: '✍️',
        title: tr('כתיבה חופשית', 'Free Writing'),
        subtitle: tr('שומעים אות וכותבים אותה לבד',
            'Hear a letter and write it yourself'),
        color: Colors.pink,
        builder: (_) => const WriteScreen(),
      ),
      _GameInfo(
        level: 7,
        emoji: '🔍',
        title: tr('אותיות דומות', 'Lookalike Letters'),
        subtitle: tr('מוצאים את האות בין אותיות שנראות דומה',
            'Find the letter among letters that look alike'),
        color: Colors.brown,
        builder: (_) => ChoiceGameScreen(
          title: tr('אותיות דומות', 'Lookalike Letters'),
          instruction: tr('איזו אות שמעת?', 'Which letter did you hear?'),
          promptBuilder: (_) => const Icon(
            Icons.volume_up,
            size: 120,
            color: Colors.deepOrange,
          ),
          optionBuilder: (c) => Text(c.letter, style: _optionLetter),
          playPrompt: (audio, c) => audio.playLetter(c),
          distractorsFor: (c) => lookalikesOf(c),
        ),
      ),
      _GameInfo(
        level: 8,
        emoji: '🏁',
        title: tr('האות האחרונה', 'Last Letter'),
        subtitle: tr('באיזו אות המילה נגמרת?',
            'Which letter does the word end with?'),
        color: Colors.deepPurple,
        isOpen: () => lastLetterPool().length >= 4,
        builder: (_) => TextChoiceGameScreen(
          title: tr('האות האחרונה', 'Last Letter'),
          instruction: tr('באיזו אות המילה נגמרת?',
              'Which letter does the word end with?'),
          color: Colors.deepPurple,
          makeRound: lastLetterRound,
        ),
      ),
      _GameInfo(
        level: 9,
        emoji: '🧩',
        title: tr('בונים מילה', 'Build a Word'),
        subtitle: tr('מסדרים את האותיות לפי הסדר', 'Put the letters in order'),
        color: Colors.cyan.shade700,
        isOpen: () => buildWordPool().length >= 3,
        builder: (_) => const BuildWordScreen(),
      ),
      // Hebrew: vowel marks. English: small letters (the next new shapes).
      if (ProfileService.instance.learnsEnglish)
        _GameInfo(
          level: 10,
          emoji: '🔡',
          title: tr('אותיות גדולות וקטנות', 'Big & Small Letters'),
          subtitle: tr('מוצאים את האות הקטנה', 'Find the small letter'),
          color: Colors.green.shade700,
          builder: (_) => ChoiceGameScreen(
            title: tr('אותיות גדולות וקטנות', 'Big & Small Letters'),
            instruction:
                tr('איזו היא האות הקטנה?', 'Which is the small letter?'),
            promptBuilder: (c) => Text(c.letter, style: _promptLetter),
            optionBuilder: (c) =>
                Text(c.letter.toLowerCase(), style: _optionLetter),
            playPrompt: (audio, c) => audio.playLetter(c),
            distractorsFor: (c) => lookalikesOf(c, smallLetters: true),
            countsForProgress: false,
          ),
        )
      else
        _GameInfo(
          level: 10,
          emoji: '🔤',
          title: tr('ניקוד', 'Vowel Marks'),
          subtitle: tr('שומעים צליל ובוחרים: בָּ בִּ בּוּ',
              'Hear a sound and pick it: בָּ בִּ בּוּ'),
          color: Colors.green.shade700,
          isOpen: () => syllableLetters().length >= 4,
          builder: (_) => TextChoiceGameScreen(
            title: tr('ניקוד', 'Vowel Marks'),
            instruction: tr('איזה צליל שמעת?', 'Which sound did you hear?'),
            color: Colors.green.shade700,
            makeRound: vowelRound,
            beforeStart: showVowelChartOnce,
            helpButton: (context) => IconButton(
              tooltip: tr('הניקוד', 'The Vowel Marks', 'Semnele vocalelor'),
              icon: const Icon(Icons.menu_book),
              onPressed: () => showVowelChart(context),
            ),
          ),
        ),
      _GameInfo(
        level: 11,
        emoji: '🎈',
        title: tr('בלונים', 'Balloons'),
        subtitle: tr('מפוצצים את הבלון עם האות ששמעת',
            'Pop the balloon with the letter you hear'),
        color: Colors.lightBlue.shade700,
        builder: (_) => const BalloonsScreen(),
      ),
    ];

class GamesMenuScreen extends StatelessWidget {
  const GamesMenuScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: appDirection,
        child: AlertDialog(
          title: Text(tr('לאפס את ההתקדמות?', 'Reset progress?')),
          content: Text(
            tr('כל הכוכבים והאותיות שנלמדו יימחקו, ומתחילים מההתחלה.',
                'All stars and learned letters will be deleted.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(tr('ביטול', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(tr('לאפס', 'Reset')),
            ),
          ],
        ),
      ),
    );
    if (ok == true) await ProgressService.instance.reset();
  }

  @override
  Widget build(BuildContext context) {
    final games = _games();
    return Directionality(
      textDirection: appDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          title: Text(tr(g('בחרי משחק 🎮', 'בחר משחק 🎮'), 'Pick a game 🎮')),
          actions: [
            IconButton(
              tooltip: tr('איפוס התקדמות (להורים)', 'Reset progress (parents)'),
              icon: const Icon(Icons.restart_alt),
              onPressed: () => _confirmReset(context),
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: ProgressService.instance,
            builder: (context, _) {
              final p = ProgressService.instance;
              final newCount = p.lettersToIntroduce.length;
              final gamesOpen = p.playableLetters.length >= 4;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _ProgressHeader(progress: p),
                      const SizedBox(height: 16),
                      _MenuCard(
                        emoji: '✨',
                        label: newCount > 0
                            ? tr('חדש!', 'New!')
                            : tr('חזרה', 'Review'),
                        title: tr(g('הכירי את האותיות', 'הכר את האותיות'),
                            'Meet the Letters'),
                        subtitle: newCount > 0
                            ? tr(
                                'יש $newCount אותיות חדשות להכיר',
                                '$newCount new letters to meet',
                                '${roCount(newCount, 'literă nouă', 'litere noi')} de cunoscut')
                            : tr('חוזרים על האותיות שלמדת',
                                'Review the letters you learned'),
                        color: Colors.green,
                        highlight: newCount > 0,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LetterIntroScreen(),
                          ),
                        ),
                      ),
                      for (final game in games) ...[
                        const SizedBox(height: 16),
                        _gameCard(context, game, gamesOpen),
                      ],
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

  /// A game card: locked until the letters are met, and the harder games
  /// also until enough letters are known for their words.
  Widget _gameCard(BuildContext context, _GameInfo game, bool gamesOpen) {
    final open = gamesOpen && (game.isOpen?.call() ?? true);
    return _MenuCard(
      emoji: game.emoji,
      label: tr('שלב ${game.level}', 'Level ${game.level}',
          'Nivelul ${game.level}'),
      title: game.title,
      subtitle: game.subtitle,
      color: game.color,
      enabled: open,
      onTap: () {
        if (!open) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                gamesOpen
                    ? tr('צריך להכיר עוד כמה אותיות כדי לשחק בזה ✨',
                        'Learn a few more letters to play this ✨')
                    : tr('קודם מכירים את האותיות ✨',
                        'First, meet the letters ✨'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: game.builder),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.progress});

  final ProgressService progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                '⭐ ${progress.stars}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${tr('אותיות', 'Letters')}: ${progress.masteredCount}/${activeLetters.length}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Every letter: green = known, white = met, grey = locked.
          // Laid out in the alphabet's own direction (א on the right).
          Directionality(
            textDirection: learnDirection,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < activeLetters.length; i++)
                  _LetterChip(
                    letter: activeLetters[i].letter,
                    unlocked: i < progress.unlockedCount,
                    mastered: progress.isMastered(activeLetters[i].id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterChip extends StatelessWidget {
  const _LetterChip({
    required this.letter,
    required this.unlocked,
    required this.mastered,
  });

  final String letter;
  final bool unlocked;
  final bool mastered;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade400;
    if (mastered) {
      bg = Colors.green.shade300;
      fg = Colors.white;
    } else if (unlocked) {
      bg = Colors.orange.shade50;
      fg = Colors.deepOrange;
    }
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: unlocked && !mastered
            ? Border.all(color: Colors.deepOrange.shade200)
            : null,
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.emoji,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.enabled = true,
    this.highlight = false,
  });

  final String emoji;
  final String label;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: color,
        elevation: highlight ? 10 : 4,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 52)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              highlight ? Colors.yellowAccent : Colors.white70,
                          fontWeight:
                              highlight ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  enabled ? Icons.play_circle_fill : Icons.lock,
                  size: 44,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
