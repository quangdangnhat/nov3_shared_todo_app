import 'package:flutter/material.dart';
import '../../../../data/models/folder.dart';
import '../widgets/folder_list_tile.dart';

/// Sezione che mostra il titolo e lo StreamBuilder per le cartelle.
class FolderListSection extends StatelessWidget {
  final bool isCollapsed;
  final Stream<List<Folder>> stream;
  final VoidCallback onToggleCollapse;
  final ValueChanged<Folder> onFolderTap;
  final ValueChanged<Folder> onEdit;
  final ValueChanged<Folder> onDelete;

  const FolderListSection({
    super.key,
    required this.isCollapsed,
    required this.stream,
    required this.onToggleCollapse,
    required this.onFolderTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ).copyWith(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Folders',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey),
                ),
                IconButton(
                  icon: Icon(
                    isCollapsed ? Icons.expand_more : Icons.expand_less,
                    color: Colors.grey,
                  ),
                  onPressed: onToggleCollapse,
                  tooltip: isCollapsed ? 'Expand Folders' : 'Collapse Folders',
                ),
              ],
            ),
          ),
        ),
        if (!isCollapsed)
          StreamBuilder<List<Folder>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'Error loading folders: ${snapshot.error}',
                    ),
                  ),
                );
              }
              final folders = snapshot.data ?? [];
              if (folders.isEmpty) {
                return const SliverToBoxAdapter(
                  child: SizedBox.shrink(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((
                  context,
                  index,
                ) {
                  final folder = folders[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    child: FolderListTile(
                      folder: folder,
                      onTap: () => onFolderTap(folder),
                      onEdit: () => onEdit(folder),
                      onDelete: () => onDelete(folder),
                    ),
                  );
                }, childCount: folders.length),
              );
            },
          ),
      ],
    );
  }
}