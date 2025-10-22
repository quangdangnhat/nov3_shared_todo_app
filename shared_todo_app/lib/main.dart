import 'package:flutter/material.dart';
import 'package:shared_todo_app/registerpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xpcqhvgkzajaoegtxiih.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhwY3FodmdremFqYW9lZ3R4aWloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5ODIwMDksImV4cCI6MjA3NjU1ODAwOX0.6Laq17RKctTPjhal-t9D1LIJBtHbK-riu2k93I6oL8s',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const RegisterPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}