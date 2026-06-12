import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'analysis_tabs/calendar_tab.dart';
import 'analysis_tabs/spending_tab.dart';
import 'analysis_tabs/prediction_tab.dart';
import 'analysis_tabs/history_tab.dart';

class CalendarPage extends StatefulWidget {
  final String searchQuery;
  const CalendarPage({super.key, this.searchQuery = ''});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _selectedIndex = 0;

  static const _tabs = ['カレンダー', '支出', '予測', '購入履歴'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '分析',
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.accent),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedIndex == index;
                return InkWell(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? colors.accent
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        color: isSelected
                            ? colors.accent
                            : Colors.grey[600],
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CalendarTab(searchQuery: widget.searchQuery),
          const SpendingTab(),
          const PredictionTab(),
          const HistoryTab(),
        ],
      ),
    );
  }
}
