import 'package:flutter/material.dart';

/// Un dialog di conferma riutilizzabile (es. per eliminare).
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final VoidCallback onConfirm; // L'azione da eseguire

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Delete', // Testo di default per il pulsante
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Chiudi
          child: const Text('Cancel'),
        ),
        // Pulsante di conferma (rosso se il testo è 'Delete')
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // Chiudi
            onConfirm(); // Esegui l'azione (es. cancellazione)
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmText.toLowerCase() == 'delete'
                ? Colors.red
                : Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
