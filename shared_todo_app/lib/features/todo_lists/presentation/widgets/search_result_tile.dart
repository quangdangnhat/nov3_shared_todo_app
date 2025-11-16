import 'package:flutter/material.dart';

class SearchResultTile extends StatelessWidget {
  final String taskTitle;
  final String listName;
  final String folderPath;
  final VoidCallback onTap;

  const SearchResultTile({
    Key? key,
    required this.taskTitle,
    required this.listName,
    required this.folderPath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Determina se mostrare il folder path
    final bool hasFolder = folderPath.isNotEmpty &&
        folderPath != 'No Folder' &&
        folderPath != 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icona task a sinistra
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Contenuto centrale
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titolo del task
                    Text(
                      taskTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Lista e cartella
                    Row(
                      children: [
                        // Icona lista
                        Icon(
                          Icons.list_alt_rounded,
                          size: 16,
                          color: colorScheme.primary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            listName,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Folder path (se presente)
                    if (hasFolder) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 16,
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              folderPath,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.8),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Icona freccia a destra
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
