import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_todo_app/data/models/task.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import '../../../../config/responsive.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repo = TaskRepository();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // cache markers
  final Map<DateTime, List<Task>> _eventsByDay = {};

  // ---------- Helpers ----------

  DateTime _monthGridStart(DateTime focused) {
    final firstOfMonth = DateTime(focused.year, focused.month, 1);
    return firstOfMonth.subtract(const Duration(days: 7));
  }

  DateTime _monthGridEnd(DateTime focused) {
    final nextMonth = DateTime(focused.year, focused.month + 1, 1);
    return nextMonth.add(const Duration(days: 7));
  }

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _dayEnd(DateTime d) => _dayStart(d).add(const Duration(days: 1));

  Future<List<Task>> _fetchMonthTasks() {
    final start = _monthGridStart(_focusedDay);
    final end = _monthGridEnd(_focusedDay);
    return _repo.getTasksForCalendar_Future(start, end);
  }

  Future<List<Task>> _fetchDayTasks() {
    final start = _dayStart(_selectedDay);
    final end = _dayEnd(_selectedDay);
    return _repo.getTasksForCalendar_Future(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return FutureBuilder<List<Task>>(
      future: _fetchMonthTasks(),
      builder: (context, snapshotMonth) {
        final monthTasks = snapshotMonth.data ?? [];

        // Ricostruzione markers
        _eventsByDay.clear();
        for (final t in monthTasks) {
          final key = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          _eventsByDay.putIfAbsent(key, () => []).add(t);
        }

        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              // Header custom
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
                    ],
                    Text(
                      'Calendario',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              // Corpo principale
              Expanded(
                child: Column(
                  children: [
                    TableCalendar<Task>(
                      firstDay: DateTime.utc(2015, 1, 1),
                      lastDay: DateTime.utc(2035, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          day.year == _selectedDay.year &&
                          day.month == _selectedDay.month &&
                          day.day == _selectedDay.day,
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      eventLoader: (day) {
                        final k = DateTime(day.year, day.month, day.day);
                        return _eventsByDay[k] ?? [];
                      },
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      onPageChanged: (focused) {
                        setState(() => _focusedDay = focused);
                      },
                      calendarStyle: const CalendarStyle(markersMaxCount: 4),
                    ),

                    const Divider(height: 0),

                    Expanded(
                      child: FutureBuilder<List<Task>>(
                        future: _fetchDayTasks(),
                        builder: (context, snapshotDay) {
                          final dayTasks = snapshotDay.data ?? [];

                          if (snapshotDay.connectionState == ConnectionState.waiting &&
                              dayTasks.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (dayTasks.isEmpty) {
                            return const Center(
                              child: Text('Nessun task per il giorno selezionato'),
                            );
                          }

                          return ListView.separated(
                            itemCount: dayTasks.length,
                            separatorBuilder: (_, __) => const Divider(height: 0),
                            itemBuilder: (context, i) {
                              final t = dayTasks[i];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.event_note),
                                title: Text(t.title),
                                subtitle: Text(t.desc ?? ''),
                                trailing: Text(
                                  '${t.dueDate.hour.toString().padLeft(2, '0')}:${t.dueDate.minute.toString().padLeft(2, '0')}',
                                ),
                                onTap: () {
                                  // TODO: Naviga al dettaglio del task
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
