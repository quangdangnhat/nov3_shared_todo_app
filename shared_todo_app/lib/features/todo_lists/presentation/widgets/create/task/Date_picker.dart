import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DatePickerType {
  startDate, // 0
  dueDate, // 1
}

class DatePickerCard extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DatePickerType type;

  const DatePickerCard({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.type = DatePickerType.dueDate, // Default: Due Date
  });

  String _getLabel() {
    switch (type) {
      case DatePickerType.startDate:
        return 'Start date';
      case DatePickerType.dueDate:
        return 'End date';
    }
  }

  Color _getIconColor() {
    switch (type) {
      case DatePickerType.startDate:
        return Colors.blue[700]!;
      case DatePickerType.dueDate:
        return Colors.green[700]!;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today, ${DateFormat('d MMMM').format(date)}';
    } else if (dateToCheck == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${DateFormat('d MMMM').format(date)}';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('d MMMM').format(date)}';
    } else {
      return DateFormat('EEEE, d MMMM').format(date);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate:
          type == DatePickerType.startDate ? DateTime.now() : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: _getIconColor()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLabel(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    _formatDate(selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black, // Aggiunto colore nero
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
