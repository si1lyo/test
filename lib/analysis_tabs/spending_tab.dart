import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';

class SpendingTab extends StatefulWidget {
  const SpendingTab({super.key});

  @override
  State<SpendingTab> createState() => _SpendingTabState();
}

class _SpendingTabState extends State<SpendingTab> {
  // 表示する直近の月数: 1, 3, 6
  int _monthRange = 3;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    final colors = AppColors.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('receipts')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kDarkGreen),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        if (allDocs.isEmpty) {
          return const Center(
            child: Text(
              '購入履歴がありません\nレシートをスキャンしてみましょう',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // 期間フィルター適用
        final cutoff = DateTime.now().subtract(
          Duration(days: _monthRange * 30),
        );
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = data['createdAt'] as Timestamp?;
          if (ts == null) return false;
          return ts.toDate().isAfter(cutoff);
        }).toList();

        final Map<String, double> monthlyTotal = {};
        final Map<String, double> genreTotal = {'食品': 0, '日用品': 0, 'その他': 0};
        final Map<String, double> itemTotal = {};

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = data['createdAt'] as Timestamp?;
          if (ts == null) continue;
          final date = ts.toDate();
          final key = DateFormat('yyyy/MM').format(date);
          final total = (data['total'] as num?)?.toDouble() ?? 0;
          monthlyTotal[key] = (monthlyTotal[key] ?? 0) + total;

          final items = (data['items'] as List<dynamic>?) ?? [];
          for (final item in items) {
            final m = item as Map;
            final name = m['name'] as String? ?? '';
            final price = (m['price'] as num?)?.toDouble() ?? 0;
            final qty = (m['quantity'] as num?)?.toInt() ?? 1;
            final genre = m['genre'] as String? ?? 'その他';
            final spend = price * qty;
            if (name.isNotEmpty) {
              itemTotal[name] = (itemTotal[name] ?? 0) + spend;
            }
            final g = ['食品', '日用品'].contains(genre) ? genre : 'その他';
            genreTotal[g] = (genreTotal[g] ?? 0) + spend;
          }
        }

        final topItems = itemTotal.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = topItems.take(5).toList();
        final genreSum = genreTotal.values.fold(0.0, (a, b) => a + b);

        final sortedKeys = monthlyTotal.keys.toList()..sort();

        final maxY = sortedKeys.isEmpty
            ? 0.0
            : sortedKeys
                  .map((k) => monthlyTotal[k]!)
                  .fold(0.0, (a, b) => a > b ? a : b);

        final barGroups = sortedKeys.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: monthlyTotal[e.value]!,
                color: kDarkGreen,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList();

        final totalAll = sortedKeys.fold(
          0.0,
          (acc, k) => acc + monthlyTotal[k]!,
        );
        final avgMonthly = sortedKeys.isEmpty
            ? 0.0
            : totalAll / sortedKeys.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 期間セレクター
              _PeriodSelector(
                selected: _monthRange,
                onChanged: (v) => setState(() => _monthRange = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SummaryCard(
                    label: '直近$_monthRangeヶ月合計',
                    value: '¥${NumberFormat('#,###').format(totalAll.toInt())}',
                    color: kDarkGreen,
                  ),
                  const SizedBox(width: 12),
                  SummaryCard(
                    label: '月平均',
                    value:
                        '¥${NumberFormat('#,###').format(avgMonthly.toInt())}',
                    color: kMint,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '月別支出',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: sortedKeys.isEmpty
                    ? Container(
                        height: 80,
                        alignment: Alignment.center,
                        child: Text(
                          '該当期間のデータがありません',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxY * 1.2,
                            barGroups: barGroups,
                            barTouchData: BarTouchData(
                              handleBuiltInTouches: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) =>
                                    kDarkGreen.withValues(alpha: 0.9),
                                tooltipBorderRadius: BorderRadius.circular(8),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final key = sortedKeys[group.x];
                                  final month = key.substring(5);
                                  return BarTooltipItem(
                                    '$month月\n',
                                    const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            '¥${NumberFormat('#,###').format(rod.toY.toInt())}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: Colors.grey.withValues(alpha: 0.2),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 52,
                                  getTitlesWidget: (value, _) => Text(
                                    '¥${NumberFormat('#,###').format(value.toInt())}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, _) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= sortedKeys.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final label = sortedKeys[idx].substring(5);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '$label月',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                '月別内訳',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: 12),
              ...sortedKeys.reversed.map(
                (key) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '¥${NumberFormat('#,###').format(monthlyTotal[key]!.toInt())}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kDarkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'カテゴリ内訳',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: 12),
              if (genreSum > 0) ...[
                ...[
                  ('食品', kDarkGreen),
                  ('日用品', kMint),
                  ('その他', Colors.grey),
                ].map((entry) {
                  final label = entry.$1;
                  final color = entry.$2;
                  final amount = genreTotal[label] ?? 0;
                  final ratio = genreSum > 0 ? amount / genreSum : 0.0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '¥${NumberFormat('#,###').format(amount.toInt())}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(ratio * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: Colors.grey.withValues(
                              alpha: 0.15,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),
              if (top5.isNotEmpty) ...[
                Text(
                  '支出上位商品',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                ...top5.asMap().entries.map((e) {
                  final rank = e.key + 1;
                  final name = e.value.key;
                  final amount = e.value.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: rank == 1
                                ? kDarkGreen
                                : rank == 2
                                ? kMint
                                : rank == 3
                                ? const Color(0xFF89C4B5)
                                : Colors.grey[200]!,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: rank <= 3
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '¥${NumberFormat('#,###').format(amount.toInt())}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kDarkGreen,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [(1, '1ヶ月'), (3, '3ヶ月'), (6, '6ヶ月')];
    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? kDarkGreen
                    : kDarkGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : kDarkGreen,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
