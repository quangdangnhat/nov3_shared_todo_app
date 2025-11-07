import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/responsive.dart';
//import '../../../config/router/app_router.dart';
import '../../../data/models/todo_list.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/task.dart';
import '../presentation/controllers/todo_list_detail_viewmodel.dart';
import '../../../core/utils/snackbar_utils.dart';
//import '../presentation/widgets/folder_list_tile.dart' hide TaskDialog;
import '../presentation/widgets/folder_dialog.dart';
import '../presentation/widgets/task_dialog.dart';
//import '../presentation/widgets/task_list_tile.dart';
//import '../../../main.dart'; // per accedere a supabase
import '../presentation/widgets/todo_list_detail_header.dart';
import '../presentation/widgets/folder_list_section.dart';
import '../presentation/widgets/task_list_section.dart';
import '../presentation/widgets/detail_action_buttons.dart';
// ---

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
  // Istanza del ViewModel
  late final TodoListDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Inizializza il ViewModel
    _viewModel = TodoListDetailViewModel();
    // Passa i dati iniziali e avvia il caricamento
    _viewModel.init(widget.todoList.id, widget.parentFolder.id);
    // Aggiunge un listener per rebuildare la UI quando lo stato cambia
    _viewModel.addListener(_onViewModelChanged);
  }

  // Metodo chiamato dal listener del ViewModel
  void _onViewModelChanged() {
    if (mounted) {
      setState(() {
        // Forza un rebuild per riflettere i cambiamenti di stato
        // (es. _isFoldersCollapsed)
      });
    }
  }

  @override
  void dispose() {
    // Rimuove il listener e fa il dispose del ViewModel
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _refreshStreams() {
    if (!mounted) return;
    _viewModel.init(widget.todoList.id, widget.parentFolder.id);
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
        showSuccessSnackBar(
          context,
          message:
              'Folder ${folderToEdit == null ? 'created' : 'updated'} successfully',
        );
        _refreshStreams();
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          message:
              'Failed to ${folderToEdit == null ? 'create' : 'update'} folder: $error',
        );
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // 1. Chiama il ViewModel per la logica di business
                  await _viewModel.deleteFolder(folder.id);

                  // 2. Gestisce la UI (rimane responsabilità della View)
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showSuccessSnackBar(
                      context,
                      message: 'Folder deleted successfully',
                    );
                    _refreshStreams();
                  }
                } catch (error) {
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showErrorSnackBar(
                      context,
                      message: 'Failed to delete folder: $error',
                    );
                  }
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
        showSuccessSnackBar(
          context,
          message:
              'Task ${taskToEdit == null ? 'created' : 'updated'} successfully',
        );
        _refreshStreams();
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          message:
              'Failed to ${taskToEdit == null ? 'create' : 'update'} task: $error',
        );
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // 1. Chiama il ViewModel
                  await _viewModel.deleteTask(task.id);

                  // 2. Gestisce la UI
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showSuccessSnackBar(
                      context,
                      message: 'Task deleted successfully',
                    );
                    _refreshStreams();
                  }
                } catch (error) {
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showErrorSnackBar(
                      context,
                      message: 'Failed to delete task: $error',
                    );
                  }
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
    try {
      // Chiama il ViewModel, non gestisce più lo stato
      await _viewModel.handleTaskStatusChange(task, newStatus);
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          message: 'Failed to update task status: $error',
        );
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
                          child: Text(
                            value[0].toUpperCase() + value.substring(1),
                          ),
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
                              // 1. Chiama il ViewModel
                              await _viewModel.inviteUser(
                                widget.todoList.id,
                                emailController.text.trim(),
                                selectedRole,
                              );

                              // 2. Gestisce la UI
                              if (mounted) {
                                Navigator.of(stfContext).pop();
                                showSuccessSnackBar(
                                  context,
                                  message: 'Invitation sent successfully!',
                                );
                              }
                            } catch (error) {
                              if (mounted) {
                                showErrorSnackBar(
                                  stfContext,
                                  message: error.toString().replaceFirst(
                                        "Exception: ",
                                        "",
                                      ),
                                );
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
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
      // 1. Chiama il ViewModel per ottenere i dati
      final parentFolder =
          await _viewModel.getParentFolderForNavigation(parentId);

      if (!mounted) return;

      // 2. Gestisce la UI (navigazione)
      if (parentFolder.parentId == null) {
        // Il parent è root
        context.go(
          '/list/${widget.todoList.id}',
          extra: {'todoList': widget.todoList, 'parentFolder': parentFolder},
        );
      } else {
        // Il parent è una sottocartella
        context.go(
          '/list/${widget.todoList.id}/folder/${parentFolder.id}',
          extra: {'todoList': widget.todoList, 'parentFolder': parentFolder},
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context, message: 'Failed to navigate back: $error');
      }
    }
  }

  void _onFolderTap(Folder folder) {
    if (!mounted) return;
    context.go(
      '/list/${widget.todoList.id}/folder/${folder.id}',
      extra: {'todoList': widget.todoList, 'parentFolder': folder},
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRootFolder = widget.parentFolder.parentId == null;
    final bool isMobile = ResponsiveLayout.isMobile(context);

    // REFACTOR: Leggiamo lo stato dal ViewModel
    final bool isFoldersCollapsed = _viewModel.isFoldersCollapsed;
    final bool isTasksCollapsed = _viewModel.isTasksCollapsed;
    final Stream<List<Folder>> foldersStream = _viewModel.foldersStream;
    final Stream<List<Task>> tasksStream = _viewModel.tasksStream;

    return Container(
      key: ValueKey(
        'folder_screen_${widget.parentFolder.id}',
      ), // KEY IMPORTANTE per forzare rebuild
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // --- WIDGET ESTRATTO ---
          TodoListDetailHeader(
            isMobile: isMobile,
            isRootFolder: isRootFolder,
            title: widget.parentFolder.title,
            onMenuPressed: () => Scaffold.of(context).openDrawer(),
            onBackPressed: _navigateToParent,
            onInvitePressed: _showInviteMemberDialog,
          ),
          // --- FINE WIDGET ESTRATTO ---

          // Contenuto principale
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async => _refreshStreams(),
                  child: CustomScrollView(
                    slivers: [
                      // --- WIDGET ESTRATTO ---
                      FolderListSection(
                        isCollapsed: isFoldersCollapsed,
                        stream: foldersStream,
                        onToggleCollapse: _viewModel.toggleFoldersCollapse,
                        onFolderTap: (folder) => _onFolderTap(folder),
                        onEdit: (folder) =>
                            _openFolderDialog(folderToEdit: folder),
                        onDelete: (folder) => _showDeleteFolderDialog(folder),
                      ),
                      // --- FINE WIDGET ESTRATTO ---

                      // --- WIDGET ESTRATTO ---
                      TaskListSection(
                        isCollapsed: isTasksCollapsed,
                        stream: tasksStream,
                        onToggleCollapse: _viewModel.toggleTasksCollapse,
                        onEdit: (task) => _openTaskDialog(taskToEdit: task),
                        onDelete: (task) => _showDeleteTaskDialog(task),
                        onStatusChanged: (task, newStatus) =>
                            _handleTaskStatusChange(task, newStatus),
                      ),
                      // --- FINE WIDGET ESTRATTO ---

                      // Spazio in fondo per non far coprire i FAB
                      const SliverToBoxAdapter(child: SizedBox(height: 160)),
                    ],
                  ),
                ),

                // --- WIDGET ESTRATTO ---
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: DetailActionButtons(
                    isMobile: isMobile,
                    onNewFolder: () => _openFolderDialog(),
                    onNewTask: () => _openTaskDialog(),
                  ),
                ),
                // --- FINE WIDGET ESTRATTO ---
              ],
            ),
          ),
        ],
      ),
    );
  }
}
