import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/router/app_router.dart';
import '../../../data/models/todo_list.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/invitation_repository.dart';
// --- IMPORT PER PARTECIPANTI ---
import '../../../data/models/participant.dart';
import '../../../data/repositories/participant_repository.dart';
// --- FINE IMPORT ---
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_drawer.dart';
import '../presentation/widgets/folder_list_tile.dart' hide TaskDialog;
import '../presentation/widgets/folder_dialog.dart';
import '../presentation/widgets/task_dialog.dart';
import '../presentation/widgets/task_list_tile.dart';
import '../../../core/enums/task_filter_type.dart';
import '../../../core/utils/task_sorter.dart';
import '../presentation/widgets/task_filter_dropdown.dart';


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
  final InvitationRepository _invitationRepo = InvitationRepository();
  // --- AGGIUNTO REPO PARTECIPANTI ---
  final ParticipantRepository _participantRepo = ParticipantRepository();
  // --- FINE ---

  // Streams
  late Stream<List<Folder>> _foldersStream;
  late Stream<List<Task>> _tasksStream;

  // Stato Collapse
  bool _isFoldersCollapsed = false;
  bool _isTasksCollapsed = false;

  // Stato Filtro
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
        builder: (BuildContext dialogContext) {
          return TaskDialog(
            folderId: widget.parentFolder.id,
            taskToEdit: taskToEdit,
          );
        },
      );
      if (result == true && mounted) {
        showSuccessSnackBar(context,
            message: 'Task ${taskToEdit == null ? 'created' : 'updated'} successfully');
        _refreshStreams();
      }
    } catch (error) {
       if (mounted) {
         showErrorSnackBar(context,
            message: 'Failed to ${taskToEdit == null ? 'create' : 'update'} task: $error');
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
   
  // --- Dialog per INVITARE Membri (ORA CHIAMATO DAL DIALOG PARTECIPANTI) ---
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
                        if (value == null || value.trim().isEmpty || !value.contains('@')) {
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
                          child: Text(value[0].toUpperCase() + value.substring(1)),
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
                  onPressed: isLoading ? null : () => Navigator.of(stfContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
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
                           showSuccessSnackBar(context, message: 'Invitation sent successfully!');
                        }

                      } catch (error) {
                         if (mounted) {
                           showErrorSnackBar(stfContext, message: error.toString().replaceFirst("Exception: ", ""));
                         }
                      } finally {
                         if (mounted) {
                           stfSetState(() => isLoading = false);
                         }
                      }
                    }
                  },
                  child: isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text('Send Invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- NUOVO: Dialog per VEDERE i partecipanti ---
  Future<void> _showParticipantsDialog() async {
    // Mostra un dialog che gestisce il proprio stato di caricamento
    showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<List<Participant>>(
          // Chiama il repository per recuperare i partecipanti
          future: _participantRepo.getParticipants(widget.todoList.id),
          builder: (context, snapshot) {
            // Stato di Caricamento
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            // Stato di Errore
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text(snapshot.error.toString().replaceFirst("Exception: ", "")),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            // Stato di Successo
            final participants = snapshot.data ?? [];

            return AlertDialog(
              title: Text('Participants (${participants.length})'),
              // Usa un ListView.builder se la lista può essere lunga
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final participant = participants[index];
                    final bool isAdmin = participant.role == 'admin';
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(participant.username.isNotEmpty 
                            ? participant.username[0].toUpperCase() 
                            : '?'),
                      ),
                      title: Text(participant.username),
                      subtitle: Text(participant.email),
                      // Mostra un "chip" per il ruolo
                      trailing: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: (isAdmin ? Colors.blue : Colors.grey).withOpacity(0.1),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Text(
                           participant.role,
                           style: TextStyle(
                             color: (isAdmin ? Colors.blue : Colors.grey).shade700,
                             fontWeight: FontWeight.bold,
                             fontSize: 12,
                           ),
                         ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                // Pulsante per invitare NUOVI membri
                TextButton.icon(
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Invite'),
                  onPressed: () {
                    // Chiudi questo dialog e apri quello di invito
                    Navigator.of(dialogContext).pop();
                    _showInviteMemberDialog(); 
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // --- FINE NUOVO DIALOG ---


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
           // --- MODIFICA PULSANTE APPBAR ---
           // Mostra il pulsante "Partecipanti" solo se sei nella cartella root
           if (isRootFolder) 
             IconButton(
               icon: const Icon(Icons.people_outline), // Icona cambiata
               tooltip: 'View Participants', // Tooltip aggiornato
               onPressed: _showParticipantsDialog, // Chiama il nuovo dialog
             ),
           // --- FINE MODIFICA ---
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
            // --- Sezione Cartelle (con collapse) ---
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

            // --- Sezione Task (con collapse e filtro) ---
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
                           onTap: () { /* ... */ },
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

