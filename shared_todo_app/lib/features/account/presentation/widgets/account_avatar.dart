import 'package:flutter/material.dart';
import 'package:shared_todo_app/config/responsive.dart';

class AccountAvatar extends StatelessWidget {
  final String username;

  const AccountAvatar({
    super.key,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Column(
      children: [
        CircleAvatar(
          radius: ResponsiveLayout.responsive<double>(
            context,
            mobile: 40,
            tablet: 50,
            desktop: 60,
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: ResponsiveLayout.responsive<double>(
                context,
                mobile: 32,
                tablet: 40,
                desktop: 48,
              ),
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          username,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: ResponsiveLayout.responsive<double>(
                  context,
                  mobile: 20,
                  tablet: 24,
                  desktop: 26,
                ),
              ),
        ),
      ],
    );
  }
}
