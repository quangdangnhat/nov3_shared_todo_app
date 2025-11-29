import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/router/app_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    final hasSession = _client.auth.currentSession != null;
    _message = hasSession
        ? 'Sessione OK. Inserisci la nuova password.'
        : 'Nessuna sessione trovata. Il link potrebbe essere scaduto o non valido.';
  }

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text.trim();

    if (newPassword.length < 6) {
      setState(() => _message = 'La password deve avere almeno 6 caratteri.');
      return;
    }

    if (_client.auth.currentSession == null) {
      setState(() => _message =
          'Nessuna sessione attiva. Riapri il link dalla mail o richiedi un nuovo reset.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Aggiornamento password in corso...';
    });

    try {
      final res =
          await _client.auth.updateUser(UserAttributes(password: newPassword));

      if (!mounted) return;

      if (res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password aggiornata con successo.')),
        );
        await _client.auth.signOut();
        context.go(AppRouter.login);
      } else {
        setState(
            () => _message = 'Impossibile aggiornare la password, riprova.');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Errore auth: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Errore imprevisto: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Enter your new password',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _updatePassword,
                      child: const Text('Upgrade password'),
                    ),
            ),
            const SizedBox(height: 16),
            if (_message != null)
              Text(
                _message!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
