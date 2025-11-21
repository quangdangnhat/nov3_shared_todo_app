// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import '../../../../../config/responsive.dart';

/// Widget per lo stato vuoto quando non ci sono task
class EmptyTasksState extends StatelessWidget {
  const EmptyTasksState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: ResponsiveLayout.responsive<double>(
                context,
                mobile: 64,
                desktop: 80,
              ),
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No pending tasks. Start creating!',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Widget per lo stato vuoto quando i filtri nascondono tutti i task
class FilteredEmptyState extends StatelessWidget {
  final VoidCallback onFilterPressed;

  const FilteredEmptyState({
    Key? key,
    required this.onFilterPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: ResponsiveLayout.responsive<double>(
                context,
                mobile: 64,
                desktop: 80,
              ),
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No tasks',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'I filtri attivi hanno nascosto tutti i task.\nModifica i filtri per visualizzare i task.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onFilterPressed,
              icon: const Icon(Icons.filter_list),
              label: const Text('Modifica Filtri'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget per lo stato di errore
class ErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorState({
    Key? key,
    required this.errorMessage,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: ResponsiveLayout.responsive<EdgeInsets>(
          context,
          mobile: const EdgeInsets.all(16.0),
          desktop: const EdgeInsets.all(24.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveLayout.responsive<double>(
                context,
                mobile: 48,
                desktop: 64,
              ),
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
