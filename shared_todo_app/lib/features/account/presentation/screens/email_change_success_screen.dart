import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmailChangeSuccessScreen extends StatelessWidget {
  const EmailChangeSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 1), () {
      if (context.mounted) {
        context.go('/login'); // ⭐ automatic redirect
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Email changed')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Email changed successfully\n\nRedirecting...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
