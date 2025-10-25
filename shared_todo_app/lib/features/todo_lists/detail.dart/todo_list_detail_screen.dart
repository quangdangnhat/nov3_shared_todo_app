import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/router/app_router.dart';
import '../../../data/models/todo_list.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_drawer.dart'; // Import corretto
import '../presentation/widgets/folder_list_tile.dart';
import '../presentation/widgets/folder_dialog.dart';
import '../presentation/widgets/task_dialog.dart';
// import '../presentation/widgets/task_list_tile.dart';


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
     final bool? result = await showDialog<bool>(
       context: context,
       builder: (dialogContext) => FolderDialog(
         todoListId: widget.todoList.id,
         parentId: widget.parentFolder.id,
         folderToEdit: folderToEdit,
       ),
     );
     if (result == true && mounted) {
       _refreshStreams();
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
                     showSuccessSnackBar(context, message: 'Folder deleted successfully');
                     _refreshStreams();
                   }
                 } catch (error) {
                   if (mounted) Navigator.of(dialogContext).pop();
                   if (mounted) {
                     showErrorSnackBar(context, message: 'Failed to delete folder: $error');
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

  // Funzione per mostrare il TaskDialog
  Future<void> _openTaskDialog({Task? taskToEdit}) async {
     if (!mounted) return;
     final bool? result = await showDialog<bool>(
       context: context,
       builder: (dialogContext) => TaskDialog(
         folderId: widget.parentFolder.id,
         // taskToEdit: taskToEdit,
       ),
     );
     if (result == true && mounted) {
       _refreshStreams();
     }
  }


  @override
  Widget build(BuildContext context) {
    final bool isRootFolder = widget.parentFolder.parentId == null;

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
              context.pop();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => _refreshStreams(),
        child: CustomScrollView(
          slivers: [
            // --- Sezione Cartelle con Bottone Collapse ---
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
            // --- MODIFICA COLLAPSE FOLDERS ---
            // StreamBuilder costruisce direttamente il sliver corretto
            StreamBuilder<List<Folder>>(
              stream: _foldersStream,
              builder: (context, snapshot) {
                // Se è collassato, ritorna un sliver vuoto
                if (_isFoldersCollapsed) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                // Gestione Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())));
                }
                // Gestione Error
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(child: Center(child: Text('Error loading folders: ${snapshot.error}')));
                }
                final folders = snapshot.data ?? [];
                // Se non è collassato e vuoto, ritorna uno sliver vuoto
                if (folders.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                // Altrimenti, ritorna la SliverList
                return SliverList(
                  delegate: SliverChildBuilderDelegate( (context, index) {
                      final folder = folders[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: FolderListTile(
                           folder: folder,
                           onTap: () => context.pushNamed(
                            AppRouter.folderDetail,
                            pathParameters: {
                              'listId': widget.todoList.id,
                              'folderId': folder.id,
                            },
                            extra: {
                              'todoList': widget.todoList,
                              'parentFolder': folder,
                            },
                          ),
                          onEdit: () => _openFolderDialog(folderToEdit: folder),
                          onDelete: () => _showDeleteFolderDialog(folder),
                        ),
                      );
                    }, childCount: folders.length, ),
                );
              },
            ),
            // --- FINE MODIFICA ---

            // --- Sezione Task con Bottone Collapse ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
                    .copyWith(top: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text('Tasks', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                     IconButton(
                       icon: Icon(_isTasksCollapsed ? Icons.expand_more : Icons.expand_less, color: Colors.grey),
                       onPressed: () => setState(() => _isTasksCollapsed = !_isTasksCollapsed),
                       tooltip: _isTasksCollapsed ? 'Expand Tasks' : 'Collapse Tasks',
                    ),
                  ],
                ),
              ),
            ),
             // --- MODIFICA COLLAPSE TASKS ---
             // StreamBuilder costruisce direttamente il sliver corretto
            StreamBuilder<List<Task>>(
              stream: _tasksStream,
              builder: (context, snapshot) {
                 // Se è collassato, ritorna un sliver vuoto
                 if (_isTasksCollapsed) {
                   return const SliverToBoxAdapter(child: SizedBox.shrink());
                 }
                 // Gestione Loading
                 if (snapshot.connectionState == ConnectionState.waiting) {
                   return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())));
                 }
                 // Gestione Error
                 if (snapshot.hasError) {
                   return SliverToBoxAdapter(child: Center(child: Text('Error loading tasks: ${snapshot.error}')));
                 }
                 final tasks = snapshot.data ?? [];
                 // Se non è collassato e vuoto, ritorna lo stato vuoto
                 if (tasks.isEmpty) {
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
                 // Altrimenti, ritorna la SliverList dei task
                 return SliverList(
                   delegate: SliverChildBuilderDelegate(
                     (context, index) {
                       final task = tasks[index];
                       // TODO: Crea e usa un widget TaskListTile
                       return Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
                         child: Card(
                           margin: const EdgeInsets.only(bottom: 8),
                           child: ListTile(
                             leading: const Icon(Icons.check_box_outline_blank),
                             title: Text(task.title),
                             subtitle: Text(
                                 'Due: ${DateFormat('dd/MM/yyyy').format(task.dueDate)} - ${task.priority}'),
                             trailing: const Icon(Icons.more_vert),
                             onTap: () { /* TODO: Apri dettaglio task */ },
                           ),
                          ),
                       );
                     },
                     childCount: tasks.length,
                   ),
                 );
               },
             ),
             // --- FINE MODIFICA ---
             const SliverToBoxAdapter(
               child: SizedBox(height: 160), // Spacer per i FAB
             )
          ],
        ),
      ),
      floatingActionButton: Stack( // Stack per i FAB
         children: <Widget>[
           Positioned(
             bottom: 80.0,
             right: 16.0,
             child: FloatingActionButton(
                onPressed: () => _openFolderDialog(),
                tooltip: 'New Folder',
                heroTag: 'fabFolder',
                child: const Icon(Icons.create_new_folder),
             ),
           ),
           Positioned(
             bottom: 16.0,
             right: 16.0,
             child: FloatingActionButton.extended(
                onPressed: () => _openTaskDialog(),
                tooltip: 'New Task',
                heroTag: 'fabTask',
                icon: const Icon(Icons.add_task),
                label: const Text('New Task'),
             ),
           ),
         ],
      ),
    );
  }
}

