import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import '../app_theme.dart';
import '../product_detail_page.dart';
import '../services/consumption_defaults.dart';

class CalendarTab extends StatefulWidget {
  final String searchQuery;
  const CalendarTab({super.key, this.searchQuery = ''});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final productsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('my_products')
        .orderBy('purchaseDate', descending: true)
        .get();

    final receiptsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('receipts')
        .orderBy('createdAt')
        .get();

    // 購入日履歴を品名ごとに集計
    final Map<String, List<DateTime>> purchaseDates = {};
    for (final doc in receiptsSnap.docs) {
      final data = doc.data();
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) continue;
      final date = ts.toDate();
      final items = data['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final name = (item as Map)['name'] as String? ?? '';
        if (name.isEmpty) continue;
        purchaseDates.putIfAbsent(name, () => []).add(date);
      }
    }

    // 品名ごとの最新商品データ
    final Map<String, Map<String, dynamic>> latestProducts = {};
    final Map<String, String> productDocIds = {};
    for (final doc in productsSnap.docs) {
      final data = doc.data();
      final name = data['name'] as String? ?? '';
      if (name.isEmpty || latestProducts.containsKey(name)) continue;
      latestProducts[name] = data;
      productDocIds[name] = doc.id;
    }

    if (!mounted) return;

    final events = <CalEvent>[];
    for (final entry in latestProducts.entries) {
      final name = entry.key;
      final data = entry.value;
      final genre = data['genre'] as String? ?? 'その他';
      final ts = data['purchaseDate'] as Timestamp?;
      final lastPurchase = ts?.toDate() ?? DateTime.now();
      final aiEstimatedDays = (data['aiEstimatedDays'] as num?)?.toInt();

      final dates = purchaseDates[name] ?? [lastPurchase];
      dates.sort();

      final days = ConsumptionDefaults.personalized(
        name: name,
        genre: genre,
        sortedDates: dates,
        aiEstimatedDays: aiEstimatedDays,
      );

      events.add(CalEvent(
        docId: productDocIds[name] ?? '',
        title: name,
        date: lastPurchase.add(Duration(days: days)),
        avgDays: days,
        purchaseCount: dates.length,
      ));
    }

    setState(() => _events = events);
  }

  List<CalEvent> _getForDay(DateTime day) =>
      _events.where((e) => isSameDay(e.date, day)).toList();

  List<CalEvent> _getSelected() {
    if (_selectedDay == null) return [];
    return _getForDay(_selectedDay!);
  }

  List<CalEvent> _upcoming() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    var list = _events.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return !d.isBefore(today);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (widget.searchQuery.isNotEmpty) {
      list = list
          .where(
            (e) => e.title
                .toLowerCase()
                .contains(widget.searchQuery.toLowerCase()),
          )
          .toList();
    }
    return list;
  }

  int _daysLeft(DateTime d) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return DateTime(d.year, d.month, d.day).difference(today).inDays;
  }

  Color _urgencyColor(int days) {
    if (days < 0) return Colors.grey;
    if (days <= 3) return Colors.red;
    if (days <= 7) return kMint;
    return kDarkGreen;
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = _getSelected();
    final upcoming = _upcoming();
    final colors = AppColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
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
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: '月'},
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colors.accent,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: colors.accent),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: colors.accent),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: kMint, width: 2),
                ),
                selectedDecoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: TextStyle(color: Colors.red[300]),
                outsideDaysVisible: false,
              ),
              calendarBuilders: CalendarBuilders(
                todayBuilder: (context, day, _) {
                  final events = _getForDay(day);
                  final eventColor = events.isEmpty
                      ? null
                      : _urgencyColor(_daysLeft(day));
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: kMint, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: colors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (eventColor != null)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: eventColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                defaultBuilder: (context, day, _) {
                  final events = _getForDay(day);
                  if (events.isEmpty) return null;
                  final color = _urgencyColor(_daysLeft(day));
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
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
                      ),
                      if (events.length > 1)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${events.length}',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: color),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          // 選択日の商品一覧
          if (_selectedDay != null && selectedItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              '${_selectedDay!.month}/${_selectedDay!.day} のなくなり予測',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.accent,
              ),
            ),
            const SizedBox(height: 10),
            ...selectedItems.map((e) => _eventTile(e, colors)),
          ],
          const SizedBox(height: 20),
          Text(
            '直近のなくなり予測',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 12),
          if (upcoming.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  '登録された商品はまだありません',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcoming.length,
              itemBuilder: (context, index) =>
                  _eventTile(upcoming[index], colors),
            ),
        ],
      ),
    );
  }

  Widget _eventTile(CalEvent event, AppColors colors) {
    final remaining = _daysLeft(event.date);
    final color = _urgencyColor(remaining);
    return GestureDetector(
      onTap: event.docId.isNotEmpty
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(docId: event.docId),
                ),
              )
          : null,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.inventory_2, color: color),
        title: Text(event.title,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          event.purchaseCount >= 2 ? '${event.avgDays}日周期（実績）' : '${event.avgDays}日周期（AI推測）',
          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            remaining == 0
                ? '今日まで'
                : remaining < 0
                    ? 'もう切れた'
                    : 'あと$remaining日',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class CalEvent {
  final String docId;
  final String title;
  final DateTime date;
  final int avgDays;
  final int purchaseCount;

  CalEvent({
    required this.docId,
    required this.title,
    required this.date,
    required this.avgDays,
    required this.purchaseCount,
  });
}
