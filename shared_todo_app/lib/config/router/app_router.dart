import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/screens/createPage/create_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/folder.dart';
import '../../data/models/todo_list.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/todo_lists/presentation/calendar/calendar_screen.dart';

// --- MODIFICA IMPORT CON PREFISSI ---
// Importa la schermata di dettaglio con un prefisso
import '../../features/todo_lists/detail.dart/todo_list_detail_screen.dart'
    as detail_screen;
// Importa la schermata delle liste con un altro prefisso
import '../../features/todo_lists/presentation/screens/todo_lists_screen.dart'
    as lists_screen;
// --- FINE MODIFICA IMPORT ---

import '../../main.dart'; // Importa 'supabase' helper

/// Notifier che ascolta i cambiamenti dello stato di autenticazione
/// e notifica GoRouter quando deve aggiornarsi.
class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _isLoggedIn = supabase.auth.currentUser != null;

  _AuthNotifier() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final bool newLoginState = data.session != null;
      if (newLoginState != _isLoggedIn) {
        _isLoggedIn = newLoginState;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}

/// Contiene la configurazione delle rotte (pagine) dell'applicazione
/// utilizzando il pacchetto GoRouter.
class AppRouter {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/';
  static const String calendar = '/calendar';
  static const String listDetail = '/list/:listId';
  static const String folderDetail = '/list/:listId/folder/:folderId';
  static const String account = '/account';

  // aggiunta per la creazione della pagina ( CREATE )
  static const String create =
      '/create'; // non credo di avere bisogno di qualcosa da passare

  static final _authNotifier = _AuthNotifier();

  static final GoRouter router = GoRouter(
    initialLocation: home,
    refreshListenable: _authNotifier,
    routes: <RouteBase>[
      GoRoute(
        path: login,
        name: login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: signup,
        name: signup,
        builder: (BuildContext context, GoRouterState state) {
          return const SignUpScreen();
        },
      ),
      GoRoute(
        path: calendar,
        name: calendar,
        builder: (BuildContext context, GoRouterState state) {
          return const CalendarScreen();
        },
      ),
      GoRoute(
        path: home,
        name: home,
        builder: (BuildContext context, GoRouterState state) {
          // --- USA IL PREFISSO ---
          return const lists_screen.TodoListsScreen();
          // --- FINE ---
        },
        routes: <RouteBase>[
          // ➕ Rotta figlia: /account
          GoRoute(
            path: 'account',
            name: account,
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: 'list/:listId',
            name: listDetail,
            builder: (BuildContext context, GoRouterState state) {
              final String listId = state.pathParameters['listId']!;
              final Map<String, dynamic> extras =
                  state.extra as Map<String, dynamic>;
              final TodoList todoListExtra = extras['todoList'] as TodoList;
              final Folder parentFolderExtra = extras['parentFolder'] as Folder;

              return detail_screen.TodoListDetailScreen(
                todoList: todoListExtra,
                parentFolder: parentFolderExtra,
              );
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'folder/:folderId',
                name: folderDetail,
                builder: (BuildContext context, GoRouterState state) {
                  final Map<String, dynamic> extras =
                      state.extra as Map<String, dynamic>;
                  final TodoList todoListExtra = extras['todoList'] as TodoList;
                  final Folder parentFolderExtra =
                      extras['parentFolder'] as Folder;

                  return detail_screen.TodoListDetailScreen(
                    todoList: todoListExtra,
                    parentFolder: parentFolderExtra,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/create',
            name: create, // usa la costante definita
            builder: (BuildContext context, GoRouterState state) {
              return CreatePage();
            },
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = supabase.auth.currentUser != null;
      // Usa state.matchedLocation o state.fullPath per controllare la rotta corrente
      final bool loggingIn =
          state.matchedLocation == login || state.matchedLocation == signup;

      if (!loggedIn && !loggingIn) {
        return login; // Reindirizza al login se non loggato e non su pagine auth
      }
      if (loggedIn && loggingIn) {
        return home; // Reindirizza alla home se loggato e su pagine auth
      }
      return null; // Nessun redirect necessario
    },
  );
}

/// 🔻 Definizione inline di AccountScreen per risolvere l'errore.
/// (Puoi spostarla in lib/features/todo_lists/presentation/screens/account_screen.dart)
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final username = (user?.userMetadata?['username'] as String?) ?? 'Sconosciuto';
    final email = user?.email ?? '—';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(initial, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text(username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Username'),
            subtitle: Text(username),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
          const ListTile(
            leading: Icon(Icons.lock),
            title: Text('Password'),
            subtitle: Text('••••••••'),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Elimina account'),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminare l’account?'),
                  content: const Text('Questa azione è definitiva. Confermi di voler eliminare il tuo account?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Elimina'),
                    ),
                  ],
                ),
              );
              if (ok != true) return;
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Eliminazione account: da implementare lato backend'), backgroundColor: Colors.orange),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}


