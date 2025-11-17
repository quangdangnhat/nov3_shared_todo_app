import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_todo_app/main.dart'; // per supabase
import 'package:shared_todo_app/config/router/app_router.dart'; // per AppRouter.login

class EmailChangeSuccessScreen extends StatefulWidget {
  const EmailChangeSuccessScreen({super.key});

  @override
  State<EmailChangeSuccessScreen> createState() =>
      _EmailChangeSuccessScreenState();
}

class _EmailChangeSuccessScreenState extends State<EmailChangeSuccessScreen> {
  @override
  void initState() {
    super.initState();
    _handleRedirect();
  }

  Future<void> _handleRedirect() async {
    // 1️⃣ Logout dell’utente
    await supabase.auth.signOut();

    // 2️⃣ Vai alla pagina di login
    if (!mounted) return;
    context.go(AppRouter.login); // oppure context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email changed'),
      ),
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
