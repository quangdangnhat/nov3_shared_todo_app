class AuthValidators {
  // Previene l'istanziazione della classe
  AuthValidators._();

  /// Valida un indirizzo email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please, insert your email';
    }

    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please, insert a valid email';
    }

    return null;
  }

  /// Valida una password
  static String? validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'The password has to contain at least 6 characters';
    }
    return null;
  }

  /// Valida la conferma password
  static String? validatePasswordConfirmation(
    String? value,
    String? password,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please, confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }
}
