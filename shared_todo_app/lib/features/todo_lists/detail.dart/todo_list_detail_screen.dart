import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/todo_list.dart';
import '../../../data/models/folder.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_drawer_widget.dart'; // Import corretto del Drawer
import '../presentation/widgets/folder_list_tile.dart';
import '../../../app/config/app_router.dart';

class TodoListDetailScreen extends StatefulWidget {
  final TodoList todoList;
  // Ora ci aspettiamo SEMPRE una cartella qui (la root o una sottocartella)
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
  final FolderRepository _folderRepo = FolderRepository();
  late Stream<List<Folder>> _foldersStream;

  @override
  void initState() {
    super.initState();
    _refreshStream(); // Carica direttamente il contenuto della cartella passata
  }

  // Metodo per (ri)caricare lo stream dei figli della cartella corrente
  void _refreshStream() {
    setState(() {
       _foldersStream = _folderRepo.getFoldersStream(
        widget.todoList.id,
        parentId: widget.parentFolder.id,
      );
    });
  }

  // Mostra dialog per creare un folder
  void _showCreateFolderDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Subfolder'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                prefixIcon: Icon(Icons.folder),
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a folder name';
                }
                return null;
              },
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
                    await _folderRepo.createFolder(
                      todoListId: widget.todoList.id,
                      title: titleController.text.trim(),
                      parentId: widget.parentFolder.id, // Crea nella cartella corrente
                    );

                    if (mounted) {
                      Navigator.of(context).pop();
                      showSuccessSnackBar(context,
                          message: 'Folder created successfully');
                    }
                  } catch (error) {
                    if (mounted) {
                      showErrorSnackBar(context,
                          message: 'Failed to create folder: $error');
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

  // Mostra dialog per modificare un folder
  void _showEditFolderDialog(Folder folder) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: folder.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Folder'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                prefixIcon: Icon(Icons.folder),
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a folder name';
                }
                return null;
              },
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
                    await _folderRepo.updateFolder(
                      id: folder.id,
                      title: titleController.text.trim(),
                    );

                    if (mounted) {
                      Navigator.of(context).pop();
                      showSuccessSnackBar(context,
                          message: 'Folder updated successfully');
                    }
                  } catch (error) {
                    if (mounted) {
                      showErrorSnackBar(context,
                          message: 'Failed to update folder: $error');
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

  // Mostra dialog per eliminare un folder
  void _showDeleteFolderDialog(Folder folder) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: Text('Are you sure you want to delete "${folder.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _folderRepo.deleteFolder(folder.id);
                  if (mounted) {
                    Navigator.of(context).pop();
                    showSuccessSnackBar(context,
                        message: 'Folder deleted successfully');
                    // Forza il refresh dello stream dopo l'eliminazione
                    _refreshStream();
                  }
                } catch (error) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    showErrorSnackBar(context,
                        message: 'Failed to delete folder: $error');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determina se siamo nella cartella root controllando se parentId è null
    final bool isRootFolder = widget.parentFolder.parentId == null;

    return Scaffold(
      appBar: AppBar(
        // Mostra il nome della cartella corrente
        title: Text(widget.parentFolder.title),
        automaticallyImplyLeading: false, // Disabilita hamburger/back automatico

        // --- MODIFICA LEADING ---
        // Mostra SEMPRE l'hamburger per il drawer
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ),
        // --- FINE MODIFICA ---

        actions: [
          // --- MODIFICA ACTIONS ---
          // Mostra SEMPRE un pulsante Indietro che usa GoRouter
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              // Usa context.pop() per tornare indietro nello stack di GoRouter
              context.pop(); 
            },
          ),
          // --- FINE MODIFICA ---
        ],
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<Folder>>(
              stream: _foldersStream, // Ascolta i figli della cartella corrente
              builder: (context, snapshot) {
                // Loading dello stream
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshStream,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final folders = snapshot.data;

                // Empty state
                if (folders == null || folders.isEmpty) {
                  // TODO: Qui dovremmo mostrare anche i task della cartella corrente
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'This folder is empty',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a subfolder or add tasks',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Lista folder
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return FolderListTile(
                      folder: folder,
                      onTap: () {
                        // Usa GoRouter per navigare nella sottocartella
                        context.pushNamed(
                          AppRouter.folderDetail, // Usa il nome della rotta per le cartelle
                          pathParameters: { // Passa gli ID necessari per l'URL
                            'listId': widget.todoList.id,
                            'folderId': folder.id,
                          },
                          extra: { // Passa gli oggetti come extra
                            'todoList': widget.todoList,
                            'parentFolder': folder, // La cartella cliccata diventa la nuova parent
                          },
                        );
                      },
                      onEdit: () {
                        _showEditFolderDialog(folder);
                      },
                      onDelete: () {
                        _showDeleteFolderDialog(folder);
                      },
                    );
                  },
                );
              },
            ),
      // FAB ora crea cartelle nella cartella corrente
      floatingActionButton: FloatingActionButton.extended(
              onPressed: _showCreateFolderDialog,
              icon: const Icon(Icons.create_new_folder),
              label: const Text('New Folder'),
            ),
    );
  }
}

