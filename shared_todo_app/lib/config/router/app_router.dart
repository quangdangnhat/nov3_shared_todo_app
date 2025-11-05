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

// Importa le schermate con prefissi per evitare conflitti
import '../../features/todo_lists/detail.dart/todo_list_detail_screen.dart'
    as detail_screen;
import '../../features/todo_lists/presentation/screens/todo_lists_screen.dart'
    as lists_screen;
// Importa la schermata Account dal suo file
import '../../features/account/presentation/screens/account_screen.dart';
// Importa la schermata Inviti dal suo file
import '../../features/invitations/presentation/screens/invitation_screen.dart';

import '../../main.dart'; // Importa 'supabase' helper

/// Notifier che ascolta i cambiamenti dello stato di autenticazione
/// e notifica GoRouter quando deve aggiornarsi.
class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _isLoggedIn = supabase.auth.currentUser != null;

  _AuthNotifier() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final bool newLoginState = data.session != null;
      // Se lo stato cambia, notifica GoRouter per rieseguire il redirect
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
  // Nomi statici per le rotte per evitare errori di battitura
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/';
  static const String calendar = '/calendar';
  static const String listDetail = '/list/:listId';
  static const String folderDetail = '/list/:listId/folder/:folderId';
  static const String account = '/account';
  static const String create = '/create';
  static const String invitations = '/invitations';

  static final _authNotifier = _AuthNotifier();

  /// L'istanza del router GoRouter configurata per l'app.
  static final GoRouter router = GoRouter(
    initialLocation: home, // Parte dalla home
    refreshListenable: _authNotifier, // Ascolta i cambiamenti di auth

    routes: <RouteBase>[
      // Rotte di Autenticazione
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

      // Rotte Principali (protette dal redirect)
      GoRoute(
        path: calendar,
        name: calendar,
        builder: (BuildContext context, GoRouterState state) {
          return const CalendarScreen();
        },
      ),
      GoRoute(
        path: invitations,
        name: invitations,
        builder: (BuildContext context, GoRouterState state) {
          return const InvitationsScreen();
        },
      ),
      GoRoute(
        path: account, // Spostato al livello superiore
        name: account,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: create, // Spostato al livello superiore
        name: create,
        builder: (BuildContext context, GoRouterState state) {
          return CreatePage();
        },
      ),

      // Rotta Home e sue sotto-rotte
      GoRoute(
        path: home,
        name: home,
        builder: (BuildContext context, GoRouterState state) {
          return const lists_screen.TodoListsScreen();
        },
        routes: <RouteBase>[
          // Dettaglio Lista (mostra la root folder)
          GoRoute(
            path: 'list/:listId', // Path relativo: /list/:listId
            name: listDetail,
            builder: (BuildContext context, GoRouterState state) {
              // Recupera i dati passati
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
              // Dettaglio Sottocartella
              GoRoute(
                path:
                    'folder/:folderId', // Path relativo: /list/:listId/folder/:folderId
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
        ],
      ),
    ],

    // Logica di Redirect per l'autenticazione
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = supabase.auth.currentUser != null;

      // Controlla se l'utente sta cercando di accedere a una pagina di autenticazione
      final bool onAuthRoute =
          state.matchedLocation == login || state.matchedLocation == signup;

      // Se l'utente NON è loggato E NON sta andando a una pagina auth -> vai al login
      if (!loggedIn && !onAuthRoute) {
        return login;
      }

      // Se l'utente È loggato E STA andando a una pagina auth -> vai alla home
      if (loggedIn && onAuthRoute) {
        return home;
      }

      // In tutti gli altri casi, non fare nulla
      return null;
    },
  );
}
