import 'package:flutter/material.dart';
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

  // Stato per il calendario
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- AppBar con il pulsante hamburger ---
      appBar: AppBar(
        title: const Text('My To-Do Lists'),
        // Il pulsante hamburger (leading) viene aggiunto automaticamente
        // quando forniamo una 'drawer' allo Scaffold.
      ),

      // --- Menu Laterale (Drawer) ---
      drawer: _buildAppDrawer(context),

      // --- Corpo della pagina ---
      body: StreamBuilder<List<TodoList>>(
        stream: _todoListRepo.getTodoListsStream(), // Ascolta lo stream
        builder: (context, snapshot) {
          // 1. Stato di caricamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Stato di errore
          if (snapshot.hasError) {
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

          // 5. Se ci sono liste, mostrale in una griglia
          return _buildListGrid(lists);
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateListDialog, // --- MODIFICA APPLICATA ---
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
              // Non serve altro, lo StreamBuilder in main.dart
              // gestirà il reindirizzamento alla pagina di login.
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
                formatButtonVisible: false, // Nasconde il selettore "2 weeks"
                titleCentered: true,
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; // Aggiorna il giorno "focalizzato"
                });
              },
            ),
          ),
          const SizedBox(height: 20), // Un po' di spazio in basso
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

  // --- Widget per la griglia delle liste ---
  Widget _buildListGrid(List<TodoList> lists) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 colonne
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1, // Quadrato
      ),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: InkWell(
            onTap: () {
              // TODO: Navigare alla pagina di dettaglio della lista
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.list_alt_rounded,
                    size: 50, color: Colors.blue),
                const SizedBox(height: 12),
                Text(
                  list.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}