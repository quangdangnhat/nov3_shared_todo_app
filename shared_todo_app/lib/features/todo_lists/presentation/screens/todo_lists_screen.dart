// lib/features/todo_lists/presentation/screens/todo_lists_screen.dart

import 'package:flutter/material.dart';
import '../../../../data/repositories/auth_repository.dart'; // Importa il tuo repository

class TodoListsScreen extends StatelessWidget {
  const TodoListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Creiamo un'istanza del repository per poter fare il logout
    final authRepo = AuthRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Le mie To-Do List'),
        actions: [
          // Bottone per il Logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // Chiama il metodo signOut
              authRepo.signOut();
              // Lo StreamBuilder in main.dart noterà il cambiamento
              // e mostrerà automaticamente la AuthScreen.
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Benvenuto! Qui compariranno le tue liste.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aggiungeremo la creazione di una nuova lista qui
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}