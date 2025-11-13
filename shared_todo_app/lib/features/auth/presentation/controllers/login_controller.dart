import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';

class LoginController extends ChangeNotifier {
  final AuthRepository _authRepository;

  LoginController({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.signIn(
        email: email.trim(),
        password: password.trim(),
      );
      // Il redirect del router ci porterà alla home
    } on AuthException catch (error) {
      if (context.mounted) {
        showErrorSnackBar(context, message: error.message);
      }
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(
          context,
          message: 'Si è verificato un errore sconosciuto.',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
