// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/repositories/folder_repository.dart';
import '../../../../data/models/todo_list.dart';
import '../../../../data/models/folder.dart';
import '../../../../config/router/app_router.dart';
import '../../models/tree/tree_node_data.dart';
import '../../models/tree/node_type.dart';

/// Service per gestire la navigazione nell'albero
class TreeNavigationService {
  final FolderRepository _folderRepository;

  TreeNavigationService({required FolderRepository folderRepository})
      : _folderRepository = folderRepository;

  /// Gestisce la navigazione verso la pagina appropriata
  void navigateToItem(BuildContext context, TreeNodeData data) {
    if (!data.type.isNavigable) return;

    switch (data.type) {
      case NodeType.todoList:
        //if (data.todoList != null) {
        //navigateToList(context, data.todoList!);
        //}
        break;
      case NodeType.folder:
        if (data.folder != null && data.todoList != null) {
          navigateToFolder(context, data.todoList!, data.folder!);
        }
        break;
      case NodeType.task:
        break;
    }
  }

  /// Naviga alla TodoList (root folder)
  Future<void> navigateToList(BuildContext context, TodoList list) async {
    _showLoadingDialog(context);

    try {
      final rootFolder = await _folderRepository.getRootFolder(list.id);

      if (!context.mounted) return;

      Navigator.of(context, rootNavigator: true).pop(); // loading
      Navigator.of(context, rootNavigator: true).pop(); // tree view

      context.goNamed(
        AppRouter.listDetail,
        pathParameters: {'listId': list.id},
        extra: {'todoList': list, 'parentFolder': rootFolder},
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar(context, 'Errore nel caricamento: $e');
      }
    }
  }

  /// Naviga a una cartella specifica
  void navigateToFolder(BuildContext context, TodoList list, Folder folder) {
    Navigator.of(context).pop();

    context.goNamed(
      AppRouter.folderDetail,
      pathParameters: {
        'listId': list.id,
        'folderId': folder.id,
      },
      extra: {'todoList': list, 'parentFolder': folder},
    );
  }

  // UI Helpers
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
