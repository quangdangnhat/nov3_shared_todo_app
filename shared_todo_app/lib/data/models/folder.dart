class Folder {
  final String id;
  final String todoListId;
  final String title;
  final String? parentId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Folder({
    required this.id,
    required this.todoListId,
    required this.title,
    this.parentId,
    required this.createdAt,
    this.updatedAt,
  });

  // --- METODO 'fromMap' ROBUSTO ---
  // Ora gestisce sia snake_case che camelCase
  factory Folder.fromMap(Map<String, dynamic> map) {
    
    // Gestione sicura per 'updated_at' che può essere nullo
    final uaValue = map['updated_at'] ?? map['updatedAt'];
    
    // Gestione sicura per 'parent_id' che può essere nullo
    final pValue = map['parent_id'] ?? map['parentId'];

    // Gestione sicura per 'todo_list_id'
    final tlValue = map['todo_list_id'] ?? map['todoListId'];

    return Folder(
      id: map['id'],
      title: map['title'],
      
      // Assicura che 'createdAt' venga letto e PARSATO
      createdAt: DateTime.parse(map['created_at'] ?? map['createdAt']),
      
      // Assicura che gli altri campi vengano letti
      todoListId: tlValue,
      parentId: pValue,
      updatedAt: uaValue != null ? DateTime.parse(uaValue) : null,
    );
  }

  // Metodo 'toMap' (o toJson)
  // Quando invii i dati, Supabase preferisce snake_case
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'todo_list_id': todoListId,
      'parent_id': parentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

