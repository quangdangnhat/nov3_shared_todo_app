import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final username =
        (user?.userMetadata?['username'] as String?) ?? 'Sconosciuto';
    final email = user?.email ?? '—';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
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
            child: Text(username,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),

          // Username (sola lettura per ora)
          _ReadOnlyTile(
            icon: Icons.person,
            label: 'Username',
            value: username,
          ),

          // Email (sola lettura)
          _ReadOnlyTile(
            icon: Icons.email,
            label: 'Email',
            value: email,
          ),

          // Password (placeholder non modificabile)
          const _ReadOnlyTile(
            icon: Icons.lock,
            label: 'Password',
            value: '••••••••',
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Elimina account'),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminare l’account?'),
                  content: const Text(
                      'Questa azione è definitiva. Confermi di voler eliminare il tuo account?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annulla')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Elimina'),
                    ),
                  ],
                ),
              );
              if (ok != true) return;

              // TODO: qui serve una funzione backend (Edge Function) con chiave di servizio per cancellare l'utente.
              // Mostriamo solo un messaggio per ora.
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Eliminazione account: implementare backend.'),
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

class _ReadOnlyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ReadOnlyTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right,
          color: Colors.transparent), // per allineamento
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
