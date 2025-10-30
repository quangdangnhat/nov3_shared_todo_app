import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/screens/createPage/create_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/folder.dart';
import '../../data/models/todo_list.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';

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
  static const String listDetail = '/list/:listId';
  static const String folderDetail = '/list/:listId/folder/:folderId';

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
        path: home,
        name: home,
        builder: (BuildContext context, GoRouterState state) {
          // --- USA IL PREFISSO ---
          return const lists_screen.TodoListsScreen();
          // --- FINE ---
        },
        routes: <RouteBase>[
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
