// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import '../../../../../config/responsive.dart';

/// Card di riepilogo con statistiche giornaliere
class SummaryCard extends StatelessWidget {
  final int totalTasks;
  final int overdueTasks;
  final int dueTodayTasks;
  final int activeTasks;

  const SummaryCard({
    Key? key,
    required this.totalTasks,
    required this.overdueTasks,
    required this.dueTodayTasks,
    required this.activeTasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Card(
      color: theme.colorScheme.surfaceVariant,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          children: [
            _buildHeader(theme, isMobile),
            SizedBox(height: isMobile ? 12 : 16),
            _buildStats(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.assessment,
          color: theme.colorScheme.primary,
          size: isMobile ? 18 : 24,
        ),
        SizedBox(width: isMobile ? 6 : 8),
        Text(
          'Daily Recap',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context, ThemeData theme) {
    final isMobile = ResponsiveLayout.isMobile(context);

    // Tutto sulla stessa riga, versione compatta per mobile
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          label: 'Total',
          count: totalTasks,
          color: theme.colorScheme.primary,
          compact: isMobile,
        ),
        _StatItem(
          label: 'Urgent',
          count: overdueTasks,
          color: theme.colorScheme.error,
          compact: isMobile,
        ),
        _StatItem(
          label: 'Today',
          count: dueTodayTasks,
          color: theme.colorScheme.secondary,
          compact: isMobile,
        ),
        _StatItem(
          label: 'Active',
          count: activeTasks,
          color: theme.colorScheme.primary,
          compact: isMobile,
        ),
      ],
    );
  }
}

/// Widget per un singolo elemento statistico
class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool compact;

  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 6 : 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: compact ? 14 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 9 : 12,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
