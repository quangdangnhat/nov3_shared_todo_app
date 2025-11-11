import 'package:flutter/material.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import '../../../../../data/models/tree/tree_node_data.dart';
import 'tree_node_card.dart';

class TreeViewContent extends StatelessWidget {
  final TreeNode<TreeNodeData> rootNode;
  final AutoScrollController scrollController;
  final ValueChanged<TreeNodeData> onNavigate;
  final ValueChanged<TreeNode<TreeNodeData>> onToggle;

  const TreeViewContent({
    Key? key,
    required this.rootNode,
    required this.scrollController,
    required this.onNavigate,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverTreeView.simpleTyped<TreeNodeData, TreeNode<TreeNodeData>>(
          tree: rootNode,
          scrollController: scrollController,
          showRootNode: false,
          builder: (context, node) => TreeNodeCard(
            node: node,
            onNavigate: onNavigate,
            onToggle: () => onToggle(node),
          ),
          indentation: const Indentation(width: 28),
          expansionBehavior: ExpansionBehavior.scrollToLastChild,
        ),
      ],
    );
  }
}
