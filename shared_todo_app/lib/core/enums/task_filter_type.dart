// coverage:ignore-file

/// Enum to define filter types for Task
enum TaskFilterType {
  createdAtNewest('Newest First', 'Sort by creation date (newest first)'),
  createdAtOldest('Oldest First', 'Sort by creation date (oldest first)'),
  priorityHighToLow(
    'Priority: High → Low',
    'Sort by priority (High, Medium, Low)',
  ),
  priorityLowToHigh(
    'Priority: Low → High',
    'Sort by priority (Low, Medium, High)',
  ),
  alphabeticalAZ('Title: A → Z', 'Sort alphabetically (A to Z)'),
  alphabeticalZA('Title: Z → A', 'Sort alphabetically (Z to A)'),
  highPriorityOnly('High Priority Only', 'Show only high priority tasks'),
  hasDueDate('Has Due Date', 'Show only tasks with due date');

  final String displayName;
  final String description;

  const TaskFilterType(this.displayName, this.description);
}
