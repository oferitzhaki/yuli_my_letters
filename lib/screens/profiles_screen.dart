// lib/screens/profiles_screen.dart
// "Who is playing?" - one card per child, plus "add a child".
// Long-press a card (parents) to edit or delete.

import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

const _avatars = ['🦁', '🦊', '🐼', '🐯', '🐨', '🐸', '🐵', '🦄'];

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  Future<void> _open(BuildContext context, ChildProfile p) async {
    await ProfileService.instance.select(p.id);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _add(BuildContext context) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (added == true && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _manage(BuildContext context, ChildProfile p) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text('עריכת הפרטים של ${p.name}'),
                onTap: () => Navigator.pop(sheetContext, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text('מחיקת ${p.name}'),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RegisterScreen(editing: p)),
      );
    } else if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('למחוק את ${p.name}?'),
            content: const Text('כל הכוכבים וההתקדמות יימחקו לצמיתות.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('ביטול'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('מחיקה'),
              ),
            ],
          ),
        ),
      );
      if (ok == true) await ProfileService.instance.delete(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: ProfileService.instance,
            builder: (context, _) {
              final profiles = ProfileService.instance.profiles;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'לומדים אותיות 🔤',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profiles.isEmpty
                            ? 'ברוכים הבאים! נתחיל בהרשמה קצרה'
                            : 'מי משחק?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (var i = 0; i < profiles.length; i++)
                            _ProfileCard(
                              profile: profiles[i],
                              avatar: _avatars[i % _avatars.length],
                              onTap: () => _open(context, profiles[i]),
                              onLongPress: () =>
                                  _manage(context, profiles[i]),
                            ),
                          _AddCard(onTap: () => _add(context)),
                        ],
                      ),
                      if (profiles.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'להורים: לחיצה ארוכה על כרטיס לעריכה או מחיקה',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.black45),
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.avatar,
    required this.onTap,
    required this.onLongPress,
  });

  final ChildProfile profile;
  final String avatar;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 190,
      child: Material(
        color: profile.isBoy ? Colors.lightBlue.shade100 : Colors.pink.shade100,
        elevation: 4,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(avatar, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 8),
                FittedBox(
                  child: Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (profile.hasVoice)
                  const Text('🎙️', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 190,
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, size: 64, color: Colors.green),
              SizedBox(height: 8),
              Text(
                'הוספת ילד/ה',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

