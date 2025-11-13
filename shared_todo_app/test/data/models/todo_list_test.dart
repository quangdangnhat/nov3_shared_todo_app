import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/models/todo_list.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('TodoList Model Tests', () {
    late Map<String, dynamic> validTodoListMap;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 11, 13);
      validTodoListMap = TestFixtures.createTodoListMap(
        id: 'list-123',
        title: 'My Todo List',
        desc: 'A test todo list',
        role: 'admin',
        createdAt: testDate,
        updatedAt: testDate.add(const Duration(hours: 2)),
      );
    });

    test('should create TodoList from valid map with snake_case keys', () {
      // Act
      final todoList = TodoList.fromMap(validTodoListMap);

      // Assert
      expect(todoList.id, 'list-123');
      expect(todoList.title, 'My Todo List');
      expect(todoList.desc, 'A test todo list');
      expect(todoList.role, 'admin');
      expect(todoList.createdAt, isNotNull);
      expect(todoList.updatedAt, isNotNull);
    });

    test('should create TodoList from map with camelCase keys', () {
      // Arrange
      final camelCaseMap = {
        'id': 'list-456',
        'title': 'Camel Case List',
        'desc': 'Description',
        'role': 'collaborator',
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.add(const Duration(days: 1)).toIso8601String(),
      };

      // Act
      final todoList = TodoList.fromMap(camelCaseMap);

      // Assert
      expect(todoList.id, 'list-456');
      expect(todoList.title, 'Camel Case List');
      expect(todoList.role, 'collaborator');
    });

    test('should handle null description', () {
      // Arrange
      final mapWithoutDesc = TestFixtures.createTodoListMap(desc: null);
      mapWithoutDesc['desc'] = null;

      // Act
      final todoList = TodoList.fromMap(mapWithoutDesc);

      // Assert
      expect(todoList.desc, isNull);
      expect(todoList.title, isNotNull);
    });

    test('should handle null updatedAt', () {
      // Arrange
      final mapWithoutUpdate = TestFixtures.createTodoListMap(
        updatedAt: null,
      );
      mapWithoutUpdate.remove('updated_at');

      // Act
      final todoList = TodoList.fromMap(mapWithoutUpdate);

      // Assert
      expect(todoList.updatedAt, isNull);
      expect(todoList.createdAt, isNotNull);
    });

    test('should default role to "Unknown" if not provided', () {
      // Arrange
      final mapWithoutRole = TestFixtures.createTodoListMap();
      mapWithoutRole.remove('role');

      // Act
      final todoList = TodoList.fromMap(mapWithoutRole);

      // Assert
      expect(todoList.role, 'Unknown');
    });

    test('should convert TodoList to map correctly', () {
      // Arrange
      final todoList = TodoList.fromMap(validTodoListMap);

      // Act
      final map = todoList.toMap();

      // Assert
      expect(map['id'], 'list-123');
      expect(map['title'], 'My Todo List');
      expect(map['desc'], 'A test todo list');
      expect(map['created_at'], isNotNull);
      expect(map['updated_at'], isNotNull);
      // Note: role is not included in toMap() as per implementation
      expect(map.containsKey('role'), isFalse);
    });

    test('should handle different role values', () {
      // Test admin role
      final adminList = TodoList.fromMap(
        TestFixtures.createTodoListMap(role: 'admin'),
      );
      expect(adminList.role, 'admin');

      // Test collaborator role
      final collabList = TodoList.fromMap(
        TestFixtures.createTodoListMap(role: 'collaborator'),
      );
      expect(collabList.role, 'collaborator');

      // Test viewer role
      final viewerList = TodoList.fromMap(
        TestFixtures.createTodoListMap(role: 'viewer'),
      );
      expect(viewerList.role, 'viewer');
    });

    test('should parse dates correctly', () {
      // Arrange
      final specificDate = DateTime(2025, 3, 20, 14, 30);
      final listMap = TestFixtures.createTodoListMap(
        createdAt: specificDate,
        updatedAt: specificDate.add(const Duration(hours: 5)),
      );

      // Act
      final todoList = TodoList.fromMap(listMap);

      // Assert
      expect(todoList.createdAt.year, 2025);
      expect(todoList.createdAt.month, 3);
      expect(todoList.createdAt.day, 20);
      expect(todoList.updatedAt?.isAfter(todoList.createdAt), isTrue);
    });

    test('should create TodoList with minimal required fields', () {
      // Arrange
      final minimalMap = {
        'id': 'minimal-list',
        'title': 'Minimal List',
        'created_at': testDate.toIso8601String(),
      };

      // Act
      final todoList = TodoList.fromMap(minimalMap);

      // Assert
      expect(todoList.id, 'minimal-list');
      expect(todoList.title, 'Minimal List');
      expect(todoList.desc, isNull);
      expect(todoList.updatedAt, isNull);
      expect(todoList.role, 'Unknown');
    });

    // test('should throw FormatException for missing createdAt', () {
    //   // Arrange
    //   final invalidMap = TestFixtures.createTodoListMap();
    //   invalidMap.remove('created_at');
    //   invalidMap.remove('createdAt');

    //   // Act & Assert
    //   expect(
    //     () => TodoList.fromMap(invalidMap),
    //     throwsA(isA<FormatException>()),
    //   );
    // });

    test('should throw FormatException for invalid createdAt format', () {
      // Arrange
      final invalidMap = TestFixtures.createTodoListMap();
      invalidMap['created_at'] = 'not-a-valid-date';

      // Act & Assert
      expect(
        () => TodoList.fromMap(invalidMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should throw error for invalid updatedAt format', () {
      // Arrange
      final invalidMap = TestFixtures.createTodoListMap();
      invalidMap['updated_at'] = 'invalid-date-format';

      // Act & Assert
      expect(
        () => TodoList.fromMap(invalidMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should preserve all field values in round-trip serialization', () {
      // Arrange
      final todoList = TodoList.fromMap(validTodoListMap);

      // Act
      final map = todoList.toMap();
      final reconstructed = TodoList.fromMap({
        ...map,
        'role': todoList.role, // role is not in toMap, so add it manually
      });

      // Assert
      expect(reconstructed.id, todoList.id);
      expect(reconstructed.title, todoList.title);
      expect(reconstructed.desc, todoList.desc);
      expect(reconstructed.role, todoList.role);
      expect(reconstructed.createdAt.toIso8601String(),
          todoList.createdAt.toIso8601String());
      expect(reconstructed.updatedAt?.toIso8601String(),
          todoList.updatedAt?.toIso8601String());
    });

    test('should handle todo list with empty title', () {
      // Arrange
      final mapWithEmptyTitle = TestFixtures.createTodoListMap(title: '');

      // Act
      final todoList = TodoList.fromMap(mapWithEmptyTitle);

      // Assert
      expect(todoList.title, '');
      expect(todoList.title, isEmpty);
    });

    test('should handle todo list with very long title', () {
      // Arrange
      final longTitle = 'A' * 1000;
      final mapWithLongTitle = TestFixtures.createTodoListMap(title: longTitle);

      // Act
      final todoList = TodoList.fromMap(mapWithLongTitle);

      // Assert
      expect(todoList.title, longTitle);
      expect(todoList.title.length, 1000);
    });

    test('should handle todo list with special characters in title', () {
      // Arrange
      const specialTitle = 'List <>&"\' with émojis 📝';
      final mapWithSpecialTitle =
          TestFixtures.createTodoListMap(title: specialTitle);

      // Act
      final todoList = TodoList.fromMap(mapWithSpecialTitle);

      // Assert
      expect(todoList.title, specialTitle);
    });

    test('should handle todo list with empty description', () {
      // Arrange
      final mapWithEmptyDesc = TestFixtures.createTodoListMap(desc: '');

      // Act
      final todoList = TodoList.fromMap(mapWithEmptyDesc);

      // Assert
      expect(todoList.desc, '');
      expect(todoList.desc, isNotNull);
      expect(todoList.desc, isEmpty);
    });

    test('should handle todo list with very long description', () {
      // Arrange
      final longDesc = 'Description ' * 200;
      final mapWithLongDesc = TestFixtures.createTodoListMap(desc: longDesc);

      // Act
      final todoList = TodoList.fromMap(mapWithLongDesc);

      // Assert
      expect(todoList.desc, longDesc);
      expect(todoList.desc!.length, greaterThan(1000));
    });

    test('should handle todo list with special characters in description', () {
      // Arrange
      const specialDesc = 'Description with <>&"\' special chars and 中文 🌟';
      final mapWithSpecialDesc =
          TestFixtures.createTodoListMap(desc: specialDesc);

      // Act
      final todoList = TodoList.fromMap(mapWithSpecialDesc);

      // Assert
      expect(todoList.desc, specialDesc);
    });

    test('should handle todo list created in the past', () {
      // Arrange
      final pastDate = DateTime(2020, 1, 1);
      final mapWithPastDate = TestFixtures.createTodoListMap(
        createdAt: pastDate,
      );

      // Act
      final todoList = TodoList.fromMap(mapWithPastDate);

      // Assert
      expect(todoList.createdAt.isBefore(DateTime.now()), isTrue);
      expect(todoList.createdAt.year, 2020);
      expect(todoList.createdAt.month, 1);
    });

    test('should handle updatedAt after createdAt', () {
      // Arrange
      final createdDate = DateTime(2025, 1, 1);
      final updatedDate = createdDate.add(const Duration(days: 30));
      final listMap = TestFixtures.createTodoListMap(
        createdAt: createdDate,
        updatedAt: updatedDate,
      );

      // Act
      final todoList = TodoList.fromMap(listMap);

      // Assert
      expect(todoList.updatedAt!.isAfter(todoList.createdAt), isTrue);
      expect(todoList.updatedAt!.difference(todoList.createdAt).inDays, 30);
    });

    test('should handle ISO 8601 date strings correctly', () {
      // Arrange
      final date = DateTime(2025, 11, 13, 10, 30, 45);
      final isoString = date.toIso8601String();
      final mapWithIsoDate = TestFixtures.createTodoListMap(
        createdAt: DateTime.parse(isoString),
      );
      mapWithIsoDate['created_at'] = isoString;

      // Act
      final todoList = TodoList.fromMap(mapWithIsoDate);

      // Assert
      expect(todoList.createdAt.toIso8601String(), isoString);
    });

    test('should convert todo list with null fields to map', () {
      // Arrange
      final mapWithNulls = TestFixtures.createTodoListMap(
        desc: null,
        updatedAt: null,
      );
      mapWithNulls['desc'] = null;
      mapWithNulls.remove('updated_at');

      final todoList = TodoList.fromMap(mapWithNulls);

      // Act
      final map = todoList.toMap();

      // Assert
      expect(map['desc'], isNull);
      expect(map['updated_at'], isNull);
      expect(map['id'], isNotNull);
      expect(map['title'], isNotNull);
      expect(map['created_at'], isNotNull);
    });

    test('should create todo list with constructor directly', () {
      // Arrange & Act
      final todoList = TodoList(
        id: 'direct-123',
        title: 'Direct List',
        desc: 'Created directly',
        role: 'admin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(todoList.id, 'direct-123');
      expect(todoList.title, 'Direct List');
      expect(todoList.desc, 'Created directly');
      expect(todoList.role, 'admin');
      expect(todoList.createdAt, isNotNull);
      expect(todoList.updatedAt, isNotNull);
    });

    test('should create todo list without optional fields using constructor',
        () {
      // Arrange & Act
      final todoList = TodoList(
        id: 'minimal-123',
        title: 'Minimal List',
        role: 'collaborator',
        createdAt: DateTime.now(),
      );

      // Assert
      expect(todoList.id, 'minimal-123');
      expect(todoList.desc, isNull);
      expect(todoList.updatedAt, isNull);
      expect(todoList.role, 'collaborator');
    });

    test('should handle custom role values', () {
      // Arrange
      const customRole = 'owner';
      final mapWithCustomRole =
          TestFixtures.createTodoListMap(role: customRole);

      // Act
      final todoList = TodoList.fromMap(mapWithCustomRole);

      // Assert
      expect(todoList.role, customRole);
    });

    test('should handle multiple todo lists with same title', () {
      // Arrange
      final list1Map = TestFixtures.createTodoListMap(
        id: 'list-1',
        title: 'Shared Title',
      );

      final list2Map = TestFixtures.createTodoListMap(
        id: 'list-2',
        title: 'Shared Title',
      );

      // Act
      final list1 = TodoList.fromMap(list1Map);
      final list2 = TodoList.fromMap(list2Map);

      // Assert
      expect(list1.title, list2.title);
      expect(list1.id, isNot(list2.id));
    });

    test('should handle unicode and emoji in title', () {
      // Arrange
      const unicodeTitle = 'Lista 任务 📋 ✓';
      final mapWithUnicode =
          TestFixtures.createTodoListMap(title: unicodeTitle);

      // Act
      final todoList = TodoList.fromMap(mapWithUnicode);

      // Assert
      expect(todoList.title, unicodeTitle);
    });

    test('should handle newlines in description', () {
      // Arrange
      const descWithNewlines = 'Line 1\nLine 2\nLine 3';
      final mapWithNewlines =
          TestFixtures.createTodoListMap(desc: descWithNewlines);

      // Act
      final todoList = TodoList.fromMap(mapWithNewlines);

      // Assert
      expect(todoList.desc, descWithNewlines);
      expect(todoList.desc!.split('\n').length, 3);
    });
  });
}
