import 'package:flutter/foundation.dart';
import '../../../../data/models/todo_list.dart';
import '../../../../data/models/folder.dart';
import 'node_type.dart';

/// Modello dati unificato per rappresentare TodoList, Folder o Task
@immutable
class TreeNodeData {
  final String id;
  final String name;
  final NodeType type;
  final String? parentId;
  final String? todoListId;
  final TodoList? todoList;
  final Folder? folder;

  const TreeNodeData({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.todoListId,
    this.todoList,
    this.folder,
  });

  /// Factory per creare un nodo TodoList
  factory TreeNodeData.fromTodoList(TodoList todoList) {
    return TreeNodeData(
      id: todoList.id,
      name: todoList.title,
      type: NodeType.todoList,
      todoList: todoList,
    );
  }

  /// Factory per creare un nodo Folder
  factory TreeNodeData.fromFolder(
    Folder folder,
    String todoListId,
    TodoList todoList,
  ) {
    return TreeNodeData(
      id: folder.id,
      name: folder.title,
      type: NodeType.folder,
      parentId: folder.parentId,
      todoListId: todoListId,
      todoList: todoList,
      folder: folder,
    );
  }

  /// Factory per creare un nodo Task
  factory TreeNodeData.fromTask(
    String taskId,
    String taskTitle,
    String todoListId,
    TodoList todoList,
  ) {
    return TreeNodeData(
      id: taskId,
      name: taskTitle,
      type: NodeType.task,
      todoListId: todoListId,
      todoList: todoList,
    );
  }

  TreeNodeData copyWith({
    String? id,
    String? name,
    NodeType? type,
    String? parentId,
    String? todoListId,
    TodoList? todoList,
    Folder? folder,
  }) {
    return TreeNodeData(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      todoListId: todoListId ?? this.todoListId,
      todoList: todoList ?? this.todoList,
      folder: folder ?? this.folder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeNodeData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() => 'TreeNodeData(id: $id, name: $name, type: $type)';
}
