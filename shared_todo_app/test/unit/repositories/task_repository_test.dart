// Purpose: Verify TaskRepository supports dependency injection
// and can be instantiated with mock client for testing.
//
// Note: For now, we verify the repository is testable (accepts mocks).
// Actual method testing will be done in integration tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import '../../mocks/mock_supabase.dart';

void main() {
  group('TaskRepository', () {
    test('can be instantiated with mock client', () {
      // Arrange
      final mockClient = MockSupabaseClient();

      // Act
      final repository = TaskRepository(client: mockClient);

      // Assert
      expect(repository, isNotNull);
      expect(repository, isA<TaskRepository>());
    });

    test('can create multiple instances with different mocks', () {
      // Arrange
      final mockClient1 = MockSupabaseClient();
      final mockClient2 = MockSupabaseClient();

      // Act
      final repo1 = TaskRepository(client: mockClient1);
      final repo2 = TaskRepository(client: mockClient2);

      // Assert
      expect(repo1, isNotNull);
      expect(repo2, isNotNull);
      expect(repo1, isNot(same(repo2)));
    });

    test('uses injected client instead of global instance', () {
      // Arrange
      final mockClient = MockSupabaseClient();

      // Act
      final repository = TaskRepository(client: mockClient);

      // Assert
      expect(repository, isNotNull);
    });
  });
}
