import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_todo_app/data/models/task.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../widgets/task_list_tile.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repo = TaskRepository();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // cache for markers
  final Map<DateTime, List<Task>> _eventsByDay = {};

  // ---------- Helpers for ranges ----------
  DateTime _monthGridStart(DateTime focused) {
    final firstOfMonth = DateTime(focused.year, focused.month, 1);
    // padding of one week to cover the entire grid
    return firstOfMonth.subtract(const Duration(days: 7));
  }

  DateTime _monthGridEnd(DateTime focused) {
    final nextMonth = DateTime(focused.year, focused.month + 1, 1);
    return nextMonth.add(const Duration(days: 7));
  }

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _dayEnd(DateTime d) => _dayStart(d).add(const Duration(days: 1));

  // ---------- Future for the monthly grid ----------
  Future<List<Task>> _fetchMonthTasks() {
    final start = _monthGridStart(_focusedDay);
    final end = _monthGridEnd(_focusedDay);
    return _repo.getTasksForCalendar_Future(start, end);
  }

  // ---------- Future for the selected day ----------
  Future<List<Task>> _fetchDayTasks() {
    final start = _dayStart(_selectedDay);
    final end = _dayEnd(_selectedDay);
    return _repo.getTasksForCalendar_Future(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: _fetchMonthTasks(),
      builder: (context, snapshotMonth) {
        final monthTasks = snapshotMonth.data ?? [];

        _eventsByDay.clear();
        for (final t in monthTasks) {
          final key = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          _eventsByDay.putIfAbsent(key, () => []).add(t);
        }

        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: const Text('Calendar'),
          ),
          body: Column(
            children: [
              TableCalendar<Task>(
                firstDay: DateTime.utc(2015, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                  setState(() {
                    _focusedDay = focused;
                  });
                },
                calendarStyle: const CalendarStyle(markersMaxCount: 4),
              ),

              // Header con la data selezionata
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Row(
                  children: [
                    Icon(Icons.event,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(_selectedDay),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              // Selected day's task list
              Expanded(
                child: FutureBuilder<List<Task>>(
                  future: _fetchDayTasks(),
                  builder: (context, snapshotDay) {
                    final dayTasks = snapshotDay.data ?? [];

                    if (snapshotDay.connectionState ==
                            ConnectionState.waiting &&
                        (dayTasks.isEmpty)) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (dayTasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks for this day',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12.0),
                      itemCount: dayTasks.length,
                      itemBuilder: (context, i) {
                        final t = dayTasks[i];
                        return TaskListTile(
                          task: t,
                          onTap: () {
                            // TODO: task detail navigation
                          },
                          onEdit: () async {
                            // TODO: navigazione alla schermata di edit
                            // Dopo l'edit, ricarica con setState(() {});
                          },
                          onDelete: () async {
                            // Conferma eliminazione
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Task'),
                                content: Text('Delete "${t.title}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _repo.deleteTask(t.id);
                              setState(() {}); // Ricarica
                            }
                          },
                          onStatusChanged: (newStatus) async {
                            setState(() {}); // Ricarica
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
