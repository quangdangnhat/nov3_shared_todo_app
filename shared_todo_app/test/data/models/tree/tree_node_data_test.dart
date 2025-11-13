import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/models/folder.dart';
import 'package:shared_todo_app/data/models/todo_list.dart';
import 'package:shared_todo_app/data/models/tree/node_type.dart';
import 'package:shared_todo_app/data/models/tree/tree_node_data.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  group('TreeNodeData Tests', () {
    late TodoList testTodoList;
    late Folder testFolder;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 11, 13);
      testTodoList = TodoList.fromMap(TestFixtures.createTodoListMap(
        id: 'list-123',
        title: 'Test List',
        role: 'admin',
      ));
      testFolder = Folder.fromMap(TestFixtures.createFolderMap(
        id: 'folder-456',
        todoListId: 'list-123',
        title: 'Test Folder',
        parentId: null,
      ));
    });

    group('fromTodoList', () {
      test('should create TreeNodeData from TodoList', () {
        // Act
        final nodeData = TreeNodeData.fromTodoList(testTodoList);

        // Assert
        expect(nodeData.id, 'list-123');
        expect(nodeData.name, 'Test List');
        expect(nodeData.type, NodeType.todoList);
        expect(nodeData.todoList, testTodoList);
        expect(nodeData.parentId, isNull);
        expect(nodeData.todoListId, isNull);
        expect(nodeData.folder, isNull);
      });

      test('should preserve TodoList reference', () {
        // Act
        final nodeData = TreeNodeData.fromTodoList(testTodoList);

        // Assert
        expect(nodeData.todoList?.id, testTodoList.id);
        expect(nodeData.todoList?.title, testTodoList.title);
      });
    });

    group('fromFolder', () {
      test('should create TreeNodeData from Folder', () {
        // Act
        final nodeData = TreeNodeData.fromFolder(
          testFolder,
          'list-123',
          testTodoList,
        );

        // Assert
        expect(nodeData.id, 'folder-456');
        expect(nodeData.name, 'Test Folder');
        expect(nodeData.type, NodeType.folder);
        expect(nodeData.folder, testFolder);
        expect(nodeData.todoListId, 'list-123');
        expect(nodeData.todoList, testTodoList);
        expect(nodeData.parentId, isNull);
      });

      test('should preserve parent folder id', () {
        // Arrange
        final subFolder = Folder.fromMap(TestFixtures.createFolderMap(
          id: 'subfolder-789',
          todoListId: 'list-123',
          title: 'Sub Folder',
          parentId: 'folder-456',
        ));

        // Act
        final nodeData = TreeNodeData.fromFolder(
          subFolder,
          'list-123',
          testTodoList,
        );

        // Assert
        expect(nodeData.parentId, 'folder-456');
      });

      test('should preserve Folder and TodoList references', () {
        // Act
        final nodeData = TreeNodeData.fromFolder(
          testFolder,
          'list-123',
          testTodoList,
        );

        // Assert
        expect(nodeData.folder?.id, testFolder.id);
        expect(nodeData.todoList?.id, testTodoList.id);
      });
    });

    group('fromTask', () {
      test('should create TreeNodeData from Task', () {
        // Act
        final nodeData = TreeNodeData.fromTask(
          'task-789',
          'Test Task',
          'list-123',
          testTodoList,
        );

        // Assert
        expect(nodeData.id, 'task-789');
        expect(nodeData.name, 'Test Task');
        expect(nodeData.type, NodeType.task);
        expect(nodeData.todoListId, 'list-123');
        expect(nodeData.todoList, testTodoList);
        expect(nodeData.parentId, isNull);
        expect(nodeData.folder, isNull);
      });

      test('should preserve TodoList reference', () {
        // Act
        final nodeData = TreeNodeData.fromTask(
          'task-789',
          'Test Task',
          'list-123',
          testTodoList,
        );

        // Assert
        expect(nodeData.todoList?.id, testTodoList.id);
      });
    });

    group('copyWith', () {
      test('should copy with new id', () {
        // Arrange
        final original = TreeNodeData.fromTodoList(testTodoList);

        // Act
        final copied = original.copyWith(id: 'new-id');

        // Assert
        expect(copied.id, 'new-id');
        expect(copied.name, original.name);
        expect(copied.type, original.type);
      });

      test('should copy with new name', () {
        // Arrange
        final original = TreeNodeData.fromTodoList(testTodoList);

        // Act
        final copied = original.copyWith(name: 'New Name');

        // Assert
        expect(copied.name, 'New Name');
        expect(copied.id, original.id);
        expect(copied.type, original.type);
      });

      test('should copy with new type', () {
        // Arrange
        final original = TreeNodeData.fromTodoList(testTodoList);

        // Act
        final copied = original.copyWith(type: NodeType.folder);

        // Assert
        expect(copied.type, NodeType.folder);
        expect(copied.id, original.id);
        expect(copied.name, original.name);
      });

      test('should copy multiple properties', () {
        // Arrange
        final original = TreeNodeData.fromTodoList(testTodoList);

        // Act
        final copied = original.copyWith(
          id: 'new-id',
          name: 'New Name',
          parentId: 'parent-123',
        );

        // Assert
        expect(copied.id, 'new-id');
        expect(copied.name, 'New Name');
        expect(copied.parentId, 'parent-123');
      });

      test('should preserve unchanged properties', () {
        // Arrange
        final original = TreeNodeData.fromFolder(
          testFolder,
          'list-123',
          testTodoList,
        );

        // Act
        final copied = original.copyWith(name: 'Updated Name');

        // Assert
        expect(copied.name, 'Updated Name');
        expect(copied.id, original.id);
        expect(copied.type, original.type);
        expect(copied.folder, original.folder);
        expect(copied.todoList, original.todoList);
      });
    });

    group('Equality', () {
      test('should be equal with same id and type', () {
        // Arrange
        final node1 = TreeNodeData.fromTodoList(testTodoList);
        final node2 = TreeNodeData.fromTodoList(testTodoList);

        // Assert
        expect(node1 == node2, isTrue);
        expect(node1.hashCode, node2.hashCode);
      });

      test('should not be equal with different id', () {
        // Arrange
        final node1 = TreeNodeData.fromTodoList(testTodoList);
        final node2 = node1.copyWith(id: 'different-id');

        // Assert
        expect(node1 == node2, isFalse);
      });

      test('should not be equal with different type', () {
        // Arrange
        final node1 = TreeNodeData.fromTodoList(testTodoList);
        final node2 = node1.copyWith(type: NodeType.folder);

        // Assert
        expect(node1 == node2, isFalse);
      });

      test('should be equal to itself', () {
        // Arrange
        final node = TreeNodeData.fromTodoList(testTodoList);

        // Assert
        expect(node == node, isTrue);
        expect(identical(node, node), isTrue);
      });

      test('should have consistent hashCode', () {
        // Arrange
        final node1 = TreeNodeData.fromTodoList(testTodoList);
        final node2 = TreeNodeData.fromTodoList(testTodoList);

        // Assert
        expect(node1.hashCode, node2.hashCode);
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        // Arrange
        final node = TreeNodeData.fromTodoList(testTodoList);

        // Act
        final string = node.toString();

        // Assert
        expect(string, contains('list-123'));
        expect(string, contains('Test List'));
        expect(string, contains('NodeType.todoList'));
      });

      test('should include all key properties', () {
        // Arrange
        final node = TreeNodeData.fromTask(
          'task-123',
          'My Task',
          'list-456',
          testTodoList,
        );

        // Act
        final string = node.toString();

        // Assert
        expect(string, contains('task-123'));
        expect(string, contains('My Task'));
        expect(string, contains('NodeType.task'));
      });
    });

    group('Immutability', () {
      test('should be immutable', () {
        // Arrange
        final original = TreeNodeData.fromTodoList(testTodoList);

        // Act
        final copied = original.copyWith(name: 'Modified');

        // Assert
        expect(original.name, 'Test List'); // Original unchanged
        expect(copied.name, 'Modified'); // Copy changed
      });

      test('should create new instances with copyWith', () {
        // Arrange
        final original = TreeNodeData.fromTodoList(testTodoList);

        // Act
        final copied = original.copyWith(id: 'new-id');

        // Assert
        expect(identical(original, copied), isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle empty name', () {
        // Arrange
        final emptyTodoList = TodoList.fromMap(
          TestFixtures.createTodoListMap(title: ''),
        );

        // Act
        final node = TreeNodeData.fromTodoList(emptyTodoList);

        // Assert
        expect(node.name, isEmpty);
      });

      test('should work in collections', () {
        // Arrange
        final node1 = TreeNodeData.fromTodoList(testTodoList);
        final node2 = TreeNodeData.fromFolder(
          testFolder,
          'list-123',
          testTodoList,
        );

        // Act
        final list = [node1, node2];
        final set = {node1, node2};

        // Assert
        expect(list.length, 2);
        expect(set.length, 2);
      });

      test('should be usable as map keys', () {
        // Arrange
        final node = TreeNodeData.fromTodoList(testTodoList);
        final map = {node: 'value'};

        // Assert
        expect(map[node], 'value');
      });
    });
  });
}
