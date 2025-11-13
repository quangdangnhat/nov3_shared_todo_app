/// Modello per rappresentare un partecipante a una lista,
/// combinando dati da 'participations' e 'users'.
class Participant {
  final String userId; // ID dell'utente
  final String todoListId; // ID della lista
  final String role; // Ruolo (es. 'admin', 'collaborator')
  final String username; // Username (da public.users)
  final String email; // Email (da public.users)

  Participant({
    required this.userId,
    required this.todoListId,
    required this.role,
    required this.username,
    required this.email,
  });

  /// Factory per creare un Participant da un JSON (risultato di un join)
  factory Participant.fromMap(Map<String, dynamic> map) {
    // I dati dell'utente (username, email) sono in una mappa annidata 'users'
    // Se 'users' è nullo (es. utente eliminato?), forniamo dei fallback.
    final userData = map['users'] as Map<String, dynamic>? ?? {};

    return Participant(
      userId: map['user_id'] as String,
      todoListId: map['todo_list_id'] as String,
      role: map['role'] as String,
      username: (userData['username'] as String?) ?? 'Unknown User',
      email: (userData['email'] as String?) ?? 'Unknown Email',
    );
  }

  /// Costruttore "empty" per fallback sicuro
  factory Participant.empty() {
    return Participant(
      userId: '',
      todoListId: '',
      role: 'collaborator', // ruolo di default
      username: 'Unknown User',
      email: 'Unknown Email',
    );
  }
}
