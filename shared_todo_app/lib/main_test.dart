import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Configurazione minima del router
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/page2',
      builder: (context, state) => const Page2(),
    ),
  ],
);

// Funzione main per il test
void main() {
  runApp(const MinimalApp());
}

// Widget radice con MaterialApp.router
class MinimalApp extends StatelessWidget {
  const MinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'GoRouter Test',
      debugShowCheckedModeBanner: false,
    );
  }
}

// Pagina 1
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            try {
              print('Attempting navigation using context.go...');
              // Usa context.go o GoRouter.of(context).go
              context.go('/page2'); 
              // GoRouter.of(context).go('/page2');
              print('Navigation call successful (no immediate error)');
            } catch (e, s) {
              print('!!! ERROR navigating: $e');
              print('Stack Trace: $s');
            }
          },
          child: const Text('Go to Page 2'),
        ),
      ),
    );
  }
}

// Pagina 2
class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page 2')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/'); // Torna indietro
          },
          child: const Text('Go Back Home'),
        ),
      ),
    );
  }
}
