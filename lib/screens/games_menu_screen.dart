// lib/screens/games_menu_screen.dart
// Games ordered by difficulty.

import 'package:flutter/material.dart';

import 'choice_game_screen.dart';
import 'memory_screen.dart';

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

class GamesMenuScreen extends StatelessWidget {
  const GamesMenuScreen({super.key});

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
      ];

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
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: games.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) => _GameCard(game: games[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});

  final _GameInfo game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: game.color,
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: game.builder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(game.emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'שלב ${game.level}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      game.subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill, size: 48, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

