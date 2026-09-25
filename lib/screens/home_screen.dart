// lib/screens/home_screen.dart
// Greeting for the child who is playing, stars, and the way into the games.

import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import '../services/progress_service.dart';
import 'games_menu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: appDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge(
              [ProfileService.instance, ProgressService.instance],
            ),
            builder: (context, _) {
              final profile = ProfileService.instance;
              final p = ProgressService.instance;
              return Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            tr('שלום ${profile.name}! 👋', 'Hi ${profile.name}! 👋'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('לומדים אותיות עם חברים', 'Learning letters with friends'),
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            activeLetters.take(3).map((c) => c.emoji).join('  '),
                            style: TextStyle(fontSize: 64),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '⭐ ${p.stars}     🔤 ${p.masteredCount}/${activeLetters.length}',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GamesMenuScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow, size: 32),
                            label: Text(
                              tr(g('בואי נשחק!', 'בוא נשחק!'), "Let's play!"),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC107),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Switch child - goes back to "who is playing?".
                  Positioned(
                    top: 8,
                    left: 8,
                    child: TextButton.icon(
                      onPressed: () async {
                        await ProfileService.instance.signOut();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.people),
                      label: Text(
                        tr('החלפת ילד/ה', 'Switch child'),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
