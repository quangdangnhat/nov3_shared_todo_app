class Invitation {
  final String id;
  final String todoListId;
  final String invitedByUserId;
  final String invitedUserId;
  final String role;
  final String status;
  final DateTime createdAt;
  // --- NUOVO CAMPO ---
  final String? todoListTitle; // Titolo della lista a cui si è invitati
  // --- FINE ---

  Invitation({
    required this.id,
    required this.todoListId,
    required this.invitedByUserId,
    required this.invitedUserId,
    required this.role,
    required this.status,
    required this.createdAt,
    this.todoListTitle, // Aggiunto al costruttore
  });

  // Factory 'fromMap' robusto
  factory Invitation.fromMap(Map<String, dynamic> map) {
    // Helper per parsare la data
    DateTime parseRequiredDate(dynamic value, String fieldName) {
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          throw FormatException('Invalid date format for required field $fieldName: $value');
        }
      }
      throw FormatException('Missing or invalid type for required field $fieldName: $value');
    }

    // Estrae il titolo della lista dal join
    String? title;
    if (map['todo_lists'] != null && map['todo_lists'] is Map) {
      title = (map['todo_lists'] as Map<String, dynamic>)['title'] as String?;
    }

    return Invitation(
      id: map['id'] as String,
      todoListId: (map['todo_list_id'] ?? map['todoListId']) as String,
      invitedByUserId: (map['invited_by_user_id'] ?? map['invitedByUserId']) as String,
      invitedUserId: (map['invited_user_id'] ?? map['invitedUserId']) as String,
      role: map['role'] as String,
      status: map['status'] as String,
      createdAt: parseRequiredDate(map['created_at'] ?? map['createdAt'], 'createdAt'),
      todoListTitle: title, // Assegna il titolo
    );
  }
}

