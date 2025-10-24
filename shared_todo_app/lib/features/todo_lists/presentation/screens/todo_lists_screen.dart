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
  // Istanziamo i repository
  final TodoListRepository _todoListRepo = TodoListRepository();

  // Variabile di stato per lo stream (per forzare l'aggiornamento)
  late Stream<List<TodoList>> _listsStream;

  // --- STATO DEL CALENDARIO RIMOSSO ---
  // (ora è gestito internamente da AppDrawer)

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

                    // Se tutto va bene, chiudi il dialog
                    // Lo StreamBuilder aggiornerà automaticamente la UI
                    if (mounted) Navigator.of(context).pop();
                  } catch (error) {
                    // Mostra un errore
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
                // Chiudi il dialog e procedi con l'eliminazione
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

      // Eliminazione riuscita
      if (mounted) {
        // Mostra un messaggio di successo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('List deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );

        // --- FORZA L'AGGIORNAMENTO DELLA UI ---
        setState(() {
          _listsStream = _todoListRepo.getTodoListsStream();
        });
      }
    } catch (error) {
      // Errore during l'eliminazione
      if (mounted) {
        showErrorSnackBar(context,
            message: 'Failed to delete list: $error');
      }
    }
  }

  // --- Logica per la modifica (da implementare) ---
  void _handleEditList(TodoList list) {
    // TODO: Implementa la logica di modifica
    // (es. mostra un dialog simile a _showCreateListDialog
    // ma pre-compilato con i dati di 'list')
    debugPrint('Edit list: ${list.title}');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My To-Do Lists'),
      ),
      // --- DRAWER SNELLITO ---
      // Ora usiamo il nostro widget personalizzato
      drawer: const AppDrawer(),
      body: StreamBuilder<List<TodoList>>(
        stream: _listsStream, // Ascolta lo stream
        builder: (context, snapshot) {
          // 1. Stato di caricamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Stato di errore
          if (snapshot.hasError) {
            // Aggiungi uno snapshot dell'errore per il debug
            debugPrint('Errore StreamBuilder: ${snapshot.error}');
            debugPrint('Stack trace: ${snapshot.stackTrace}');
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          // 3. Dati ricevuti
          final lists = snapshot.data;

          // 4. Se non ci sono dati o la lista è vuota
          if (lists == null || lists.isEmpty) {
            return _buildEmptyState();
          }

          // 5. Se ci sono liste, mostrale in una lista
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


  // --- WIDGET PER IL DRAWER RIMOSSO ---
  // (Ora si trova in 'app_drawer.dart')


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

  // --- LISTA SNELLITA ---
  // Ora questo metodo è molto più pulito e usa il nuovo widget
  Widget _buildList(List<TodoList> lists) {
    return ListView.builder(
      // Padding per la lista
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        
        // Ritorna il nostro nuovo widget personalizzato
        return TodoListTile(
          list: list,
          onTap: () => _onSelectedList(list),
          onEdit: () => _handleEditList(list),
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
        // Assicurati che 'FolderPage' sia importato correttamente
        builder: (context) => FolderPage(todoList: list),
      ),
    );
  }
}

