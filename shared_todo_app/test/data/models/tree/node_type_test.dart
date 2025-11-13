import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/models/tree/node_type.dart';

void main() {
  group('NodeType Tests', () {
    group('canHaveChildren', () {
      test('todoList should be able to have children', () {
        expect(NodeType.todoList.canHaveChildren, isTrue);
      });

      test('folder should be able to have children', () {
        expect(NodeType.folder.canHaveChildren, isTrue);
      });

      test('task should not be able to have children', () {
        expect(NodeType.task.canHaveChildren, isFalse);
      });
    });

    group('isNavigable', () {
      test('todoList should be navigable', () {
        expect(NodeType.todoList.isNavigable, isTrue);
      });

      test('folder should be navigable', () {
        expect(NodeType.folder.isNavigable, isTrue);
      });

      test('task should not be navigable', () {
        expect(NodeType.task.isNavigable, isFalse);
      });
    });

    group('displayName', () {
      test('todoList should return "Lista"', () {
        expect(NodeType.todoList.displayName, 'Lista');
      });

      test('folder should return "Cartella"', () {
        expect(NodeType.folder.displayName, 'Cartella');
      });

      test('task should return "Task"', () {
        expect(NodeType.task.displayName, 'Task');
      });
    });

    group('Enum Values', () {
      test('should have exactly 3 values', () {
        expect(NodeType.values.length, 3);
      });

      test('should contain all expected values', () {
        expect(NodeType.values, contains(NodeType.todoList));
        expect(NodeType.values, contains(NodeType.folder));
        expect(NodeType.values, contains(NodeType.task));
      });

      test('should be able to compare enum values', () {
        expect(NodeType.todoList == NodeType.todoList, isTrue);
        expect(NodeType.todoList == NodeType.folder, isFalse);
        expect(NodeType.folder == NodeType.task, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should maintain consistent behavior across multiple calls', () {
        // Test that properties don't change
        expect(NodeType.task.canHaveChildren, isFalse);
        expect(NodeType.task.canHaveChildren, isFalse);
        expect(NodeType.task.canHaveChildren, isFalse);
      });

      test('should work in switch statements', () {
        String getDescription(NodeType type) {
          switch (type) {
            case NodeType.todoList:
              return 'list';
            case NodeType.folder:
              return 'folder';
            case NodeType.task:
              return 'task';
          }
        }

        expect(getDescription(NodeType.todoList), 'list');
        expect(getDescription(NodeType.folder), 'folder');
        expect(getDescription(NodeType.task), 'task');
      });

      test('should be usable in collections', () {
        final navigableTypes = NodeType.values
            .where((type) => type.isNavigable)
            .toList();

        expect(navigableTypes.length, 2);
        expect(navigableTypes, contains(NodeType.todoList));
        expect(navigableTypes, contains(NodeType.folder));
        expect(navigableTypes, isNot(contains(NodeType.task)));
      });

      test('should be usable as map keys', () {
        final map = {
          NodeType.todoList: 'List',
          NodeType.folder: 'Folder',
          NodeType.task: 'Task',
        };

        expect(map[NodeType.todoList], 'List');
        expect(map[NodeType.folder], 'Folder');
        expect(map[NodeType.task], 'Task');
      });
    });
  });
}
