enum NodeType {
  todoList,
  folder,
  task;

  /// Helper per verificare se il nodo può avere figli
  bool get canHaveChildren => this != NodeType.task;

  /// Helper per verificare se il nodo è navigabile
  bool get isNavigable => this != NodeType.task;

  /// Helper per ottenere un nome leggibile
  String get displayName {
    switch (this) {
      case NodeType.todoList:
        return 'Lista';
      case NodeType.folder:
        return 'Cartella';
      case NodeType.task:
        return 'Task';
    }
  }
}