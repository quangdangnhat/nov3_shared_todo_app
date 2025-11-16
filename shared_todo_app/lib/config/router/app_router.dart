// coverage:ignore-file

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/screens/createPage/create_screen.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/screens/today_tasks/today_task.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/screens/tree_view/folder_view_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/folder.dart';
import '../../data/models/todo_list.dart';
import '../../data/repositories/todo_list_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/todo_lists/presentation/screens/calendar/calendar_screen.dart';
import '../../features/account/presentation/screens/email_change_success_screen.dart';


// Importa le schermate con prefissi per evitare conflitti
import '../../features/todo_lists/detail.dart/todo_list_detail_screen.dart'
    as detail_screen;
import '../../features/todo_lists/presentation/screens/todo_lists_screen.dart'
    as lists_screen;
// Importa la schermata Account dal suo file
import '../../features/account/presentation/screens/account_screen.dart';
// Importa la schermata Inviti dal suo file
import '../../features/invitations/presentation/screens/invitation_screen.dart';

import '../../features/todo_lists/presentation/widgets/layout/main_layout.dart';
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
  static const String tasks_day = '/today-tasks';
  static const String calendar = '/calendar';
  static const String listDetail = 'listDetail'; // Nome per la navigazione
  static const String folderDetail = 'folderDetail'; // Nome per la navigazione
  static const String account = '/account';
  static const String create = '/create';
  static const String invitations = '/invitations';
  static const String visualizer = '/tree_visualizer';

  static final _authNotifier = _AuthNotifier();
  static const String emailChangeSuccess = '/email-change-success';
  
  /// L'istanza del router GoRouter configurata per l'app.
  static final GoRouter router = GoRouter(
    initialLocation: home,
    refreshListenable: _authNotifier,
    routes: <RouteBase>[
      // ========================================
      // ROTTE DI AUTENTICAZIONE (senza MainLayout)
      // ========================================
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
            name: AppRouter.emailChangeSuccess,
            path: AppRouter.emailChangeSuccess,
            builder: (context, state) => const EmailChangeSuccessScreen(),
      ),

      // ========================================
      // SHELL ROUTE - Tutte le rotte con MainLayout persistente
      // ========================================
      ShellRoute(
        builder: (context, state, child) {
          // Questo builder wrappa TUTTE le rotte figlie con MainLayout
          // mantenendo la sidebar sempre visibile e consistente
          return MainLayout(child: child);
        },
        routes: <RouteBase>[
          // Home - Lista Todo
          GoRoute(
            path: home,
            name: home,
            pageBuilder: (BuildContext context, GoRouterState state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const lists_screen.TodoListsScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  // Nessuna animazione per transizioni fluide
                  return child;
                },
              );
            },
          ),

          GoRoute(
            path: tasks_day,
            name: 'today-tasks',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const TodayTasksPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return child;
                },
              );
            },
          ),
          // Dettaglio Lista (mostra la root folder)
          GoRoute(
            path: '/list/:listId', // Path assoluto
            name: listDetail,
            pageBuilder: (BuildContext context, GoRouterState state) {
              // Recupera i dati passati
              final Map<String, dynamic> extras =
                  state.extra as Map<String, dynamic>;
              final TodoList todoListExtra = extras['todoList'] as TodoList;
              final Folder parentFolderExtra = extras['parentFolder'] as Folder;

              return CustomTransitionPage(
                key: state.pageKey,
                child: detail_screen.TodoListDetailScreen(
                  todoList: todoListExtra,
                  parentFolder: parentFolderExtra,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  // Nessuna animazione per transizioni fluide
                  return child;
                },
              );
            },
          ),
          GoRoute(
            path: visualizer,
            name: visualizer,
            pageBuilder: (BuildContext context, GoRouterState state) {
              // 1. Recupera il repository passato come argomento 'extra'
              final repository = state.extra as TodoListRepository;

              return CustomTransitionPage(
                key: state.pageKey,
                // 2. Rimuovi 'const' e passa il repository alla pagina
                child: FolderTreeViewPage(
                  todoListRepository: repository,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  // (La tua transizione personalizzata)
                  return child;
                },
              );
            },
          ),

          // Route per folder - path assoluto, stesso livello di listDetail
          GoRoute(
            path: '/list/:listId/folder/:folderId',
            name: folderDetail,
            pageBuilder: (BuildContext context, GoRouterState state) {
              final Map<String, dynamic> extras =
                  state.extra as Map<String, dynamic>;
              final TodoList todoListExtra = extras['todoList'] as TodoList;
              final Folder parentFolderExtra = extras['parentFolder'] as Folder;

              return CustomTransitionPage(
                key: ValueKey('folder_${parentFolderExtra.id}'),
                child: detail_screen.TodoListDetailScreen(
                  todoList: todoListExtra,
                  parentFolder: parentFolderExtra,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return child;
                },
              );
            },
          ),

          // Calendario
          GoRoute(
            path: calendar,
            name: calendar,
            pageBuilder: (BuildContext context, GoRouterState state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const CalendarScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return child;
                },
              );
            },
          ),

          // Inviti
          GoRoute(
            path: invitations,
            name: invitations,
            pageBuilder: (BuildContext context, GoRouterState state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const InvitationsScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return child;
                },
              );
            },
          ),

          // Crea nuova lista
          GoRoute(
            path: create,
            name: create,
            pageBuilder: (BuildContext context, GoRouterState state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: CreatePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  // Definiamo un'animazione di scorrimento (Slide)
                  final tween = Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeInOut));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              );
            },
          ),
          // Account/Profile
          GoRoute(
            path: account,
            name: account,
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const AccountScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return child;
                },
              );
            },
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

    // Gestione errori
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Pagina non trovata: ${state.matchedLocation}')),
    ),
  );
}
