// lib/widgets/round_complete_dialog.dart

import 'package:flutter/material.dart';

Future<void> showRoundCompleteDialog(
  BuildContext context, {
  required int score,
  required VoidCallback onPlayAgain,
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
        content: Text(
          'צברת $score נקודות ⭐',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(); // back to the games menu
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
      ),
    ),
  );
}
