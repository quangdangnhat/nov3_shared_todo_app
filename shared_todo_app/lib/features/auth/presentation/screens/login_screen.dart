import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Importa GoRouter
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/router/app_router.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // NOTA: Ora passiamo il BuildContext corretto a questo metodo
  Future<void> _submitLogin(BuildContext scaffoldContext) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isLoading = true; });

    try {
      await _authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Il redirect del router ci porterà alla home.
    } on AuthException catch (error) {
      // Usiamo scaffoldContext per mostrare lo SnackBar
      if (mounted) showErrorSnackBar(scaffoldContext, message: error.message);
    } catch (error) {
      if (mounted) showErrorSnackBar(scaffoldContext, message: 'An unknown error occurred.');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // NOTA: Ora passiamo il BuildContext corretto a questo metodo
  void _navigateToSignUp(BuildContext scaffoldContext) {
    // Usiamo scaffoldContext per assicurarci di avere il GoRouter
    GoRouter.of(scaffoldContext).goNamed(AppRouter.signup);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      // --- AGGIUNTA CHIAVE: Builder Widget ---
      // Usiamo un Builder per ottenere un contesto sicuramente sotto lo Scaffold
      body: Builder(
        builder: (scaffoldContext) { // Questo è il nuovo contesto da usare
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            // Passa il contesto corretto
                            onPressed: () => _submitLogin(scaffoldContext), 
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Login'),
                          ),
                    const SizedBox(height: 16),
                    TextButton(
                      // Passa il contesto corretto
                      onPressed: () => _navigateToSignUp(scaffoldContext), 
                      child: const Text('Don\'t have an account? Sign Up'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
      // --- FINE AGGIUNTA ---
    );
  }
}

