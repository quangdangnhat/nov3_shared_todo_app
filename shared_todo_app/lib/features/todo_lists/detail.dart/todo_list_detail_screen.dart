// coverage:ignore-file

// consider testing later

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/responsive.dart';
import '../../../config/router/app_router.dart';
import '../../../data/models/todo_list.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/task.dart';
// Importa il ViewModel
import '../../../data/repositories/folder_repository.dart';
import '../presentation/controllers/todo_list_detail_viewmodel.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../presentation/widgets/folder_dialog.dart';
import '../presentation/widgets/task_dialog.dart';
import '../presentation/widgets/task_list_tile.dart';
import '../../../main.dart'; // per accedere a supabase
import '../presentation/widgets/todo_list_detail_header.dart';
import '../presentation/widgets/folder_list_section.dart';
import '../presentation/widgets/detail_action_buttons.dart';
import '../presentation/widgets/participants_dialog.dart';
import '../presentation/widgets/manage_members_dialog.dart'; // Importato per _showInviteFormDialog

// --- IMPORT AGGIUNTI PER IL FILTRO ---
import '../../../../core/enums/task_filter_type.dart';
import '../../../../core/utils/task_sorter.dart';
import '../presentation/widgets/task_filter_dropdown.dart';
// --- FINE IMPORT ---

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

  // --- STATO PER IL FILTRO TASK ---
  // Aggiungiamo lo stato per il filtro, defaultato
  TaskFilterType _selectedTaskFilter = TaskFilterType.createdAtNewest;
  // --- FINE STATO ---

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

  // --- Funzioni Dialog (invariate) ---
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
      builder: (dialogContext) {
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
                  // Correzione: folderId come primo parametro
                  await _viewModel.deleteTask(widget.parentFolder.id, task.id);

                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showSuccessSnackBar(
                      context,
                      message: 'Task deleted successfully',
                    );
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

  void _showManageMembersDialog() {
    final currentUserId = supabase.auth.currentUser?.id ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return ParticipantsDialog(
          viewModel: _viewModel,
          todoListId: widget.todoList.id,
          todoListTitle: widget.todoList.title,
          currentUserId: currentUserId,
          currentUserRole: _viewModel.currentUserRole,
          onInvitationSent: () {
            showSuccessSnackBar(context, message: 'Invitation Sent!');
          },
          onParticipantsChanged: () {
            // Non serve ricaricare, lo stream aggiorna
          },
        );
      },
    );
  }

  Future<void> _navigateToParent() async {
    // 1. Controlla se la cartella corrente è la cartella "root"
    final bool isRootFolder = widget.parentFolder.parentId == null;

    if (!mounted) return;

    if (isRootFolder) {
      // 2. Se È la root, torna alla schermata Home (elenco delle liste)
      context.go(AppRouter.home);
    } else {
      // 3. Se NON È la root, ha un genitore. Dobbiamo caricarlo.
      final String parentFolderId = widget.parentFolder.parentId!;

      try {
        // Inizializza il repository (il costruttore vuoto va bene)
        final folderRepository = FolderRepository();

        // 4. MODIFICA: Chiamiamo 'getFolder' come nel tuo nuovo repository
        final Folder parentOfCurrentFolder = await folderRepository.getFolder(
          parentFolderId,
        );

        if (!mounted) return;

        // 5. Controlla se il genitore che abbiamo caricato è la root
        final bool isParentTheRoot = parentOfCurrentFolder.parentId == null;

        if (isParentTheRoot) {
          // 6a. Se il genitore è la root, naviga alla rotta 'listDetail'
          context.goNamed(
            AppRouter.listDetail,
            pathParameters: {'listId': widget.todoList.id},
            extra: {
              'todoList': widget.todoList,
              'parentFolder': parentOfCurrentFolder,
            },
          );
        } else {
          // 6b. Se il genitore è un'altra cartella, naviga a 'folderDetail'
          context.goNamed(
            AppRouter.folderDetail,
            pathParameters: {
              'listId': widget.todoList.id,
              'folderId': parentOfCurrentFolder.id,
            },
            extra: {
              'todoList': widget.todoList,
              'parentFolder': parentOfCurrentFolder,
            },
          );
        }
      } catch (error) {
        if (mounted) {
          showErrorSnackBar(
            context,
            message: 'Failed to navigate back: $error',
          );
        }
      }
    }
  }
  // --- FINE FUNZIONI DIALOG ---

  @override
  Widget build(BuildContext context) {
    final bool isRootFolder = widget.parentFolder.parentId == null;
    final bool isMobile = ResponsiveLayout.isMobile(context);

    // Leggiamo lo stato dal ViewModel
    final bool isFoldersCollapsed = _viewModel.isFoldersCollapsed;
    final bool isTasksCollapsed = _viewModel.isTasksCollapsed;
    final Stream<List<Folder>> foldersStream = _viewModel.foldersStream;
    final Stream<List<Task>> tasksStream =
        _viewModel.tasksStream(widget.parentFolder.id);

    return Container(
      key: ValueKey(
        'folder_screen_${widget.parentFolder.id}',
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // === 1. HEADER WIDGET ===
          TodoListDetailHeader(
            isMobile: isMobile,
            isRootFolder: isRootFolder,
            title: widget.parentFolder.title,
            onBackTap: _navigateToParent,
            onManageTap: _showManageMembersDialog,
            onInviteTap: _showInviteFormDialog,
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
                        currentUserRole: _viewModel.currentUserRole,
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

                      // === 4. TASK LIST HEADER ===
                      // Aggiunto il filtro
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0)
                              .copyWith(top: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tasks',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: Colors.grey)),
                              Row(
                                children: [
                                  // --- AGGIUNTO TaskFilterDropdown ---
                                  TaskFilterDropdown(
                                    selectedFilter: _selectedTaskFilter,
                                    onFilterChanged: (newFilter) {
                                      // Aggiorna lo stato per applicare il nuovo filtro
                                      setState(() {
                                        _selectedTaskFilter = newFilter;
                                      });
                                    },
                                  ),
                                  // --- FINE ---
                                  IconButton(
                                    icon: Icon(
                                        isTasksCollapsed
                                            ? Icons.expand_more
                                            : Icons.expand_less,
                                        color: Colors.grey),
                                    onPressed: _viewModel.toggleTasksCollapse,
                                    tooltip: isTasksCollapsed
                                        ? 'Expand Tasks'
                                        : 'Collapse Tasks',
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),

                      // === 5. TASK LIST WIDGET ===
                      // Applicato il TaskSorter
                      StreamBuilder<List<Task>>(
                        stream: tasksStream,
                        builder: (context, snapshot) {
                          if (isTasksCollapsed) {
                            return const SliverToBoxAdapter(
                                child: SizedBox.shrink());
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SliverToBoxAdapter(
                                child: Center(
                                    child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator())));
                          }
                          if (snapshot.hasError) {
                            return SliverToBoxAdapter(
                                child: Center(
                                    child: Text(
                                        'Error loading tasks: ${snapshot.error}')));
                          }

                          // --- APPLICA ORDINAMENTO CLIENT-SIDE ---
                          final tasks = snapshot.data ?? [];
                          final sortedTasks =
                              TaskSorter.sortTasks(tasks, _selectedTaskFilter);

                          if (sortedTasks.isEmpty) {
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

                          // Usa la lista ordinata (sortedTasks)
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final task = sortedTasks[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: TaskListTile(
                                    task: task,
                                    currentUserRole: _viewModel.currentUserRole,
                                    onTap: () {
                                      /* TODO: Navigare al dettaglio task */
                                    },
                                    onEdit: () {
                                      _openTaskDialog(taskToEdit: task);
                                    },
                                    onDelete: () {
                                      _showDeleteTaskDialog(task);
                                    },
                                    onStatusChanged: (newStatus) {
                                      _handleTaskStatusChange(task, newStatus);
                                    },
                                  ),
                                );
                              },
                              childCount:
                                  sortedTasks.length, // Usa la lista ordinata
                            ),
                          );
                        },
                      ),
                      // Spaziatore per i FAB
                      const SliverToBoxAdapter(child: SizedBox(height: 160)),
                    ],
                  ),
                ),
                // === 6. ACTION BUTTONS WIDGET ===
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // FAB Chat
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: FloatingActionButton(
                          heroTag: 'chat_fab', // Serve se ci sono più FAB
                          onPressed: () {
                            // Naviga alla chat della todo list corrente
                            context.go('/list/${widget.todoList.id}/chat');
                          },
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.chat),
                          tooltip: 'Open Chat',
                        ),
                      ),
                      // FAB esistenti (DetailActionButtons)
                      DetailActionButtons(
                        onNewFolder: () => _openFolderDialog(),
                        onNewTask: () => _openTaskDialog(),
                        isMobile: isMobile,
                        currentUserRole: _viewModel.currentUserRole,
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
