import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/router/app_router.dart';
import '../../data/repositories/auth_repository.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthRepository _authRepo = AuthRepository();
  final user = Supabase.instance.client.auth.currentUser;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final username = user?.userMetadata?['username'] as String? ?? 'No Username';
    final email = user?.email ?? 'No Email';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Drawer(
      child: SafeArea(
        child: ListView( // 👈 scrollabile: il bottone non si “taglia”
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(username),
              accountEmail: Text(email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(initial, style: const TextStyle(fontSize: 40)),
              ),
            ),

            // Voci menu
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Account'),
              onTap: () {
              Navigator.pop(context);            // chiude il drawer
              context.push(AppRouter.account);   // naviga a /account
            },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () {
                Navigator.pop(context);
                _authRepo.signOut();
              },
            ),

            // Mini calendario + CTA in una Card estetica
            Card(
              elevation: 0,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2015, 1, 1),
                      lastDay: DateTime.utc(2035, 12, 31),
                      focusedDay: _focusedDay,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      availableGestures: AvailableGestures.none,
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      daysOfWeekVisible: true,
                      calendarStyle: const CalendarStyle(
                        markersMaxCount: 0, // nessun marker nel mini
                      ),
                      selectedDayPredicate: (day) =>
                      day.year == _selectedDay?.year &&
                          day.month == _selectedDay?.month &&
                          day.day == _selectedDay?.day,
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // CTA: usa push (NON go) così il back torna alla home
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Apri calendario'),
                        onPressed: () {
                          Navigator.pop(context);           // chiudi sidebar
                          context.push(AppRouter.calendar); // apri calendario full
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
