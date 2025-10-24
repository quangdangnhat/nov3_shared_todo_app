import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/repositories/auth_repository.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthRepository _authRepo = AuthRepository();
  
  // --- 2. RECUPERA L'UTENTE CORRENTE ---
  final user = Supabase.instance.client.auth.currentUser;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    // --- 3. PREPARA I DATI PER LA UI ---
    // Estrai l'username dai metadata
    final username = user?.userMetadata?['username'] as String? ?? 'No Username';
    // Estrai l'email
    final email = user?.email ?? 'No Email';
    // Estrai l'iniziale per l'avatar
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Drawer(
      child: Column(
        children: [
          // Header del Drawer (ora dinamico)
          UserAccountsDrawerHeader(
            accountName: Text(username), // <-- VALORE DINAMICO
            accountEmail: Text(email),   // <-- VALORE DINAMICO
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                initial, // <-- VALORE DINAMICO
                style: const TextStyle(fontSize: 40.0),
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
}

