import 'package:flutter/material.dart';
import 'package:shared_todo_app/features/auth/presentation/domain/validators/auth_validators.dart';

class EmailTextField extends StatelessWidget {
  final TextEditingController controller;

  const EmailTextField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: theme.colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
      ),
      keyboardType: TextInputType.emailAddress,
      validator: AuthValidators.validateEmail,
    );
  }
}
