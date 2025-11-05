// lib/presentation/widgets/task/create_task_button.dart

import 'package:flutter/material.dart';

class CreateTaskButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const CreateTaskButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Task',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
