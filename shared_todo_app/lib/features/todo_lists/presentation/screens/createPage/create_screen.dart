import 'package:flutter/material.dart';
import 'package:shared_todo_app/data/models/todo_list.dart';
import 'package:shared_todo_app/data/repositories/folder_repository.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/screens/createPage/folder_create.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/screens/createPage/task_create.dart';

import '../../../../../data/models/folder.dart';
import '../../../../../data/repositories/todo_list_repository.dart'
    show TodoListRepository;

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  // 0 = Folder, 1 = Task
  int _selectedIndex = 0;

  // Per poter visualizzare le todoList dell'utente
  final _todoListRepo = TodoListRepository();



  // Gestione dei campi della sezione folders
  final TextEditingController _folderNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();


  @override
  void dispose() {
    _folderNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create"),
      ),
      body: Column(
        children: [
          // Selector in alto a tutta larghezza
          _buildSelector(),

          // Contenuto che cambia in base alla selezione
          Expanded(
            child: _selectedIndex == 0 ? FolderCreatePage() : TaskCreatePage(),
          ),
        ],
      ),
    );
  }

  // ==================== SELECTOR ====================
  Widget _buildSelector() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSelectorButton(
              label: 'Folder',
              icon: Icons.folder,
              isSelected: _selectedIndex == 0,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
          ),
          Expanded(
            child: _buildSelectorButton(
              label: 'Task',
              icon: Icons.task_alt,
              isSelected: _selectedIndex == 1,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: Seleziona colore
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
      ),
    );
  }

  Widget _buildIconOption(IconData icon) {
    return GestureDetector(
      onTap: () {
        // TODO: Seleziona icona
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Icon(icon, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildPriorityChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
