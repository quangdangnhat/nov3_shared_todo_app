class TodoList {
  final String id;
  final String title;
  final String? desc;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String role; // <-- NUOVA PROPRIETÀ

  TodoList({
    required this.id,
    required this.title,
    this.desc,
    required this.createdAt,
    this.updatedAt,
    required this.role, // <-- AGGIUNTO AL COSTRUTTORE
  });

  // Factory 'fromMap' (o fromJson)
  // Reso robusto per gestire sia snake_case che camelCase
  factory TodoList.fromMap(Map<String, dynamic> map) {
    // Gestione sicura per 'updated_at' che può essere nullo
    final uaValue = map['updated_at'] ?? map['updatedAt'];

    return TodoList(
      id: map['id'], // Ora questo funziona (String -> String)
      title: map['title'],
      desc: map['desc'],
      // Controlla entrambi i formati per 'created_at'
      createdAt: DateTime.parse(map['created_at'] ?? map['createdAt']),
      updatedAt: uaValue != null ? DateTime.parse(uaValue) : null,
      role: map['role'] ?? 'Unknown', // <-- AGGIUNTO PER IL RUOLO
    );
  }

  // Metodo 'toMap' (o toJson)
  // Quando invii i dati, Supabase preferisce snake_case
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'desc': desc,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // Nota: non inviamo il 'role' quando creiamo/aggiorniamo una lista
    };
  }
}
