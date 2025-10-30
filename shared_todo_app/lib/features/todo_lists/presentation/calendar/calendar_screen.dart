import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_todo_app/data/models/task.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';

import '../../../../config/router/app_router.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repo = TaskRepository();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // cache per markers
  final Map<DateTime, List<Task>> _eventsByDay = {};

  // ---------- Helpers per i range ----------
  DateTime _monthGridStart(DateTime focused) {
    final firstOfMonth = DateTime(focused.year, focused.month, 1);
    // padding di una settimana per coprire tutta la griglia
    return firstOfMonth.subtract(const Duration(days: 7));
  }

  DateTime _monthGridEnd(DateTime focused) {
    final nextMonth = DateTime(focused.year, focused.month + 1, 1);
    return nextMonth.add(const Duration(days: 7)); // esclusivo
  }

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _dayEnd(DateTime d) => _dayStart(d).add(const Duration(days: 1)); // esclusivo

  // ---------- Future per la griglia mensile ----------
  Future<List<Task>> _fetchMonthTasks() {
    final start = _monthGridStart(_focusedDay);
    final end = _monthGridEnd(_focusedDay);
    return _repo.getTasksForCalendar_Future(start, end);
  }

  // ---------- Future per il giorno selezionato ----------
  Future<List<Task>> _fetchDayTasks() {
    final start = _dayStart(_selectedDay);
    final end   = _dayEnd(_selectedDay);
    return _repo.getTasksForCalendar_Future(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: _fetchMonthTasks(),
      builder: (context, snapshotMonth) {
        final monthTasks = snapshotMonth.data ?? [];

        // ricostruisci la mappa per markers
        _eventsByDay.clear();
        for (final t in monthTasks) {
          final key = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          _eventsByDay.putIfAbsent(key, () => []).add(t);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Calendario'),
            automaticallyImplyLeading: false,
            leading: IconButton(
              tooltip: 'Indietro',
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();   // torna alla pagina precedente
                } else {
                  context.go(AppRouter.home);    // fallback alla home
                }
              },
            ),
          ),
          body: Column(
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
                  setState(() {
                    _focusedDay = focused;
                  });
                },
                calendarStyle: const CalendarStyle(markersMaxCount: 4),
              ),

              const Divider(height: 0),

              // Lista task del giorno selezionato
              Expanded(
                child: FutureBuilder<List<Task>>(
                  future: _fetchDayTasks(),
                  builder: (context, snapshotDay) {
                    final dayTasks = snapshotDay.data ?? [];

                    if (snapshotDay.connectionState == ConnectionState.waiting &&
                        (dayTasks.isEmpty)) {
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
                            // TODO: nav. al dettaglio task (GoRouter route al tuo dettaglio)
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
