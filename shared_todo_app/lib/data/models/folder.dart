class Folder {
  final String id;
  final DateTime createdAt;
  final String todoListId;
  final String title;
  final DateTime? updatedAt;
  final String? parentId;

  Folder({
    required this.id,
    required this.createdAt,
    required this.todoListId,
    required this.title,
    this.updatedAt,
    this.parentId,
  });

  // Da JSON (da Supabase)
  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      todoListId: json['todo_list_id'] as String,
      title: json['title'] as String,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      parentId: json['parent_id'] as String?, 
    );
  }


// A JSON (per Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'todo_list_id': todoListId,
      'title': title,
      'updated_at': updatedAt?.toIso8601String(),
      'parent_id' : parentId,
    };
  }}
