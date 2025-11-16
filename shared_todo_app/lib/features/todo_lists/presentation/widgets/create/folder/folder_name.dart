// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';

class FolderNameField extends StatelessWidget {
  final TextEditingController controller;

  const FolderNameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Folder name',
        hintText: 'Ex: work, shopping cart...',
        prefixIcon: const Icon(Icons.folder),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
