// coverage:ignore-file

import 'package:flutter/material.dart';
import '../../../../../../core/enums/recurrence_type.dart';

class RecurrenceSelector extends StatelessWidget {
  final bool isRecurring;
  final RecurrenceType recurrenceType;
  final ValueChanged<bool> onRecurringChanged;
  final ValueChanged<RecurrenceType> onRecurrenceTypeChanged;

  const RecurrenceSelector({
    super.key,
    required this.isRecurring,
    required this.recurrenceType,
    required this.onRecurringChanged,
    required this.onRecurrenceTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox for "Make recurring"
        Row(
          children: [
            Checkbox(
              value: isRecurring,
              onChanged: (value) => onRecurringChanged(value ?? false),
            ),
            const Text(
              'Make recurring',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),

        // Show recurrence options only when recurring is enabled
        if (isRecurring) ...[
          const SizedBox(height: 12),
          const Text(
            'Recurrence Pattern',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRecurrenceChip(
                  RecurrenceType.daily,
                  'Daily',
                  Icons.today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRecurrenceChip(
                  RecurrenceType.weekly,
                  'Weekly',
                  Icons.calendar_view_week,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRecurrenceChip(
                  RecurrenceType.monthly,
                  'Monthly',
                  Icons.calendar_month,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRecurrenceChip(
    RecurrenceType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = isRecurring && recurrenceType == type;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? color : Colors.grey[600]),
          const SizedBox(width: 4),
          Flexible(child: Text(label)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onRecurrenceTypeChanged(type);
        }
      },
      selectedColor: color.withOpacity(0.2),
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }
}