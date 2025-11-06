class Task {
  final String id;
  final String folderId;
  final String title;
  final String? desc;
  final String priority;
  final String status;
  final DateTime? startDate;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.folderId,
    required this.title,
    this.desc,
    required this.priority,
    required this.status,
    this.startDate,
    required this.dueDate,
    required this.createdAt,
    this.updatedAt,
  });

  // Factory 'fromMap' robusto
  factory Task.fromMap(Map<String, dynamic> map) {
    // Helper sicuro per parsare date nullable
    DateTime? parseNullableDate(dynamic value) {
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null; // Ignora formati non validi
        }
      }
      return null;
    }

    // Helper sicuro per parsare date NON nullable
    DateTime parseRequiredDate(dynamic value, String fieldName) {
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          throw FormatException(
            'Invalid date format for required field $fieldName: $value',
          );
        }
      }
      throw FormatException(
        'Missing or invalid type for required field $fieldName: $value',
      );
    }

    final sdValue = map['start_date'] ?? map['startDate'];
    final uaValue = map['updated_at'] ?? map['updatedAt'];
    final ddValue = map['due_date'] ?? map['dueDate'];
    final caValue = map['created_at'] ?? map['createdAt'];

    return Task(
      id: map['id'] as String,
      folderId: (map['folder_id'] ?? map['folderId']) as String,
      title: map['title'] as String,
      desc: map['desc'] as String?,
      priority: map['priority'] as String,
      status: map['status'] as String,
      // --- MODIFICA: Usa parseNullableDate ---
      startDate: parseNullableDate(sdValue),
      // --- FINE MODIFICA ---
      dueDate: parseRequiredDate(ddValue, 'dueDate'),
      createdAt: parseRequiredDate(caValue, 'createdAt'),
      updatedAt: parseNullableDate(uaValue),
    );
  }

  // Metodo 'toMap' per l'invio al DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folder_id': folderId,
      'title': title,
      'desc': desc,
      'priority': priority,
      'status': status,
      // --- MODIFICA: Riportato a Nullable ---
      'start_date': startDate?.toIso8601String(), // Invia null se non impostato
      // --- FINE MODIFICA ---
      'due_date': dueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
