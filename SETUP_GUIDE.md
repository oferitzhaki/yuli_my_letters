# Hebrew Alphabet Learning App - Character Design Setup Guide

## 📋 What We Just Created

You now have the complete character design system with:
- ✅ **3 Main Characters** (Aleph/Lion, Bet/Bear, Gimel/Camel)
- ✅ **3 Growth Stages Each** (Baby, Kid, Adult)
- ✅ **SVG Illustrations** (ready to use in Flutter)
- ✅ **Flutter Widgets** (CharacterCard, CharacterGrid)
- ✅ **Character Database** (22 Hebrew letters with animals)

---

## 🚀 Integration Steps

### Step 1: Create Flutter Project Structure

```bash
cd ~/your_projects_folder
flutter create hebrew_alphabet_app
cd hebrew_alphabet_app
```

### Step 2: Add Dependencies

Edit `pubspec.yaml` and add these under `dependencies:`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_svg: ^2.0.0          # For SVG support
  hive: ^2.2.3                 # Local database
  hive_flutter: ^1.1.0
  just_audio: ^0.9.30          # Audio playback
  riverpod: ^2.3.0             # State management
  flutter_riverpod: ^2.3.0

dev_dependencies:
  hive_generator: ^2.0.0
  build_runner: ^2.4.0

flutter_assets:
  - assets/audio/
  - assets/characters/
```

Run: `flutter pub get`

### Step 3: Copy Files to Project

Create the following directory structure:

```
lib/
├── constants/
│   └── hebrew_characters.dart          [Copy from hebrew_characters.dart]
├── assets/
│   ├── characters_svg.dart             [Copy from characters_svg.dart]
│   └── svg/                            [For future SVG files]
├── widgets/
│   └── character_card.dart             [Copy from character_card_widget.dart]
├── models/
│   ├── user.dart                       [Create next - User model]
│   ├── character.dart                  [Create next - Character progress model]
│   └── lesson.dart                     [Create next - Lesson structure]
├── screens/
│   ├── home_screen.dart                [Create next]
│   └── learn_screen.dart               [Create next]
├── services/
│   └── hive_service.dart               [Create next - Local DB service]
└── main.dart

assets/
├── audio/                              [Record 22 Hebrew letter pronunciations]
│   ├── aleph.m4a
│   ├── bet.m4a
│   ├── gimel.m4a
│   └── ...
└── images/
    └── backgrounds/                    [Optional backgrounds for screens]
```

### Step 4: Update pubspec.yaml Assets

```yaml
flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/audio/
```

### Step 5: Create Main App File

Create `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'constants/hebrew_characters.dart';

void main() async {
  await Hive.initFlutter();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hebrew Alphabet Learning',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hebrew Alphabet Learning'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome! 👋',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to learning screen
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Learning'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 6: Test the Setup

```bash
flutter run
```

You should see the welcome screen with a "Start Learning" button.

---

## 📦 Next Files to Create (Week 1)

### 1. **models/user.dart** - User Progress Model
```dart
// User data with progress tracking
class User {
  final String id;
  final String name;
  int level;
  int totalPoints;
  Map<String, CharacterProgress> characterProgress;
  DateTime lastSessionDate;
}

class CharacterProgress {
  String characterId;
  int attempts;
  double accuracy;
  CharacterStage currentStage;
  DateTime? lastPracticed;
}
```

### 2. **services/hive_service.dart** - Offline Database
```dart
// Hive database operations for offline storage
class HiveService {
  static const String userBox = 'user';
  static const String progressBox = 'progress';
  
  Future<void> saveUser(User user) async { ... }
  Future<User?> getUser() async { ... }
  Future<void> updateCharacterProgress(CharacterProgress progress) async { ... }
}
```

### 3. **screens/learn_screen.dart** - Main Learning Interface
```dart
// Display character, pronunciation, and game modes
class LearnScreen extends StatefulWidget {
  final HebrewCharacter character;
  
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}
```

---

## 🎨 Asset Preparation

### Audio Files
You need to record or find 22 Hebrew letter pronunciations:

**Recommended:**
- Use Google Translate (Hebrew → listen)
- Or use: https://www.forvo.com/languages/he/ (crowdsourced pronunciations)
- Convert to M4A format and save in `assets/audio/`

**Format:**
- File: `assets/audio/{character-id}.m4a`
- Examples: `aleph.m4a`, `bet.m4a`, `gimel.m4a`

---

## 🔄 Using the Character Card Widget

Once integrated, you can display characters like this:

```dart
import 'widgets/character_card.dart';
import 'constants/hebrew_characters.dart';

// Display single character in Baby stage
CharacterCard(
  character: hebrewCharacters[0], // Aleph
  stage: CharacterStage.baby,
  onTap: () => print('Aleph tapped!'),
)

// Display grid of characters
CharacterGrid(
  characters: getCharactersByLevel(1),
  stage: CharacterStage.kid,
  onCharacterTap: (character) {
    Navigator.push(/* ... */);
  },
)
```

---

## 📸 Screenshot Preview

Once you run `flutter run`, you should see:

```
┌─────────────────────────────┐
│   Hebrew Alphabet Learning  │
├─────────────────────────────┤
│                             │
│         Welcome! 👋         │
│                             │
│      [Start Learning]       │
│                             │
└─────────────────────────────┘
```

Then clicking "Start Learning" will navigate to the learning screen where you'll see the character cards.

---

## ✅ Checklist for This Week

- [ ] Create Flutter project
- [ ] Add dependencies (flutter_svg, hive, riverpod)
- [ ] Copy constants and SVG files
- [ ] Copy CharacterCard widget
- [ ] Create main.dart with basic home screen
- [ ] Run `flutter run` and see the welcome screen
- [ ] Verify no errors

---

## 🎯 Next Session Goals

Once this is set up, we'll create:
1. **Learn Screen** with character display
2. **Hive Database** for offline progress tracking
3. **First Game Mode** (See & Match)
4. **Audio Playback** for letter pronunciation
5. **Progress Tracking** and achievements

---

## 📞 Quick Troubleshooting

**Issue:** `flutter_svg` error
**Fix:** Run `flutter pub get` and rebuild

**Issue:** Can't find files
**Fix:** Check file paths are correct relative to `lib/` folder

**Issue:** State management error
**Fix:** Make sure `flutter_riverpod` is in pubspec.yaml and wrapped in `ProviderScope`

---

**Ready? Let's go! 🚀**

Once you complete these steps, let me know and we'll start building the game modes!