// coverage:ignore-file
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_todo_app/features/chat/screens/chat_screen.dart';
import 'package:shared_todo_app/features/history/presentation/screens/history_screen.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/screens/createPage/create_screen.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/screens/today_tasks/today_task.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/screens/tree_view/folder_view_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/folder.dart';
import '../../data/models/todo_list.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/todo_list_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/history/presentation/controllers/history_controller.dart';
import '../../features/todo_lists/presentation/screens/calendar/calendar_screen.dart';
import '../../features/account/presentation/screens/email_change_success_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';

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

  bool isPasswordRecovery = false;

  _AuthNotifier() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        isPasswordRecovery = true;
      } else {
        // Se avviene qualsiasi altro evento (es. login normale, logout, token refresh),
        // disattiviamo la modalità recupero.
        isPasswordRecovery = false;
      }
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
  static const String history = '/history';
  static const String listDetail = 'listDetail'; // Nome per la navigazione
  static const String folderDetail = 'folderDetail'; // Nome per la navigazione
  static const String account = '/account';
  static const String create = '/create';
  static const String invitations = '/invitations';
  static const String visualizer = '/tree_visualizer';
  static const String passwordRecovery = '/password-recovery';

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
        path: passwordRecovery,
        name: passwordRecovery,
        builder: (BuildContext context, GoRouterState state) {
          return const ResetPasswordScreen();
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
          // Home - List Todo
          GoRoute(
            path: home,
            name: home,
            pageBuilder: (BuildContext context, GoRouterState state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const lists_screen.TodoListsScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
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
            path: '/list/:listId/chat',
            name: 'chat',
            pageBuilder: (BuildContext context, GoRouterState state) {
              // Recupera l'ID della lista dal path param
              final todoListId = state.pathParameters[
                  'listId']!; // sempre presente perché definito in path

              return CustomTransitionPage(
                key: state.pageKey,
                child: ChatScreen(todoListId: todoListId),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return child; // nessuna animazione
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

          // History
          GoRoute(
            path: history, // o AppRouter.history
            name: history, // o AppRouter.history
            pageBuilder: (BuildContext context, GoRouterState state) {
              return CustomTransitionPage(
                key: state.pageKey,

                // --- MODIFICA QUI: Avvolgi HistoryScreen col Provider ---
                child: ChangeNotifierProvider(
                  create: (_) => HistoryController(
                    taskRepository: TaskRepository(),
                  ),
                  child: const HistoryScreen(),
                ),
                // -------------------------------------------------------

                transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
                child: const InvitationsNotificationButton(),
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
      final String path = state.uri.path;

      // Tutte le rotte di autenticazione che devono essere accessibili anche se non loggati
      final bool isAuthRoute =
          path == login ||
              path == signup ||
              path == passwordRecovery;

      // Se NON sono loggato e non sto andando su una rotta di auth → login
      if (!loggedIn && !isAuthRoute) {
        return login;
      }

      // Se sono loggato e vado su login o signup → manda a home
      if (loggedIn && (path == login || path == signup)) {
        return home;
      }

      return null;
    },

    // Gestione errori
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Pagina non trovata: ${state.matchedLocation}')),
    ),
  );
}
