import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Importa GoRouter per la navigazione
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/router/app_router.dart'; // Importa AppRouter per la rotta home

/// Schermata che mostra i dettagli dell'account dell'utente.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    // Testi tradotti in inglese
    final username =
        (user?.userMetadata?['username'] as String?) ?? 'Unknown User';
    final email = user?.email ?? '—';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        // Aggiunge un pulsante "indietro" che usa GoRouter
        leading: BackButton(
          onPressed: () {
            // Controlla se possiamo tornare indietro nello stack
            if (context.canPop()) {
              context.pop();
            } else {
              // Altrimenti, torna alla home come fallback
              context.goNamed(AppRouter.home);
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(initial, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              username,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Username'),
            subtitle: Text(username),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
          const ListTile(
            leading: Icon(Icons.lock),
            title: Text('Password'),
            subtitle: Text('••••••••'),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.delete_forever),
            // Testo tradotto
            label: const Text('Delete Account'),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  // Testi tradotti
                  title: const Text('Delete Account?'),
                  content: const Text(
                    'This action is permanent. Are you sure you want to delete your account?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok != true) return;
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  // Testo tradotto
                  const SnackBar(
                    content: Text(
                      'Account deletion: backend logic to be implemented',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
