class TodoList {
  final String id;
  final String title;
  final String? desc;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String role;
  final int memberCount; // Aggiunto per il conteggio dei membri

  TodoList({
    required this.id,
    required this.title,
    this.desc,
    required this.createdAt,
    this.updatedAt,
    required this.role,
    required this.memberCount, // Aggiunto al costruttore
  });

  factory TodoList.fromMap(Map<String, dynamic> map) {
    final uaValue = map['updated_at'] ?? map['updatedAt'];

    // Esegui il parsing di member_count, gestendo il caso in cui sia nullo o non un intero
    final memberCountValue = map['member_count'];
    int memberCount = 0; // Default a 0
    if (memberCountValue is int) {
      memberCount = memberCountValue;
    } else if (memberCountValue is String) {
      memberCount = int.tryParse(memberCountValue) ?? 0;
    }

    return TodoList(
      id: map['id'],
      title: map['title'],
      desc: map['desc'],
      createdAt: DateTime.parse(map['created_at'] ?? map['createdAt']),
      updatedAt: uaValue != null ? DateTime.parse(uaValue) : null,
      role: map['role'] ?? 'Unknown',
      memberCount: memberCount, // Assegna il valore processato
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'desc': desc,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
