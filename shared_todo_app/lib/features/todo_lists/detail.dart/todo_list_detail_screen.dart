import 'package:flutter/material.dart';
import '../../../data/models/todo_list.dart';
import '../../../data/models/folder.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widget/app_drawer_widget.dart';
import '../presentation/widgets/folder_list_tile.dart';

class TodoListDetailScreen extends StatefulWidget {
  final TodoList todoList;

  const TodoListDetailScreen({
    super.key,
    required this.todoList,
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
    _refreshStream();
  }

  // Metodo per ricaricare lo stream
  void _refreshStream() {
    // TODO: Qui dovremmo filtrare per parent_id == null per mostrare solo la root
    _foldersStream = _folderRepo.getFoldersStream(widget.todoList.id);
  }

  // Mostra dialog per creare un folder
  void _showCreateFolderDialog({String? parentId}) { // Aggiunto parentId
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(parentId == null ? 'Create New Folder' : 'Create Subfolder'),
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
                      parentId: parentId, // Passa il parentId
                    );

                    if (mounted) {
                      Navigator.of(context).pop();
                      setState(() {
                        _refreshStream();
                      });
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
                      // parentId: 
                      // parentId per inserire la cartella padre se esiste
                    );

                    if (mounted) {
                      Navigator.of(context).pop();
                      setState(() {
                        _refreshStream();
                      });
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
                    // Forza il refresh dello stream
                    setState(() {
                      _refreshStream();
                    });
                    showSuccessSnackBar(context,
                        message: 'Folder deleted successfully');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todoList.title),
        actions: [
          const BackButton(),
        ],
      ),
      drawer: const AppDrawer(), // <-- USA IL WIDGET SNELLITO
      body: StreamBuilder<List<Folder>>(
        stream: _foldersStream,
        builder: (context, snapshot) {
          // Loading
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
                    onPressed: () {
                      setState(() {
                        _refreshStream();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final folders = snapshot.data;

          // Empty state
          if (folders == null || folders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No folders yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first folder to organize your tasks',
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

          // --- LISTA SNELLITA ---
          // Ora usa il ListView.builder per chiamare il nostro nuovo widget
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return FolderListTile(
                folder: folder,
                onTap: () {
                  // TODO: Naviga alla pagina dei task del folder
                  debugPrint('Apri folder: ${folder.title}');
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFolderDialog(), // Crea una folder root
        icon: const Icon(Icons.create_new_folder),
        label: const Text('New Folder'),
      ),
    );
  }

  // --- _buildFolderCard() RIMOSSO ---
  // --- _formatDate() RIMOSSO ---
}
