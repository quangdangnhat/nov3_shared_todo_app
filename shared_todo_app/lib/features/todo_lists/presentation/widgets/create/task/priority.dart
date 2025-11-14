// coverage:ignore-file

// consider testing later

// lib/presentation/widgets/task/priority_selector.dart

import 'package:flutter/material.dart';

class PrioritySelector extends StatelessWidget {
  final String selectedPriority;
  final ValueChanged<String> onPriorityChanged;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPriorityChip('low', 'Low', Colors.green)),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPriorityChip('medium', 'Medium', Colors.orange),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildPriorityChip('high', 'High', Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityChip(String value, String label, Color color) {
    final isSelected = selectedPriority == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onPriorityChanged(value);
        }
      },
      selectedColor: color.withOpacity(0.2),
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }
}
