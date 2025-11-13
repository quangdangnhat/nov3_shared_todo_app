import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_todo_app/data/models/folder.dart';
import 'package:shared_todo_app/data/repositories/folder_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../helpers/mock_supabase_client.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('FolderRepository Tests', () {
    late MockSupabaseClient mockClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late MockPostgrestTransformBuilder mockTransformBuilder;
    late FolderRepository repository;
    late DateTime testDate;

    setUpAll(() {
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      mockClient = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      mockTransformBuilder = MockPostgrestTransformBuilder();
      repository = FolderRepository(client: mockClient);
      testDate = DateTime(2025, 11, 13);
    });

    group('createFolder', () {
      test('should create folder successfully', () async {
        // Arrange
        final folderMap = TestFixtures.createFolderMap(
          id: 'new-folder-id',
          todoListId: 'list-123',
          title: 'New Folder',
          parentId: null,
        );

        when(() => mockClient.from('folders')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => folderMap);

        // Act
        final folder = await repository.createFolder(
          todoListId: 'list-123',
          title: 'New Folder',
        );

        // Assert
        expect(folder.id, 'new-folder-id');
        expect(folder.title, 'New Folder');
        expect(folder.todoListId, 'list-123');
        verify(() => mockClient.from('folders')).called(1);
      });

      test('should create subfolder with parentId', () async {
        // Arrange
        final subfolderMap = TestFixtures.createFolderMap(
          id: 'subfolder-id',
          todoListId: 'list-123',
          title: 'Subfolder',
          parentId: 'parent-folder-id',
        );

        when(() => mockClient.from('folders')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => subfolderMap);

        // Act
        final folder = await repository.createFolder(
          todoListId: 'list-123',
          title: 'Subfolder',
          parentId: 'parent-folder-id',
        );

        // Assert
        expect(folder.parentId, 'parent-folder-id');
      });

      test('should throw exception when creation fails', () async {
        // Arrange
        when(() => mockClient.from('folders')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenThrow(Exception('Creation failed'));

        // Act & Assert
        expect(
          () => repository.createFolder(
            todoListId: 'list-123',
            title: 'Failed Folder',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateFolder', () {
      test('should update folder title', () async {
        // Arrange
        final updatedFolderMap = TestFixtures.createFolderMap(
          id: 'folder-123',
          title: 'Updated Folder',
        );

        when(() => mockClient.from('folders')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => updatedFolderMap);

        // Act
        final folder = await repository.updateFolder(
          id: 'folder-123',
          title: 'Updated Folder',
        );

        // Assert
        expect(folder.title, 'Updated Folder');
        verify(() => mockClient.from('folders')).called(1);
      });

      test('should update folder parentId (move folder)', () async {
        // Arrange
        final movedFolderMap = TestFixtures.createFolderMap(
          id: 'folder-123',
          parentId: 'new-parent-id',
        );

        when(() => mockClient.from('folders')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => movedFolderMap);

        // Act
        final folder = await repository.updateFolder(
          id: 'folder-123',
          parentId: 'new-parent-id',
        );

        // Assert
        expect(folder.parentId, 'new-parent-id');
      });

      test('should throw exception when nothing to update', () async {
        // Act & Assert
        expect(
          () => repository.updateFolder(id: 'folder-123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when update fails', () async {
        // Arrange
        when(() => mockClient.from('folders')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenThrow(Exception('Update failed'));

        // Act & Assert
        expect(
          () => repository.updateFolder(
            id: 'folder-123',
            title: 'Failed Update',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteFolder', () {
      test('should delete folder successfully', () async {
        // Arrange
        when(() => mockClient.from('folders')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenAnswer((_) async => []);

        // Act
        await repository.deleteFolder('folder-to-delete');

        // Assert
        verify(() => mockClient.from('folders')).called(1);
        verify(() => mockQueryBuilder.delete()).called(1);
        verify(() => mockFilterBuilder.eq('id', 'folder-to-delete')).called(1);
      });

      test('should throw exception when deletion fails', () async {
        // Arrange
        when(() => mockClient.from('folders')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenThrow(Exception('Deletion failed'));

        // Act & Assert
        expect(
          () => repository.deleteFolder('folder-123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getFolder', () {
      test('should get folder by id', () async {
        // Arrange
        final folderMap = TestFixtures.createFolderMap(
          id: 'folder-123',
          title: 'My Folder',
        );

        when(() => mockClient.from('folders')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => folderMap);

        // Act
        final folder = await repository.getFolder('folder-123');

        // Assert
        expect(folder.id, 'folder-123');
        expect(folder.title, 'My Folder');
        verify(() => mockClient.from('folders')).called(1);
      });

      test('should throw exception when folder not found', () async {
        // Arrange
        when(() => mockClient.from('folders')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenThrow(Exception('Not found'));

        // Act & Assert
        expect(
          () => repository.getFolder('non-existent'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getRootFolder', () {
      test('should get root folder for todo list', () async {
        // Arrange
        final rootFolderMap = TestFixtures.createFolderMap(
          id: 'root-folder',
          todoListId: 'list-123',
          title: 'Root',
          parentId: null,
        );

        when(() => mockClient.from('folders')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.filter(any(), any(), any()))
            .thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => rootFolderMap);

        // Act
        final folder = await repository.getRootFolder('list-123');

        // Assert
        expect(folder.id, 'root-folder');
        expect(folder.parentId, isNull);
        verify(() => mockClient.from('folders')).called(1);
      });

      test('should throw exception when root folder not found', () async {
        // Arrange
        when(() => mockClient.from('folders')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.filter(any(), any(), any()))
            .thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenThrow(Exception('Not found'));

        // Act & Assert
        expect(
          () => repository.getRootFolder('list-123'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
