// lib/widgets/round_complete_dialog.dart

import 'package:flutter/material.dart';

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
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text(
          '🎉 כל הכבוד יולי!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'צברת $score כוכבים ⭐',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22),
            ),
            if (unlockedNew) ...[
              const SizedBox(height: 16),
              const Text(
                '🎁 נפתחו אותיות חדשות!\nבואי להכיר אותן',
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
              child: const Text('לאותיות החדשות 🎁',
                  style: TextStyle(fontSize: 18)),
            )
          else ...[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('למשחקים 🎮', style: TextStyle(fontSize: 18)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onPlayAgain();
              },
              child: const Text('עוד סיבוב 🔄', style: TextStyle(fontSize: 18)),
            ),
          ],
        ],
      ),
    ),
  );
}
