import 'package:flutter/material.dart';
import '../../../data/models/todo_list.dart';
import '../../../data/models/folder.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../core/utils/snackbar_utils.dart';

class FolderPage extends StatefulWidget {
  final TodoList todoList;

  const FolderPage({
    super.key,
    required this.todoList,
  });

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  final FolderRepository _folderRepo = FolderRepository();
  late Stream<List<Folder>> _foldersStream;

  @override
  void initState() {
    super.initState();
    _refreshStream();
  }

  // Metodo per ricaricare lo stream
  void _refreshStream() {
    _foldersStream = _folderRepo.getFoldersStream(widget.todoList.id);
  }

  // Mostra dialog per creare un folder
  void _showCreateFolderDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Folder'),
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
      ),
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

          // Lista folder
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return _buildFolderCard(folder);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateFolderDialog,
        icon: const Icon(Icons.create_new_folder),
        label: const Text('New Folder'),
      ),
    );
  }

  Widget _buildFolderCard(Folder folder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: const Icon(Icons.folder, color: Colors.blue),
        ),
        title: Text(
          folder.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Created: ${_formatDate(folder.createdAt)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteFolderDialog(folder);
            } else if (value == 'edit') {
              _showEditFolderDialog(folder);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Naviga alla pagina dei task del folder
          debugPrint('Apri folder: ${folder.title}');
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}