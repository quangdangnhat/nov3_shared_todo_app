import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_todo_app/data/models/folder.dart';
import 'package:shared_todo_app/data/models/todo_list.dart';
import 'package:shared_todo_app/data/repositories/folder_repository.dart';
import 'package:shared_todo_app/data/repositories/todo_list_repository.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/controllers/folder/folder_create_controller.dart';

// Mock classes
class MockTodoListRepository extends Mock implements TodoListRepository {}
class MockFolderRepository extends Mock implements FolderRepository {}

void main() {
  group('FolderCreateController Tests', () {
    late MockTodoListRepository mockTodoListRepo;
    late MockFolderRepository mockFolderRepo;
    late FolderCreateController controller;

    setUp(() {
      mockTodoListRepo = MockTodoListRepository();
      mockFolderRepo = MockFolderRepository();
      controller = FolderCreateController(
        todoListRepo: mockTodoListRepo,
        folderRepo: mockFolderRepo,
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
        controller.updateSearchQuery('test');

        // Assert
        expect(controller.searchQuery, 'test');
        expect(listenerCalled, true);
      });

      test('should handle empty search query', () {
        // Act
        controller.updateSearchQuery('');

        // Assert
        expect(controller.searchQuery, '');
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

        when(() => mockFolderRepo.getRootFolder('list-1'))
            .thenAnswer((_) async => rootFolder);
        when(() => mockFolderRepo.getFoldersStream(
              'list-1',
              parentId: 'folder-root',
            )).thenAnswer((_) => Stream<List<Folder>>.value([]));

        // Act
        await controller.selectTodoList(todoList);

        // Assert
        expect(controller.selectedTodoList, todoList);
        expect(controller.rootFolder, rootFolder);
        expect(controller.selectedFolder, rootFolder);
        expect(controller.folderStream, isNotNull);
        expect(controller.isLoading, false);
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
            .thenThrow(Exception('Failed to load'));

        // Act & Assert
        expect(
          () => controller.selectTodoList(todoList),
          throwsA(isA<Exception>()),
        );
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

        // Act
        await controller.selectFolder(subFolder);

        // Assert
        expect(controller.selectedFolder, subFolder);
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

        // Assert - Should not trigger listener
        expect(listenerCallCount, 0);
      });
    });

    group('Create Folder', () {
      

      test('should throw exception when no todo list selected', () async {
        // Act & Assert
        expect(
          () => controller.createFolder('Folder'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('No todo list selected'),
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
          () => controller.createFolder(''),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Folder name cannot be empty'),
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
          () => controller.createFolder('   '),
          throwsA(isA<Exception>()),
        );
      });

      

      
    });

    group('Can Create Folder', () {
      test('should return true when list is selected and name is not empty', () async {
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
        final result = controller.canCreateFolder('My Folder');

        // Assert
        expect(result, true);
      });

      test('should return false when no list is selected', () {
        // Act
        final result = controller.canCreateFolder('My Folder');

        // Assert
        expect(result, false);
      });

      test('should return false when name is empty', () async {
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
        final result = controller.canCreateFolder('   ');

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
        controller.updateSearchQuery('test');

        // Act
        controller.resetForm();

        // Assert
        expect(controller.selectedTodoList, isNull);
        expect(controller.selectedFolder, isNull);
        expect(controller.rootFolder, isNull);
        expect(controller.folderStream, isNull);
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
    });

    group('Error Handling', () {
      test('should handle repository error when creating folder', () async {
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
        when(() => mockFolderRepo.createFolder(
              todoListId: any(named: 'todoListId'),
              title: any(named: 'title'),
              parentId: any(named: 'parentId'),
            )).thenThrow(Exception('Network error'));

        await controller.selectTodoList(todoList);

        // Act & Assert
        expect(
          () => controller.createFolder('Folder'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}