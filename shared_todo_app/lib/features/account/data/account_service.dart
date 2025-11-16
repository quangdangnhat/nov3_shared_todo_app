import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountService {
  final supabase = Supabase.instance.client;

  Future<void> updateEmail(String newEmail) async {
    String? redirectUrl;

    if (kIsWeb) {
      // esempio: http://localhost:5173/#/login
      final origin = Uri.base.origin;
      redirectUrl = '$origin/#/login';
    }

    await supabase.auth.updateUser(
      UserAttributes(email: newEmail),
      emailRedirectTo: redirectUrl,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> updateUsername(String newUsername) async {
    await supabase.auth.updateUser(
      UserAttributes(data: {'username': newUsername}),
    );
  }
}
