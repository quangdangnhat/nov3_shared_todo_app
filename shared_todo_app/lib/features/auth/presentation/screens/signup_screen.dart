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
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();

  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authRepository.signUp(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Sign up successful! Please check your email to verify.'),
          backgroundColor: Colors.green,
        ),
      );

      context.goNamed(AppRouter.login);
    } on AuthException catch (error) {
      if (mounted) {
        showErrorSnackBar(context, message: error.message);
      }
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
          context,
          message: 'An unknown error occurred.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToLogin() => context.goNamed(AppRouter.login);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width > 800;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.surface,
              colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: isWide
                        ? Row(
                            children: [
                              const Expanded(
                                child: _SignupIllustration(isWide: true),
                              ),
                              const SizedBox(width: 32),
                              Expanded(child: _buildForm(context)),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _SignupIllustration(isWide: false),
                              const SizedBox(height: 24),
                              _buildForm(context),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create your account',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign up to start sharing your to-do lists.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Username
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter a username'
                : null,
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
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
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
            validator: (value) => (value == null || value.length < 6)
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 16),

          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(labelText: 'Confirm Password'),
            obscureText: true,
            validator: (value) => (value != _passwordController.text)
                ? 'Passwords do not match'
                : null,
          ),
          const SizedBox(height: 32),

          // Bottone Sign Up
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitSignUp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Sign Up'),
                  ),
          ),
          const SizedBox(height: 16),

          // Link al login
          Center(
            child: TextButton(
              onPressed: _navigateToLogin,
              child: const Text('Already have an account? Login'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupIllustration extends StatelessWidget {
  const _SignupIllustration({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: isWide ? 4 / 5 : 16 / 9,
        child: Container(
          // colore di sfondo per capire se il widget viene disegnato
          color: Colors.grey,
          child: Image.asset(
            'assets/images/sign_up_page_image.jpg',
            fit: BoxFit.cover,
            // se l'immagine non si carica, mostra un placeholder
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  'Image not found',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
