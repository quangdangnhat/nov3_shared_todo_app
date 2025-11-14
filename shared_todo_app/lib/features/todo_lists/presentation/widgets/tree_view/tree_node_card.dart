// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import '../../../../../core/utils/tree_style_util.dart'; // Assicurati che questo percorso sia corretto
import '../../../../../data/models/tree/tree_node_data.dart'; // Assicurati che questo percorso sia corretto
import '../../../../../data/models/tree/node_type.dart'; // Assicurati che questo percorso sia corretto

class TreeNodeCard extends StatelessWidget {
  final TreeNode<TreeNodeData> node;
  final ValueChanged<TreeNodeData> onNavigate;
  final VoidCallback onToggle;

  const TreeNodeCard({
    Key? key,
    required this.node,
    required this.onNavigate,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = node.data!;
    final hasChildren = node.childrenAsList.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: TreeStyleUtils.getCardElevation(data.type),
      color: TreeStyleUtils.getBackgroundColor(data.type, theme),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            // Il click sull'intera card è DISABILITATO
            onTap: null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              child: Row(
                children: [
                  // L'icona a sinistra ora è cliccabile (vedi sotto)
                  _buildExpansionIcon(data, hasChildren, theme),
                  const SizedBox(width: 12),
                  _buildTypeIcon(data, theme),
                  const SizedBox(width: 16),
                  _buildTitle(data, theme),
                  const SizedBox(width: 8),
                  if (hasChildren && data.type.canHaveChildren)
                    _buildChildrenBadge(data, theme),

                  // FIX FRECCIA DESTRA: Mostra solo per NodeType.folder
                  if (data.type == NodeType.folder)
                    _buildNavigationButton(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // FIX FRECCIA SINISTRA: Resa cliccabile
  Widget _buildExpansionIcon(
    TreeNodeData data,
    bool hasChildren,
    ThemeData theme,
  ) {
    // Se non ci sono figli, lascia uno spazio vuoto
    if (!hasChildren) return const SizedBox(width: 32);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle, // Azione di click per espandere/comprimere
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4.0), // Area di click
          child: Icon(
            node.isExpanded
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_right,
            size: 24,
            color: TreeStyleUtils.getIconColor(data.type, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(TreeNodeData data, ThemeData theme) {
    return Icon(
      TreeStyleUtils.getIconForType(data.type),
      color: TreeStyleUtils.getIconColor(data.type, theme),
      size: 24,
    );
  }

  Widget _buildTitle(TreeNodeData data, ThemeData theme) {
    return Expanded(
      child: Text(
        data.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: TreeStyleUtils.getTitleFontSize(data.type),
          fontWeight: TreeStyleUtils.getTitleFontWeight(data.type),
        ),
      ),
    );
  }

  Widget _buildChildrenBadge(TreeNodeData data, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TreeStyleUtils.getIconColor(data.type, theme)
            .withOpacity(isDark ? 0.2 : 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${node.childrenAsList.length}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: TreeStyleUtils.getIconColor(data.type, theme),
        ),
      ),
    );
  }

  Widget _buildNavigationButton(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onNavigate(node.data!),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.arrow_forward_ios,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
