/// Modello per rappresentare un invito.
class Invitation {
  final String id;
  final String todoListId;
  final String invitedByUserId;
  final String invitedUserId;
  final String role;
  final String status;
  final DateTime createdAt;

  // --- NUOVI CAMPI PER INFO AGGIUNTIVE ---
  final String? todoListTitle; // Titolo della lista
  final String? invitedByUserEmail; // Email di chi ha invitato

  Invitation({
    required this.id,
    required this.todoListId,
    required this.invitedByUserId,
    required this.invitedUserId,
    required this.role,
    required this.status,
    required this.createdAt,
    this.todoListTitle, // Aggiunto al costruttore
    this.invitedByUserEmail, // Aggiunto al costruttore
  });

  // Factory 'fromMap' per convertire il JSON da Supabase
  factory Invitation.fromMap(Map<String, dynamic> map) {
    // Estrae il titolo della lista dal join
    // Supabase inserisce i dati joinati in una mappa con il nome della tabella
    String? title;
    if (map['todo_lists'] != null && map['todo_lists'] is Map) {
      title = (map['todo_lists'] as Map<String, dynamic>)['title'] as String?;
    }

    // Estrae l'email di chi ha invitato dal join
    // Abbiamo usato 'users:invited_by_user_id(email)'
    String? email;
    if (map['users'] != null && map['users'] is Map) {
      email = (map['users'] as Map<String, dynamic>)['email'] as String?;
    }

    return Invitation(
      id: map['id'] as String,
      todoListId: (map['todo_list_id'] ?? map['todoListId']) as String,
      invitedByUserId:
          (map['invited_by_user_id'] ?? map['invitedByUserId']) as String,
      invitedUserId: (map['invited_user_id'] ?? map['invitedUserId']) as String,
      role: map['role'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] ?? map['createdAt']),
      todoListTitle: title,
      invitedByUserEmail: email,
    );
  }
}
