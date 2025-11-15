// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_todo_app/features/auth/presentation/widgets/email_text_field.dart';
import 'package:shared_todo_app/features/auth/presentation/widgets/login_button.dart';
import 'package:shared_todo_app/features/auth/presentation/widgets/password_text_field.dart';
import 'package:shared_todo_app/features/auth/presentation/widgets/sign_up_button.dart';
import '../../../../config/router/app_router.dart';
import '../controllers/login_controller.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin(LoginController controller) {
    if (!_formKey.currentState!.validate()) return;

    controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
      context: context,
    );
  }

  void _navigateToSignUp() {
    context.goNamed(AppRouter.signup);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Provider.of<LoginController>(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Access',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Access in to your account',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          EmailTextField(controller: _emailController),
          const SizedBox(height: 16),
          PasswordTextField(
            controller: _passwordController,
            isObscure: _isPasswordObscure,
            onToggleVisibility: () {
              setState(() => _isPasswordObscure = !_isPasswordObscure);
            },
          ),
          const SizedBox(height: 32),
          LoginButton(
            isLoading: controller.isLoading,
            onPressed: () => _submitLogin(controller),
          ),
          const SizedBox(height: 24),
          SignUpPrompt(onSignUp: _navigateToSignUp),
        ],
      ),
    );
  }
}
