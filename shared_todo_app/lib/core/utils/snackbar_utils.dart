import 'package:flutter/material.dart';

// Una funzione helper riutilizzabile
void showErrorSnackBar(BuildContext context, {required String message}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}


void showSuccessSnackBar(BuildContext context, {required String message}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}