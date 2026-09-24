import 'package:flutter/material.dart';

import 'constants/hebrew_characters.dart';
import 'screens/games_menu_screen.dart';
import 'services/progress_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressService.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yuli Letters',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'שלום יולי! 👋',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'לומדים אותיות עם חברים',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 20, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                const Text('🦁  🦆  🐪', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                ListenableBuilder(
                  listenable: ProgressService.instance,
                  builder: (context, _) {
                    final p = ProgressService.instance;
                    return Text(
                      '⭐ ${p.stars}     🔤 ${p.masteredCount}/${hebrewCharacters.length}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GamesMenuScreen()),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, size: 32),
                  label: const Text(
                    'בואי נשחק!',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
