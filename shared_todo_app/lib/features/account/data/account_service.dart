import 'package:supabase_flutter/supabase_flutter.dart';

class AccountService {
  final supabase = Supabase.instance.client;

  Future<void> updateEmail(String newEmail) async {
    await supabase.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> updateUsername(String newUsername) async {
    await supabase.auth.updateUser(
      UserAttributes(
        data: {
          'username': newUsername,
        },
      ),
    );
  }
}
