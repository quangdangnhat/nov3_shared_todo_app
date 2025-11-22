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
        SizedBox(width: isMobile ? 6 : 8),
        Text(
          'Daily Recap',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 24 : 30,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context, ThemeData theme) {
    final isMobile = ResponsiveLayout.isMobile(context);
    // Definisco il grigio per i bordi standard (non troppo chiaro, es. shade500)
    final standardBorderColor = Colors.grey.shade500;

    // Tutto sulla stessa riga, versione compatta per mobile
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          label: 'Total',
          count: totalTasks,
          color: theme.colorScheme.primary,
          borderColor: standardBorderColor, // Grigio
          compact: isMobile,
        ),
        _StatItem(
          label: 'Urgent',
          count: overdueTasks,
          color: theme.colorScheme.error,
          borderColor:
              theme.colorScheme.error, // Rosso (Mantiene il suo colore)
          compact: isMobile,
        ),
        _StatItem(
          label: 'Today',
          count: dueTodayTasks,
          color: theme.colorScheme.secondary,
          borderColor: standardBorderColor, // Grigio
          compact: isMobile,
        ),
        _StatItem(
          label: 'Active',
          count: activeTasks,
          color: theme.colorScheme.primary,
          borderColor: standardBorderColor, // Grigio
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
  final Color borderColor; // Nuova proprietà per il colore del bordo
  final bool compact;

  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
    required this.borderColor, // Richiesto nel costruttore
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
            // Aggiunto il bordo
            border: Border.all(
              color: borderColor,
              width: 2.0, // Spessore del bordo
            ),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 13 : 16,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
