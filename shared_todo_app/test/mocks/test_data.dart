import 'package:shared_todo_app/data/models/task.dart';
import 'package:shared_todo_app/data/models/folder.dart';
import 'package:shared_todo_app/data/models/todo_list.dart';
import 'package:shared_todo_app/data/models/invitation.dart';
import 'package:shared_todo_app/data/models/participant.dart';

/// Test Data Generator
///
/// Provides factory methods to create test data with smart defaults.
/// All methods support customization via optional parameters.
class TestData {
  // ============================================================
  // COMMON TEST DATA
  // ============================================================

  /// Test user IDs
  static const String testUserId = 'test-user-123';
  static const String testUserId2 = 'test-user-456';

  /// Test user details
  static const String testUserEmail = 'test@example.com';
  static const String testUsername = 'testuser';
  static const String testUserEmail2 = 'test2@example.com';
  static const String testUsername2 = 'testuser2';

  /// Common test dates
  static DateTime get now => DateTime.now();
  static DateTime get yesterday =>
      DateTime.now().subtract(const Duration(days: 1));
  static DateTime get tomorrow => DateTime.now().add(const Duration(days: 1));
  static DateTime get nextWeek => DateTime.now().add(const Duration(days: 7));

  // ============================================================
  // TASK FIXTURES
  // ============================================================

  static Task createTask({
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
    return Task(
      id: id ?? 'task-1',
      folderId: folderId ?? 'folder-1',
      title: title ?? 'Test Task',
      desc: desc ?? 'Test task description',
      priority: priority ?? 'medium',
      status: status ?? 'todo',
      startDate: startDate,
      dueDate: dueDate ?? tomorrow,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt,
    );
  }

  /// Creates multiple tasks
  static List<Task> createTasks(
    int count, {
    String? folderId,
    String? priority,
    String? status,
  }) {
    return List.generate(
      count,
      (index) => createTask(
        id: 'task-${index + 1}',
        title: 'Task ${index + 1}',
        folderId: folderId ?? 'folder-1',
        priority: priority ?? (index % 3 == 0 ? 'high' : 'medium'),
        status: status ?? (index % 2 == 0 ? 'todo' : 'done'),
      ),
    );
  }

  /// Creates a high priority task
  static Task createHighPriorityTask({String? id, String? folderId}) {
    return createTask(
      id: id ?? 'task-high-priority',
      title: 'Urgent Task',
      priority: 'high',
      status: 'todo',
      dueDate: tomorrow,
      folderId: folderId,
    );
  }

  /// Creates an overdue task
  static Task createOverdueTask({String? id, String? folderId}) {
    return createTask(
      id: id ?? 'task-overdue',
      title: 'Overdue Task',
      priority: 'high',
      status: 'todo',
      dueDate: yesterday,
      folderId: folderId,
    );
  }

  /// Creates a completed task
  static Task createCompletedTask({String? id, String? folderId}) {
    return createTask(
      id: id ?? 'task-completed',
      title: 'Completed Task',
      status: 'done',
      dueDate: yesterday,
      folderId: folderId,
    );
  }

  // ============================================================
  // FOLDER FIXTURES
  // ============================================================

  static Folder createFolder({
    String? id,
    String? todoListId,
    String? title,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Folder(
      id: id ?? 'folder-1',
      todoListId: todoListId ?? 'todo-list-1',
      title: title ?? 'Test Folder',
      parentId: parentId,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt,
    );
  }

  /// Creates multiple folders

  static List<Folder> createFolders(int count, {String? todoListId}) {
    return List.generate(
      count,
      (index) => createFolder(
        id: 'folder-${index + 1}',
        title: 'Folder ${index + 1}',
        todoListId: todoListId ?? 'todo-list-1',
      ),
    );
  }

  /// Creates a root folder
  static Folder createRootFolder({String? id, String? todoListId}) {
    return createFolder(
      id: id ?? 'folder-root',
      title: 'Root',
      todoListId: todoListId ?? 'todo-list-1',
      parentId: null,
    );
  }

  /// Creates a subfolder
  static Folder createSubfolder({
    String? id,
    String? parentId,
    String? todoListId,
  }) {
    return createFolder(
      id: id ?? 'folder-sub',
      title: 'Subfolder',
      parentId: parentId ?? 'folder-root',
      todoListId: todoListId ?? 'todo-list-1',
    );
  }

  // ============================================================
  // TODO LIST FIXTURES
  // ============================================================

  static TodoList createTodoList({
    String? id,
    String? title,
    String? desc,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoList(
      id: id ?? 'todo-list-1',
      title: title ?? 'Test Todo List',
      desc: desc ?? 'Test todo list description',
      role: role ?? 'admin',
      createdAt: createdAt ?? now,
      updatedAt: updatedAt,
    );
  }

  /// Creates multiple todo lists

  static List<TodoList> createTodoLists(int count, {String? role}) {
    return List.generate(
      count,
      (index) => createTodoList(
        id: 'todo-list-${index + 1}',
        title: 'Todo List ${index + 1}',
        role: role ?? (index == 0 ? 'admin' : 'collaborator'),
      ),
    );
  }

  /// Creates an admin-owned todo list
  static TodoList createAdminTodoList({String? id}) {
    return createTodoList(
      id: id ?? 'todo-list-admin',
      title: 'Admin Todo List',
      role: 'admin',
    );
  }

  /// Creates a shared todo list
  static TodoList createSharedTodoList({String? id}) {
    return createTodoList(
      id: id ?? 'todo-list-shared',
      title: 'Shared Todo List',
      role: 'collaborator',
    );
  }

  // ============================================================
  // INVITATION FIXTURES
  // ============================================================

  static Invitation createInvitation({
    String? id,
    String? todoListId,
    String? invitedByUserId,
    String? invitedUserId,
    String? role,
    String? status,
    String? todoListTitle,
    String? invitedByUserEmail,
    DateTime? createdAt,
  }) {
    return Invitation(
      id: id ?? 'invitation-1',
      todoListId: todoListId ?? 'todo-list-1',
      invitedByUserId: invitedByUserId ?? testUserId,
      invitedUserId: invitedUserId ?? testUserId2,
      role: role ?? 'collaborator',
      status: status ?? 'pending',
      todoListTitle: todoListTitle ?? 'Test Todo List',
      invitedByUserEmail: invitedByUserEmail ?? testUserEmail,
      createdAt: createdAt ?? now,
    );
  }

  /// Creates multiple invitations

  static List<Invitation> createInvitations(int count, {String? status}) {
    return List.generate(
      count,
      (index) => createInvitation(
        id: 'invitation-${index + 1}',
        invitedUserId: 'user-${index + 1}',
        invitedByUserEmail: 'inviter${index + 1}@example.com',
        status: status ?? 'pending',
      ),
    );
  }

  /// Creates a pending invitation
  static Invitation createPendingInvitation({String? id}) {
    return createInvitation(
      id: id ?? 'invitation-pending',
      status: 'pending',
    );
  }

  /// Creates an accepted invitation
  static Invitation createAcceptedInvitation({String? id}) {
    return createInvitation(
      id: id ?? 'invitation-accepted',
      status: 'accepted',
    );
  }

  /// Creates a rejected invitation
  static Invitation createRejectedInvitation({String? id}) {
    return createInvitation(
      id: id ?? 'invitation-rejected',
      status: 'rejected',
    );
  }

  // ============================================================
  // PARTICIPANT FIXTURES
  // ============================================================

  static Participant createParticipant({
    String? userId,
    String? todoListId,
    String? role,
    String? username,
    String? email,
  }) {
    return Participant(
      userId: userId ?? testUserId,
      todoListId: todoListId ?? 'todo-list-1',
      role: role ?? 'collaborator',
      username: username ?? testUsername,
      email: email ?? testUserEmail,
    );
  }

  /// Creates multiple participants

  static List<Participant> createParticipants(
    int count, {
    String? todoListId,
  }) {
    return List.generate(
      count,
      (index) => createParticipant(
        userId: 'user-${index + 1}',
        todoListId: todoListId ?? 'todo-list-1',
        username: 'user${index + 1}',
        email: 'user${index + 1}@example.com',
        role: index == 0 ? 'admin' : 'collaborator',
      ),
    );
  }

  /// Creates an admin participant
  static Participant createAdminParticipant({
    String? userId,
    String? todoListId,
  }) {
    return createParticipant(
      userId: userId ?? testUserId,
      todoListId: todoListId,
      role: 'admin',
      username: 'admin',
      email: 'admin@example.com',
    );
  }

  /// Creates a collaborator participant
  static Participant createCollaboratorParticipant({
    String? userId,
    String? todoListId,
  }) {
    return createParticipant(
      userId: userId ?? testUserId2,
      todoListId: todoListId,
      role: 'collaborator',
      username: 'collaborator',
      email: 'collaborator@example.com',
    );
  }

  // ============================================================
  // COMPLEX FIXTURES (Multiple Related Objects)
  // ============================================================

  static Map<String, dynamic> createCompleteTodoListData() {
    final todoList = createTodoList();
    final folders = createFolders(3, todoListId: todoList.id);
    final tasks = createTasks(5, folderId: folders.first.id);
    final participants = createParticipants(2, todoListId: todoList.id);

    return {
      'todoList': todoList,
      'folders': folders,
      'tasks': tasks,
      'participants': participants,
    };
  }

  /// Creates a folder with tasks

  static Map<String, dynamic> createFolderWithTasks({int taskCount = 5}) {
    final folder = createFolder();
    final tasks = createTasks(taskCount, folderId: folder.id);

    return {
      'folder': folder,
      'tasks': tasks,
    };
  }

  /// Creates a todo list with pending invitations

  static Map<String, dynamic> createTodoListWithInvitations({
    int invitationCount = 3,
  }) {
    final todoList = createTodoList();
    final invitations = createInvitations(
      invitationCount,
    )
        .map((inv) => createInvitation(
              id: inv.id,
              todoListId: todoList.id,
              todoListTitle: todoList.title,
            ))
        .toList();

    return {
      'todoList': todoList,
      'invitations': invitations,
    };
  }
}
