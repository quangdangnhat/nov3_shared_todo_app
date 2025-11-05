import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/responsive.dart';
import '../../../../config/router/app_router.dart';
import '../../../../data/models/todo_list.dart';
import '../../../../data/repositories/todo_list_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../widgets/todo_list_tile.dart';
import '../../../../data/models/folder.dart';
import '../../../../data/repositories/folder_repository.dart';

/// Schermata principale che mostra l'elenco delle TodoList dell'utente.
/// NOTA: La sidebar è gestita da MainLayout tramite ShellRoute
class TodoListsScreen extends StatefulWidget {
  const TodoListsScreen({super.key});

  @override
  State<TodoListsScreen> createState() => _TodoListsScreenState();
}

class _TodoListsScreenState extends State<TodoListsScreen> {
  final TodoListRepository _todoListRepo = TodoListRepository();
  final FolderRepository _folderRepo = FolderRepository();
  late Stream<List<TodoList>> _listsStream;

  @override
  void initState() {
    super.initState();
    _listsStream = _todoListRepo.getTodoListsStream();
  }

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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
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
      },
    );
  }

  void _showDeleteConfirmationDialog(TodoList list) {
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
                Navigator.of(context).pop();
                _handleDeleteList(list.id);
              },
              child: const Text('Leave'), // Testo aggiornato
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteList(String listId) async {
    try {
      await _todoListRepo.leaveTodoList(listId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have left the list.'), // Messaggio aggiornato
            backgroundColor: Colors.green,
          ),
        );
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

  // In: todo_lists_screen.dart

// In: todo_lists_screen.dart

Future<void> _onSelectedList(TodoList list) async {
  // 1. Mostra il dialog di caricamento
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // 2. Esegui la logica asincrona
    final Folder rootFolder = await _folderRepo.getRootFolder(list.id);

    // 3. Controlla se il widget è ancora valido
    if (!mounted) return;

    // --- INIZIO MODIFICA ---

    // 4. Chiudi il dialog.
    //    Usiamo 'rootNavigator: true' per essere sicuri
    //    di chiudere il dialog che vive sul Navigator principale.
    Navigator.of(context, rootNavigator: true).pop();

    // 5. Schedula la navigazione per DOPO che questo frame è stato completato.
    //    Questo dà al Navigator il tempo di finire il 'pop()' e sbloccarsi
    //    prima di ricevere il comando 'goNamed()'.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      
      // 6. Ricontrolla 'mounted' perché questo è un callback asincrono
      if (mounted) {
        context.goNamed(
          AppRouter.listDetail,
          pathParameters: {'listId': list.id},
          extra: {
            'todoList': list,
            'parentFolder': rootFolder,
          },
        );
      }
    });
    // --- FINE MODIFICA ---

  } on Exception catch (e) {
    if (mounted) {
      // Anche qui, usa rootNavigator: true per sicurezza
      Navigator.of(context, rootNavigator: true).pop();
      showErrorSnackBar(context,
          message:
              'Could not load list details: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  } catch (error) {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      showErrorSnackBar(context,
          message: 'An unexpected error occurred: $error');
    }
  }
}

@override
Widget build(BuildContext context) {
  final isMobile = ResponsiveLayout.isMobile(context);

  // --- MODIFICA INIZIA QUI ---
  // Aggiunto Container opaco per prevenire glitch di rendering
  return Container(
    color: Theme.of(context).colorScheme.surface,
    child: Column(
      children: [
        // Header personalizzato che sostituisce l'AppBar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Hamburger menu SOLO su mobile
              if (isMobile) ...[
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menu',
                ),
                const SizedBox(width: 8),
              ],

              // Titolo
              Text(
                'My To-Do Lists',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),

              // Pulsante Create
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: "Create",
                onPressed: () {
                  context.go(AppRouter.create); // Usa go invece di pushNamed
                },
              ),
            ],
          ),
        ),

        // Contenuto principale (StreamBuilder)
        Expanded(
          child: Stack(
            children: [
              StreamBuilder<List<TodoList>>(
                stream: _listsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    debugPrint('Errore StreamBuilder: ${snapshot.error}');
                    debugPrint('Stack trace: ${snapshot.stackTrace}');
                    return Center(
                      child: Text('Error loading lists: ${snapshot.error}'),
                    );
                  }

                  final lists = snapshot.data;

                  if (lists == null || lists.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildList(lists);
                },
              ),

              // FloatingActionButton posizionato manualmente
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: _showCreateListDialog,
                  tooltip: 'Create List',
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  // --- MODIFICA FINISCE QUI ---
}


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
          onDelete: () => _showDeleteConfirmationDialog(list),
        );
      },
    );
  }
}