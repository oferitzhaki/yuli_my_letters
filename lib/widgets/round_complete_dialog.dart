// lib/widgets/round_complete_dialog.dart

import 'package:flutter/material.dart';

import '../services/profile_service.dart';

Future<void> showRoundCompleteDialog(
  BuildContext context, {
  required int score,
  required VoidCallback onPlayAgain,
  bool unlockedNew = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Directionality(
      textDirection: appDirection,
      child: AlertDialog(
        title: Text(
          tr('🎉 כל הכבוד ${ProfileService.instance.name}!',
              '🎉 Great job, ${ProfileService.instance.name}!'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('צברת $score כוכבים ⭐', 'You earned $score stars ⭐'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22),
            ),
            if (unlockedNew) ...[
              const SizedBox(height: 16),
              Text(
                tr('🎁 נפתחו אותיות חדשות!\n${g('בואי', 'בוא')} להכיר אותן',
                    "🎁 New letters unlocked!\nLet's meet them"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          if (unlockedNew)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: Text(tr('לאותיות החדשות 🎁', 'Meet the new letters 🎁'),
                  style: TextStyle(fontSize: 18)),
            )
          else ...[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: Text(tr('למשחקים 🎮', 'To the games 🎮'),
                  style: const TextStyle(fontSize: 18)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onPlayAgain();
              },
              child: Text(tr('עוד סיבוב 🔄', 'Play again 🔄'),
                  style: const TextStyle(fontSize: 18)),
            ),
          ],
        ],
      ),
    ),
  );
}
