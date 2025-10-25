import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/router/app_router.dart';
import '../../../../data/models/todo_list.dart';
import '../../../../data/repositories/todo_list_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../widgets/todo_list_title.dart';
import '../../../../data/models/folder.dart'; // Necessario per Folder
import '../../../../data/repositories/folder_repository.dart'; // Necessario per getRootFolder


// Schermata principale che mostra l'elenco delle TodoList dell'utente.
class TodoListsScreen extends StatefulWidget {
  const TodoListsScreen({super.key});

  @override
  State<TodoListsScreen> createState() => _TodoListsScreenState();
}

class _TodoListsScreenState extends State<TodoListsScreen> {
  // Istanziamo i repository necessari
  final TodoListRepository _todoListRepo = TodoListRepository();
  final FolderRepository _folderRepo = FolderRepository(); // Aggiunto per trovare la root

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
                    // Lo StreamBuilder aggiornerà automaticamente la UI
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
    // Pre-compila i campi con i valori esistenti
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
                      listId: list.id, // Passa l'ID corretto
                      title: titleController.text.trim(),
                      desc: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : null,
                    );
                    if (mounted) {
                      Navigator.of(context).pop();
                       showSuccessSnackBar(context,
                          message: 'List updated successfully');
                       // Forza l'aggiornamento dello stream per vedere le modifiche
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
      },
    );
  }

  /// Mostra un popup di conferma prima di eliminare una lista.
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
                Navigator.of(context).pop(); // Chiude il dialog
                _handleDeleteList(list.id); // Procede con l'eliminazione
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  /// Gestisce l'effettiva eliminazione della lista e aggiorna lo stream.
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
        // Forza l'aggiornamento dello stream per riflettere l'eliminazione
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

  /// Naviga alla schermata di dettaglio della lista selezionata.
  /// Ora usa GoRouter e carica la cartella root prima di navigare.
  Future<void> _onSelectedList(TodoList list) async {
     // Mostra un dialog di caricamento mentre troviamo la root folder
    showDialog(
      context: context,
      barrierDismissible: false, // Impedisce la chiusura accidentale
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Trova la cartella root associata alla lista
      final Folder rootFolder = await _folderRepo.getRootFolder(list.id);

      if (mounted) {
        Navigator.of(context).pop(); // Chiudi il dialog di caricamento

        // --- NAVIGAZIONE CON GOROUTER ---
        context.pushNamed(
          AppRouter.listDetail, // Usa il nome della rotta
          pathParameters: {'listId': list.id}, // Passa l'ID nei parametri URL
          extra: { // Passa gli oggetti necessari come 'extra' in una Map
            'todoList': list,
            'parentFolder': rootFolder,
          },
        );
        // --- FINE NAVIGAZIONE ---
      }
    } on Exception catch (e) { // Gestisce specificamente l'eccezione da getRootFolder
       if (mounted) {
         Navigator.of(context).pop(); // Chiudi il dialog di caricamento
         showErrorSnackBar(context, message: 'Could not load list details: ${e.toString().replaceFirst("Exception: ","")}');
       }
    } 
    catch (error) { // Gestione generica per altri errori
      if (mounted) {
        Navigator.of(context).pop(); // Chiudi il dialog di caricamento
        showErrorSnackBar(context, message: 'An unexpected error occurred: $error');
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
          // Stato di caricamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Stato di errore
          if (snapshot.hasError) {
            debugPrint('Errore StreamBuilder: ${snapshot.error}');
            debugPrint('Stack trace: ${snapshot.stackTrace}');
            return Center(child: Text('Error loading lists: ${snapshot.error}'));
          }

          final lists = snapshot.data;

          // Stato vuoto (nessuna lista)
          if (lists == null || lists.isEmpty) {
            return _buildEmptyState();
          }

          // Mostra la lista usando il widget Tile esterno
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

  /// Costruisce la ListView usando il widget TodoListTile.
  Widget _buildList(List<TodoList> lists) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return TodoListTile(
          list: list,
          onTap: () => _onSelectedList(list), // Chiama la navigazione
          onEdit: () => _showEditListDialog(list), // Apre il dialog di modifica
          onDelete: () => _showDeleteConfirmationDialog(list), // Apre il dialog di conferma
        );
      },
    );
  }
}

