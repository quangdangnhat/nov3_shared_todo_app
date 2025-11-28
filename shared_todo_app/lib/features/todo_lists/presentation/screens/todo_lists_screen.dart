import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_todo_app/data/models/task.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/search_result_tile.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/todo_list_tile.dart';
import '../../../../config/responsive.dart';
import '../../../../config/router/app_router.dart';
import '../../../../data/models/todo_list.dart';
import '../../../../data/repositories/todo_list_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/models/folder.dart';
import '../../../../data/repositories/folder_repository.dart';

enum ListFilter { all, personal, shared }

class TodoListsScreen extends StatefulWidget {
  const TodoListsScreen({super.key});

  @override
  State<TodoListsScreen> createState() => _TodoListsScreenState();
}

class _TodoListsScreenState extends State<TodoListsScreen> {
  final TodoListRepository _todoListRepo = TodoListRepository();
  final FolderRepository _folderRepo = FolderRepository();
  late Stream<List<TodoList>> _listsStream;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ListFilter _currentFilter = ListFilter.all;

  // --- Search State ---
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _listsStream = _todoListRepo.getTodoListsStream();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text;
      if (query.trim().isEmpty && _searchQuery.isNotEmpty) {
        setState(() {
          _searchQuery = '';
          _searchResults = [];
          _isSearching = false;
        });
      } else if (query.trim().length > 2) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });
    try {
      final results = await _todoListRepo.searchTasksAndGetPath(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context,
            message: "Error searching tasks: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showCreateListDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New List'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _todoListRepo.createTodoList(
                      title: titleController.text.trim(),
                      desc: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : null,
                    );
                    if (mounted) Navigator.of(context).pop();
                  } catch (error) {
                    if (mounted) {
                      showErrorSnackBar(
                        context,
                        message: 'Failed to create list: $error',
                      );
                    }
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showEditListDialog(TodoList list) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: list.title);
    final descController = TextEditingController(text: list.desc);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit List'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _todoListRepo.updateTodoList(
                      listId: list.id,
                      title: titleController.text.trim(),
                      desc: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : null,
                    );
                    if (mounted) {
                      Navigator.of(context).pop();
                      showSuccessSnackBar(
                        context,
                        message: 'List updated successfully',
                      );
                      setState(() {
                        _listsStream = _todoListRepo.getTodoListsStream();
                      });
                    }
                  } catch (error) {
                    if (mounted) {
                      showErrorSnackBar(
                        context,
                        message: 'Failed to update list: $error',
                      );
                    }
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(TodoList list) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave List?'),
          content: Text(
            'Are you sure you want to leave "${list.title}"?\n\nIf you are the last member, the list will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _handleDeleteList(list.id);
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteList(String listId) async {
    try {
      await _todoListRepo.leaveTodoList(listId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have left the list.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _listsStream = _todoListRepo.getTodoListsStream();
        });
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context, message: 'Failed to leave list: $error');
      }
    }
  }

  Future<void> _onSelectedList(TodoList list) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final Folder rootFolder = await _folderRepo.getRootFolder(list.id);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.goNamed(
            AppRouter.listDetail,
            pathParameters: {'listId': list.id},
            extra: {'todoList': list, 'parentFolder': rootFolder},
          );
        }
      });
    } on Exception catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showErrorSnackBar(
          context,
          message:
              'Could not load list details: ${e.toString().replaceFirst("Exception: ", "")}',
        );
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showErrorSnackBar(
          context,
          message: 'An unexpected error occurred: $error',
        );
      }
    }
  }

  Future<void> _navigateToTask(Map<String, dynamic> taskData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final String listId = taskData['list_id'];

      final TodoList todoList = await _todoListRepo.getTodoListById(listId);
      final Folder rootFolder = await _folderRepo.getRootFolder(listId);

      final Task task = Task.fromMap(taskData);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      context.goNamed(
        AppRouter.listDetail,
        pathParameters: {'listId': listId},
        extra: {
          'todoList': todoList,
          'parentFolder': rootFolder,
          'taskToShow': task,
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showErrorSnackBar(
          context,
          message: 'Could not navigate to task: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (isMobile) ...[
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: 'Menu',
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  'My To-Do Lists',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: "Create",
                  onPressed: () {
                    context.go(AppRouter.create);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.account_tree_outlined),
                  tooltip: "Tree View",
                  onPressed: () {
                    context.go(AppRouter.visualizer, extra: _todoListRepo);
                  },
                ),
                // gestione del campenello
                //  InvitationsNotificationButton(key: ValueKey('invitation_button')),
              ],
            ),
          ),

          // BARRA DI RICERCA MIGLIORATA
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          Expanded(
            child: _searchQuery.isEmpty
                ? _buildListsView()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No tasks found for "$_searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
      ),
      itemBuilder: (context, index) {
        final result = _searchResults[index];

        return SearchResultTile(
          taskTitle: result['title'] ?? 'No Title',
          listName: result['list_name'] ?? 'Unknown List',
          folderPath: result['folder_path'] ?? 'No Folder',
          onTap: () => _navigateToTask(result),
        );
      },
    );
  }

  Widget _buildListsView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filters = {
      'All': ListFilter.all,
      'Personal': ListFilter.personal,
      'Shared': ListFilter.shared
    };

    return Column(
      children: [
        // FILTRI MIGLIORATI
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: filters.entries.map((entry) {
                final label = entry.key;
                final filter = entry.value;
                final isSelected = _currentFilter == filter;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentFilter = filter;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              StreamBuilder<List<TodoList>>(
                stream: _listsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                          'Error loading lists. Check your connection and try again!'),
                    );
                  }

                  final lists = snapshot.data;

                  if (lists == null || lists.isEmpty) {
                    return _buildEmptyState();
                  }

                  var filteredLists = lists;

                  if (_currentFilter == ListFilter.personal) {
                    filteredLists = lists
                        .where((list) =>
                            list.role == 'admin' && list.memberCount == 1)
                        .toList();
                  } else if (_currentFilter == ListFilter.shared) {
                    filteredLists = lists
                        .where((list) =>
                            !(list.role == 'admin' && list.memberCount == 1))
                        .toList();
                  }

                  if (filteredLists.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          "No lists in this category",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return _buildList(filteredLists);
                },
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: _showCreateListDialog,
                  tooltip: 'Create List',
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "You don't have any lists yet. Create one!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<TodoList> lists) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return TodoListTile(
          list: list,
          onTap: () => _onSelectedList(list),
          onEdit: () => _showEditListDialog(list),
          onDelete: () => _showDeleteConfirmationDialog(list),
        );
      },
    );
  }
}
