enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case RecurrenceType.none:
        return 'None';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
    }
  }

  String get value {
    return name;
  }

  static RecurrenceType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'daily':
        return RecurrenceType.daily;
      case 'weekly':
        return RecurrenceType.weekly;
      case 'monthly':
        return RecurrenceType.monthly;
      default:
        return RecurrenceType.none;
    }
  }
}