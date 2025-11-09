import 'package:flutter/material.dart';
import 'package:shared_todo_app/core/widgets/app_drawer.dart';
import 'package:shared_todo_app/data/models/daily_tasks/task_category.dart';
import '../../../../../config/responsive.dart';
import '../../../../../core/utils/daily_tasks/date_formatter.dart';
import '../../../../../core/utils/daily_tasks/task_categorizer.dart';
import '../../../../../data/models/task.dart';
import '../../../../../data/repositories/task_repository.dart';
import '../../widgets/daily_tasks.dart/empty_state.dart';
import '../../widgets/daily_tasks.dart/filter_dialog.dart';
import '../../widgets/daily_tasks.dart/section_header.dart';
import '../../widgets/daily_tasks.dart/summary_card.dart';
import '../../widgets/daily_tasks.dart/task_card.dart';
import '../../widgets/daily_tasks.dart/task_detail.dart';

/// Pagina che visualizza i task rilevanti per oggi del cliente.
/// Organizza i task in sezioni: scaduti, scadenza oggi, in corso, iniziano oggi.
class TodayTasksPage extends StatefulWidget {
  const TodayTasksPage({Key? key}) : super(key: key);

  @override
  State<TodayTasksPage> createState() => _TodayTasksPageState();
}

class _TodayTasksPageState extends State<TodayTasksPage> {
  final TaskRepository _taskRepository = TaskRepository();

  bool _isLoading = true;
  String? _errorMessage;

  // Task categorizzati
  Map<TaskCategory, List<Task>> _categorizedTasks = {};

  // Filtri attivi (tutti di default)
  Set<TaskCategory> _activeFilters = Set.from(TaskCategory.values);

  @override
  void initState() {
    super.initState();
    _loadTodayTasks();
  }

  /// Carica e categorizza tutti i task rilevanti per oggi
  Future<void> _loadTodayTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateRange = TaskCategorizer.getSearchRange();

      final allTasks = await _taskRepository.getTasksForCalendar_Future(
        dateRange.start,
        dateRange.end,
      );

      final categorized = TaskCategorizer.categorize(allTasks);

      setState(() {
        _categorizedTasks = categorized;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore nel caricamento dei task: $e';
        _isLoading = false;
      });
    }
  }

  /// Mostra il dialog dei filtri
  Future<void> _showFilterDialog() async {
    final taskCounts = {
      for (var category in TaskCategory.values)
        category: _categorizedTasks[category]?.length ?? 0,
    };

    final result = await FilterDialog.show(
      context,
      activeFilters: _activeFilters,
      taskCounts: taskCounts,
    );

    if (result != null) {
      setState(() {
        _activeFilters = result;
      });
    }
  }

  /// Mostra i dettagli di un task
  void _showTaskDetails(Task task) {
    TaskDetailsDialog.show(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      appBar: _buildAppBar(theme, isMobile),
      drawer: isMobile ? const AppDrawer() : null,
      body: _buildBody(),
    );
  }

  /// Costruisce l'AppBar
  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isMobile) {
    return AppBar(
      leading: isMobile ? null : const SizedBox.shrink(),
      automaticallyImplyLeading: isMobile,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks Recap',
            style: ResponsiveLayout.responsive<TextStyle?>(
              context,
              mobile: theme.textTheme.titleMedium,
              desktop: theme.textTheme.titleLarge,
            ),
          ),
          Text(
            DateFormatter.formatToday(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.appBarTheme.foregroundColor?.withOpacity(0.7),
              fontSize: ResponsiveLayout.responsive<double>(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 13,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Badge(
            isLabelVisible: _activeFilters.length < TaskCategory.values.length,
            label: Text('${_activeFilters.length}'),
            child: const Icon(Icons.filter_list),
          ),
          onPressed: _showFilterDialog,
          tooltip: 'Filtra',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadTodayTasks,
          tooltip: 'Aggiorna',
        ),
        if (!isMobile) const SizedBox(width: 8),
      ],
    );
  }

  /// Costruisce il body della pagina
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ErrorState(
        errorMessage: _errorMessage!,
        onRetry: _loadTodayTasks,
      );
    }

    return _buildTasksList();
  }

  /// Costruisce la lista dei task
  Widget _buildTasksList() {
    final hasAnyTasks =
        _categorizedTasks.values.any((tasks) => tasks.isNotEmpty);

    if (!hasAnyTasks) {
      return const EmptyTasksState();
    }

    final hasVisibleTasks = _activeFilters.any(
      (category) => (_categorizedTasks[category]?.isNotEmpty ?? false),
    );

    if (!hasVisibleTasks) {
      return FilteredEmptyState(onFilterPressed: _showFilterDialog);
    }

    return RefreshIndicator(
      onRefresh: _loadTodayTasks,
      child: ListView(
        padding: ResponsiveLayout.responsive<EdgeInsets>(
          context,
          mobile: const EdgeInsets.all(12.0),
          tablet: const EdgeInsets.all(16.0),
          desktop: const EdgeInsets.all(24.0),
        ),
        children: [
          // Riepilogo (sempre visibile, responsive)
          _buildSummaryCard(),
          SizedBox(
            height: ResponsiveLayout.responsive<double>(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),

          // Sezioni task
          ...TaskCategory.values.expand((category) {
            if (!_activeFilters.contains(category)) return [];

            final tasks = _categorizedTasks[category] ?? [];
            if (tasks.isEmpty) return [];

            return [
              SectionHeader(
                category: category,
                taskCount: tasks.length,
              ),
              SizedBox(
                height: ResponsiveLayout.responsive<double>(
                  context,
                  mobile: 8,
                  desktop: 12,
                ),
              ),
              _buildTasksSection(tasks, category),
              SizedBox(
                height: ResponsiveLayout.responsive<double>(
                  context,
                  mobile: 16,
                  desktop: 24,
                ),
              ),
            ];
          }),
        ],
      ),
    );
  }

  /// Costruisce la summary card
  Widget _buildSummaryCard() {
    final overdue = _categorizedTasks[TaskCategory.overdue]?.length ?? 0;
    final dueToday = _categorizedTasks[TaskCategory.dueToday]?.length ?? 0;
    final ongoing = _categorizedTasks[TaskCategory.ongoing]?.length ?? 0;
    final starting = _categorizedTasks[TaskCategory.startingToday]?.length ?? 0;
    final total = overdue + dueToday + ongoing + starting;

    return SummaryCard(
      totalTasks: total,
      overdueTasks: overdue,
      dueTodayTasks: dueToday,
      activeTasks: ongoing + starting,
    );
  }

  /// Costruisce una sezione di task
  Widget _buildTasksSection(List<Task> tasks, TaskCategory category) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => SizedBox(
        height: ResponsiveLayout.responsive<double>(
          context,
          mobile: 8,
          desktop: 12,
        ),
      ),
      itemBuilder: (context, index) {
        return TaskCard(
          task: tasks[index],
          category: category,
          onTap: () => _showTaskDetails(tasks[index]),
        );
      },
    );
  }
}
