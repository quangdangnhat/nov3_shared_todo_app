import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/responsive.dart';
import '../../../../config/router/app_router.dart';
import '../../../../data/models/todo_list.dart';
import '../../../../data/models/folder.dart';
import '../../../../data/models/task.dart';
// Importa il ViewModel
import '../presentation/controllers/todo_list_detail_viewmodel.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../presentation/widgets/folder_list_tile.dart' hide TaskDialog;
import '../presentation/widgets/folder_dialog.dart';
import '../presentation/widgets/task_dialog.dart';
import '../presentation/widgets/task_list_tile.dart';
import '../../../../main.dart'; // per accedere a supabase
import '../presentation/widgets/todo_list_detail_header.dart';
import '../presentation/widgets/folder_list_section.dart';
import '../presentation/widgets/task_list_section.dart';
import '../presentation/widgets/detail_action_buttons.dart';
import '../presentation/widgets/participants_dialog.dart';
import '../presentation/widgets/manage_members_dialog.dart'; // Importato per _showInviteFormDialog

/// Schermata di dettaglio di una TodoList con le sue cartelle e task.
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
    // Resetta l'inizializzazione e ricarica i dati
    _viewModel.resetInitialization();
    _viewModel.init(widget.todoList.id, widget.parentFolder.id);
  }

  // Logica di presentazione per il dialogo Folder
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

  // Logica di presentazione per il dialogo Delete Folder
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
                  // 1. Chiama il ViewModel
                  await _viewModel.deleteFolder(folder.id);

                  // 2. Gestisce la UI
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

  // Logica di presentazione per il dialogo Task
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

  // Logica di presentazione per il dialogo Delete Task
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

  // Logica di presentazione per l'update dello stato
  Future<void> _handleTaskStatusChange(Task task, String newStatus) async {
    try {
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

  // --- NUOVO METODO: Apre il form di invito (ManageMembersDialog) ---
  void _showInviteFormDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return ManageMembersDialog(
          todoListId: widget.todoList.id,
          viewModel: _viewModel,
        );
      },
    );
  }

  // --- RINOMINATO: Apre la lista di gestione (ParticipantsDialog) ---
  void _showManageMembersDialog() {
    // Ottiene l'ID utente corrente per passarlo al dialog
    final currentUserId = supabase.auth.currentUser?.id ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Chiama il ParticipantsDialog (la lista di gestione)
        return ParticipantsDialog(
          viewModel: _viewModel,
          todoListId: widget.todoList.id,
          todoListTitle: widget.todoList.title,
          currentUserId: currentUserId,
          currentUserRole: _viewModel.currentUserRole,
          // Gli passiamo le callback per aggiornare la UI
          onInvitationSent: () {
            showSuccessSnackBar(context, message: 'Invitation Sent!');
            // Non serve ricaricare i flussi qui, perché lo Stream gestisce l'aggiornamento
          },
          onParticipantsChanged: () {
            // Non serve ricaricare i flussi qui, perché lo Stream gestisce l'aggiornamento
          },
        );
      },
    );
  }

  // Logica di navigazione (chiama il ViewModel per i dati)
  Future<void> _navigateToParent() async {
    final parentId = widget.parentFolder.parentId;

    if (parentId == null) {
      if (!mounted) return;
      context.go('/');
      return;
    }

    try {
      // 1. Chiama il ViewModel
      final parentFolder =
          await _viewModel.getParentFolderForNavigation(parentId);

      if (!mounted) return;

      // 2. Gestisce la UI (navigazione)
      if (parentFolder.parentId == null) {
        context.go(
          '/list/${widget.todoList.id}',
          extra: {'todoList': widget.todoList, 'parentFolder': parentFolder},
        );
      } else {
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

  @override
  Widget build(BuildContext context) {
    final bool isRootFolder = widget.parentFolder.parentId == null;
    final bool isMobile = ResponsiveLayout.isMobile(context);

    // Leggiamo lo stato dal ViewModel
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
          // === 1. HEADER WIDGET ===
          TodoListDetailHeader(
            isMobile: isMobile,
            isRootFolder: isRootFolder,
            title: widget.parentFolder.title,
            // --- FIX: PARAMETRI CORRETTI ---
            onBackTap: _navigateToParent,
            onManageTap: _showManageMembersDialog, // Apre la LISTA (ParticipantsDialog)
            onInviteTap: _showInviteFormDialog, // Apre il FORM (ManageMembersDialog)
            // --- FINE FIX ---
          ),

          // === 2. CONTENUTO PRINCIPALE ===
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async => _refreshStreams(),
                  child: CustomScrollView(
                    slivers: [
                      // === 3. FOLDER LIST WIDGET ===
                      FolderListSection(
                        isCollapsed: isFoldersCollapsed,
                        stream: foldersStream,
                        onToggleCollapse: _viewModel.toggleFoldersCollapse,
                        onFolderTap: (folder) {
                          context.go(
                            '/list/${widget.todoList.id}/folder/${folder.id}',
                            extra: {
                              'todoList': widget.todoList,
                              'parentFolder': folder
                            },
                          );
                        },
                        onEdit: (folder) => _openFolderDialog(
                          folderToEdit: folder,
                        ),
                        onDelete: (folder) => _showDeleteFolderDialog(folder),
                      ),

                      // === 4. TASK LIST WIDGET ===
                      TaskListSection(
                        isCollapsed: isTasksCollapsed,
                        stream: tasksStream,
                        onToggleCollapse: _viewModel.toggleTasksCollapse,
                        onEdit: (task) => _openTaskDialog(taskToEdit: task),
                        onDelete: (task) => _showDeleteTaskDialog(task),
                        onStatusChanged: (task, newStatus) =>
                            _handleTaskStatusChange(task, newStatus),
                      ),

                      // Spaziatore per i FAB
                      const SliverToBoxAdapter(child: SizedBox(height: 160)),
                    ],
                  ),
                ),
                // === 5. ACTION BUTTONS WIDGET ===
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: DetailActionButtons(
                    isMobile: isMobile,
                    onNewFolder: () => _openFolderDialog(),
                    onNewTask: () => _openTaskDialog(),
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
