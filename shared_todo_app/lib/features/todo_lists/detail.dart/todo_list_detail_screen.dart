import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/router/app_router.dart';
import '../../../data/models/todo_list.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_drawer.dart'; // Corretto import Drawer
import '../../../core/utils/task_sorter.dart'; //ADD: import TaskSorter
import '../../../core/enums/task_filter_type.dart'; //ADD: import TaskFilterType
import '../presentation/widgets/folder_list_tile.dart' hide TaskDialog;
import '../presentation/widgets/folder_dialog.dart';
import '../presentation/widgets/task_dialog.dart';
import '../presentation/widgets/task_list_tile.dart';
import '../presentation/widgets/task_filter_dropdown.dart'; //ADD: import TaskFilterDropdown


class TodoListDetailScreen extends StatefulWidget {
  final TodoList todoList;
  final Folder parentFolder; // Riceve sempre la cartella corrente (root o sub)

  const TodoListDetailScreen({
    super.key,
    required this.todoList,
    required this.parentFolder,
  });

  @override
  State<TodoListDetailScreen> createState() => _TodoListDetailScreenState();
}

class _TodoListDetailScreenState extends State<TodoListDetailScreen> {
  // Repository
  final FolderRepository _folderRepo = FolderRepository();
  final TaskRepository _taskRepo = TaskRepository();

  // Streams per cartelle e task
  late Stream<List<Folder>> _foldersStream;
  late Stream<List<Task>> _tasksStream;

  // Stato per il collapse
  bool _isFoldersCollapsed = false;
  bool _isTasksCollapsed = false;

  // ADD: Filter state
  TaskFilterType _currentFilter = TaskFilterType.createdAtNewest;

  @override
  void initState() {
    super.initState();
    _refreshStreams(); // Carica entrambi gli stream
  }

  // Ricarica entrambi gli stream (figli della cartella corrente)
  void _refreshStreams() {
    if (!mounted) return;
    setState(() {
      _foldersStream = _folderRepo.getFoldersStream(
        widget.todoList.id,
        parentId: widget.parentFolder.id,
      );
      _tasksStream = _taskRepo.getTasksStream(
        widget.parentFolder.id, // Carica i task della cartella corrente
      );
    });
  }

  // Funzione per mostrare il FolderDialog
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
             message: 'Folder ${folderToEdit == null ? 'created' : 'updated'} successfully');
         _refreshStreams();
       }
     } catch (error) {
        if (mounted) {
          showErrorSnackBar(context,
             message: 'Failed to ${folderToEdit == null ? 'create' : 'update'} folder: $error');
        }
     }
  }

  // Dialog per eliminare Folder
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


  // Funzione per mostrare il TaskDialog (per Creare o Modificare)
  Future<void> _openTaskDialog({Task? taskToEdit}) async {
    if (!mounted) return;
    try {
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return TaskDialog(
            folderId: widget.parentFolder.id,
            taskToEdit: taskToEdit, // Passa il task se stiamo modificando
          );
        },
      );
      // Se il dialog ha avuto successo, mostra SnackBar e aggiorna
      if (result == true && mounted) {
        showSuccessSnackBar(context,
            message: 'Task ${taskToEdit == null ? 'created' : 'updated'} successfully'); 
        _refreshStreams();
      }
    } catch (error) {
       // Se showDialog propaga un errore, mostralo qui
       if (mounted) {
         showErrorSnackBar(context,
            message: 'Failed to ${taskToEdit == null ? 'create' : 'update'} task: $error');
       }
    }
  }

   // Dialog per eliminare Task
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
                  if(deleting) return;
                  deleting = true;
                  try {
                    await _taskRepo.deleteTask(task.id);
                    if (mounted) Navigator.of(dialogContext).pop();
                    if (mounted) {
                      showSuccessSnackBar(context, message: 'Task deleted successfully');
                      _refreshStreams(); 
                    }
                  } catch (error) {
                    if (mounted) Navigator.of(dialogContext).pop();
                    if (mounted) {
                      showErrorSnackBar(context, message: 'Failed to delete task: $error');
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parentFolder.title),
        automaticallyImplyLeading: false, 
        leading: Builder(
           builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ),
        actions: [ 
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
              // Il builder è obbligatorio
              builder: (context, snapshot) { 
                 if (_isFoldersCollapsed) { return const SliverToBoxAdapter(child: SizedBox.shrink());}
                 if (snapshot.connectionState == ConnectionState.waiting) { return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())));}
                 if (snapshot.hasError) { return SliverToBoxAdapter(child: Center(child: Text('Error loading folders: ${snapshot.error}'))); }
                 final folders = snapshot.data ?? [];
                 if (folders.isEmpty) { return const SliverToBoxAdapter(child: SizedBox.shrink()); }
                return SliverList(
                  // Il delegate è obbligatorio
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

            // Sezione Task (con collapse)
            SliverToBoxAdapter(
              child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(top: 24),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text('Tasks', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                     Row( // ADD: Row per Dropdown e Icona Collapse
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         // ADD: Filter Dropdown
                         TaskFilterDropdown(
                           selectedFilter: _currentFilter,
                           onFilterChanged: (TaskFilterType newFilter) {
                             setState(() {
                               _currentFilter = newFilter;
                             });
                           },
                         ),
                     IconButton(
                       icon: Icon(_isTasksCollapsed ? Icons.expand_more : Icons.expand_less, color: Colors.grey),
                       onPressed: () => setState(() => _isTasksCollapsed = !_isTasksCollapsed),
                       tooltip: _isTasksCollapsed ? 'Expand Tasks' : 'Collapse Tasks',
                    ),
                   ],
                 ),
                ]              
              ),
            ),
          ),
             StreamBuilder<List<Task>>(
              stream: _tasksStream,
               // Il builder è obbligatorio
              builder: (context, snapshot) {
                 if (_isTasksCollapsed) { return const SliverToBoxAdapter(child: SizedBox.shrink()); }
                 if (snapshot.connectionState == ConnectionState.waiting) { return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))); }
                 if (snapshot.hasError) {
                   debugPrint('Errore StreamBuilder Tasks: ${snapshot.error}');
                   return SliverToBoxAdapter(child: Center(child: Text('Error loading tasks: ${snapshot.error}')));
                 }

                //ADD: Apply the filter
                 final rawTasks = snapshot.data ?? [];
                 final filteredTasks = TaskSorter.sortTasks(rawTasks, _currentFilter); 

                 if (filteredTasks.isEmpty) { 
                    return SliverToBoxAdapter(
                     child: Padding(
                       // Il padding è obbligatorio
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
                   // Il delegate è obbligatorio
                   delegate: SliverChildBuilderDelegate( 
                     (context, index) {
                       final task = filteredTasks[index]; // Usa filteredTasks qui
                       return Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
                         child: TaskListTile(
                           task: task,
                           onTap: () { /* ... */ },
                           onEdit: () { _openTaskDialog(taskToEdit: task); },
                           onDelete: () { _showDeleteTaskDialog(task); },
                           onStatusChanged: (newStatus) { _handleTaskStatusChange(task, newStatus); },
                         ),
                       );
                     },
                     childCount: filteredTasks.length, // Usa filteredTasks.length qui
                   ),
                 );
               },
             ),
             const SliverToBoxAdapter( child: SizedBox(height: 160), ) // Spacer
          ],
        ),
      ),
      // Sostituito Stack con Column per i FAB
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _openFolderDialog(),
            tooltip: 'New Folder',
            heroTag: 'fabFolder',
            mini: true, 
            child: const Icon(Icons.create_new_folder),
          ),
          const SizedBox(height: 16), 
          FloatingActionButton.extended(
            onPressed: () => _openTaskDialog(),
            tooltip: 'New Task',
            heroTag: 'fabTask',
            icon: const Icon(Icons.add_task),
            label: const Text('New Task'),
          ),
        ],
      ),
    );
  }
}

