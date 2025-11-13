# Unit Tests for Backend (lib/)

This directory contains comprehensive unit tests for the backend logic of the shared_todo_app.

## Test Structure

```
test/
├── helpers/
│   ├── mock_supabase_client.dart    # Mock classes for Supabase
│   └── test_fixtures.dart            # Test data fixtures
├── data/
│   ├── models/
│   │   ├── task_test.dart           # Task model tests
│   │   ├── folder_test.dart         # Folder model tests
│   │   ├── todo_list_test.dart      # TodoList model tests
│   │   └── participant_test.dart    # Participant model tests
│   └── repositories/
│       ├── task_repository_test.dart     # TaskRepository tests
│       ├── folder_repository_test.dart   # FolderRepository tests
│       └── auth_repository_test.dart     # AuthRepository tests
└── core/
    └── utils/
        ├── task_sorter_test.dart                      # TaskSorter tests
        └── daily_tasks/
            ├── date_formatter_test.dart               # DateFormatter tests
            └── task_categorizer_test.dart             # TaskCategorizer tests
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/data/models/task_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
```

### View coverage report
```bash
# Install lcov if not already installed
# On macOS: brew install lcov
# On Linux: sudo apt-get install lcov

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

## Test Coverage

### Models (100% coverage target)
- ✅ Task model - fromMap, toMap, date parsing, edge cases
- ✅ Folder model - fromMap, toMap, hierarchy, nullable fields
- ✅ TodoList model - fromMap, toMap, roles, optional fields
- ✅ Participant model - fromMap, nested data, fallbacks

### Repositories (Core functionality tested)
- ✅ TaskRepository - CRUD operations, calendar queries, error handling
- ✅ FolderRepository - CRUD operations, root folder, hierarchy
- ✅ AuthRepository - sign up, sign in, sign out, auth state

### Utils (100% coverage target)
- ✅ TaskSorter - all sort types, edge cases, stability
- ✅ DateFormatter - formatting, calculations, localization
- ✅ TaskCategorizer - categorization logic, date ranges

## Test Dependencies

The tests use the following packages:
- `flutter_test`: Flutter's testing framework
- `mocktail`: For mocking dependencies (Supabase client)

These are already configured in `pubspec.yaml` under `dev_dependencies`.

## Writing New Tests

### Example: Testing a new model

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/data/models/your_model.dart';

void main() {
  group('YourModel Tests', () {
    test('should create model from map', () {
      // Arrange
      final map = {'id': '123', 'name': 'Test'};

      // Act
      final model = YourModel.fromMap(map);

      // Assert
      expect(model.id, '123');
      expect(model.name, 'Test');
    });
  });
}
```

### Example: Testing a repository with mocks

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:your_app/data/repositories/your_repository.dart';
import '../../helpers/mock_supabase_client.dart';

void main() {
  late MockSupabaseClient mockClient;
  late YourRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = YourRepository(client: mockClient);
  });

  test('should fetch data successfully', () async {
    // Arrange
    when(() => mockClient.from('table')).thenReturn(mockQueryBuilder);
    // ... setup mocks

    // Act
    final result = await repository.fetchData();

    // Assert
    expect(result, isNotNull);
    verify(() => mockClient.from('table')).called(1);
  });
}
```

## Best Practices

1. **Arrange-Act-Assert Pattern**: Structure tests clearly
2. **Mock External Dependencies**: Use mocktail for Supabase client
3. **Test Edge Cases**: Null values, empty lists, error conditions
4. **Descriptive Test Names**: Use clear, descriptive test names
5. **Independent Tests**: Each test should be independent
6. **Setup and Teardown**: Use setUp() and tearDown() for common setup

## Continuous Integration

These tests are designed to run in CI/CD pipelines. Add to your CI configuration:

```yaml
# Example GitHub Actions
- name: Run tests
  run: flutter test

- name: Check test coverage
  run: |
    flutter test --coverage
    lcov --summary coverage/lcov.info
```

## Troubleshooting

### Issue: Tests fail with Supabase initialization error
**Solution**: Ensure you're using the injected client in repositories, not the global Supabase.instance.client

### Issue: Mock not working as expected
**Solution**: Make sure to register fallback values with `registerFallbackValue()` in `setUpAll()`

### Issue: Date-related tests failing
**Solution**: Use fixed dates in tests instead of DateTime.now() for consistency

## Contributing

When adding new features to the backend:
1. Write tests first (TDD approach)
2. Ensure all tests pass before committing
3. Maintain or improve code coverage
4. Update this README if adding new test categories
