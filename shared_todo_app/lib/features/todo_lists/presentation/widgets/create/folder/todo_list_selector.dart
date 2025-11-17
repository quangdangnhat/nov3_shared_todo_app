// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import '../../../../../../config/responsive.dart';
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
    final theme = Theme.of(context);
    final borderRadius = ResponsiveLayout.responsive<double>(
      context,
      mobile: 12,
      tablet: 14,
      desktop: 16,
    );
    final iconSize = ResponsiveLayout.responsive<double>(
      context,
      mobile: 18,
      tablet: 20,
      desktop: 22,
    );
    final fontSize = ResponsiveLayout.responsive<double>(
      context,
      mobile: 14,
      tablet: 15,
      desktop: 16,
    );
    final horizontalPadding = ResponsiveLayout.responsive<double>(
      context,
      mobile: 12,
      tablet: 14,
      desktop: 16,
    );
    final verticalPadding = ResponsiveLayout.responsive<double>(
      context,
      mobile: 12,
      tablet: 14,
      desktop: 16,
    );

    return StreamBuilder<List<TodoList>>(
      stream: widget.controller.listsStream,
      builder: (context, snapshot) {
        return InkWell(
          onTap: _showTodoListDialog,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: iconSize,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(
                          width: ResponsiveLayout.responsive<double>(
                        context,
                        mobile: 8,
                        tablet: 10,
                        desktop: 12,
                      )),
                      Flexible(
                        child: Text(
                          widget.controller.selectedTodoList?.title ??
                              'Select a list',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: fontSize,
                            color: widget.controller.selectedTodoList != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: iconSize + 6,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
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
    final theme = Theme.of(context);
    final borderRadius = ResponsiveLayout.responsive<double>(
      context,
      mobile: 12,
      tablet: 16,
      desktop: 20,
    );
    final maxHeightFactor = ResponsiveLayout.responsive<double>(
      context,
      mobile: 0.6,
      tablet: 0.65,
      desktop: 0.7,
    );
    final maxWidthFactor = ResponsiveLayout.responsive<double>(
      context,
      mobile: 0.9,
      tablet: 0.7,
      desktop: 0.5,
    );
    final iconSize = ResponsiveLayout.responsive<double>(
      context,
      mobile: 20,
      tablet: 22,
      desktop: 24,
    );
    final fontSize = ResponsiveLayout.responsive<double>(
      context,
      mobile: 14,
      tablet: 15,
      desktop: 16,
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      backgroundColor: theme.dialogTheme.backgroundColor,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
          maxWidth: MediaQuery.of(context).size.width * maxWidthFactor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con campo di ricerca
            Padding(
              padding: EdgeInsets.all(ResponsiveLayout.responsive<double>(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              )),
              child: TextField(
                controller: widget.searchController,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search lists...',
                  hintStyle: theme.inputDecorationTheme.hintStyle,
                  prefixIcon: Icon(
                    Icons.search,
                    size: iconSize,
                    color: theme.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius * 0.67),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius * 0.67),
                    borderSide: BorderSide(
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius * 0.67),
                    borderSide: BorderSide(
                      color: theme.colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveLayout.responsive<double>(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    vertical: ResponsiveLayout.responsive<double>(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
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

            Divider(
              height: 1,
              thickness: 1,
              color: theme.dividerTheme.color,
            ),

            // Lista delle TodoList
            Flexible(
              child: StreamBuilder<List<TodoList>>(
                stream: widget.controller.listsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
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
                              size: ResponsiveLayout.responsive<double>(
                                context,
                                mobile: 48,
                                tablet: 56,
                                desktop: 64,
                              ),
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            SizedBox(
                                height: ResponsiveLayout.responsive<double>(
                              context,
                              mobile: 8,
                              tablet: 10,
                              desktop: 12,
                            )),
                            Text(
                              'No lists found',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
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
                        leading: Icon(
                          Icons.list_alt,
                          size: iconSize,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          list.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: fontSize,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(borderRadius * 0.75),
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
