class Task {
  final String id;
  final String folderId;
  final String title;
  final String? desc; // Nullable
  final String priority;
  final String status;
  final DateTime? startDate; // Nullable se il DB lo permette, altrimenti DateTime
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt; // Nullable

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
    // Gestione date nullable
    final sdValue = map['start_date'] ?? map['startDate'];
    final uaValue = map['updated_at'] ?? map['updatedAt'];

    return Task(
      id: map['id'],
      folderId: map['folder_id'] ?? map['folderId'],
      title: map['title'],
      desc: map['desc'],
      priority: map['priority'],
      status: map['status'],
      startDate: sdValue != null ? DateTime.parse(sdValue) : null,
      dueDate: DateTime.parse(map['due_date'] ?? map['dueDate']),
      createdAt: DateTime.parse(map['created_at'] ?? map['createdAt']),
      updatedAt: uaValue != null ? DateTime.parse(uaValue) : null,
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
      'start_date': startDate?.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}