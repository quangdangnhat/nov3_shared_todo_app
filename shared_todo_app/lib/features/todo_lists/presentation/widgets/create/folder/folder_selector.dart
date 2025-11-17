// coverage:ignore-file

// consider testing later

// lib/presentation/widgets/folder/folder_selector.dart

import 'package:flutter/material.dart';
import '../../../../../../config/responsive.dart';
import '../../../../../../data/models/folder.dart';
import '../../../controllers/base_controller.dart';

class FolderSelector extends StatefulWidget {
  final BaseFolderSelectionController controller;
  final ValueChanged<Folder> onFolderSelected;

  const FolderSelector({
    super.key,
    required this.controller,
    required this.onFolderSelected,
  });

  @override
  State<FolderSelector> createState() => _FolderSelectorState();
}

class _FolderSelectorState extends State<FolderSelector> {
  Future<void> _showFolderDialog() async {
    final subFolders = await widget.controller.folderStream!.first;

    final Folder? selected = await showDialog<Folder>(
      context: context,
      builder: (context) => _FolderDialog(
        controller: widget.controller,
        subFolders: subFolders,
      ),
    );

    if (selected != null) {
      widget.onFolderSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = ResponsiveLayout.responsive<double>(
      context,
      mobile: 12,
      tablet: 14,
      desktop: 16,
    );
    final iconSize = ResponsiveLayout.responsive<double>(
      context,
      mobile: 18,
      tablet: 20,
      desktop: 22,
    );
    final fontSize = ResponsiveLayout.responsive<double>(
      context,
      mobile: 14,
      tablet: 15,
      desktop: 16,
    );
    final horizontalPadding = ResponsiveLayout.responsive<double>(
      context,
      mobile: 12,
      tablet: 14,
      desktop: 16,
    );
    final verticalPadding = ResponsiveLayout.responsive<double>(
      context,
      mobile: 12,
      tablet: 14,
      desktop: 16,
    );

    return StreamBuilder<List<Folder>>(
      stream: widget.controller.folderStream,
      builder: (context, snapshot) {
        final isEnabled = widget.controller.selectedTodoList != null;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return InkWell(
          onTap: isEnabled && !isLoading ? _showFolderDialog : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: isEnabled
                    ? theme.colorScheme.onSurface.withOpacity(0.3)
                    : theme.colorScheme.onSurface.withOpacity(0.15),
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              color: isEnabled ? null : theme.colorScheme.onSurface.withOpacity(0.05),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder,
                        size: iconSize,
                        color: isEnabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      SizedBox(width: ResponsiveLayout.responsive<double>(
                        context,
                        mobile: 8,
                        tablet: 10,
                        desktop: 12,
                      )),
                      Flexible(
                        child: Text(
                          isLoading
                              ? 'Loading...'
                              : widget.controller.selectedFolder?.title ?? 'Select folder',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: fontSize,
                            color: widget.controller.selectedFolder != null
                                ? theme.colorScheme.onSurface
                                : isEnabled
                                    ? theme.colorScheme.onSurface.withOpacity(0.5)
                                    : theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: iconSize + 6,
                  color: isEnabled && !isLoading
                      ? theme.colorScheme.onSurface.withOpacity(0.7)
                      : theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Dialog personalizzato per la selezione Folder
class _FolderDialog extends StatefulWidget {
  final BaseFolderSelectionController controller;
  final List<Folder> subFolders;

  const _FolderDialog({
    required this.controller,
    required this.subFolders,
  });

  @override
  State<_FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<_FolderDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = ResponsiveLayout.responsive<double>(
      context,
      mobile: 12,
      tablet: 16,
      desktop: 20,
    );
    final maxHeightFactor = ResponsiveLayout.responsive<double>(
      context,
      mobile: 0.6,
      tablet: 0.65,
      desktop: 0.7,
    );
    final maxWidthFactor = ResponsiveLayout.responsive<double>(
      context,
      mobile: 0.9,
      tablet: 0.7,
      desktop: 0.5,
    );
    final iconSize = ResponsiveLayout.responsive<double>(
      context,
      mobile: 18,
      tablet: 20,
      desktop: 22,
    );
    final fontSize = ResponsiveLayout.responsive<double>(
      context,
      mobile: 14,
      tablet: 15,
      desktop: 16,
    );
    final spacing = ResponsiveLayout.responsive<double>(
      context,
      mobile: 8,
      tablet: 10,
      desktop: 12,
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      backgroundColor: theme.dialogTheme.backgroundColor,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
          maxWidth: MediaQuery.of(context).size.width * maxWidthFactor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(ResponsiveLayout.responsive<double>(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              )),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_open,
                    color: theme.colorScheme.primary,
                    size: iconSize + 4,
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      'Select Folder',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: theme.dividerTheme.color,
            ),

            // Lista delle Folder
            Flexible(
              child: _buildFolderList(
                context,
                theme,
                iconSize,
                fontSize,
                spacing,
                borderRadius,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderList(
    BuildContext context,
    ThemeData theme,
    double iconSize,
    double fontSize,
    double spacing,
    double borderRadius,
  ) {
    // Mostra la cartella corrente (dove ci troviamo)
    final currentFolder = widget.controller.selectedFolder;
    final subFolders = widget.subFolders;

    if (currentFolder == null && subFolders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_off,
                size: ResponsiveLayout.responsive<double>(
                  context,
                  mobile: 48,
                  tablet: 56,
                  desktop: 64,
                ),
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              SizedBox(height: spacing),
              Text(
                'No folders available',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        // Cartella corrente
        if (currentFolder != null)
          ListTile(
            leading: Icon(
              Icons.folder_open,
              size: iconSize,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              '... (${currentFolder.title})',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius * 0.75),
            ),
            onTap: () {
              Navigator.of(context).pop(currentFolder);
            },
          ),

        // Divider se ci sono sottocartelle
        if (currentFolder != null && subFolders.isNotEmpty)
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerTheme.color,
          ),

        // Messaggio "No subfolders"
        if (subFolders.isEmpty && currentFolder != null)
          ListTile(
            enabled: false,
            leading: Icon(
              Icons.info_outline,
              size: iconSize,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            title: Text(
              'No subfolders',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: fontSize,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Lista delle sottocartelle
        ...subFolders.map((folder) {
          return ListTile(
            leading: Icon(
              Icons.folder,
              size: iconSize,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              folder.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: fontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius * 0.75),
            ),
            onTap: () {
              Navigator.of(context).pop(folder);
            },
          );
        }),
      ],
    );
  }
}