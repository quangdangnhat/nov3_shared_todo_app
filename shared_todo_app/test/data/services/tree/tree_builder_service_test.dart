import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_todo_app/data/models/folder.dart';
import 'package:shared_todo_app/data/models/task.dart';
import 'package:shared_todo_app/data/models/todo_list.dart';
import 'package:shared_todo_app/data/models/tree/tree_data_cache_service.dart';
import 'package:shared_todo_app/data/models/tree/node_type.dart';
import 'package:shared_todo_app/data/repositories/folder_repository.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import 'package:shared_todo_app/data/services/tree/tree_builder_service.dart';
import '../../../helpers/test_fixtures.dart';

class MockFolderRepository extends Mock implements FolderRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockTreeDataCacheService extends Mock implements TreeDataCacheService {}

void main() {
  group('TreeBuilderService Tests', () {
    late TreeBuilderService service;
    late MockFolderRepository mockFolderRepo;
    late MockTaskRepository mockTaskRepo;
    late MockTreeDataCacheService mockCache;
    late TodoList testTodoList;
    late Folder testRootFolder;
    late Folder testSubFolder;
    late Task testTask;

    setUp(() {
      mockFolderRepo = MockFolderRepository();
      mockTaskRepo = MockTaskRepository();
      mockCache = MockTreeDataCacheService();

      service = TreeBuilderService(
        folderRepository: mockFolderRepo,
        taskRepository: mockTaskRepo,
        cache: mockCache,
      );

      testTodoList = TodoList.fromMap(TestFixtures.createTodoListMap(
        id: 'list-123',
        title: 'Test List',
      ));

      testRootFolder = Folder.fromMap(TestFixtures.createFolderMap(
        id: 'root-folder-123',
        todoListId: 'list-123',
        title: 'Root Folder',
        parentId: null,
      ));

      testSubFolder = Folder.fromMap(TestFixtures.createFolderMap(
        id: 'sub-folder-456',
        todoListId: 'list-123',
        title: 'Sub Folder',
        parentId: 'root-folder-123',
      ));

      testTask = Task.fromMap(TestFixtures.createTaskMap(
        id: 'task-789',
        folderId: 'root-folder-123',
        title: 'Test Task',
      ));

      // Default stubs
      when(() => mockCache.clear()).thenReturn(null);
      when(() => mockCache.hasRootFolder(any())).thenReturn(false);
      when(() => mockCache.hasSubFolders(any())).thenReturn(false);
      when(() => mockCache.hasTasks(any())).thenReturn(false);
      when(() => mockCache.setRootFolder(any(), any())).thenReturn(null);
      when(() => mockCache.setSubFolders(any(), any())).thenReturn(null);
      when(() => mockCache.setTasks(any(), any())).thenReturn(null);
    });

    group('buildTreeFromLists', () {
      test('should clear cache before building tree', () async {
        // Arrange
        when(() => mockFolderRepo.getRootFolder(any()))
            .thenAnswer((_) async => testRootFolder);
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        await service.buildTreeFromLists([testTodoList]);

        // Assert
        verify(() => mockCache.clear()).called(1);
      });

      test('should create root node with correct structure', () async {
        // Arrange
        when(() => mockFolderRepo.getRootFolder(any()))
            .thenAnswer((_) async => testRootFolder);
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildTreeFromLists([testTodoList]);

        // Assert
        expect(result.key, 'root');
        expect(result.data?.id, 'root');
        expect(result.data?.name, 'Root');
        expect(result.data?.type, NodeType.todoList);
      });

      test('should add TodoList nodes to root', () async {
        // Arrange
        when(() => mockFolderRepo.getRootFolder(any()))
            .thenAnswer((_) async => testRootFolder);
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildTreeFromLists([testTodoList]);

        // Assert
        expect(result.children.length, 1);
        expect(result.children.first.data?.id, 'list-123');
        expect(result.children.first.data?.name, 'Test List');
      });

      test('should handle multiple TodoLists', () async {
        // Arrange
        final todoList2 = TodoList.fromMap(TestFixtures.createTodoListMap(
          id: 'list-456',
          title: 'Second List',
        ));
        final rootFolder2 = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'root-folder-456',
          todoListId: 'list-456',
          title: 'Root Folder 2',
        ));

        when(() => mockFolderRepo.getRootFolder('list-123'))
            .thenAnswer((_) async => testRootFolder);
        when(() => mockFolderRepo.getRootFolder('list-456'))
            .thenAnswer((_) async => rootFolder2);
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildTreeFromLists([testTodoList, todoList2]);

        // Assert
        expect(result.children.length, 2);
      });

      test('should continue building tree if one TodoList fails', () async {
        // Arrange
        final todoList2 = TodoList.fromMap(TestFixtures.createTodoListMap(
          id: 'list-456',
          title: 'Second List',
        ));
        final rootFolder2 = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'root-folder-456',
          todoListId: 'list-456',
          title: 'Root Folder 2',
        ));

        when(() => mockFolderRepo.getRootFolder('list-123'))
            .thenThrow(Exception('Network error'));
        when(() => mockFolderRepo.getRootFolder('list-456'))
            .thenAnswer((_) async => rootFolder2);
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildTreeFromLists([testTodoList, todoList2]);

        // Assert - Should have only the second list
        expect(result.children.length, 1);
        expect(result.children.first.data?.id, 'list-456');
      });

      test('should return empty tree for empty list', () async {
        // Act
        final result = await service.buildTreeFromLists([]);

        // Assert
        expect(result.children.length, 0);
      });
    });

    group('buildTodoListNode', () {
      test('should create TodoList node with correct data', () async {
        // Arrange
        when(() => mockFolderRepo.getRootFolder(any()))
            .thenAnswer((_) async => testRootFolder);
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildTodoListNode(testTodoList);

        // Assert
        expect(result.key, 'list_list-123');
        expect(result.data?.id, 'list-123');
        expect(result.data?.name, 'Test List');
        expect(result.data?.type, NodeType.todoList);
      });

      test('should add root folder as child', () async {
        // Arrange
        when(() => mockFolderRepo.getRootFolder(any()))
            .thenAnswer((_) async => testRootFolder);
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildTodoListNode(testTodoList);

        // Assert
        expect(result.children.length, 1);
        expect(result.children.first.data?.id, 'root-folder-123');
      });

      test('should throw error if root folder fails to load', () async {
        // Arrange
        when(() => mockFolderRepo.getRootFolder(any()))
            .thenThrow(Exception('Not found'));

        // Act & Assert
        expect(
          () => service.buildTodoListNode(testTodoList),
          throwsException,
        );
      });
    });

    group('buildFolderNode', () {
      test('should create folder node with correct data', () async {
        // Arrange
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildFolderNode(
          testRootFolder,
          'list-123',
          testTodoList,
        );

        // Assert
        expect(result.key, 'folder_root-folder-123');
        expect(result.data?.id, 'root-folder-123');
        expect(result.data?.name, 'Root Folder');
        expect(result.data?.type, NodeType.folder);
      });

      test('should add tasks to folder node', () async {
        // Arrange
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream('root-folder-123'))
            .thenAnswer((_) => Stream.value([testTask]));

        // Act
        final result = await service.buildFolderNode(
          testRootFolder,
          'list-123',
          testTodoList,
        );

        // Assert
        final taskNodes = result.children.where((node) =>
          node.data?.type == NodeType.task
        ).toList();
        expect(taskNodes.length, 1);
        expect(taskNodes.first.data?.id, 'task-789');
      });

      test('should add sub folders recursively', () async {
        // Arrange
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'root-folder-123'))
            .thenAnswer((_) => Stream.value([testSubFolder]));
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'sub-folder-456'))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildFolderNode(
          testRootFolder,
          'list-123',
          testTodoList,
        );

        // Assert
        final folderNodes = result.children.where((node) =>
          node.data?.type == NodeType.folder
        ).toList();
        expect(folderNodes.length, 1);
        expect(folderNodes.first.data?.id, 'sub-folder-456');
      });

      test('should handle folders with both tasks and subfolders', () async {
        // Arrange
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'root-folder-123'))
            .thenAnswer((_) => Stream.value([testSubFolder]));
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'sub-folder-456'))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream('root-folder-123'))
            .thenAnswer((_) => Stream.value([testTask]));
        when(() => mockTaskRepo.getTasksStream('sub-folder-456'))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildFolderNode(
          testRootFolder,
          'list-123',
          testTodoList,
        );

        // Assert
        expect(result.children.length, 2); // 1 task + 1 subfolder
      });

      test('should continue if subfolder construction fails', () async {
        // Arrange
        final subfolder2 = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'sub-folder-789',
          title: 'Sub Folder 2',
          parentId: 'root-folder-123',
        ));

        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'root-folder-123'))
            .thenAnswer((_) => Stream.value([testSubFolder, subfolder2]));
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'sub-folder-456'))
            .thenThrow(Exception('Error'));
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'sub-folder-789'))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildFolderNode(
          testRootFolder,
          'list-123',
          testTodoList,
        );

        // Assert - Should have only the second subfolder
        expect(result.children.length, 1);
        expect(result.children.first.data?.id, 'sub-folder-789');
      });
    });

    group('Cache Integration', () {
      test('should use cached root folder if available', () async {
        // Arrange
        when(() => mockCache.hasRootFolder('list-123')).thenReturn(true);
        when(() => mockCache.getRootFolder('list-123')).thenReturn(testRootFolder);
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        await service.buildTodoListNode(testTodoList);

        // Assert
        verifyNever(() => mockFolderRepo.getRootFolder(any()));
        verify(() => mockCache.getRootFolder('list-123')).called(1);
      });

      test('should cache root folder after fetching', () async {
        // Arrange
        when(() => mockFolderRepo.getRootFolder(any()))
            .thenAnswer((_) async => testRootFolder);
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        await service.buildTodoListNode(testTodoList);

        // Assert
        verify(() => mockCache.setRootFolder('list-123', testRootFolder)).called(1);
      });

      test('should use cached sub folders if available', () async {
        // Arrange
        when(() => mockCache.hasSubFolders('root-folder-123')).thenReturn(true);
        when(() => mockCache.getSubFolders('root-folder-123')).thenReturn([testSubFolder]);
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'sub-folder-456'))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        await service.buildFolderNode(testRootFolder, 'list-123', testTodoList);

        // Assert
        verify(() => mockCache.getSubFolders('root-folder-123')).called(1);
      });

      test('should cache sub folders after fetching', () async {
        // Arrange
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'root-folder-123'))
            .thenAnswer((_) => Stream.value([testSubFolder]));
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'sub-folder-456'))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        await service.buildFolderNode(testRootFolder, 'list-123', testTodoList);

        // Assert
        verify(() => mockCache.setSubFolders('root-folder-123', [testSubFolder])).called(1);
      });

      test('should use cached tasks if available', () async {
        // Arrange
        when(() => mockCache.hasTasks('root-folder-123')).thenReturn(true);
        when(() => mockCache.getTasks('root-folder-123')).thenReturn([testTask]);
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));

        // Act
        await service.buildFolderNode(testRootFolder, 'list-123', testTodoList);

        // Assert
        verify(() => mockCache.getTasks('root-folder-123')).called(1);
        verifyNever(() => mockTaskRepo.getTasksStream(any()));
      });

      test('should cache tasks after fetching', () async {
        // Arrange
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream('root-folder-123'))
            .thenAnswer((_) => Stream.value([testTask]));

        // Act
        await service.buildFolderNode(testRootFolder, 'list-123', testTodoList);

        // Assert
        verify(() => mockCache.setTasks('root-folder-123', [testTask])).called(1);
      });

      test('should handle null parentId in cache key', () async {
        // Arrange
        final rootFolder = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'folder-123',
          parentId: null, // Root level folder
        ));

        when(() => mockCache.hasSubFolders('null')).thenReturn(true);
        when(() => mockCache.getSubFolders('null')).thenReturn([]);
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        await service.buildFolderNode(rootFolder, 'list-123', testTodoList);

        // Assert
        verify(() => mockCache.getSubFolders('null')).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle task loading errors gracefully', () async {
        // Arrange
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenThrow(Exception('Network error'));

        // Act & Assert - Should not throw
        final result = await service.buildFolderNode(
          testRootFolder,
          'list-123',
          testTodoList,
        );

        expect(result, isNotNull);
        expect(result.children.length, 0);
      });

      test('should handle empty task list', () async {
        // Arrange
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildFolderNode(
          testRootFolder,
          'list-123',
          testTodoList,
        );

        // Assert
        expect(result.children.length, 0);
      });

      test('should handle empty subfolder list', () async {
        // Arrange
        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildFolderNode(
          testRootFolder,
          'list-123',
          testTodoList,
        );

        // Assert
        expect(result.children.length, 0);
      });
    });

    group('Complex Tree Structures', () {
      test('should build deep nested tree', () async {
        // Arrange - Create 3 levels of folders
        final level2Folder = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'folder-level-2',
          title: 'Level 2',
          parentId: 'sub-folder-456',
        ));

        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'root-folder-123'))
            .thenAnswer((_) => Stream.value([testSubFolder]));
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'sub-folder-456'))
            .thenAnswer((_) => Stream.value([level2Folder]));
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'folder-level-2'))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildFolderNode(
          testRootFolder,
          'list-123',
          testTodoList,
        );

        // Assert
        expect(result.children.length, 1);
        expect(result.children.first.children.length, 1);
        expect(result.children.first.children.first.data?.id, 'folder-level-2');
      });

      test('should handle multiple tasks in folder', () async {
        // Arrange
        final task2 = Task.fromMap(TestFixtures.createTaskMap(
          id: 'task-2',
          title: 'Task 2',
        ));
        final task3 = Task.fromMap(TestFixtures.createTaskMap(
          id: 'task-3',
          title: 'Task 3',
        ));

        when(() => mockFolderRepo.getFoldersStream(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream('root-folder-123'))
            .thenAnswer((_) => Stream.value([testTask, task2, task3]));

        // Act
        final result = await service.buildFolderNode(
          testRootFolder,
          'list-123',
          testTodoList,
        );

        // Assert
        expect(result.children.length, 3);
        expect(result.children.every((node) => node.data?.type == NodeType.task), isTrue);
      });

      test('should handle multiple subfolders in folder', () async {
        // Arrange
        final subfolder2 = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'subfolder-2',
          title: 'Subfolder 2',
        ));
        final subfolder3 = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'subfolder-3',
          title: 'Subfolder 3',
        ));

        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'root-folder-123'))
            .thenAnswer((_) => Stream.value([testSubFolder, subfolder2, subfolder3]));
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'sub-folder-456'))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'subfolder-2'))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockFolderRepo.getFoldersStream('list-123', parentId: 'subfolder-3'))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTaskRepo.getTasksStream(any()))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final result = await service.buildFolderNode(
          testRootFolder,
          'list-123',
          testTodoList,
        );

        // Assert
        expect(result.children.length, 3);
        expect(result.children.every((node) => node.data?.type == NodeType.folder), isTrue);
      });
    });
  });
}
