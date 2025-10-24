import 'package:flutter/material.dart';
import 'package:shared_todo_app/features/todo_lists/detail.dart/folder_page.dart'; 
import 'package:table_calendar/table_calendar.dart';
import '../../../../data/models/todo_list.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/todo_list_repository.dart';
import '../../../../core/utils/snackbar_utils.dart'; // Import per gli snackbar

class TodoListsScreen extends StatefulWidget {
  const TodoListsScreen({super.key});

  @override
  State<TodoListsScreen> createState() => _TodoListsScreenState();
}

class _TodoListsScreenState extends State<TodoListsScreen> {
  // Istanziamo i repository
  final AuthRepository _authRepo = AuthRepository();
  final TodoListRepository _todoListRepo = TodoListRepository();

  // Variabile di stato per lo stream (per forzare l'aggiornamento)
  late Stream<List<TodoList>> _listsStream;

  // Stato per il calendario
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My To-Do Lists'),
      ),
      drawer: _buildAppDrawer(context),
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

  // --- Widget per il Menu Laterale (Drawer) ---
  Widget _buildAppDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header del Drawer
          const UserAccountsDrawerHeader(
            accountName: Text('Francesco'), // TODO: Sostituire con nome utente
            accountEmail:
                Text('francesco@abc.com'), // TODO: Sostituire con email utente
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                'F', // TODO: Sostituire con iniziali utente
                style: TextStyle(fontSize: 40.0),
              ),
            ),
          ),

          // Voce: Account
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Account'),
            onTap: () {
              // TODO: Navigare alla pagina dell'account
              Navigator.pop(context); // Chiude il drawer
            },
          ),

          // Voce: Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              _authRepo.signOut();
            },
          ),

          // --- Calendario in fondo al Drawer ---
          const Spacer(), // Spinge il calendario in fondo
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; 
                });
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
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

  // --- MODIFICA ESTETICA: Widget per la lista ---
  Widget _buildList(List<TodoList> lists) {
    // Helper per formattare la data (puoi sostituirlo con 'package:intl')
    String formatDate(DateTime date) {
      final localDate = date.toLocal();
      return '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year}';
    }

    // Helper per formattare il ruolo
    String formatRole(String role) {
      if (role == 'admin') return 'Admin';
      if (role == 'collaborator') return 'Collaborator';
      return role; // Gestisce 'Unknown' o altri futuri ruoli
    }

    return ListView.builder(
      // Padding per la lista
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        
        // Colore del "chip" del ruolo
        final roleColor = list.role == 'admin' ? Colors.blue : Colors.grey;

        return Card(
          elevation: 3.0,
          margin: const EdgeInsets.only(bottom: 12.0), // Spazio tra le card
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            leading: const Icon(Icons.list_alt_rounded,
                size: 40, color: Colors.blue),
            title: Text(
              list.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            // --- SOTTOTITOLO MODIFICATO ---
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // Descrizione
                Text(
                  list.desc ?? 'No description', // Mostra la descrizione
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10), // Spaziatore
                
                // --- NUOVA RIGA PER I METADATI ---
                Row(
                  children: [
                    // CHIP PER IL RUOLO
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formatRole(list.role),
                        style: TextStyle(
                          color: roleColor.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // DATA DI CREAZIONE
                    Icon(Icons.calendar_today,
                        size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(list.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Il menu a 3 puntini va qui
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  // TODO: Implementa logica di modifica
                } else if (value == 'delete') {
                  _showDeleteConfirmationDialog(list);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            onTap: () {
              _onSelectedList(list);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
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

