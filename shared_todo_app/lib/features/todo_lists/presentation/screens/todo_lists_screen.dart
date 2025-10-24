import 'package:flutter/material.dart';
import 'package:shared_todo_app/features/todo_lists/detail.dart/folder_page.dart';
import '../../../../core/widget/app_drawer_widget.dart';
import '../../../../core/widget/todo_list_title.dart';
import '../../../../data/models/todo_list.dart';
import '../../../../data/repositories/todo_list_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';

class TodoListsScreen extends StatefulWidget {
  const TodoListsScreen({super.key});

  @override
  State<TodoListsScreen> createState() => _TodoListsScreenState();
}

class _TodoListsScreenState extends State<TodoListsScreen> {
  // Istanziamo il repository (solo quello delle liste)
  final TodoListRepository _todoListRepo = TodoListRepository();

  // Variabile di stato per lo stream (per forzare l'aggiornamento)
  late Stream<List<TodoList>> _listsStream;

  @override
  void initState() {
    super.initState();
    // Inizializziamo lo stream una sola volta qui
    _listsStream = _todoListRepo.getTodoListsStream();
  }

  // Mostra il Dialog per creare la lista ---
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
              mainAxisSize: MainAxisSize.min, // Per non occupare tutto lo schermo
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

  // --- NUOVO DIALOG PER LA MODIFICA ---
  void _showEditListDialog(TodoList list) {
    final formKey = GlobalKey<FormState>();
    // Pre-compila i controller con i dati esistenti
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
                    await _todoListRepo.updateTodoList(
                      listId: list.id, // Passa l'ID della lista
                      title: titleController.text.trim(),
                      desc: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : null,
                    );
                    
                    if (mounted) {
                      Navigator.of(context).pop(); // Chiudi il dialog
                      // Mostra successo
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('List updated successfully.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // --- CORREZIONE APPLICATA ---
                      // Forza l'aggiornamento dello stream,
                      // proprio come facciamo per l'eliminazione.
                      setState(() {
                        _listsStream = _todoListRepo.getTodoListsStream();
                      });
                      // --- FINE CORREZIONE ---
                    }
                  } catch (error) {
                    if (mounted) {
                      showErrorSnackBar(context,
                          message: 'Failed to update list: $error');
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // --- Mostra il popup di conferma eliminazione ---
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

  // --- Logica per chiamare il repository e aggiornare la UI ---
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

  // --- NUOVA LOGICA DI MODIFICA ---
  void _handleEditList(TodoList list) {
    _showEditListDialog(list);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My To-Do Lists'),
      ),
      drawer: const AppDrawer(), // Usa il widget snellito
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

  // --- Widget per lo stato vuoto ---
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

  // --- LISTA SNELLITA (USA IL TILE) ---
  Widget _buildList(List<TodoList> lists) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        
        return TodoListTile(
          list: list,
          onTap: () => _onSelectedList(list),
          onEdit: () => _handleEditList(list), // <-- MODIFICA APPLICATA
          onDelete: () => _showDeleteConfirmationDialog(list),
        );
      },
    );
  }

  // Navigare nella pagina della lista scelta
  void _onSelectedList(TodoList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderPage(todoList: list),
      ),
    );
  }
}

