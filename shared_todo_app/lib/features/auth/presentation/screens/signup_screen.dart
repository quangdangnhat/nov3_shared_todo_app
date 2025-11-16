// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/router/app_router.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _submitSignUp(BuildContext scaffoldContext) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.signUp(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        // Mostra un messaggio di successo
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Sign up successful! Please check your email to verify.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Torna alla schermata di Login usando pop() (o goNamed se pop fallisce)
        // GoRouter.of(scaffoldContext).pop();
        // Proviamo con goNamed per sicurezza
        GoRouter.of(scaffoldContext).goNamed(AppRouter.login);
      }
    } on AuthException catch (error) {
      if (mounted) showErrorSnackBar(scaffoldContext, message: error.message);
    } catch (error) {
      if (mounted)
        showErrorSnackBar(
          scaffoldContext,
          message: 'An unknown error occurred.',
        );
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  // --- MODIFICA PER TORNARE AL LOGIN ---
  void _navigateToLogin(BuildContext scaffoldContext) {
    // Usiamo goNamed invece di pop per essere più espliciti e robusti.
    GoRouter.of(scaffoldContext).goNamed(AppRouter.login);
  }
  // --- FINE MODIFICA ---

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        // La freccia indietro potrebbe non apparire sempre a seconda di come si arriva qui.
        // Il pulsante esplicito è più sicuro.
      ),
      body: Builder(
        // Usiamo Builder per ottenere un contesto valido per GoRouter e SnackBar
        builder: (scaffoldContext) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
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
                    const SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Bottone Submit
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () => _submitSignUp(
                              scaffoldContext,
                            ), // Passa il contesto
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Sign Up'),
                          ),

                    // --- PULSANTE PER TORNARE AL LOGIN ---
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => _navigateToLogin(
                        scaffoldContext,
                      ), // Passa il contesto
                      child: const Text('Already have an account? Login'),
                    ),
                    // --- FINE PULSANTE ---
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
