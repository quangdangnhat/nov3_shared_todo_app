import 'package:flutter/material.dart';
import '../../../data/models/todo_list.dart';
import '../../../data/models/folder.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_drawer_widget.dart';
import '../presentation/widgets/folder_list_tile.dart';

class TodoListDetailScreen extends StatefulWidget {
  final TodoList todoList;
  final Folder? parentFolder; // Se null, stiamo visualizzando la "root"

  const TodoListDetailScreen({
    super.key,
    required this.todoList,
    this.parentFolder,
  });

  @override
  State<TodoListDetailScreen> createState() => _TodoListDetailScreenState();
}

class _TodoListDetailScreenState extends State<TodoListDetailScreen> {
  final FolderRepository _folderRepo = FolderRepository();
  
  // --- LOGICA PER GESTIRE LA CARTELLA CORRENTE ---
  Folder? _currentParentFolder; // La cartella di cui mostriamo il contenuto
  Stream<List<Folder>> _foldersStream = Stream.empty();
  bool _isLoadingInitialFolder = false; // Stato per caricamento iniziale

  @override
  void initState() {
    super.initState();
    _loadInitialFolderAndStream(); // Carica la cartella iniziale e imposta lo stream
  }

  // Carica la cartella iniziale (root o passata) e poi il suo contenuto
  Future<void> _loadInitialFolderAndStream() async {
    setState(() {
      _isLoadingInitialFolder = true; 
    });
    
    try {
      if (widget.parentFolder == null) {
        // Siamo al livello principale: dobbiamo trovare la cartella Root
        _currentParentFolder = await _folderRepo.getRootFolder(widget.todoList.id);
      } else {
        // Stiamo navigando in una sottocartella
        _currentParentFolder = widget.parentFolder;
      }
      // Una volta trovata la cartella corrente, carichiamo il suo stream
      _refreshStream(); // Questo chiamerà setState internamente
    } catch (e) {
       if (mounted) {
         showErrorSnackBar(context, message: 'Error loading folder: $e');
         // Eventualmente, potremmo tornare indietro nella schermata precedente qualora non venisse trovata la cartella
         // Navigator.of(context).pop();
       }
    } finally {
       if (mounted) {
         setState(() {
           _isLoadingInitialFolder = false;
         });
       }
    }
  }


  // Metodo per (ri)caricare lo stream dei figli della cartella corrente
  void _refreshStream() {
    // Si assicura di avere una cartella corrente prima di caricare
    if (_currentParentFolder != null) {
      setState(() {
        _foldersStream = _folderRepo.getFoldersStream(
          widget.todoList.id,
          parentId: _currentParentFolder!.id, // Carica i figli della cartella corrente
        );
      });
    } else {
       // Se _currentParentFolder è null (es. errore in caricamento root), mostra stream vuoto
       setState(() {
         _foldersStream = Stream.value([]);
       });
    }
  }

  // Mostra dialog per creare un folder
  void _showCreateFolderDialog() {
    // Non crea se non abbiamo ancora caricato la cartella corrente
    if (_currentParentFolder == null) return; 

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Il titolo è sempre 'Create Subfolder' perché siamo dentro la root o una subfolder
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
                      parentId: _currentParentFolder!.id, // Crea nella cartella corrente
                    );

                    if (mounted) {
                      Navigator.of(context).pop();
                      // Lo stream si aggiornerà automaticamente grazie a Supabase Realtime
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
                      // Lo stream si aggiornerà automaticamente
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
                    
                    // --- AGGIORNAMENTO ISTANTANEO ---
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
    return Scaffold(
      appBar: AppBar(
        // Mostra il nome della cartella corrente o della lista se siamo nella root
        title: Text(_currentParentFolder?.title ?? widget.todoList.title), 
        actions: [
          const BackButton(),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoadingInitialFolder // Mostra caricamento iniziale se necessario
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading folder content...'),
                ],
              ),
            )
          : StreamBuilder<List<Folder>>( // Altrimenti mostra lo stream
              stream: _foldersStream, // Ascolta i figli della cartella corrente
              builder: (context, snapshot) {
                // Loading dello stream (diverso da quello iniziale)
                if (snapshot.connectionState == ConnectionState.waiting && !_isLoadingInitialFolder) {
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
                          onPressed: _refreshStream, // Ricarica lo stream
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
                        // Naviga nella sottocartella cliccata
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TodoListDetailScreen(
                              todoList: widget.todoList,
                              parentFolder: folder, // Passa la cartella cliccata come nuova parente
                            ),
                          ),
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
      // Mostra il FAB solo se la cartella corrente è stata caricata
      floatingActionButton: _isLoadingInitialFolder || _currentParentFolder == null
          ? null 
          : FloatingActionButton.extended(
              onPressed: _showCreateFolderDialog, 
              icon: const Icon(Icons.create_new_folder),
              label: const Text('New Folder'),
            ),
    );
  }
}