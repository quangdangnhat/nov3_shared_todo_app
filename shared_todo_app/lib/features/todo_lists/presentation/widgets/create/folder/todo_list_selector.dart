import 'package:flutter/material.dart';
import '../../../../../../data/models/todo_list.dart';
import '../../../controllers/base_controller.dart';

class TodoListSelector extends StatefulWidget {
  final BaseFolderSelectionController controller;
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
  State<TodoListSelector> createState() => _TodoListSelectorState();
}

class _TodoListSelectorState extends State<TodoListSelector> {
  Future<void> _showTodoListDialog() async {
    // Reset search quando apri il dialog
    widget.searchController.clear();
    widget.onSearchChanged('');

    final TodoList? selected = await showDialog<TodoList>(
      context: context,
      builder: (context) => _TodoListDialog(
        controller: widget.controller,
        searchController: widget.searchController,
        onSearchChanged: widget.onSearchChanged,
      ),
    );

    if (selected != null) {
      widget.onTodoListSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TodoList>>(
      stream: widget.controller.listsStream,
      builder: (context, snapshot) {
        return InkWell(
          onTap: _showTodoListDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
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
                          widget.controller.selectedTodoList?.title ??
                              'Select a list',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.controller.selectedTodoList != null
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
          ),
        );
      },
    );
  }
}

// Dialog personalizzato per la selezione TodoList
class _TodoListDialog extends StatefulWidget {
  final BaseFolderSelectionController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _TodoListDialog({
    required this.controller,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  State<_TodoListDialog> createState() => _TodoListDialogState();
}

class _TodoListDialogState extends State<_TodoListDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con campo di ricerca
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: widget.searchController,
                decoration: InputDecoration(
                  hintText: 'Search lists...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  widget.onSearchChanged(value);
                  setState(() {
                    // Ricostruisce il dialog per mostrare i risultati filtrati
                  });
                },
              ),
            ),

            const Divider(height: 1),

            // Lista delle TodoList
            Flexible(
              child: StreamBuilder<List<TodoList>>(
                stream: widget.controller.listsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final allLists = snapshot.data ?? [];
                  final filteredLists = widget.controller.filterLists(allLists);

                  if (filteredLists.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No lists found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredLists.length,
                    itemBuilder: (context, index) {
                      final list = filteredLists[index];
                      return ListTile(
                        leading: const Icon(Icons.list_alt, size: 20),
                        title: Text(
                          list.title,
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          Navigator.of(context).pop(list);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
