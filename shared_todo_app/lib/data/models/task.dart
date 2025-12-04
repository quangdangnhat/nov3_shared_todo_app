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
  final double? latitude;
  final double? longitude;
  final String? placeName;
  final bool isRecurring;
  final String recurrenceType;
  final String? parentRecurringTaskId;

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
    this.latitude,
    this.longitude,
    this.placeName,
    this.isRecurring = false,
    this.recurrenceType = 'none',
    this.parentRecurringTaskId,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    // --- HELPER ROBUSTO PER IL PARSING DELLE DATE ---
    DateTime? parseDateSafe(dynamic value, String fieldName) {
      if (value == null) return null;

      // Se è già DateTime, lo ritorniamo
      if (value is DateTime) return value;

      String dateStr = value.toString();

      // 🛠️ FIX CRUCIALE:
      // Dart vuole "YYYY-MM-DDTHH:MM:SS".
      // Se il DB manda lo spazio ("2025-11-21 16:00"), lo sostituiamo con T.
      if (dateStr.contains(' ') && !dateStr.contains('T')) {
        dateStr = dateStr.replaceFirst(' ', 'T');
      }

      try {
        return DateTime.parse(dateStr).toLocal();
      } catch (e) {
        print(
            "🚨 ERRORE GRAVE parsing $fieldName: Valore '$value' non valido.");
        return null; // Ritorna null se fallisce, NON DateTime.now()!
      }
    }

    // --- ESTRAZIONE VALORI ---
    final sdValue = map['start_date'] ?? map['startDate'];
    final ddValue = map['due_date'] ?? map['dueDate'];
    final caValue = map['created_at'] ?? map['createdAt'];
    final uaValue = map['updated_at'] ?? map['updatedAt'];

    // --- BLOCCO DEBUG TEMPORANEO (Per capire perché era null) ---
    // Se vedi questi log nel terminale, controlla cosa stampa "RAW" vs "PARSED"
    /*
    if (sdValue != null) {
      print("🔍 DEBUG TASK '${map['title']}'");
      print("   💾 RAW startDate da DB: '$sdValue'");
      final parsed = parseDateSafe(sdValue, 'startDate');
      print("   ✅ PARSED startDate: $parsed");
      print("--------------------------------");
    }
    */
    // -----------------------------------------------------------

    return Task(
      id: map['id'] as String,
      folderId: (map['folder_id'] ?? map['folderId']) as String,
      title: map['title'] as String,
      desc: map['desc'] as String?,
      priority: map['priority'] as String,
      status: map['status'] as String,

      // ✅ Usiamo la funzione sicura
      startDate: parseDateSafe(sdValue, 'startDate'),

      // Per i campi obbligatori, usiamo un fallback solo se restituisce null
      dueDate: parseDateSafe(ddValue, 'dueDate') ?? DateTime.now(),
      createdAt: parseDateSafe(caValue, 'createdAt') ?? DateTime.now(),

      updatedAt: parseDateSafe(uaValue, 'updatedAt'),

      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      placeName: map['place_name'] as String?,

      // Recurring fields
      isRecurring: (map['is_recurring'] ?? map['isRecurring'] ?? false) as bool,
      recurrenceType: (map['recurrence_type'] ?? map['recurrenceType'] ?? 'none') as String,
      parentRecurringTaskId: (map['parent_recurring_task_id'] ?? map['parentRecurringTaskId']) as String?,
    );
  }

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
      'latitude': latitude,
      'longitude': longitude,
      'place_name': placeName,
      'is_recurring': isRecurring,
      'recurrence_type': recurrenceType,
      'parent_recurring_task_id': parentRecurringTaskId,
    };
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, startDate: $startDate, dueDate: $dueDate)';
  }
}
