import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'widgets/icon_picker.dart';

class ProductDetailPage extends StatefulWidget {
  final String docId;
  final bool isGroup;
  final String? groupId;

  const ProductDetailPage({
    super.key,
    required this.docId,
    this.isGroup = false,
    this.groupId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  DocumentReference get _docRef {
    if (widget.isGroup && widget.groupId != null) {
      return FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('group_products')
          .doc(widget.docId);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('my_products')
        .doc(widget.docId);
  }

  Future<List<_PurchaseRecord>> _loadHistory(String name) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('receipts')
        .orderBy('createdAt', descending: true)
        .get();

    final records = <_PurchaseRecord>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) continue;
      final items = (data['items'] as List<dynamic>?) ?? [];
      for (final item in items) {
        final m = item as Map;
        if ((m['name'] as String?) == name) {
          records.add(_PurchaseRecord(
            date: ts.toDate(),
            price: (m['price'] as num?)?.toDouble() ?? 0,
            storeName: data['storeName'] as String?,
          ));
        }
      }
    }
    return records;
  }

  Future<void> _delete() async {
    final colors = AppColors.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colors.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                '商品を削除しますか？',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'この操作は元に戻せません。',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.accent,
                        side: BorderSide(color: colors.accent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('削除'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      await _docRef.delete();
    }
  }

  void _showEdit(Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name'] as String? ?? '');
    final typeCtrl = TextEditingController(text: data['type'] as String? ?? '');
    final priceCtrl = TextEditingController(
        text: (data['price'] as num?) != null
            ? (data['price'] as num).toStringAsFixed(0)
            : '');
    String genre = data['genre'] as String? ?? '食品';
    String icon = data['icon'] as String? ?? '';
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('商品を編集',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.accent)),
                const SizedBox(height: 20),
                // アイコン選択
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picked =
                            await showIconPicker(ctx, current: icon);
                        if (picked != null) setSheet(() => icon = picked);
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: colors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: () {
                            final code = int.tryParse(icon);
                            if (code != null) {
                              return Icon(
                                IconData(code, fontFamily: 'MaterialIcons'),
                                color: colors.accent,
                                size: 28,
                              );
                            }
                            return Icon(Icons.add_photo_alternate_outlined,
                                color: colors.accent);
                          }(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        decoration:
                            const InputDecoration(labelText: '商品名'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: typeCtrl,
                    decoration:
                        const InputDecoration(labelText: '種類（例：牛乳）')),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '価格 (¥)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: genre,
                  decoration: const InputDecoration(labelText: 'ジャンル'),
                  items: ['食品', '日用品', 'その他']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setSheet(() => genre = v!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: colors.accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      await _docRef.update({
                        'name': nameCtrl.text.trim(),
                        'type': typeCtrl.text.trim(),
                        'genre': genre,
                        'icon': icon,
                        if (priceCtrl.text.isNotEmpty)
                          'price':
                              double.tryParse(priceCtrl.text) ?? 0,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('保存', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: _docRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final name = data['name'] as String? ?? '';
        final genre = data['genre'] as String? ?? '';
        final price = (data['price'] as num?)?.toDouble() ?? 0;
        final purchaseDate =
            (data['purchaseDate'] as Timestamp?)?.toDate();
        final icon = data['icon'] as String? ?? '';

        return Scaffold(
          backgroundColor: colors.bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: colors.accent),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('商品詳細',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: colors.accent)),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: colors.accent),
                onPressed: () => _showEdit(data),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _delete,
              ),
            ],
          ),
          body: FutureBuilder<List<_PurchaseRecord>>(
            future: _loadHistory(name),
            builder: (context, histSnap) {
              final history = histSnap.data ?? [];
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(
                        colors, icon, name, genre, price, purchaseDate),
                    const SizedBox(height: 20),
                    _buildPredictionSection(
                        colors, purchaseDate, genre, history),
                    const SizedBox(height: 20),
                    if (history.isNotEmpty) ...[
                      _buildPriceChart(colors, history),
                      const SizedBox(height: 20),
                      _buildHistoryList(colors, history),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppColors colors, String icon, String name,
      String genre, double price, DateTime? purchaseDate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: () {
                final code = int.tryParse(icon);
                if (code != null) {
                  return Icon(
                    IconData(code, fontFamily: 'MaterialIcons'),
                    color: colors.accent,
                    size: 30,
                  );
                }
                return Icon(Icons.inventory_2_outlined,
                    color: colors.accent, size: 30);
              }(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    if (genre.isNotEmpty)
                      _Chip(genre, colors.accent),
                    if (price > 0)
                      _Chip(
                          '¥${NumberFormat('#,###').format(price.toInt())}',
                          kMint),
                  ],
                ),
                if (purchaseDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('yyyy年M月d日購入').format(purchaseDate),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionSection(AppColors colors, DateTime? purchaseDate,
      String genre, List<_PurchaseRecord> history) {
    int avgDays;
    if (history.length >= 2) {
      final dates = history.map((h) => h.date).toList()
        ..sort();
      int total = 0;
      for (int i = 1; i < dates.length; i++) {
        total += dates[i].difference(dates[i - 1]).inDays;
      }
      avgDays = (total / (dates.length - 1)).round();
      if (avgDays < 1) avgDays = 1;
    } else {
      avgDays = switch (genre) {
        '食品' => 7,
        '日用品' => 30,
        _ => 14,
      };
    }

    final last = purchaseDate ?? DateTime.now();
    final daysElapsed = DateTime.now().difference(last).inDays;
    final daysLeft = avgDays - daysElapsed;
    final progress = (daysElapsed / avgDays).clamp(0.0, 1.0);

    Color barColor;
    if (progress >= 0.85) {
      barColor = Colors.red;
    } else if (progress >= 0.6) {
      barColor = kMint;
    } else {
      barColor = kDarkGreen;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('なくなり予測',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.accent)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  daysLeft <= 0 ? 'もうすぐ切れそう' : 'あと$daysLeft日',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: barColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            history.length >= 2
                ? '${history.length}回の購入データから算出（平均${avgDays}日周期）'
                : 'デフォルト値（${avgDays}日）で予測中',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChart(AppColors colors, List<_PurchaseRecord> history) {
    final sorted = [...history]..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length < 2) {
      return const SizedBox.shrink();
    }

    final spots = sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.price);
    }).toList();

    final maxY = sorted.map((h) => h.price).fold(0.0, (a, b) => a > b ? a : b);
    final minY = sorted.map((h) => h.price).fold(double.infinity, (a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('価格推移',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.accent)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: (minY * 0.9).floorToDouble(),
                maxY: (maxY * 1.1).ceilToDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: colors.accent,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: colors.accent,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors.accent.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, _) => Text(
                        '¥${v.toInt()}',
                        style: const TextStyle(
                            fontSize: 9, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= sorted.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('M/d').format(sorted[i].date),
                            style: const TextStyle(
                                fontSize: 9, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(AppColors colors, List<_PurchaseRecord> history) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('購入履歴（${history.length}回）',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.accent)),
          const SizedBox(height: 12),
          ...history.map((h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.receipt_outlined,
                        color: Colors.grey[400], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('yyyy年M月d日').format(h.date),
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (h.storeName != null) ...[
                      Text('  ${h.storeName}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                    const Spacer(),
                    if (h.price > 0)
                      Text(
                        '¥${NumberFormat('#,###').format(h.price.toInt())}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _PurchaseRecord {
  final DateTime date;
  final double price;
  final String? storeName;
  _PurchaseRecord(
      {required this.date, required this.price, this.storeName});
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
