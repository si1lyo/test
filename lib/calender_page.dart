import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

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
    _listenToFirestore();
  }

  // Firestoreをリアルタイムで監視してイベントに変換
  void _listenToFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('my_products')
        .orderBy('purchaseDate', descending: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _events = snapshot.docs.map((doc) {
          final data = doc.data();
          final Timestamp? timestamp = data['purchaseDate'];

          // purchaseDate + 7日 を賞味期限とする
          final DateTime baseDate = timestamp != null
              ? timestamp.toDate()
              : DateTime.now();
          final DateTime expiryDate = baseDate.add(const Duration(days: 7));

          return Event(
            title: data['name'] ?? '商品名なし',
            date: expiryDate,
          );
        }).toList();
      });
    });
  }

  List<Event> getEvents(DateTime day) {
    return _events.where((event) => isSameDay(event.date, day)).toList();
  }

  List<Event> getUpcomingEvents() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final upcoming = _events
        .where((event) => !event.date.isBefore(todayOnly))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return upcoming.take(3).toList();
  }

  int daysLeft(DateTime targetDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final targetOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return targetOnly.difference(todayOnly).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final upcomingEvents = getUpcomingEvents();

    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final events = getEvents(day);
                  if (events.isEmpty) return null;

                  // 期限切れ間近（3日以内）は赤、それ以外は緑
                  final daysRemaining = daysLeft(day);
                  final color = daysRemaining <= 3 ? Colors.red : Colors.green;

                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '直近の賞味期限',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: upcomingEvents.isEmpty
                  ? const Center(child: Text('登録された商品はまだありません'))
                  : ListView.builder(
                      itemCount: upcomingEvents.length,
                      itemBuilder: (context, index) {
                        final event = upcomingEvents[index];
                        final remaining = daysLeft(event.date);

                        // 残り日数で色を変える
                        final color = remaining <= 3
                            ? Colors.red
                            : remaining <= 7
                                ? Colors.orange
                                : Colors.green;

                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.inventory_2, color: color),
                            title: Text(event.title),
                            subtitle: Text(
                              '賞味期限: ${event.date.year}/${event.date.month}/${event.date.day}',
                            ),
                            trailing: Text(
                              remaining == 0
                                  ? '今日まで'
                                  : remaining < 0
                                      ? '期限切れ'
                                      : 'あと${remaining}日',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
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

class Event {
  final String title;
  final DateTime date;

  Event({required this.title, required this.date});
}