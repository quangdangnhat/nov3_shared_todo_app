import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Importa GoRouter
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/router/app_router.dart'; // Importa i nomi delle rotte

/// Il Drawer (menu laterale) riutilizzabile per l'applicazione.
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  /// Gestisce il logout dell'utente.
  Future<void> _handleLogout() async {
    try {
      // Chiama il metodo signOut
      await Supabase.instance.client.auth.signOut();
      // GoRouter (tramite il refreshListenable) gestirà automaticamente
      // il reindirizzamento alla schermata di login.
    } catch (error) {
      // Mostra un errore se il logout fallisce
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recupera l'utente corrente per mostrare i dati
    final user = Supabase.instance.client.auth.currentUser;
    final username = (user?.userMetadata?['username'] as String?) ?? 'No Username';
    final email = user?.email ?? 'No Email';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Drawer(
      // --- MODIFICA: Sostituito Column con ListView ---
      // ListView rende il contenuto scrollabile se supera l'altezza
      child: ListView(
        padding: EdgeInsets.zero, // Rimuovi il padding di default del ListView
        children: [
          // Header del Drawer con le info utente
          UserAccountsDrawerHeader(
            accountName: Text(username),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                initial,
                style: const TextStyle(fontSize: 40.0, fontWeight: FontWeight.bold),
              ),
            ),
            margin: EdgeInsets.zero, // Rimuove il margine inferiore
          ),
          
          // Link alla Schermata Inviti
          ListTile(
            leading: const Icon(Icons.mail_outline), // Icona per gli inviti
            title: const Text('My Invitations'), // Testo aggiornato
            onTap: () {
              Navigator.of(context).pop(); 
              context.goNamed(AppRouter.invitations); 
            },
          ),

          // Link alla Pagina Account
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Account'),
            onTap: () {
              Navigator.pop(context);
              context.goNamed(AppRouter.account);
            },
          ),

          // Link al Calendario
           ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Calendar View'),
            onTap: () {
              Navigator.pop(context); // Chiude il drawer
              context.goNamed(AppRouter.calendar); // Naviga al calendario
            },
          ),
          
          const Divider(),

          // Voce: Logout
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[300]),
            title: Text('Log Out', style: TextStyle(color: Colors.red[300])),
            onTap: () {
              Navigator.of(context).pop(); 
              _handleLogout(); // Avvia la procedura di logout
            },
          ),

          // --- MODIFICA: Rimosso Spacer ---
          // const Spacer(), // Non serve più dentro un ListView

          // Calendario (ora scorrerà se necessario)
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
                titleTextStyle: TextStyle(fontSize: 16), 
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: const TextStyle(fontSize: 14),
                weekendTextStyle: TextStyle(fontSize: 14, color: Colors.red[300]),
                outsideTextStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                // weekendStyle: TextStyle(color: Colors.red[300]), 
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; 
                });
                // TODO: Filtra le liste/task in base alla data selezionata?
              },
            ),
          ),
          const SizedBox(height: 20), // Spazio in fondo
        ],
      ),
      // --- FINE MODIFICA ---
    );
  }
}
