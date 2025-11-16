// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import '../../../../../core/widgets/empty_state_widget.dart';
import '../../../../../core/widgets/error_state_widget.dart';
import '../../../../../core/widgets/loading_state_widget.dart';
import '../../../../../data/models/tree/tree_data_cache_service.dart';
import '../../../../../data/models/tree/tree_node_data.dart';
import '../../../../../data/repositories/folder_repository.dart';
import '../../../../../data/repositories/task_repository.dart';
import '../../../../../data/repositories/todo_list_repository.dart';
import '../../../../../data/services/tree/tree_builder_service.dart';
import '../../../../../data/services/tree/tree_navigation_service.dart';
import '../../widgets/tree_view/tree_view_content.dart';

class FolderTreeViewPage extends StatefulWidget {
  final TodoListRepository todoListRepository;

  const FolderTreeViewPage({
    Key? key,
    required this.todoListRepository,
  }) : super(key: key);

  @override
  State<FolderTreeViewPage> createState() => _FolderTreeViewPageState();
}

class _FolderTreeViewPageState extends State<FolderTreeViewPage> {
  late final AutoScrollController _scrollController;
  late final TreeBuilderService _treeBuilder;
  late final TreeNavigationService _navigationService;
  late Stream<TreeNode<TreeNodeData>> _treeStream;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _treeStream = _buildTreeStream();
  }

  void _initializeServices() {
    _scrollController = AutoScrollController();

    final cache = TreeDataCacheService();
    final folderRepository = FolderRepository();
    final taskRepository = TaskRepository();

    _treeBuilder = TreeBuilderService(
      folderRepository: folderRepository,
      taskRepository: taskRepository,
      cache: cache,
    );

    _navigationService = TreeNavigationService(
      folderRepository: folderRepository,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _treeBuilder.dispose();
    super.dispose();
  }

  Stream<TreeNode<TreeNodeData>> _buildTreeStream() {
    return widget.todoListRepository
        .getTodoListsStream()
        .asyncMap(_treeBuilder.buildTreeFromLists);
  }

  void _handleToggle(TreeNode<TreeNodeData> node) {
    setState(() {
      node.expansionNotifier.value = !node.isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tree Visulization'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              _treeStream = _buildTreeStream();
            }),
            tooltip: 'Update',
          ),
        ],
      ),
      body: StreamBuilder<TreeNode<TreeNodeData>>(
        stream: _treeStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingStateWidget(
              message: 'Loading...',
            );
          }

          if (snapshot.hasError) {
            return ErrorStateWidget(
              title: 'Loading Error ',
              error: snapshot.error,
              onRetry: () => setState(() {
                _treeStream = _buildTreeStream();
              }),
            );
          }

          if (!snapshot.hasData || snapshot.data!.childrenAsList.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.inbox,
              title: 'No TO-Do list found',
              subtitle: 'Create your first to-do list !',
            );
          }

          return TreeViewContent(
            rootNode: snapshot.data!,
            scrollController: _scrollController,
            onNavigate: (TreeNodeData data) =>
                _navigationService.navigateToItem(context, data),
            onToggle: _handleToggle,
          );
        },
      ),
    );
  }
}
