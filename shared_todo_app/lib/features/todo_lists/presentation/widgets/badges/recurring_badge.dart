// coverage:ignore-file

import 'package:flutter/material.dart';
import '../../../../../core/enums/recurrence_type.dart';

/// Widget for displaying a recurring task badge
class RecurringBadge extends StatelessWidget {
  final bool isRecurring;
  final String recurrenceType;
  final bool isMobile;

  const RecurringBadge({
    Key? key,
    required this.isRecurring,
    required this.recurrenceType,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isRecurring || recurrenceType == 'none') {
      return const SizedBox.shrink();
    }

    final type = RecurrenceType.fromString(recurrenceType);
    final color = _getRecurrenceColor(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRecurrenceIcon(type),
            size: isMobile ? 16 : 18,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            type.displayName,
            style: TextStyle(
              color: color,
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRecurrenceColor(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return Colors.blue;
      case RecurrenceType.weekly:
        return Colors.purple;
      case RecurrenceType.monthly:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRecurrenceIcon(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return Icons.refresh;
      case RecurrenceType.weekly:
        return Icons.event_repeat;
      case RecurrenceType.monthly:
        return Icons.calendar_today;
      default:
        return Icons.repeat;
    }
  }
}