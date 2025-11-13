import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/models/tree/tree_data_cache_service.dart';
import '../../../helpers/test_fixtures.dart';
import 'package:shared_todo_app/data/models/folder.dart';
import 'package:shared_todo_app/data/models/task.dart';

void main() {
  group('TreeDataCacheService Tests', () {
    late TreeDataCacheService cache;
    late Folder testFolder;
    late Task testTask;

    setUp(() {
      cache = TreeDataCacheService();
      testFolder = Folder.fromMap(TestFixtures.createFolderMap(
        id: 'folder-123',
        todoListId: 'list-456',
        title: 'Test Folder',
      ));
      testTask = Task.fromMap(TestFixtures.createTaskMap(
        id: 'task-789',
        folderId: 'folder-123',
        title: 'Test Task',
      ));
    });

    group('Root Folders', () {
      test('should set and get root folder', () {
        // Act
        cache.setRootFolder('list-123', testFolder);
        final result = cache.getRootFolder('list-123');

        // Assert
        expect(result, testFolder);
        expect(result?.id, 'folder-123');
      });

      test('should return null for non-existent root folder', () {
        // Act
        final result = cache.getRootFolder('non-existent');

        // Assert
        expect(result, isNull);
      });

      test('should check if root folder exists', () {
        // Arrange
        cache.setRootFolder('list-123', testFolder);

        // Assert
        expect(cache.hasRootFolder('list-123'), isTrue);
        expect(cache.hasRootFolder('non-existent'), isFalse);
      });

      test('should overwrite existing root folder', () {
        // Arrange
        final folder1 = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'folder-1',
          title: 'Folder 1',
        ));
        final folder2 = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'folder-2',
          title: 'Folder 2',
        ));

        // Act
        cache.setRootFolder('list-123', folder1);
        cache.setRootFolder('list-123', folder2);
        final result = cache.getRootFolder('list-123');

        // Assert
        expect(result?.id, 'folder-2');
      });

      test('should clear all root folders', () {
        // Arrange
        cache.setRootFolder('list-1', testFolder);
        cache.setRootFolder('list-2', testFolder);

        // Act
        cache.clearRootFolders();

        // Assert
        expect(cache.hasRootFolder('list-1'), isFalse);
        expect(cache.hasRootFolder('list-2'), isFalse);
      });
    });

    group('Sub Folders', () {
      test('should set and get sub folders', () {
        // Arrange
        final subFolders = [testFolder];

        // Act
        cache.setSubFolders('parent-123', subFolders);
        final result = cache.getSubFolders('parent-123');

        // Assert
        expect(result, subFolders);
        expect(result?.length, 1);
      });

      test('should return null for non-existent sub folders', () {
        // Act
        final result = cache.getSubFolders('non-existent');

        // Assert
        expect(result, isNull);
      });

      test('should check if sub folders exist', () {
        // Arrange
        cache.setSubFolders('parent-123', [testFolder]);

        // Assert
        expect(cache.hasSubFolders('parent-123'), isTrue);
        expect(cache.hasSubFolders('non-existent'), isFalse);
      });

      test('should handle empty sub folders list', () {
        // Act
        cache.setSubFolders('parent-123', []);
        final result = cache.getSubFolders('parent-123');

        // Assert
        expect(result, isEmpty);
        expect(cache.hasSubFolders('parent-123'), isTrue);
      });

      test('should overwrite existing sub folders', () {
        // Arrange
        final folders1 = [testFolder];
        final folder2 = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'folder-new',
          title: 'New Folder',
        ));
        final folders2 = [folder2];

        // Act
        cache.setSubFolders('parent-123', folders1);
        cache.setSubFolders('parent-123', folders2);
        final result = cache.getSubFolders('parent-123');

        // Assert
        expect(result?.length, 1);
        expect(result?[0].id, 'folder-new');
      });

      test('should clear all sub folders', () {
        // Arrange
        cache.setSubFolders('parent-1', [testFolder]);
        cache.setSubFolders('parent-2', [testFolder]);

        // Act
        cache.clearSubFolders();

        // Assert
        expect(cache.hasSubFolders('parent-1'), isFalse);
        expect(cache.hasSubFolders('parent-2'), isFalse);
      });
    });

    group('Tasks', () {
      test('should set and get tasks', () {
        // Arrange
        final tasks = [testTask];

        // Act
        cache.setTasks('folder-123', tasks);
        final result = cache.getTasks('folder-123');

        // Assert
        expect(result, tasks);
        expect(result?.length, 1);
      });

      test('should return null for non-existent tasks', () {
        // Act
        final result = cache.getTasks('non-existent');

        // Assert
        expect(result, isNull);
      });

      test('should check if tasks exist', () {
        // Arrange
        cache.setTasks('folder-123', [testTask]);

        // Assert
        expect(cache.hasTasks('folder-123'), isTrue);
        expect(cache.hasTasks('non-existent'), isFalse);
      });

      test('should handle empty tasks list', () {
        // Act
        cache.setTasks('folder-123', []);
        final result = cache.getTasks('folder-123');

        // Assert
        expect(result, isEmpty);
        expect(cache.hasTasks('folder-123'), isTrue);
      });

      test('should overwrite existing tasks', () {
        // Arrange
        final tasks1 = [testTask];
        final task2 = Task.fromMap(TestFixtures.createTaskMap(
          id: 'task-new',
          title: 'New Task',
        ));
        final tasks2 = [task2];

        // Act
        cache.setTasks('folder-123', tasks1);
        cache.setTasks('folder-123', tasks2);
        final result = cache.getTasks('folder-123');

        // Assert
        expect(result?.length, 1);
        expect(result?[0].id, 'task-new');
      });

      test('should clear all tasks', () {
        // Arrange
        cache.setTasks('folder-1', [testTask]);
        cache.setTasks('folder-2', [testTask]);

        // Act
        cache.clearTasks();

        // Assert
        expect(cache.hasTasks('folder-1'), isFalse);
        expect(cache.hasTasks('folder-2'), isFalse);
      });
    });

    group('Cache Management', () {
      test('should clear all cache data', () {
        // Arrange
        cache.setRootFolder('list-123', testFolder);
        cache.setSubFolders('parent-123', [testFolder]);
        cache.setTasks('folder-123', [testTask]);

        // Act
        cache.clear();

        // Assert
        expect(cache.hasRootFolder('list-123'), isFalse);
        expect(cache.hasSubFolders('parent-123'), isFalse);
        expect(cache.hasTasks('folder-123'), isFalse);
      });

      test('should return correct cache size', () {
        // Arrange
        cache.setRootFolder('list-1', testFolder);
        cache.setRootFolder('list-2', testFolder);
        cache.setSubFolders('parent-1', [testFolder]);
        cache.setTasks('folder-1', [testTask]);

        // Act
        final size = cache.cacheSize;

        // Assert
        expect(size, 4); // 2 root + 1 sub + 1 tasks
      });

      test('should return zero cache size when empty', () {
        // Act
        final size = cache.cacheSize;

        // Assert
        expect(size, 0);
      });

      test('should return correct cache stats', () {
        // Arrange
        cache.setRootFolder('list-1', testFolder);
        cache.setRootFolder('list-2', testFolder);
        cache.setSubFolders('parent-1', [testFolder]);
        cache.setSubFolders('parent-2', [testFolder]);
        cache.setTasks('folder-1', [testTask]);

        // Act
        final stats = cache.cacheStats;

        // Assert
        expect(stats['rootFolders'], 2);
        expect(stats['subFolders'], 2);
        expect(stats['tasks'], 1);
      });

      test('should return zero stats when empty', () {
        // Act
        final stats = cache.cacheStats;

        // Assert
        expect(stats['rootFolders'], 0);
        expect(stats['subFolders'], 0);
        expect(stats['tasks'], 0);
      });
    });

    group('Multiple Items', () {
      test('should handle multiple root folders', () {
        // Arrange
        final folder1 = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'folder-1',
          title: 'Folder 1',
        ));
        final folder2 = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'folder-2',
          title: 'Folder 2',
        ));

        // Act
        cache.setRootFolder('list-1', folder1);
        cache.setRootFolder('list-2', folder2);

        // Assert
        expect(cache.getRootFolder('list-1')?.id, 'folder-1');
        expect(cache.getRootFolder('list-2')?.id, 'folder-2');
      });

      test('should handle multiple sub folders for different parents', () {
        // Arrange
        final folders1 = [testFolder];
        final folder2 = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'folder-different',
          title: 'Different',
        ));
        final folders2 = [folder2];

        // Act
        cache.setSubFolders('parent-1', folders1);
        cache.setSubFolders('parent-2', folders2);

        // Assert
        expect(cache.getSubFolders('parent-1')?[0].id, 'folder-123');
        expect(cache.getSubFolders('parent-2')?[0].id, 'folder-different');
      });

      test('should handle multiple tasks for different folders', () {
        // Arrange
        final tasks1 = [testTask];
        final task2 = Task.fromMap(TestFixtures.createTaskMap(
          id: 'task-different',
          title: 'Different Task',
        ));
        final tasks2 = [task2];

        // Act
        cache.setTasks('folder-1', tasks1);
        cache.setTasks('folder-2', tasks2);

        // Assert
        expect(cache.getTasks('folder-1')?[0].id, 'task-789');
        expect(cache.getTasks('folder-2')?[0].id, 'task-different');
      });
    });

    group('Edge Cases', () {
      test('should handle cache after clear and re-populate', () {
        // Arrange
        cache.setRootFolder('list-123', testFolder);
        cache.clear();

        // Act
        cache.setRootFolder('list-123', testFolder);
        final result = cache.getRootFolder('list-123');

        // Assert
        expect(result, isNotNull);
      });

      test('should handle selective clearing', () {
        // Arrange
        cache.setRootFolder('list-123', testFolder);
        cache.setSubFolders('parent-123', [testFolder]);
        cache.setTasks('folder-123', [testTask]);

        // Act
        cache.clearRootFolders();

        // Assert
        expect(cache.hasRootFolder('list-123'), isFalse);
        expect(cache.hasSubFolders('parent-123'), isTrue);
        expect(cache.hasTasks('folder-123'), isTrue);
      });

      test('should handle large number of items', () {
        // Arrange
        for (int i = 0; i < 100; i++) {
          cache.setRootFolder('list-$i', testFolder);
          cache.setSubFolders('parent-$i', [testFolder]);
          cache.setTasks('folder-$i', [testTask]);
        }

        // Assert
        expect(cache.cacheSize, 300);
      });
    });
  });
}
