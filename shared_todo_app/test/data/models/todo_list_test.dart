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
  });
}
