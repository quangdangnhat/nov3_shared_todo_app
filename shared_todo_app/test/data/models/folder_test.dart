import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/models/folder.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('Folder Model Tests', () {
    late Map<String, dynamic> validFolderMap;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 11, 13);
      validFolderMap = TestFixtures.createFolderMap(
        id: 'folder-123',
        todoListId: 'list-456',
        title: 'Test Folder',
        parentId: 'parent-789',
        createdAt: testDate,
        updatedAt: testDate.add(const Duration(hours: 1)),
      );
    });

    test('should create Folder from valid map with snake_case keys', () {
      // Act
      final folder = Folder.fromMap(validFolderMap);

      // Assert
      expect(folder.id, 'folder-123');
      expect(folder.todoListId, 'list-456');
      expect(folder.title, 'Test Folder');
      expect(folder.parentId, 'parent-789');
      expect(folder.createdAt, isNotNull);
      expect(folder.updatedAt, isNotNull);
    });

    test('should create Folder from map with camelCase keys', () {
      // Arrange
      final camelCaseMap = {
        'id': 'folder-123',
        'todoListId': 'list-456',
        'title': 'Camel Case Folder',
        'parentId': 'parent-789',
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.add(const Duration(hours: 1)).toIso8601String(),
      };

      // Act
      final folder = Folder.fromMap(camelCaseMap);

      // Assert
      expect(folder.id, 'folder-123');
      expect(folder.todoListId, 'list-456');
      expect(folder.title, 'Camel Case Folder');
      expect(folder.parentId, 'parent-789');
    });

    test('should handle null parentId (root folder)', () {
      // Arrange
      final rootFolderMap = TestFixtures.createFolderMap(
        id: 'root-folder',
        parentId: null,
      );
      rootFolderMap['parent_id'] = null;

      // Act
      final folder = Folder.fromMap(rootFolderMap);

      // Assert
      expect(folder.id, 'root-folder');
      expect(folder.parentId, isNull);
      expect(folder.title, isNotNull);
    });

    test('should handle null updatedAt', () {
      // Arrange
      final folderWithoutUpdate = TestFixtures.createFolderMap(
        updatedAt: null,
      );
      folderWithoutUpdate.remove('updated_at');

      // Act
      final folder = Folder.fromMap(folderWithoutUpdate);

      // Assert
      expect(folder.updatedAt, isNull);
      expect(folder.createdAt, isNotNull);
    });

    test('should convert Folder to map correctly', () {
      // Arrange
      final folder = Folder.fromMap(validFolderMap);

      // Act
      final map = folder.toMap();

      // Assert
      expect(map['id'], 'folder-123');
      expect(map['todo_list_id'], 'list-456');
      expect(map['title'], 'Test Folder');
      expect(map['parent_id'], 'parent-789');
      expect(map['created_at'], isNotNull);
      expect(map['updated_at'], isNotNull);
    });

    test('should convert root folder to map with null parent_id', () {
      // Arrange
      final rootFolderMap = TestFixtures.createFolderMap(parentId: null);
      rootFolderMap['parent_id'] = null;
      final folder = Folder.fromMap(rootFolderMap);

      // Act
      final map = folder.toMap();

      // Assert
      expect(map['parent_id'], isNull);
    });

    test('should parse createdAt date correctly', () {
      // Arrange
      final specificDate = DateTime(2025, 1, 15, 10, 30);
      final folderMap = TestFixtures.createFolderMap(
        createdAt: specificDate,
      );

      // Act
      final folder = Folder.fromMap(folderMap);

      // Assert
      expect(folder.createdAt.year, 2025);
      expect(folder.createdAt.month, 1);
      expect(folder.createdAt.day, 15);
    });

    test('should create subfolder with valid parentId', () {
      // Arrange
      final subfolderMap = TestFixtures.createFolderMap(
        id: 'subfolder-1',
        parentId: 'parent-folder-1',
        title: 'Subfolder',
      );

      // Act
      final subfolder = Folder.fromMap(subfolderMap);

      // Assert
      expect(subfolder.id, 'subfolder-1');
      expect(subfolder.parentId, 'parent-folder-1');
      expect(subfolder.title, 'Subfolder');
    });

    test('should handle folder hierarchy', () {
      // Create a root folder
      final rootMap = TestFixtures.createFolderMap(
        id: 'root',
        parentId: null,
        title: 'Root',
      );
      rootMap['parent_id'] = null;

      // Create a child folder
      final childMap = TestFixtures.createFolderMap(
        id: 'child',
        parentId: 'root',
        title: 'Child',
      );

      // Act
      final root = Folder.fromMap(rootMap);
      final child = Folder.fromMap(childMap);

      // Assert
      expect(root.parentId, isNull);
      expect(child.parentId, 'root');
      expect(child.parentId, equals(root.id));
    });
  });
}
