// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import '../../../../../data/models/tree/tree_node_data.dart';
import 'tree_node_card.dart';
import '../../../../../data/models/tree/node_type.dart';

class TreeViewContent extends StatelessWidget {
  final TreeNode<TreeNodeData> rootNode;
  final AutoScrollController scrollController;
  final ValueChanged<TreeNodeData> onNavigate;
  final ValueChanged<TreeNode<TreeNodeData>> onToggle;

// NUOVO: callback chiamata quando trasciniamo un nodo sopra un altro
  final Future<void> Function(TreeNodeData dragged, TreeNodeData target)
      onMoveNode;

  const TreeViewContent({
    Key? key,
    required this.rootNode,
    required this.scrollController,
    required this.onNavigate,
    required this.onToggle,
    required this.onMoveNode,
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
          builder: (context, node) =>
              _buildDraggableNode(context, node), // <--- MODIFICA
          indentation: const Indentation(width: 28),
          expansionBehavior: ExpansionBehavior.scrollToLastChild,
        ),
      ],
    );
  }

  Widget _buildDraggableNode(
  BuildContext context,
  TreeNode<TreeNodeData> node,
) {
  final data = node.data;

  final baseTile = TreeNodeCard(
    node: node,
    onNavigate: onNavigate,
    onToggle: () => onToggle(node),
  );

  if (data == null) {
    return baseTile;
  }

  if (data.type == NodeType.todoList) {
    return baseTile;
  }

  return DragTarget<TreeNodeData>(
    onWillAccept: (dragged) {
      if (dragged == null) return false;

      debugPrint(
        '👀 onWillAccept: dragged=${dragged.id} (${dragged.type}) '
        '→ target=${data.id} (${data.type})',
      );

      if (dragged.id == data.id && dragged.type == data.type) {
        return false;
      }

      if (dragged.type == NodeType.task && data.type == NodeType.folder) {
        return true;
      }

      if (dragged.type == NodeType.folder && data.type == NodeType.folder) {
        return true;
      }

      return false;
    },
    onAccept: (dragged) {
      debugPrint(
        ' onAccept: dragged=${dragged.id} (${dragged.type}) '
        '→ target=${data.id} (${data.type})',
      );
      onMoveNode(dragged, data);
    },
    builder: (context, candidateData, rejectedData) {
      final isHighlighted = candidateData.isNotEmpty;

      final decoratedTile = Container(
        decoration: BoxDecoration(
          color: isHighlighted
              ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: baseTile,
      );

      // 🔁 Draggable "normale" (non long press) + log
      return Draggable<TreeNodeData>(
        data: data,
        onDragStarted: () {
          debugPrint('DRAG STARTED for node=${data.id} (${data.type})');
        },
        onDragEnd: (details) {
          debugPrint('DRAG ENDED for node=${data.id} (${data.type})');
        },
        feedback: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: decoratedTile,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.4,
          child: decoratedTile,
        ),
        child: decoratedTile,
      );
    },
  );
}

}
