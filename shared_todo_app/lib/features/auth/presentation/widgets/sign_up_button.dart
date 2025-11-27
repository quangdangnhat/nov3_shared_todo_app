// coverage:ignore-file
// consider testing later

import 'package:flutter/material.dart';

class SignUpPrompt extends StatelessWidget {
  final VoidCallback onSignUp;

  const SignUpPrompt({
    super.key,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account?',
          style: theme.textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: onSignUp,
          child: Text(
            'Sign up',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
