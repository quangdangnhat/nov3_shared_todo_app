// RIMUOVI QUESTO IMPORT: import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

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
  
  // MODIFICA: Usa 'double' minuscolo
  final double? latitude;
  final double? longitude;
  final String? placeName;

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
    // MODIFICA
    this.latitude,
    this.longitude,
    this.placeName,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    // ... (i tuoi helper date restano uguali) ...
    DateTime? parseNullableDate(dynamic value) { /* ... */ return null; } 
    DateTime parseRequiredDate(dynamic value, String fieldName) { /* ... */ return DateTime.now(); } // Semplificato per brevità

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
      startDate: parseNullableDate(sdValue),
      dueDate: parseRequiredDate(ddValue, 'dueDate'),
      createdAt: parseRequiredDate(caValue, 'createdAt'),
      updatedAt: parseNullableDate(uaValue),
      
      // --- MODIFICA FONDAMENTALE ---
      // Convertiamo in double in modo sicuro (gestisce anche se il DB manda un int)
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      placeName: map['place_name'] as String?,
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
      
      // I double passano normalmente
      'latitude': latitude,
      'longitude': longitude,
      'place_name': placeName,
    };
  }
}