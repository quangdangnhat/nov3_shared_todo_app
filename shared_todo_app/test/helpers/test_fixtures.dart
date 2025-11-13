/// Test fixtures for creating test data
class TestFixtures {
  /// Create a sample task map for testing
  static Map<String, dynamic> createTaskMap({
    String? id,
    String? folderId,
    String? title,
    String? desc,
    String? priority,
    String? status,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return {
      'id': id ?? 'test-task-id',
      'folder_id': folderId ?? 'test-folder-id',
      'title': title ?? 'Test Task',
      'desc': desc,
      'priority': priority ?? 'High',
      'status': status ?? 'Pending',
      'start_date': startDate?.toIso8601String(),
      'due_date': (dueDate ?? now.add(const Duration(days: 7))).toIso8601String(),
      'created_at': (createdAt ?? now).toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a sample folder map for testing
  static Map<String, dynamic> createFolderMap({
    String? id,
    String? todoListId,
    String? title,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return {
      'id': id ?? 'test-folder-id',
      'todo_list_id': todoListId ?? 'test-todo-list-id',
      'title': title ?? 'Test Folder',
      'parent_id': parentId,
      'created_at': (createdAt ?? now).toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a sample todo list map for testing
  static Map<String, dynamic> createTodoListMap({
    String? id,
    String? title,
    String? desc,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return {
      'id': id ?? 'test-todo-list-id',
      'title': title ?? 'Test Todo List',
      'desc': desc,
      'role': role ?? 'admin',
      'created_at': (createdAt ?? now).toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a sample participant map for testing
  static Map<String, dynamic> createParticipantMap({
    String? userId,
    String? todoListId,
    String? role,
    String? username,
    String? email,
  }) {
    return {
      'user_id': userId ?? 'test-user-id',
      'todo_list_id': todoListId ?? 'test-todo-list-id',
      'role': role ?? 'collaborator',
      'users': {
        'username': username ?? 'testuser',
        'email': email ?? 'test@example.com',
      },
    };
  }

  /// Create a sample invitation map for testing
  static Map<String, dynamic> createInvitationMap({
    String? id,
    String? todoListId,
    String? inviterId,
    String? inviteeEmail,
    String? status,
    DateTime? createdAt,
  }) {
    final now = DateTime.now();
    return {
      'id': id ?? 'test-invitation-id',
      'todo_list_id': todoListId ?? 'test-todo-list-id',
      'inviter_id': inviterId ?? 'test-inviter-id',
      'invitee_email': inviteeEmail ?? 'invitee@example.com',
      'status': status ?? 'pending',
      'created_at': (createdAt ?? now).toIso8601String(),
    };
  }
}
