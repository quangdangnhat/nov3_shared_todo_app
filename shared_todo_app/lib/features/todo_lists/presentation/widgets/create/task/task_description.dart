import 'package:flutter/material.dart';

class TaskDescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const TaskDescriptionField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'Description (optional)',
        hintText: 'Add details',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
