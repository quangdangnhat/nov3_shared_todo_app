// ============================================================
// Purpose: Single source of truth for all repository mocks
// ============================================================

import 'package:mocktail/mocktail.dart';
import 'package:shared_todo_app/data/repositories/auth_repository.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import 'package:shared_todo_app/data/repositories/folder_repository.dart';
import 'package:shared_todo_app/data/repositories/todo_list_repository.dart';
import 'package:shared_todo_app/data/repositories/invitation_repository.dart';
import 'package:shared_todo_app/data/repositories/participant_repository.dart';

// ============================================================
// REPOSITORY MOCKS
// ============================================================

/// Mock Auth Repository - Auth operations
///
/// Methods to mock:
/// - signIn(email, password)
/// - signUp(email, password, username)
/// - signOut()
/// - currentUser (getter)
/// - authStateChanges (stream)
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock Task Repository - Task CRUD + calendar queries
///
/// Methods to mock:
/// - getTasksStream(folderId)
/// - createTask(folderId, title, desc, priority, status, startDate, dueDate)
/// - updateTask(taskId, title, desc, priority, status, startDate, dueDate)
/// - deleteTask(taskId)
/// - getTasksForCalendar_Future(from, to)
/// - getTasksForDay_Future(dayStartInclusive, dayEndExclusive)
class MockTaskRepository extends Mock implements TaskRepository {}

/// Mock Folder Repository - Folder management with parent/child
///
/// Methods to mock:
/// - getFoldersStream(todoListId, {parentId})
/// - getRootFolder(todoListId)
/// - createFolder(todoListId, title, {parentId})
/// - updateFolder(id, {title, parentId})
/// - deleteFolder(id)
class MockFolderRepository extends Mock implements FolderRepository {}

/// Mock TodoList Repository -  TodoList CRUD + leave functionality
///
/// Methods to mock:
/// - getTodoListsStream()
/// - createTodoList(title, {desc})
/// - updateTodoList(listId, title, {desc})
/// - leaveTodoList(todoListId)
class MockTodoListRepository extends Mock implements TodoListRepository {}

/// Mock Invitation Repository - Invitation system with Edge Functions
///
/// Methods to mock:
/// - inviteUserToList(todoListId, email, role)
/// - getPendingInvitationsStream()
/// - respondToInvitation(invitationId, accept)
class MockInvitationRepository extends Mock implements InvitationRepository {}

/// Mock Participant Repository - Participant listing
///
/// Methods to mock:
/// - getParticipants(todoListId)
class MockParticipantRepository extends Mock implements ParticipantRepository {}
