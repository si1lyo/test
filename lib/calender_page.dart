import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'app_theme.dart';

class CalendarPage extends StatefulWidget {
  final String searchQuery;
  const CalendarPage({super.key, this.searchQuery = ''});

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
      if (!mounted) return;
      setState(() {
        _events = snapshot.docs.map((doc) {
          final data = doc.data();
          final Timestamp? ts = data['purchaseDate'];
          final base = ts?.toDate() ?? DateTime.now();
          return Event(
            title: data['name'] ?? '商品名なし',
            date: base.add(const Duration(days: 7)),
          );
        }).toList();
      });
    });
  }

  List<Event> _getEventsForDay(DateTime day) =>
      _events.where((e) => isSameDay(e.date, day)).toList();

  List<Event> _getUpcoming() {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    var list = _events
        .where((e) {
          final d = DateTime(e.date.year, e.date.month, e.date.day);
          return !d.isBefore(today);
        })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (widget.searchQuery.isNotEmpty) {
      list = list
          .where((e) => e.title
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  int _daysLeft(DateTime d) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final target = DateTime(d.year, d.month, d.day);
    return target.difference(today).inDays;
  }

  Color _urgencyColor(int days) {
    if (days < 0) return Colors.grey;
    if (days <= 3) return Colors.red;
    if (days <= 7) return kMint;
    return kDarkGreen;
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _getUpcoming();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('カレンダー',
            style: TextStyle(fontWeight: FontWeight.bold, color: kDarkGreen)),
        centerTitle: true,
      ),
      // SingleChildScrollView で全体を包んでオーバーフロー解消
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── カレンダー ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                // 月表示固定でサイズ変動を防ぐ
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: '月'},
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kDarkGreen,
                  ),
                  leftChevronIcon:
                      Icon(Icons.chevron_left, color: kDarkGreen),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: kDarkGreen),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: const BoxDecoration(
                      color: kMint, shape: BoxShape.circle),
                  selectedDecoration: const BoxDecoration(
                      color: kDarkGreen, shape: BoxShape.circle),
                  todayTextStyle: const TextStyle(color: Colors.white),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.red[300]),
                  outsideDaysVisible: false,
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) {
                    final events = _getEventsForDay(day);
                    if (events.isEmpty) return null;
                    final color = _urgencyColor(_daysLeft(day));
                    return Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                      child: Center(
                        child: Text('${day.day}',
                            style:
                                const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── セクションヘッダ ──
            Row(
              children: [
                const Text('直近の賞味期限',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: kDarkGreen)),
                if (widget.searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '「${widget.searchQuery}」で絞り込み中',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // ── イベントリスト（shrinkWrap でColumn内に展開） ──
            if (upcoming.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    widget.searchQuery.isNotEmpty
                        ? '「${widget.searchQuery}」は見つかりません'
                        : '登録された商品はまだありません',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcoming.length,
                itemBuilder: (context, index) {
                  final event = upcoming[index];
                  final remaining = _daysLeft(event.date);
                  final color = _urgencyColor(remaining);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Icon(Icons.inventory_2, color: color),
                      title: Text(event.title),
                      subtitle: Text(
                        '賞味期限: ${event.date.year}/${event.date.month}/${event.date.day}',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          remaining == 0
                              ? '今日まで'
                              : remaining < 0
                                  ? '期限切れ'
                                  : 'あと$remaining日',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
