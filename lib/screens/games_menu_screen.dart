// lib/screens/games_menu_screen.dart
// Progress header, "Meet the letters", and the games ordered by difficulty.

import 'package:flutter/material.dart';

import '../constants/hebrew_characters.dart';
import '../services/progress_service.dart';
import 'choice_game_screen.dart';
import 'letter_intro_screen.dart';
import 'memory_screen.dart';
import 'trace_screen.dart';
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
  });

  final int level;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final WidgetBuilder builder;
}

List<_GameInfo> _games() => [
      _GameInfo(
        level: 1,
        emoji: '🦁',
        title: 'רואים ומתאימים',
        subtitle: 'רואים אות ובוחרים תמונה',
        color: Colors.orange,
        builder: (_) => ChoiceGameScreen(
          title: 'רואים ומתאימים',
          instruction: 'מה מתחיל באות הזו?',
          promptBuilder: (c) => Text(c.letter, style: _promptLetter),
          optionBuilder: (c) => Text(c.emoji, style: _optionEmoji),
          playPrompt: (audio, c) => audio.playLetter(c),
        ),
      ),
      _GameInfo(
        level: 2,
        emoji: '👂',
        title: 'שומעים ובוחרים',
        subtitle: 'שומעים אות ומוצאים אותה',
        color: Colors.blue,
        builder: (_) => ChoiceGameScreen(
          title: 'שומעים ובוחרים',
          instruction: 'איזו אות שמעת?',
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
        title: 'באיזו אות מתחיל?',
        subtitle: 'רואים תמונה ובוחרים אות',
        color: Colors.teal,
        builder: (_) => ChoiceGameScreen(
          title: 'באיזו אות מתחיל?',
          instruction: 'באיזו אות זה מתחיל?',
          promptBuilder: (c) => Text(c.emoji, style: _promptEmoji),
          optionBuilder: (c) => Text(c.letter, style: _optionLetter),
          playPrompt: (audio, c) => audio.playAnimal(c),
        ),
      ),
      _GameInfo(
        level: 4,
        emoji: '🧠',
        title: 'משחק זיכרון',
        subtitle: 'מוצאים זוגות של אות ותמונה',
        color: Colors.purple,
        builder: (_) => const MemoryScreen(),
      ),
      _GameInfo(
        level: 5,
        emoji: '✏️',
        title: 'מעקב אחרי האות',
        subtitle: 'מציירים את האות באצבע',
        color: Colors.indigo,
        builder: (_) => const TraceScreen(),
      ),
      _GameInfo(
        level: 6,
        emoji: '✍️',
        title: 'כתיבה חופשית',
        subtitle: 'שומעים אות וכותבים אותה לבד',
        color: Colors.pink,
        builder: (_) => const WriteScreen(),
      ),
    ];

class GamesMenuScreen extends StatelessWidget {
  const GamesMenuScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('לאפס את ההתקדמות?'),
          content: const Text(
            'כל הכוכבים והאותיות שנלמדו יימחקו, ומתחילים מההתחלה.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ביטול'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('לאפס'),
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          title: const Text('בחרי משחק 🎮'),
          actions: [
            IconButton(
              tooltip: 'איפוס התקדמות (להורים)',
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
                        label: newCount > 0 ? 'חדש!' : 'חזרה',
                        title: 'הכירי את האותיות',
                        subtitle: newCount > 0
                            ? 'יש $newCount אותיות חדשות להכיר'
                            : 'חוזרים על האותיות שלמדת',
                        color: Colors.green,
                        highlight: newCount > 0,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LetterIntroScreen(),
                          ),
                        ),
                      ),
                      for (final g in games) ...[
                        const SizedBox(height: 16),
                        _MenuCard(
                          emoji: g.emoji,
                          label: 'שלב ${g.level}',
                          title: g.title,
                          subtitle: g.subtitle,
                          color: g.color,
                          enabled: gamesOpen,
                          onTap: () {
                            if (!gamesOpen) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'קודם מכירים את האותיות ✨',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: g.builder),
                            );
                          },
                        ),
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
                'אותיות: ${progress.masteredCount}/${hebrewCharacters.length}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Every letter: green = known, white = met, grey = locked.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < hebrewCharacters.length; i++)
                _LetterChip(
                  letter: hebrewCharacters[i].letter,
                  unlocked: i < progress.unlockedCount,
                  mastered: progress.isMastered(hebrewCharacters[i].id),
                ),
            ],
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
                          color: highlight ? Colors.yellowAccent : Colors.white70,
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
