import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_todo_app/data/models/folder.dart';
import 'package:shared_todo_app/data/models/task.dart';
import 'package:shared_todo_app/data/models/todo_list.dart';
import 'package:shared_todo_app/data/repositories/folder_repository.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import 'package:shared_todo_app/data/repositories/todo_list_repository.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/controllers/task/task_create_controller.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/create/task/status_picker.dart';

// Mock classes
class MockTodoListRepository extends Mock implements TodoListRepository {}
class MockFolderRepository extends Mock implements FolderRepository {}
class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  group('TaskCreateController Tests', () {
    late MockTodoListRepository mockTodoListRepo;
    late MockFolderRepository mockFolderRepo;
    late MockTaskRepository mockTaskRepo;
    late TaskCreateController controller;

    setUp(() {
      mockTodoListRepo = MockTodoListRepository();
      mockFolderRepo = MockFolderRepository();
      mockTaskRepo = MockTaskRepository();
      controller = TaskCreateController(
        todoListRepo: mockTodoListRepo,
        folderRepo: mockFolderRepo,
        taskRepo: mockTaskRepo,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(controller.selectedTodoList, isNull);
        expect(controller.selectedFolder, isNull);
        expect(controller.rootFolder, isNull);
        expect(controller.listsStream, isNull);
        expect(controller.folderStream, isNull);
        expect(controller.searchQuery, '');
        expect(controller.isLoading, false);
        expect(controller.selectedPriority, 'low');
        expect(controller.selectedStatus, TaskStatus.toDo);
        expect(controller.dateError, isNull);
        expect(controller.hasValidDates, true);
      });

      test('should initialize selectedDueDate to today', () {
        final now = DateTime.now();
        expect(
          controller.selectedDueDate.difference(now).inMinutes,
          lessThan(1),
        );
      });

      test('should initialize selectedStartDate to today', () {
        final now = DateTime.now();
        expect(
          controller.selectedStartDate!.difference(now).inMinutes,
          lessThan(1),
        );
      });

      test('should set up listsStream when initialize is called', () {
        // Arrange
        final mockStream = Stream<List<TodoList>>.value([]);
        when(() => mockTodoListRepo.getTodoListsStream())
            .thenAnswer((_) => mockStream);

        // Act
        controller.initialize();

        // Assert
        expect(controller.listsStream, isNotNull);
        verify(() => mockTodoListRepo.getTodoListsStream()).called(1);
      });
    });

    group('Search Query', () {
      test('should update search query and notify listeners', () {
        // Arrange
        var listenerCalled = false;
        controller.addListener(() => listenerCalled = true);

        // Act
        controller.updateSearchQuery('test query');

        // Assert
        expect(controller.searchQuery, 'test query');
        expect(listenerCalled, true);
      });

      test('should handle empty search query', () {
        // Act
        controller.updateSearchQuery('');

        // Assert
        expect(controller.searchQuery, '');
      });

      test('should handle unicode characters in search query', () {
        // Act
        controller.updateSearchQuery('测试 тест 🔍');

        // Assert
        expect(controller.searchQuery, '测试 тест 🔍');
      });

      test('should handle very long search query', () {
        // Arrange
        final longQuery = 'a' * 1000;

        // Act
        controller.updateSearchQuery(longQuery);

        // Assert
        expect(controller.searchQuery, longQuery);
      });
    });

    group('Filter Lists', () {
      test('should return all lists when search query is empty', () {
        // Arrange
        final lists = [
          TodoList(
            id: '1',
            title: 'List One',
            desc: null,
            role: 'admin',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          TodoList(
            id: '2',
            title: 'List Two',
            desc: null,
            role: 'admin',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Act
        final filtered = controller.filterLists(lists);

        // Assert
        expect(filtered.length, 2);
      });

      test('should filter lists by title (case insensitive)', () {
        // Arrange
        final lists = [
          TodoList(
            id: '1',
            title: 'Shopping List',
            desc: null,
            role: 'admin',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          TodoList(
            id: '2',
            title: 'Work Tasks',
            desc: null,
            role: 'admin',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        controller.updateSearchQuery('shop');

        // Act
        final filtered = controller.filterLists(lists);

        // Assert
        expect(filtered.length, 1);
        expect(filtered[0].title, 'Shopping List');
      });

      test('should filter lists with uppercase query', () {
        // Arrange
        final lists = [
          TodoList(
            id: '1',
            title: 'shopping list',
            desc: null,
            role: 'admin',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        controller.updateSearchQuery('SHOP');

        // Act
        final filtered = controller.filterLists(lists);

        // Assert
        expect(filtered.length, 1);
      });

      test('should return empty list when no matches found', () {
        // Arrange
        final lists = [
          TodoList(
            id: '1',
            title: 'List One',
            desc: null,
            role: 'admin',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        controller.updateSearchQuery('nonexistent');

        // Act
        final filtered = controller.filterLists(lists);

        // Assert
        expect(filtered.length, 0);
      });

      test('should handle empty list input', () {
        // Arrange
        controller.updateSearchQuery('test');

        // Act
        final filtered = controller.filterLists([]);

        // Assert
        expect(filtered.length, 0);
      });
    });

    group('Select TodoList', () {
      test('should select TodoList and load root folder successfully', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final rootFolder = Folder(
          id: 'folder-root',
          title: 'Root',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final mockFolderStream = Stream<List<Folder>>.value([]);

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => rootFolder);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: 'folder-root',
            )).thenAnswer((_) => mockFolderStream);

        var listenerCallCount = 0;
        controller.addListener(() => listenerCallCount++);

        // Act
        await controller.selectTodoList(todoList);

        // Assert
        expect(controller.selectedTodoList, todoList);
        expect(controller.rootFolder, rootFolder);
        expect(controller.selectedFolder, rootFolder);
        expect(controller.folderStream, isNotNull);
        expect(controller.isLoading, false);
        expect(listenerCallCount, greaterThan(0));
        verify(() => mockFolderRepo.getRootFolder('list-1')).called(1);
      });

      test('should set isLoading to true then false during selection', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final rootFolder = Folder(
          id: 'folder-root',
          title: 'Root',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => rootFolder);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: 'folder-root',
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));

        final loadingStates = <bool>[];
        controller.addListener(() {
          loadingStates.add(controller.isLoading);
        });

        // Act
        await controller.selectTodoList(todoList);

        // Assert
        expect(loadingStates, contains(true));
        expect(controller.isLoading, false);
      });

      test('should reset previous folder selection when selecting new list', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final rootFolder = Folder(
          id: 'folder-root',
          title: 'Root',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder(any()))
            .thenAnswer((_) async => rootFolder);
        when(() => mockFolderRepo.getFoldersStream(
              any(),
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));

        // Act
        await controller.selectTodoList(todoList);

        // Assert - These should be reset first, then set to new values
        expect(controller.selectedTodoList, isNotNull);
        expect(controller.selectedFolder, isNotNull);
        expect(controller.rootFolder, isNotNull);
        expect(controller.folderStream, isNotNull);
      });

      test('should handle error when loading root folder', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenThrow(Exception('Failed to load root folder'));

        // Act & Assert
        expect(
          () => controller.selectTodoList(todoList),
          throwsA(isA<Exception>()),
        );

        // Verify loading is set back to false even on error
        await expectLater(
          controller.selectTodoList(todoList),
          throwsException,
        );
        expect(controller.isLoading, false);
      });

      test('should notify listeners on error', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenThrow(Exception('Error'));

        var listenerCalled = false;
        controller.addListener(() => listenerCalled = true);

        // Act
        try {
          await controller.selectTodoList(todoList);
        } catch (_) {}

        // Assert
        expect(listenerCalled, true);
      });
    });

    group('Select Folder', () {
      test('should select folder and load subfolders', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final rootFolder = Folder(
          id: 'folder-root',
          title: 'Root',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final subFolder = Folder(
          id: 'folder-sub',
          title: 'Subfolder',
          todoListId: 'list-1',
          parentId: 'folder-root',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => rootFolder);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));

        await controller.selectTodoList(todoList);

        var listenerCalled = false;
        controller.addListener(() => listenerCalled = true);

        // Act
        await controller.selectFolder(subFolder);

        // Assert
        expect(controller.selectedFolder, subFolder);
        expect(controller.folderStream, isNotNull);
        expect(listenerCalled, true);
      });

      test('should not change folder if same folder is selected', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final folder = Folder(
          id: 'folder-1',
          title: 'Folder',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => folder);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));

        await controller.selectTodoList(todoList);

        var listenerCallCount = 0;
        controller.addListener(() => listenerCallCount++);

        // Act
        await controller.selectFolder(folder);

        // Assert - Should not trigger listener because same folder
        expect(listenerCallCount, 0);
      });

      test('should not change folder if no TodoList selected', () async {
        // Arrange
        final folder = Folder(
          id: 'folder-1',
          title: 'Folder',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        var listenerCalled = false;
        controller.addListener(() => listenerCalled = true);

        // Act
        await controller.selectFolder(folder);

        // Assert
        expect(controller.selectedFolder, isNull);
        expect(listenerCalled, false);
      });
    });

    group('Priority Management', () {
      test('should set priority and notify listeners', () {
        // Arrange
        var listenerCalled = false;
        controller.addListener(() => listenerCalled = true);

        // Act
        controller.setPriority('high');

        // Assert
        expect(controller.selectedPriority, 'high');
        expect(listenerCalled, true);
      });

      test('should handle different priority values', () {
        // Act & Assert
        controller.setPriority('low');
        expect(controller.selectedPriority, 'low');

        controller.setPriority('medium');
        expect(controller.selectedPriority, 'medium');

        controller.setPriority('high');
        expect(controller.selectedPriority, 'high');
      });

      test('should handle empty priority string', () {
        // Act
        controller.setPriority('');

        // Assert
        expect(controller.selectedPriority, '');
      });
    });

    group('Status Management', () {
      test('should set status and notify listeners', () {
        // Arrange
        var listenerCalled = false;
        controller.addListener(() => listenerCalled = true);

        // Act
        controller.setStatus(TaskStatus.inProgress);

        // Assert
        expect(controller.selectedStatus, TaskStatus.inProgress);
        expect(listenerCalled, true);
      });

      test('should handle all TaskStatus values', () {
        // Act & Assert
        controller.setStatus(TaskStatus.toDo);
        expect(controller.selectedStatus, TaskStatus.toDo);

        controller.setStatus(TaskStatus.inProgress);
        expect(controller.selectedStatus, TaskStatus.inProgress);

        controller.setStatus(TaskStatus.done);
        expect(controller.selectedStatus, TaskStatus.done);
      });
    });

    group('Date Management', () {
      test('should set due date and notify listeners', () {
        // Arrange
        final newDate = DateTime(2025, 12, 31);
        var listenerCalled = false;
        controller.addListener(() => listenerCalled = true);

        // Act
        controller.setDueDate(newDate);

        // Assert
        expect(controller.selectedDueDate, newDate);
        expect(listenerCalled, true);
      });

      test('should set start date and notify listeners', () {
        // Arrange
        final newDate = DateTime(2025, 1, 1);
        var listenerCalled = false;
        controller.addListener(() => listenerCalled = true);

        // Act
        controller.setStartDate(newDate);

        // Assert
        expect(controller.selectedStartDate, newDate);
        expect(listenerCalled, true);
      });

      test('should validate dates when start date is before due date', () {
        // Arrange
        final startDate = DateTime(2025, 1, 1);
        final dueDate = DateTime(2025, 12, 31);

        // Act
        controller.setDueDate(dueDate);
        controller.setStartDate(startDate);

        // Assert
        expect(controller.dateError, isNull);
        expect(controller.hasValidDates, true);
      });

      test('should set error when start date is after due date', () {
        // Arrange
        final startDate = DateTime(2025, 12, 31);
        final dueDate = DateTime(2025, 1, 1);

        // Act
        controller.setDueDate(dueDate);
        controller.setStartDate(startDate);

        // Assert
        expect(controller.dateError, isNotNull);
        expect(controller.dateError, 'Start date cannot be after end date');
        expect(controller.hasValidDates, false);
      });

      test('should clear error when dates become valid', () {
        // Arrange
        final invalidStartDate = DateTime(2025, 12, 31);
        final validStartDate = DateTime(2025, 1, 1);
        final dueDate = DateTime(2025, 6, 15);

        controller.setDueDate(dueDate);
        controller.setStartDate(invalidStartDate);
        expect(controller.dateError, isNotNull);

        // Act
        controller.setStartDate(validStartDate);

        // Assert
        expect(controller.dateError, isNull);
        expect(controller.hasValidDates, true);
      });

      test('should validate when changing due date', () {
        // Arrange
        final startDate = DateTime(2025, 6, 15);
        final earlyDueDate = DateTime(2025, 1, 1);
        final lateDueDate = DateTime(2025, 12, 31);

        controller.setStartDate(startDate);
        controller.setDueDate(earlyDueDate);
        expect(controller.dateError, isNotNull);

        // Act
        controller.setDueDate(lateDueDate);

        // Assert
        expect(controller.dateError, isNull);
      });

      test('should handle same start and due date', () {
        // Arrange
        final sameDate = DateTime(2025, 6, 15);

        // Act
        controller.setStartDate(sameDate);
        controller.setDueDate(sameDate);

        // Assert
        expect(controller.dateError, isNull);
        expect(controller.hasValidDates, true);
      });
    });

    group('Create Task', () {

      test('should throw exception when no folder selected', () async {
        // Act & Assert
        expect(
          () => controller.createTask(title: 'Task'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('No folder selected'),
            ),
          ),
        );
      });

      test('should throw exception when title is empty', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final folder = Folder(
          id: 'folder-1',
          title: 'Folder',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => folder);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));

        await controller.selectTodoList(todoList);

        // Act & Assert
        expect(
          () => controller.createTask(title: ''),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Task title cannot be empty'),
            ),
          ),
        );
      });

      test('should throw exception when title is only whitespace', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final folder = Folder(
          id: 'folder-1',
          title: 'Folder',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => folder);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));

        await controller.selectTodoList(todoList);

        // Act & Assert
        expect(
          () => controller.createTask(title: '   '),
          throwsA(isA<Exception>()),
        );
      });

   
    });

    group('Can Create Task', () {
      test('should return true when folder is selected and title is not empty', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final folder = Folder(
          id: 'folder-1',
          title: 'Folder',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => folder);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));

        await controller.selectTodoList(todoList);

        // Act
        final result = controller.canCreateTask('My Task');

        // Assert
        expect(result, true);
      });

      test('should return false when no folder is selected', () {
        // Act
        final result = controller.canCreateTask('My Task');

        // Assert
        expect(result, false);
      });

      test('should return false when title is empty', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final folder = Folder(
          id: 'folder-1',
          title: 'Folder',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => folder);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));

        await controller.selectTodoList(todoList);

        // Act
        final result = controller.canCreateTask('');

        // Assert
        expect(result, false);
      });

      test('should return false when title is only whitespace', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final folder = Folder(
          id: 'folder-1',
          title: 'Folder',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => folder);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));

        await controller.selectTodoList(todoList);

        // Act
        final result = controller.canCreateTask('   ');

        // Assert
        expect(result, false);
      });
    });

    group('Reset Form', () {
      test('should reset all form values to initial state', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final folder = Folder(
          id: 'folder-1',
          title: 'Folder',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => folder);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));

        await controller.selectTodoList(todoList);
        controller.setPriority('high');
        controller.setStatus(TaskStatus.done);
        controller.updateSearchQuery('test');

        // Act
        controller.resetForm();

        // Assert
        expect(controller.selectedTodoList, isNull);
        expect(controller.selectedFolder, isNull);
        expect(controller.rootFolder, isNull);
        expect(controller.folderStream, isNull);
        expect(controller.selectedPriority, 'low');
        expect(controller.selectedStatus, TaskStatus.toDo);
        expect(controller.searchQuery, '');
      });

      test('should notify listeners when resetting', () {
        // Arrange
        var listenerCalled = false;
        controller.addListener(() => listenerCalled = true);

        // Act
        controller.resetForm();

        // Assert
        expect(listenerCalled, true);
      });

      test('should reset to current date for due date', () {
        // Arrange
        controller.setDueDate(DateTime(2026, 12, 31));

        // Act
        controller.resetForm();

        // Assert
        final now = DateTime.now();
        expect(
          controller.selectedDueDate.difference(now).inMinutes,
          lessThan(1),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle special characters in search query', () {
        // Act
        controller.updateSearchQuery('!@#\$%^&*()');

        // Assert
        expect(controller.searchQuery, '!@#\$%^&*()');
      });

      test('should handle newlines in search query', () {
        // Act
        controller.updateSearchQuery('line1\nline2');

        // Assert
        expect(controller.searchQuery, 'line1\nline2');
      });

      test('should handle multiple consecutive folder selections', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final folder1 = Folder(
          id: 'folder-1',
          title: 'Folder 1',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final folder2 = Folder(
          id: 'folder-2',
          title: 'Folder 2',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => folder1);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));

        await controller.selectTodoList(todoList);

        // Act
        await controller.selectFolder(folder2);
        await controller.selectFolder(folder1);

        // Assert
        expect(controller.selectedFolder, folder1);
      });

      test('should handle rapid priority changes', () {
        // Act
        controller.setPriority('low');
        controller.setPriority('medium');
        controller.setPriority('high');
        controller.setPriority('low');

        // Assert
        expect(controller.selectedPriority, 'low');
      });

      test('should handle rapid status changes', () {
        // Act
        controller.setStatus(TaskStatus.toDo);
        controller.setStatus(TaskStatus.inProgress);
        controller.setStatus(TaskStatus.done);
        controller.setStatus(TaskStatus.toDo);

        // Assert
        expect(controller.selectedStatus, TaskStatus.toDo);
      });
    });

    group('Error Handling', () {
      test('should handle repository error when creating task', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final folder = Folder(
          id: 'folder-1',
          title: 'Folder',
          todoListId: 'list-1',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => folder);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));
        when(() => mockTaskRepo.createTask(
              folderId: any(named: 'folderId'),
              title: any(named: 'title'),
              desc: any(named: 'desc'),
              priority: any(named: 'priority'),
              status: any(named: 'status'),
              startDate: any(named: 'startDate'),
              dueDate: any(named: 'dueDate'),
            )).thenThrow(Exception('Network error'));

        await controller.selectTodoList(todoList);

        // Act & Assert
        expect(
          () => controller.createTask(title: 'Task'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle network timeout when selecting list', () async {
        // Arrange
        final todoList = TodoList(
          id: 'list-1',
          title: 'Test List',
          desc: null,
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenThrow(Exception('Request timeout'));

        // Act & Assert
        expect(
          () => controller.selectTodoList(todoList),
          throwsA(isA<Exception>()),
        );
        expect(controller.isLoading, false);
      });
    });
  });
}