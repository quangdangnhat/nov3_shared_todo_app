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

    test('should throw FormatException for missing createdAt', () {
      // Arrange
      final invalidMap = TestFixtures.createFolderMap();
      invalidMap.remove('created_at');
      invalidMap.remove('createdAt');

      // Act & Assert
      expect(
        () => Folder.fromMap(invalidMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should throw FormatException for invalid createdAt format', () {
      // Arrange
      final invalidMap = TestFixtures.createFolderMap();
      invalidMap['created_at'] = 'not-a-date';

      // Act & Assert
      expect(
        () => Folder.fromMap(invalidMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should throw error for invalid updatedAt format', () {
      // Arrange
      final invalidMap = TestFixtures.createFolderMap();
      invalidMap['updated_at'] = 'invalid-date-format';

      // Act & Assert
      expect(
        () => Folder.fromMap(invalidMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should preserve all field values in round-trip serialization', () {
      // Arrange
      final folder = Folder.fromMap(validFolderMap);

      // Act
      final map = folder.toMap();
      final reconstructed = Folder.fromMap(map);

      // Assert
      expect(reconstructed.id, folder.id);
      expect(reconstructed.todoListId, folder.todoListId);
      expect(reconstructed.title, folder.title);
      expect(reconstructed.parentId, folder.parentId);
      expect(reconstructed.createdAt.toIso8601String(),
          folder.createdAt.toIso8601String());
      expect(reconstructed.updatedAt?.toIso8601String(),
          folder.updatedAt?.toIso8601String());
    });

    test('should handle folder with empty title', () {
      // Arrange
      final mapWithEmptyTitle = TestFixtures.createFolderMap(title: '');

      // Act
      final folder = Folder.fromMap(mapWithEmptyTitle);

      // Assert
      expect(folder.title, '');
      expect(folder.title, isEmpty);
    });

    test('should handle folder with very long title', () {
      // Arrange
      final longTitle = 'A' * 500;
      final mapWithLongTitle = TestFixtures.createFolderMap(title: longTitle);

      // Act
      final folder = Folder.fromMap(mapWithLongTitle);

      // Assert
      expect(folder.title, longTitle);
      expect(folder.title.length, 500);
    });

    test('should handle folder with special characters in title', () {
      // Arrange
      const specialTitle = 'Folder <>&"\' émoji 📁';
      final mapWithSpecialTitle =
          TestFixtures.createFolderMap(title: specialTitle);

      // Act
      final folder = Folder.fromMap(mapWithSpecialTitle);

      // Assert
      expect(folder.title, specialTitle);
    });

    test('should handle folder created in the past', () {
      // Arrange
      final pastDate = DateTime(2020, 6, 15);
      final mapWithPastDate = TestFixtures.createFolderMap(createdAt: pastDate);

      // Act
      final folder = Folder.fromMap(mapWithPastDate);

      // Assert
      expect(folder.createdAt.isBefore(DateTime.now()), isTrue);
      expect(folder.createdAt.year, 2020);
      expect(folder.createdAt.month, 6);
    });

    test('should convert folder with null fields to map', () {
      // Arrange
      final mapWithNulls = TestFixtures.createFolderMap(
        parentId: null,
        updatedAt: null,
      );
      mapWithNulls['parent_id'] = null;
      mapWithNulls.remove('updated_at');

      final folder = Folder.fromMap(mapWithNulls);

      // Act
      final map = folder.toMap();

      // Assert
      expect(map['parent_id'], isNull);
      expect(map['updated_at'], isNull);
      expect(map['id'], isNotNull);
      expect(map['title'], isNotNull);
      expect(map['todo_list_id'], isNotNull);
      expect(map['created_at'], isNotNull);
    });

    test('should handle ISO 8601 date strings correctly', () {
      // Arrange
      final date = DateTime(2025, 11, 13, 14, 30, 45);
      final isoString = date.toIso8601String();
      final mapWithIsoDate = TestFixtures.createFolderMap(
        createdAt: DateTime.parse(isoString),
      );
      mapWithIsoDate['created_at'] = isoString;

      // Act
      final folder = Folder.fromMap(mapWithIsoDate);

      // Assert
      expect(folder.createdAt.toIso8601String(), isoString);
    });

    test('should create folder with constructor directly', () {
      // Arrange & Act
      final folder = Folder(
        id: 'direct-123',
        todoListId: 'list-456',
        title: 'Direct Folder',
        parentId: 'parent-789',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(folder.id, 'direct-123');
      expect(folder.todoListId, 'list-456');
      expect(folder.title, 'Direct Folder');
      expect(folder.parentId, 'parent-789');
      expect(folder.createdAt, isNotNull);
      expect(folder.updatedAt, isNotNull);
    });

    test('should create folder without optional fields using constructor', () {
      // Arrange & Act
      final folder = Folder(
        id: 'minimal-123',
        todoListId: 'list-456',
        title: 'Minimal Folder',
        createdAt: DateTime.now(),
      );

      // Assert
      expect(folder.id, 'minimal-123');
      expect(folder.parentId, isNull);
      expect(folder.updatedAt, isNull);
    });

    test('should handle deep folder nesting', () {
      // Create multiple levels of folders
      final level1Map = TestFixtures.createFolderMap(
        id: 'level-1',
        parentId: null,
        title: 'Level 1',
      );
      level1Map['parent_id'] = null;

      final level2Map = TestFixtures.createFolderMap(
        id: 'level-2',
        parentId: 'level-1',
        title: 'Level 2',
      );

      final level3Map = TestFixtures.createFolderMap(
        id: 'level-3',
        parentId: 'level-2',
        title: 'Level 3',
      );

      // Act
      final level1 = Folder.fromMap(level1Map);
      final level2 = Folder.fromMap(level2Map);
      final level3 = Folder.fromMap(level3Map);

      // Assert
      expect(level1.parentId, isNull);
      expect(level2.parentId, level1.id);
      expect(level3.parentId, level2.id);
    });

    test('should handle folder in different todo lists', () {
      // Arrange
      final folder1Map = TestFixtures.createFolderMap(
        id: 'folder-1',
        todoListId: 'list-1',
      );

      final folder2Map = TestFixtures.createFolderMap(
        id: 'folder-2',
        todoListId: 'list-2',
      );

      // Act
      final folder1 = Folder.fromMap(folder1Map);
      final folder2 = Folder.fromMap(folder2Map);

      // Assert
      expect(folder1.todoListId, 'list-1');
      expect(folder2.todoListId, 'list-2');
      expect(folder1.todoListId, isNot(folder2.todoListId));
    });

    test('should handle updatedAt after createdAt', () {
      // Arrange
      final createdDate = DateTime(2025, 1, 1);
      final updatedDate = createdDate.add(const Duration(days: 10));
      final folderMap = TestFixtures.createFolderMap(
        createdAt: createdDate,
        updatedAt: updatedDate,
      );

      // Act
      final folder = Folder.fromMap(folderMap);

      // Assert
      expect(folder.updatedAt!.isAfter(folder.createdAt), isTrue);
      expect(folder.updatedAt!.difference(folder.createdAt).inDays, 10);
    });

    test('should handle same id in different todo lists', () {
      // This might be valid in different lists
      // Arrange
      final folder1Map = TestFixtures.createFolderMap(
        id: 'same-id',
        todoListId: 'list-1',
        title: 'Folder in List 1',
      );

      final folder2Map = TestFixtures.createFolderMap(
        id: 'same-id',
        todoListId: 'list-2',
        title: 'Folder in List 2',
      );

      // Act
      final folder1 = Folder.fromMap(folder1Map);
      final folder2 = Folder.fromMap(folder2Map);

      // Assert
      expect(folder1.id, folder2.id);
      expect(folder1.todoListId, isNot(folder2.todoListId));
      expect(folder1.title, isNot(folder2.title));
    });
  });
}
