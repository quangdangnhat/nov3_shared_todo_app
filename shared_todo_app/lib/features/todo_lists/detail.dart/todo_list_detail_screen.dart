import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/router/app_router.dart';
import '../../../data/models/todo_list.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/task_repository.dart';
// Rimossi: InvitationRepository e ParticipantRepository (ora gestiti dai dialog)
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_drawer.dart';
import '../presentation/widgets/folder_list_tile.dart' hide TaskDialog;
import '../presentation/widgets/folder_dialog.dart';
import '../presentation/widgets/task_dialog.dart';
import '../presentation/widgets/task_list_tile.dart';
import '../../../core/enums/task_filter_type.dart';
import '../../../core/utils/task_sorter.dart';
import '../presentation/widgets/task_filter_dropdown.dart';

// --- IMPORT DEI DIALOG ESTRATTI ---
import '../presentation/widgets/participants_dialog.dart';
import '../../../core/widgets/confirmation_dialog.dart';
// Non serve importare InviteMemberDialog qui, perché è chiamato da ParticipantsDialog
// --- FINE IMPORT ---


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
  // Repository (ora solo 2)
  final FolderRepository _folderRepo = FolderRepository();
  final TaskRepository _taskRepo = TaskRepository();

  // Streams
  late Stream<List<Folder>> _foldersStream;
  late Stream<List<Task>> _tasksStream;

  // Stato UI
  bool _isFoldersCollapsed = false;
  bool _isTasksCollapsed = false;
  TaskFilterType _selectedTaskFilter = TaskFilterType.createdAtNewest;

  @override
  void initState() {
    super.initState();
    _refreshStreams(); 
  }

  // Ricarica entrambi gli stream
  void _refreshStreams() {
    if (!mounted) return;
    setState(() {
      _foldersStream = _folderRepo.getFoldersStream(
        widget.todoList.id,
        parentId: widget.parentFolder.id,
      );
      _tasksStream = _taskRepo.getTasksStream(
        widget.parentFolder.id,
      );
    });
  }

  // --- LOGICA DIALOG SNELLITA ---

  // Funzione per mostrare il FolderDialog (già estratto)
  Future<void> _openFolderDialog({Folder? folderToEdit}) async {
     if (!mounted) return;
     try {
       final bool? result = await showDialog<bool>(
         context: context,
         builder: (BuildContext dialogContext) => FolderDialog(
             todoListId: widget.todoList.id,
             parentId: widget.parentFolder.id,
             folderToEdit: folderToEdit,
           ),
       );
       if (result == true && mounted) {
         showSuccessSnackBar(context,
             message: 'Folder ${folderToEdit == null ? 'created' : 'updated'} successfully');
         _refreshStreams(); // Aggiorna stream
       }
     } catch (error) {
        if (mounted) {
          showErrorSnackBar(context,
             message: 'Failed to ${folderToEdit == null ? 'create' : 'update'} folder: $error');
        }
     }
  }

  // Dialog per eliminare Folder (ora usa ConfirmationDialog)
  void _showDeleteFolderDialog(Folder folder) {
     if (!mounted) return;
     showDialog(
       context: context,
       builder: (BuildContext dialogContext) {
        // Usa il widget ConfirmationDialog riutilizzabile
        return ConfirmationDialog(
          title: 'Delete Folder',
          content: 'Are you sure you want to delete "${folder.title}"?',
          confirmText: 'Delete',
          onConfirm: () async {
             try {
               await _folderRepo.deleteFolder(folder.id);
               if (mounted) {
                 showSuccessSnackBar(context,
                     message: 'Folder deleted successfully');
                 _refreshStreams(); // Aggiorna stream
               }
             } catch (error) {
               if (mounted) {
                 showErrorSnackBar(context,
                     message: 'Failed to delete folder: $error');
               }
             }
           },
         );
      },
    );
  }


  // Funzione per mostrare il TaskDialog (già estratto)
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
            message: 'Task ${taskToEdit == null ? 'created' : 'updated'} successfully'); 
        _refreshStreams(); // Aggiorna stream
      }
    } catch (error) {
       if (mounted) {
         showErrorSnackBar(context,
            message: 'Failed to ${taskToEdit == null ? 'create' : 'update'} task: $error');
       }
    }
  }

   // Dialog per eliminare Task (ora usa ConfirmationDialog)
   void _showDeleteTaskDialog(Task task) {
     if (!mounted) return;
     showDialog(
       context: context,
       builder: (BuildContext dialogContext) {
         // Usa il widget ConfirmationDialog riutilizzabile
         return ConfirmationDialog(
           title: 'Delete Task',
           content: 'Are you sure you want to delete "${task.title}"?',
           confirmText: 'Delete',
           onConfirm: () async {
              try {
                await _taskRepo.deleteTask(task.id);
                if (mounted) {
                  showSuccessSnackBar(context, message: 'Task deleted successfully');
                  _refreshStreams(); // Aggiorna stream
                }
              } catch (error) {
                if (mounted) {
                  showErrorSnackBar(context, message: 'Failed to delete task: $error');
                }
              }
           },
         );
       },
     );
   }

   // Gestisce il cambio di stato dai Chip
   Future<void> _handleTaskStatusChange(Task task, String newStatus) async {
      if (task.status == newStatus) return;
      try {
         await _taskRepo.updateTask(taskId: task.id, status: newStatus);
      } catch (error) {
         if (mounted) {
           showErrorSnackBar(context, message: 'Failed to update task status: $error');
         }
      }
   }
   
  // --- RIMOSSO: _showInviteMemberDialog ---
  // (Spostato in ParticipantsDialog)

  // --- ESTRATTO: Dialog per VEDERE i partecipanti ---
  Future<void> _showParticipantsDialog() async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Chiama il widget ParticipantsDialog estratto
        return ParticipantsDialog(
          todoListId: widget.todoList.id,
          todoListTitle: widget.todoList.title,
          // Se l'invito ha successo (callback dal ParticipantsDialog),
          // mostra una SnackBar qui
          onInvitationSent: () {
            if (mounted) {
              showSuccessSnackBar(context, message: 'Invitation sent successfully!');
            }
          },
        );
      },
    );
  }
  // --- FINE ESTRAZIONE ---


  @override
  Widget build(BuildContext context) {
    // Determina se siamo nella cartella root
    final bool isRootFolder = widget.parentFolder.parentId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parentFolder.title),
        automaticallyImplyLeading: false, 
        leading: isRootFolder ? Builder( 
           builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ) : BackButton(onPressed: (){ 
              if(context.canPop()) {
                 context.pop();
              } else {
                 context.goNamed(AppRouter.home);
              }
            }),
        actions: [ 
           if (isRootFolder) 
             IconButton(
               icon: const Icon(Icons.people_outline), // Icona Partecipanti
               tooltip: 'View Participants',
               onPressed: _showParticipantsDialog, // Chiama dialog partecipanti
             ),
           IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              if(context.canPop()) {
                 context.pop();
              } else {
                 context.goNamed(AppRouter.home);
              }
            },
          ),
        ],
       ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => _refreshStreams(),
        child: CustomScrollView(
          slivers: [
            // Sezione Cartelle (con collapse)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
                    .copyWith(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Folders', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                    IconButton(
                      icon: Icon(_isFoldersCollapsed ? Icons.expand_more : Icons.expand_less, color: Colors.grey),
                      onPressed: () => setState(() => _isFoldersCollapsed = !_isFoldersCollapsed),
                      tooltip: _isFoldersCollapsed ? 'Expand Folders' : 'Collapse Folders',
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<Folder>>(
              stream: _foldersStream,
              builder: (context, snapshot) {
                 if (_isFoldersCollapsed) { return const SliverToBoxAdapter(child: SizedBox.shrink());}
                 if (snapshot.connectionState == ConnectionState.waiting) { return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())));}
                 if (snapshot.hasError) { return SliverToBoxAdapter(child: Center(child: Text('Error loading folders: ${snapshot.error}'))); }
                 final folders = snapshot.data ?? [];
                 if (folders.isEmpty) { return const SliverToBoxAdapter(child: SizedBox.shrink()); }
                return SliverList(
                  delegate: SliverChildBuilderDelegate( (context, index) {
                      final folder = folders[index];
                      return Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
                         child: FolderListTile(
                            folder: folder,
                            onTap: () {
                              context.pushNamed(
                                AppRouter.folderDetail,
                                pathParameters: {
                                  'listId': widget.todoList.id,
                                  'folderId': folder.id,
                                },
                                extra: {
                                  'todoList': widget.todoList,
                                  'parentFolder': folder,
                                },
                              );
                            },
                            onEdit: () => _openFolderDialog(folderToEdit: folder),
                            onDelete: () => _showDeleteFolderDialog(folder),
                         ),
                       );
                    }, childCount: folders.length, ),
                );
              },
            ),

            // Sezione Task (con collapse e filtro)
            SliverToBoxAdapter(
              child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(top: 24),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text('Tasks', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                     Row(
                       children: [
                         TaskFilterDropdown(
                           selectedFilter: _selectedTaskFilter,
                           onFilterChanged: (newFilter) {
                             setState(() {
                               _selectedTaskFilter = newFilter;
                             });
                           },
                         ),
                         IconButton(
                           icon: Icon(_isTasksCollapsed ? Icons.expand_more : Icons.expand_less, color: Colors.grey),
                           onPressed: () => setState(() => _isTasksCollapsed = !_isTasksCollapsed),
                           tooltip: _isTasksCollapsed ? 'Expand Tasks' : 'Collapse Tasks',
                         ),
                       ],
                     )
                   ],
                 ),
              ),
            ),
             StreamBuilder<List<Task>>(
              stream: _tasksStream,
              builder: (context, snapshot) {
                 if (_isTasksCollapsed) { return const SliverToBoxAdapter(child: SizedBox.shrink()); }
                 if (snapshot.connectionState == ConnectionState.waiting) { return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))); }
                 if (snapshot.hasError) {
                   debugPrint('Errore StreamBuilder Tasks: ${snapshot.error}');
                   return SliverToBoxAdapter(child: Center(child: Text('Error loading tasks: ${snapshot.error}')));
                 }
                 
                 final tasks = snapshot.data ?? [];
                 final sortedTasks = TaskSorter.sortTasks(tasks, _selectedTaskFilter);

                 if (sortedTasks.isEmpty) { 
                    return SliverToBoxAdapter(
                     child: Padding(
                       padding: const EdgeInsets.symmetric(vertical: 32.0), 
                       child: Center(
                         child: Text(
                           'No tasks in this folder yet.',
                            style: TextStyle(color: Colors.grey[600]),
                         ),
                       ),
                     ),
                   );
                  }

                 // Lista Task
                 return SliverList(
                   delegate: SliverChildBuilderDelegate( 
                     (context, index) {
                       final task = sortedTasks[index];
                       return Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
                         child: TaskListTile(
                           task: task,
                           onTap: () { /* TODO: Navigare al dettaglio task */ },
                           onEdit: () { _openTaskDialog(taskToEdit: task); },
                           onDelete: () { _showDeleteTaskDialog(task); },
                           onStatusChanged: (newStatus) { _handleTaskStatusChange(task, newStatus); },
                         ),
                       );
                     },
                     childCount: sortedTasks.length,
                   ),
                 );
               },
             ),
             const SliverToBoxAdapter( child: SizedBox(height: 160), ) // Spacer
          ],
        ),
      ),
      floatingActionButton: Column(
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
              child: Text('New Folder', textAlign: TextAlign.center),
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
    );
  }
}

