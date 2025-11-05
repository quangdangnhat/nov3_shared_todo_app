import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/responsive.dart';
import '../../../config/router/app_router.dart';
import '../../../data/models/todo_list.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/invitation_repository.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../presentation/widgets/folder_list_tile.dart' hide TaskDialog;
import '../presentation/widgets/folder_dialog.dart';
import '../presentation/widgets/task_dialog.dart';
import '../presentation/widgets/task_list_tile.dart';
import '../../../main.dart'; // per accedere a supabase

/// Schermata di dettaglio di una TodoList con le sue cartelle e task.
/// NOTA: La sidebar è gestita da MainLayout tramite ShellRoute
class TodoListDetailScreen extends StatefulWidget {
  final TodoList todoList;
  final Folder parentFolder;

  const TodoListDetailScreen({
    super.key,
    required this.todoList,
    required this.parentFolder,
  });

  @override
  State<TodoListDetailScreen> createState() => _TodoListDetailScreenState();
}

class _TodoListDetailScreenState extends State<TodoListDetailScreen> {
  final FolderRepository _folderRepo = FolderRepository();
  final TaskRepository _taskRepo = TaskRepository();
  final InvitationRepository _invitationRepo = InvitationRepository();

  late Stream<List<Folder>> _foldersStream;
  late Stream<List<Task>> _tasksStream;

  bool _isFoldersCollapsed = false;
  bool _isTasksCollapsed = false;

  @override
  void initState() {
    super.initState();
    _refreshStreams();
  }

  void _refreshStreams() {
    if (!mounted) return;
    setState(() {
      _foldersStream = _folderRepo.getFoldersStream(
        widget.todoList.id,
        parentId: widget.parentFolder.id,
      );
      _tasksStream = _taskRepo.getTasksStream(widget.parentFolder.id);
    });
  }

  Future<void> _openFolderDialog({Folder? folderToEdit}) async {
    if (!mounted) return;
    try {
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return FolderDialog(
            todoListId: widget.todoList.id,
            parentId: widget.parentFolder.id,
            folderToEdit: folderToEdit,
          );
        },
      );
      if (result == true && mounted) {
        showSuccessSnackBar(context,
            message:
                'Folder ${folderToEdit == null ? 'created' : 'updated'} successfully');
        _refreshStreams();
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context,
            message:
                'Failed to ${folderToEdit == null ? 'create' : 'update'} folder: $error');
      }
    }
  }

  void _showDeleteFolderDialog(Folder folder) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: Text('Are you sure you want to delete "${folder.title}"?'),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                bool deleting = false;
                if (deleting) return;
                deleting = true;
                try {
                  await _folderRepo.deleteFolder(folder.id);
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showSuccessSnackBar(context,
                        message: 'Folder deleted successfully');
                    _refreshStreams();
                  }
                } catch (error) {
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showErrorSnackBar(context,
                        message: 'Failed to delete folder: $error');
                  }
                } finally {
                  deleting = false;
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openTaskDialog({Task? taskToEdit}) async {
    if (!mounted) return;
    try {
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => TaskDialog(
          folderId: widget.parentFolder.id,
          taskToEdit: taskToEdit,
        ),
      );
      if (result == true && mounted) {
        showSuccessSnackBar(context,
            message:
                'Task ${taskToEdit == null ? 'created' : 'updated'} successfully');
        _refreshStreams();
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context,
            message:
                'Failed to ${taskToEdit == null ? 'create' : 'update'} task: $error');
      }
    }
  }

  void _showDeleteTaskDialog(Task task) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                bool deleting = false;
                if (deleting) return;
                deleting = true;
                try {
                  await _taskRepo.deleteTask(task.id);
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showSuccessSnackBar(context,
                        message: 'Task deleted successfully');
                    _refreshStreams();
                  }
                } catch (error) {
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showErrorSnackBar(context,
                        message: 'Failed to delete task: $error');
                  }
                } finally {
                  deleting = false;
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleTaskStatusChange(Task task, String newStatus) async {
    if (task.status == newStatus) return;
    try {
      await _taskRepo.updateTask(taskId: task.id, status: newStatus);
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context,
            message: 'Failed to update task status: $error');
      }
    }
  }

  void _showInviteMemberDialog() {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final roles = ['admin', 'collaborator'];
    String selectedRole = roles[1];
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              title: const Text('Invite Member'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: emailController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'User Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty ||
                            !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: roles.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child:
                              Text(value[0].toUpperCase() + value.substring(1)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        stfSetState(() => selectedRole = newValue!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(stfContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            stfSetState(() => isLoading = true);
                            try {
                              await _invitationRepo.inviteUserToList(
                                todoListId: widget.todoList.id,
                                email: emailController.text.trim(),
                                role: selectedRole,
                              );

                              if (mounted) {
                                Navigator.of(stfContext).pop();
                                showSuccessSnackBar(context,
                                    message: 'Invitation sent successfully!');
                              }
                            } catch (error) {
                              if (mounted) {
                                showErrorSnackBar(stfContext,
                                    message: error
                                        .toString()
                                        .replaceFirst("Exception: ", ""));
                              }
                            } finally {
                              if (mounted) {
                                stfSetState(() => isLoading = false);
                              }
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send Invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToParent() async {
    final parentId = widget.parentFolder.parentId;
    
    if (parentId == null) {
      // Siamo nella root, torna alla home
      if (!mounted) return;
      context.go('/');
      return;
    }

    try {
      // Usa la query diretta a Supabase per ottenere il folder parent
      final response = await supabase
          .from('folders')
          .select()
          .eq('id', parentId)
          .single();
      
      final parentFolder = Folder.fromMap(response);

      if (!mounted) return;

      // Usa sempre go() per la navigazione all'indietro
      if (parentFolder.parentId == null) {
        // Il parent è root
        context.go(
          '/list/${widget.todoList.id}',
          extra: {
            'todoList': widget.todoList,
            'parentFolder': parentFolder,
          },
        );
      } else {
        // Il parent è una sottocartella
        context.go(
          '/list/${widget.todoList.id}/folder/${parentFolder.id}',
          extra: {
            'todoList': widget.todoList,
            'parentFolder': parentFolder,
          },
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context, message: 'Failed to navigate back: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRootFolder = widget.parentFolder.parentId == null;
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      key: ValueKey('folder_screen_${widget.parentFolder.id}'), // KEY IMPORTANTE per forzare rebuild
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header personalizzato che sostituisce l'AppBar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Leading button
                if (isMobile && isRootFolder)
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: 'Menu',
                  )
                else if (!isMobile)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                    onPressed: _navigateToParent,
                  )
                else if (isMobile && !isRootFolder)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                    onPressed: _navigateToParent,
                  ),

                if (isRootFolder && isMobile) const SizedBox(width: 8),

                // Titolo
                Expanded(
                  child: Text(
                    widget.parentFolder.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Actions
                if (isRootFolder)
                  IconButton(
                    icon: const Icon(Icons.person_add_outlined),
                    tooltip: 'Invite Member',
                    onPressed: _showInviteMemberDialog,
                  ),
              ],
            ),
          ),

          // Contenuto principale
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async => _refreshStreams(),
                  child: CustomScrollView(
                    slivers: [
                      // Sezione Cartelle
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0)
                              .copyWith(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Folders',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isFoldersCollapsed
                                      ? Icons.expand_more
                                      : Icons.expand_less,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() =>
                                    _isFoldersCollapsed = !_isFoldersCollapsed),
                                tooltip: _isFoldersCollapsed
                                    ? 'Expand Folders'
                                    : 'Collapse Folders',
                              ),
                            ],
                          ),
                        ),
                      ),
                      StreamBuilder<List<Folder>>(
                        stream: _foldersStream,
                        builder: (context, snapshot) {
                          if (_isFoldersCollapsed) {
                            return const SliverToBoxAdapter(
                                child: SizedBox.shrink());
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return SliverToBoxAdapter(
                              child: Center(
                                child: Text(
                                  'Error loading folders: ${snapshot.error}',
                                ),
                              ),
                            );
                          }
                          final folders = snapshot.data ?? [];
                          if (folders.isEmpty) {
                            return const SliverToBoxAdapter(
                                child: SizedBox.shrink());
                          }

                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final folder = folders[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: FolderListTile(
                                    folder: folder,
                                    onTap: () {
                                      debugPrint(' Navigating to folder: ${folder.id}');
                                      debugPrint('   Current parent folder: ${widget.parentFolder.id}');
                                      debugPrint('   TodoList: ${widget.todoList.id}');
                                      
                                      // Usa go() con path completo
                                      context.go(
                                        '/list/${widget.todoList.id}/folder/${folder.id}',
                                        extra: {
                                          'todoList': widget.todoList,
                                          'parentFolder': folder,
                                        },
                                      );
                                    },
                                    onEdit: () =>
                                        _openFolderDialog(folderToEdit: folder),
                                    onDelete: () =>
                                        _showDeleteFolderDialog(folder),
                                  ),
                                );
                              },
                              childCount: folders.length,
                            ),
                          );
                        },
                      ),

                      // Sezione Task
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0)
                              .copyWith(top: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tasks',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isTasksCollapsed
                                      ? Icons.expand_more
                                      : Icons.expand_less,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() =>
                                    _isTasksCollapsed = !_isTasksCollapsed),
                                tooltip: _isTasksCollapsed
                                    ? 'Expand Tasks'
                                    : 'Collapse Tasks',
                              ),
                            ],
                          ),
                        ),
                      ),
                      StreamBuilder<List<Task>>(
                        stream: _tasksStream,
                        builder: (context, snapshot) {
                          if (_isTasksCollapsed) {
                            return const SliverToBoxAdapter(
                                child: SizedBox.shrink());
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            debugPrint(
                                'Errore StreamBuilder Tasks: ${snapshot.error}');
                            return SliverToBoxAdapter(
                              child: Center(
                                child: Text(
                                    'Error loading tasks: ${snapshot.error}'),
                              ),
                            );
                          }
                          final tasks = snapshot.data ?? [];
                          if (tasks.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32.0),
                                child: Center(
                                  child: Text(
                                    'No tasks in this folder yet.',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                            );
                          }

                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final task = tasks[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: TaskListTile(
                                    task: task,
                                    onTap: () {},
                                    onEdit: () =>
                                        _openTaskDialog(taskToEdit: task),
                                    onDelete: () => _showDeleteTaskDialog(task),
                                    onStatusChanged: (newStatus) =>
                                        _handleTaskStatusChange(
                                            task, newStatus),
                                  ),
                                );
                              },
                              childCount: tasks.length,
                            ),
                          );
                        },
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 160)),
                    ],
                  ),
                ),

                // FloatingActionButtons posizionati manualmente
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton.extended(
                        onPressed: () => _openFolderDialog(),
                        tooltip: 'New Folder',
                        heroTag: 'fabFolder',
                        icon: const Icon(Icons.create_new_folder),
                        label: const SizedBox(
                          width: 110,
                          child:
                              Text('New Folder', textAlign: TextAlign.center),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FloatingActionButton.extended(
                        onPressed: () => _openTaskDialog(),
                        tooltip: 'New Task',
                        heroTag: 'fabTask',
                        icon: const Icon(Icons.add_task),
                        label: const SizedBox(
                          width: 110,
                          child: Text('New Task', textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}