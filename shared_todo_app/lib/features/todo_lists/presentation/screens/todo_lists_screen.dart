import 'package:flutter/material.dart';
import '../../../../data/models/todo_list.dart';
import '../../../../data/repositories/todo_list_repository.dart';
import '../../../../data/repositories/folder_repository.dart'; // Import per FolderRepository
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_drawer_widget.dart';
import '../../../../core/widgets/todo_list_title.dart';
import '../../detail.dart/todo_list_detail_screen.dart';

class TodoListsScreen extends StatefulWidget {
  const TodoListsScreen({super.key});

  @override
  State<TodoListsScreen> createState() => _TodoListsScreenState();
}

class _TodoListsScreenState extends State<TodoListsScreen> {
  final TodoListRepository _todoListRepo = TodoListRepository();
  final FolderRepository _folderRepo = FolderRepository(); // Aggiunto FolderRepository
  late Stream<List<TodoList>> _listsStream;

  @override
  void initState() {
    super.initState();
    _listsStream = _todoListRepo.getTodoListsStream();
  }

  // Mostra il Dialog per creare la lista
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: descController,
                  decoration:
                      const InputDecoration(labelText: 'Description (Optional)'),
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
                    // Non serve refresh, il trigger e lo stream aggiornano
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

  // Mostra il Dialog per modificare la lista
   void _showEditListDialog(TodoList list) {
    final formKey = GlobalKey<FormState>();
    // Pre-compila con i dati esistenti
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
                  decoration:
                      const InputDecoration(labelText: 'Description (Optional)'),
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
                    // --- CORREZIONE: Usa listId invece di id ---
                    await _todoListRepo.updateTodoList(
                      listId: list.id, // Passa l'ID della lista da aggiornare
                      title: titleController.text.trim(),
                      desc: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : null,
                    );
                    // --- FINE CORREZIONE ---

                    if (mounted) {
                       Navigator.of(context).pop();
                       showSuccessSnackBar(context, message: 'List updated successfully.');
                       // --- FORZA L'AGGIORNAMENTO DELLO STREAM ---
                       setState(() {
                         _listsStream = _todoListRepo.getTodoListsStream();
                       });
                       // --- FINE AGGIORNAMENTO ---
                    }
                  } catch (error) {
                    if (mounted) {
                      showErrorSnackBar(context,
                          message: 'Failed to update list: $error');
                    }
                  }
                }
              },
              child: const Text('Save Changes'), // Testo bottone modificato
            ),
          ],
        );
      },
    );
  }

  // Mostra il popup di conferma eliminazione
  void _showDeleteConfirmationDialog(TodoList list) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete List'),
          content: Text(
              'Are you sure you want to delete "${list.title}"? This action cannot be undone.'),
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Logica per chiamare il repository e aggiornare la UI
  Future<void> _handleDeleteList(String listId) async {
    try {
      await _todoListRepo.deleteTodoList(listId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('List deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _listsStream = _todoListRepo.getTodoListsStream();
        });
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context,
            message: 'Failed to delete list: $error');
      }
    }
  }

   // --- NUOVA LOGICA: Carica Root e Naviga ---
  Future<void> _onSelectedList(TodoList list) async {
    // 1. Mostra un dialog di caricamento
    showDialog(
      context: context,
      barrierDismissible: false, // Impedisce all'utente di chiuderlo
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Trova la cartella Root associata alla lista
      final rootFolder = await _folderRepo.getRootFolder(list.id);
      
      // 3. Chiudi il dialog di caricamento
      if (mounted) Navigator.of(context).pop(); 

      // 4. Naviga alla pagina di dettaglio, passando la root trovata
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TodoListDetailScreen(
              todoList: list,
              parentFolder: rootFolder, // Passa la root direttamente
            ),
          ),
        );
      }
    } catch (e) {
      // 5. In caso di errore, chiudi il loading e mostra un errore
      if (mounted) {
        Navigator.of(context).pop(); // Chiudi il loading
        showErrorSnackBar(context, message: 'Could not load list content: $e');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My To-Do Lists'),
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<TodoList>>(
        stream: _listsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Errore StreamBuilder: ${snapshot.error}');
            debugPrint('Stack trace: ${snapshot.stackTrace}');
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          final lists = snapshot.data;
          if (lists == null || lists.isEmpty) {
            return _buildEmptyState();
          }
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

  Widget _buildEmptyState() {
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
  }

  // Widget per la lista (ora usa TodoListTile)
  Widget _buildList(List<TodoList> lists) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return TodoListTile(
          list: list,
          onTap: () => _onSelectedList(list), // Chiama la nuova logica async
          onEdit: () => _showEditListDialog(list),
          onDelete: () => _showDeleteConfirmationDialog(list),
        );
      },
    );
  }
}