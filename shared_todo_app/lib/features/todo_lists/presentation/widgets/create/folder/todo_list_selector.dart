// lib/presentation/widgets/folder/todo_list_selector.dart

import 'package:flutter/material.dart';
import '../../../../../../data/models/todo_list.dart';
import '../../../controllers/folder/folder_create_page.dart';

class TodoListSelector extends StatelessWidget {
  final FolderCreateController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TodoList> onTodoListSelected;

  const TodoListSelector({
    super.key,
    required this.controller,
    required this.searchController,
    required this.onSearchChanged,
    required this.onTodoListSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TodoList>>(
      stream: controller.listsStream,
      builder: (context, snapshot) {
        final allLists = snapshot.data ?? [];
        final filteredLists = controller.filterLists(allLists);

        return PopupMenuButton<TodoList>(
          offset: const Offset(0, 50),
          constraints: BoxConstraints(
            minWidth: (MediaQuery.of(context).size.width - 40) / 2,
            maxWidth: (MediaQuery.of(context).size.width - 40) / 2,
          ),
          child: _buildSelectorButton(context),
          itemBuilder: (context) => _buildMenuItems(filteredLists),
          onSelected: onTodoListSelected,
        );
      },
    );
  }

  Widget _buildSelectorButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.list_alt, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    controller.selectedTodoList?.title ?? 'Select a list',
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.selectedTodoList != null
                          ? Colors.white
                          : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 24),
        ],
      ),
    );
  }

  List<PopupMenuEntry<TodoList>> _buildMenuItems(List<TodoList> filteredLists) {
    return [
      // Campo di ricerca
      PopupMenuItem<TodoList>(
        enabled: false,
        child: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search, size: 18),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onSearchChanged,
        ),
      ),
      const PopupMenuDivider(),

      // Lista delle TodoList filtrate
      ...filteredLists.map((list) {
        return PopupMenuItem<TodoList>(
          value: list,
          child: Row(
            children: [
              const Icon(Icons.list_alt, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  list.title,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),

      // Messaggio se non ci sono risultati
      if (filteredLists.isEmpty)
        const PopupMenuItem<TodoList>(
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'No lists found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
    ];
  }
}