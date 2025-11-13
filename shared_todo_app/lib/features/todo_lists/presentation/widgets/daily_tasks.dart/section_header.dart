import 'package:flutter/material.dart';
import '../../../../../config/responsive.dart';
import '../../../../../core/utils/daily_tasks/color_helper.dart';
import '../../../../../data/models/daily_tasks/task_category.dart';

/// Widget per l'header di una sezione di task
class SectionHeader extends StatelessWidget {
  final TaskCategory category;
  final int taskCount;

  const SectionHeader({
    Key? key,
    required this.category,
    required this.taskCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ColorHelper.getCategoryColor(category, theme);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              category.icon,
              color: color,
              size: ResponsiveLayout.responsive<double>(
                context,
                mobile: 24,
                desktop: 28,
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: Text(
                category.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveLayout.responsive<double>(
                    context,
                    mobile: 18,
                    tablet: 20,
                    desktop: 22,
                  ),
                ),
              ),
            ),
            _buildCountBadge(color, isMobile),
          ],
        ),
        if (!isMobile) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              category.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCountBadge(Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$taskCount',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 12 : 14,
        ),
      ),
    );
  }
}
