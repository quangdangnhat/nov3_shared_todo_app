import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_todo_app/config/router/app_router.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/screens/createPage/folder_create.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/screens/createPage/task_create.dart';
import '../../../../../config/responsive.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  // 0 = Folder, 1 = Task
  int _selectedIndex = 0;
  

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header custom (al posto dell'AppBar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (isMobile) ...[
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: 'Menu',
                  ),
                  const SizedBox(width: 8),
                ]else...[
                  IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                   context.go(AppRouter.home);
                  },
                  tooltip: 'back', // Tooltip per accessibilità
                ),
                const SizedBox(width: 8),
                ],
                Text(
                  'Create',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          // Selector Folder / Task
          _buildSelector(),

          // Contenuto dinamico
          Expanded(
            child: _selectedIndex == 0
                ? const FolderCreatePage()
                : const TaskCreatePage(),
          ),
        ],
      ),
    );
  }

  // Widget per il selettore top
  Widget _buildSelector() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSelectorButton(
              label: 'Folder',
              icon: Icons.folder,
              isSelected: _selectedIndex == 0,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
          ),
          Expanded(
            child: _buildSelectorButton(
              label: 'Task',
              icon: Icons.task_alt,
              isSelected: _selectedIndex == 1,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
