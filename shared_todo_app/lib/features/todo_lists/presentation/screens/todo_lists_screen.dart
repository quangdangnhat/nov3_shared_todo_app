import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/router/app_router.dart';
import '../../../../data/models/todo_list.dart';
import '../../../../data/repositories/todo_list_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../widgets/todo_list_tile.dart';
import '../../../../data/models/folder.dart'; // Necessario per Folder
import '../../../../data/repositories/folder_repository.dart'; // Necessario per getRootFolder

/// Schermata principale che mostra l'elenco delle TodoList dell'utente.
class TodoListsScreen extends StatefulWidget {
  const TodoListsScreen({super.key});

  @override
  State<TodoListsScreen> createState() => _TodoListsScreenState();
}

class _TodoListsScreenState extends State<TodoListsScreen> {
  // Istanziamo i repository necessari
  final TodoListRepository _todoListRepo = TodoListRepository();
  final FolderRepository _folderRepo = FolderRepository();

  // Mantiene lo stato dello stream per poterlo aggiornare
  late Stream<List<TodoList>> _listsStream;

  @override
  void initState() {
    super.initState();
    // Inizializza lo stream all'avvio dello stato
    _listsStream = _todoListRepo.getTodoListsStream();
  }

  // Mostra un dialog per creare una nuova TodoList.
  void _showCreateListDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New List'),
          // --- CODICE RIPRISTINATO ---
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
                      labelText: 'Description (Optional)'),
                ),
              ],
            ),
          ),
          // --- FINE ---
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
                      showErrorSnackBar(context,
                          message: 'Failed to create list: $error');
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

  /// Mostra un dialog per modificare una TodoList esistente.
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
                        labelText: 'Description (Optional)'),
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
                        showSuccessSnackBar(context,
                            message: 'List updated successfully');
                        setState(() {
                          _listsStream = _todoListRepo.getTodoListsStream();
                        });
                      }
                    } catch (error) {
                      if (mounted) {
                        showErrorSnackBar(context,
                            message: 'Failed to update list: $error');
                      }
                    }
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        });
    // --- FINE ---
  }

  /// Mostra un popup di conferma prima di abbandonare una lista.
  void _showLeaveConfirmationDialog(TodoList list) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave List?'),
          content: Text(
              'Are you sure you want to leave "${list.title}"?\n\nIf you are the last member, the list will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(); // Chiude il dialog
                _handleLeaveList(list.id); // Procede con l'abbandono
              },
              child: const Text('Leave'), // Testo aggiornato
            ),
          ],
        );
      },
    );
  }

  /// Gestisce l'abbandono della lista e aggiorna lo stream.
  Future<void> _handleLeaveList(String listId) async {
    try {
      await _todoListRepo.leaveTodoList(listId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have left the list.'), // Messaggio aggiornato
            backgroundColor: Colors.green,
          ),
        );
        // Forza l'aggiornamento dello stream
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

  /// Naviga alla schermata di dettaglio della lista selezionata.
  Future<void> _onSelectedList(TodoList list) async {
    // Mostra un dialog di caricamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final Folder rootFolder = await _folderRepo.getRootFolder(list.id);
      if (mounted) {
        Navigator.of(context).pop(); // Chiudi dialog caricamento
        context.pushNamed(
          AppRouter.listDetail,
          pathParameters: {'listId': list.id},
          extra: {
            'todoList': list,
            'parentFolder': rootFolder,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showErrorSnackBar(context,
            message:
                'Could not load list details: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My To-Do Lists'),
      ),
      drawer: const AppDrawer(), // Usa il widget Drawer esterno
      body: StreamBuilder<List<TodoList>>(
        stream: _listsStream,
        builder: (context, snapshot) {
          // --- CODICE RIPRISTINATO ---
          // Stato di caricamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Stato di errore
          if (snapshot.hasError) {
            debugPrint('Errore StreamBuilder: ${snapshot.error}');
            debugPrint('Stack trace: ${snapshot.stackTrace}');
            return Center(
                child: Text('Error loading lists: ${snapshot.error}'));
          }

          final lists = snapshot.data;

          // Stato vuoto (nessuna lista)
          if (lists == null || lists.isEmpty) {
            return _buildEmptyState();
          }
          // --- FINE ---

          // Mostra la lista usando il widget Tile esterno
          // Questa chiamata è ora sicura perché 'lists' non è nullo
          return _buildList(lists);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateListDialog,
        tooltip: 'Create List',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Costruisce il widget da mostrare quando non ci sono liste.
  Widget _buildEmptyState() {
    // --- CODICE RIPRISTINATO ---
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          "You don't have any lists yet. Create one!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
    // --- FINE ---
  }

  /// Costruisce la ListView usando il widget TodoListTile.
  Widget _buildList(List<TodoList> lists) {
    // Accetta List<TodoList> (non nullo)
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return TodoListTile(
          list: list,
          onTap: () => _onSelectedList(list),
          onEdit: () => _showEditListDialog(list),
          onDelete: () =>
              _showLeaveConfirmationDialog(list), // Aggiornato per "Leave"
        );
      },
    );
  }
}
