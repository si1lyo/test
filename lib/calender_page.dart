import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class Event {
  final String title;
  final DateTime date;

  Event({
    required this.title,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date.toIso8601String(),
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['title'],
      date: DateTime.parse(json['date']),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    
    _events = [
      Event(
        title: 'シャンプー',
        date: DateTime(2026, 6, 10),
      ),
      Event(
        title: '歯ブラシ',
         date: DateTime(2026, 6, 15),
      ),
      Event(
        title: '洗剤',
        date: DateTime(2026, 6, 20),
      ),
    ];
  }

  Future<void> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = prefs.getStringList('events') ?? [];

    setState(() {
      _events = jsonList
          .map(
            (e) => Event.fromJson(
              jsonDecode(e),
            ),
          )
          .toList();
    });
  }

  Future<void> saveEvents() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = _events
        .map(
          (e) => jsonEncode(
            e.toJson(),
          ),
        )
        .toList();

    await prefs.setStringList(
      'events',
      jsonList,
    );
  }

  List<Event> getEvents(DateTime day) {
    return _events.where((event) {
      return isSameDay(
        event.date,
        day,
      );
    }).toList();
  }

  List<Event> getUpcomingEvents() {
    final today = DateTime.now();

    final upcoming = _events.where((event) {
      return !event.date.isBefore(
        DateTime(
          today.year,
          today.month,
          today.day,
        ),
      );
    }).toList();

    upcoming.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    return upcoming.take(3).toList();
  }

  int daysLeft(DateTime targetDate) {
    final today = DateTime.now();

    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final targetOnly = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    return targetOnly
        .difference(todayOnly)
        .inDays;
  }

  Future<void> addEvent() async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '先に日付を選択してください',
          ),
        ),
      );
      return;
    }

    final controller =
        TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('予定追加'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(
              hintText: '予定名',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'キャンセル',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text
                    .trim()
                    .isEmpty) {
                  return;
                }

                setState(() {
                  _events.add(
                    Event(
                      title: controller.text
                          .trim(),
                      date: _selectedDay!,
                    ),
                  );
                });

                await saveEvents();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                '保存',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteEvent(
    Event event,
  ) async {
    setState(() {
      _events.remove(event);
    });

    await saveEvents();
  }

  @override
  Widget build(BuildContext context) {
    final upcomingEvents =
        getUpcomingEvents();

    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            TableCalendar(
              firstDay:
                  DateTime.utc(
                2020,
                1,
                1,
              ),
              lastDay:
                  DateTime.utc(
                2035,
                12,
                31,
              ),
              focusedDay:
                  _focusedDay,

              selectedDayPredicate:
                  (day) {
                return isSameDay(
                  _selectedDay,
                  day,
                );
              },

              onDaySelected:
                  (
                    selectedDay,
                    focusedDay,
                  ) {
                setState(() {
                  _selectedDay =
                      selectedDay;
                  _focusedDay =
                      focusedDay;
                });
              },

              headerStyle:
                  const HeaderStyle(
                titleCentered:
                    true,
                formatButtonVisible:
                    false,
              ),

              calendarStyle:
                  const CalendarStyle(
                todayDecoration:
                    BoxDecoration(
                  color:
                      Colors.orange,
                  shape:
                      BoxShape.circle,
                ),
                selectedDecoration:
                    BoxDecoration(
                  color:
                      Colors.blue,
                  shape:
                      BoxShape.circle,
                ),
              ),

              calendarBuilders:
                  CalendarBuilders(
                defaultBuilder: (
                  context,
                  day,
                  focusedDay,
                ) {
                  final hasEvent =
                      getEvents(day)
                          .isNotEmpty;

                  if (!hasEvent) {
                    return null;
                  }

                  return Container(
                    margin:
                        const EdgeInsets
                            .all(6),
                    decoration:
                        const BoxDecoration(
                      color:
                          Colors.green,
                      shape:
                          BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style:
                            const TextStyle(
                          color: Colors
                              .white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                '直近の予定',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Expanded(
              child:
                  upcomingEvents
                          .isEmpty
                      ? const Center(
                          child: Text(
                            '予定はありません',
                          ),
                        )
                      : ListView.builder(
                          itemCount:
                              upcomingEvents
                                  .length,
                          itemBuilder:
                              (
                                context,
                                index,
                              ) {
                            final event =
                                upcomingEvents[
                                    index];

                            return Card(
                              child:
                                  ListTile(
                                title: Text(
                                  event.title,
                                ),
                                subtitle:
                                    Text(
                                  '${event.date.year}/${event.date.month}/${event.date.day}',
                                ),
                                trailing:
                                    Text(
                                  'あと${daysLeft(event.date)}日',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                onLongPress:
                                    () {
                                  deleteEvent(
                                    event,
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}