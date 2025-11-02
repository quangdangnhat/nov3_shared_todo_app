import 'package:flutter/material.dart';
import '../../../../../data/models/todo_list.dart';
import '../../../../../data/repositories/folder_repository.dart';
import '../../../../../data/repositories/todo_list_repository.dart';
import '../../controllers/folder/folder_create_controller.dart';
import '../../widgets/create/folder/create_folder_botton.dart';
import '../../widgets/create/folder/folder_name.dart';
import '../../widgets/create/folder/folder_selector.dart';
import '../../widgets/create/folder/todo_list_selector.dart';

class FolderCreatePage extends StatefulWidget {
  const FolderCreatePage({super.key});

  @override
  State<FolderCreatePage> createState() => _FolderCreatePageState();
}

class _FolderCreatePageState extends State<FolderCreatePage> {
  late final FolderCreateController _controller;
  final TextEditingController _folderNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Inizializza il controller
    _controller = FolderCreateController(
      todoListRepo: TodoListRepository(),
      folderRepo: FolderRepository(),
    );
    _controller.initialize();

    // Ascolta i cambiamenti del campo nome per aggiornare il pulsante
    _folderNameController.addListener(() {
      setState(() {
        // Forza il rebuild per aggiornare lo stato del pulsante
      });
    });
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTodoListSelection(TodoList list) async {
    try {
      await _controller.selectTodoList(list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading folders: $e')),
        );
      }
    }
  }

  Future<void> _handleFolderSelection(folder) async {
    try {
      await _controller.selectFolder(folder);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting folder: $e')),
        );
      }
    }
  }

  Future<void> _handleCreateFolder() async {
    try {
      await _controller.createFolder(_folderNameController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder created')),
        );
        _folderNameController.clear();
        _controller.resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titolo
                const Text(
                  'Create a new folder',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a folder in your todo list',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Campo nome cartella
                FolderNameField(controller: _folderNameController),
                const SizedBox(height: 16),

                // Selettori TodoList e Folder
                Row(
                  children: [
                    Expanded(
                      child: TodoListSelector(
                        controller: _controller,
                        searchController: _searchController,
                        onSearchChanged: (query) {
                          _controller.updateSearchQuery(query);
                        },
                        onTodoListSelected: _handleTodoListSelection,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FolderSelector(
                        controller: _controller,
                        onFolderSelected: _handleFolderSelection,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pulsante crea
                CreateFolderButton(
                  isEnabled: _controller.canCreateFolder(
                    _folderNameController.text,
                  ),
                  onPressed: _handleCreateFolder,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
