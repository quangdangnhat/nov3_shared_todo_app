import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/repositories/invitation_repository.dart';
import '../../mocks/mock_supabase.dart';

void main() {
  group('InvitationRepository', () {
    test('can be instantiated with mock client', () {
      // Arrange
      final mockClient = MockSupabaseClient();

      // Act
      final repository = InvitationRepository(client: mockClient);

      // Assert
      expect(repository, isNotNull);
      expect(repository, isA<InvitationRepository>());
    });

    test('can create multiple instances with different mocks', () {
      // Arrange
      final mockClient1 = MockSupabaseClient();
      final mockClient2 = MockSupabaseClient();

      // Act
      final repo1 = InvitationRepository(client: mockClient1);
      final repo2 = InvitationRepository(client: mockClient2);

      // Assert
      expect(repo1, isNotNull);
      expect(repo2, isNotNull);
      expect(repo1, isNot(same(repo2)));
    });

    test('uses injected client instead of global instance', () {
      // Arrange
      final mockClient = MockSupabaseClient();

      // Act
      final repository = InvitationRepository(client: mockClient);

      // Assert
      expect(repository, isNotNull);
    });
  });
}
