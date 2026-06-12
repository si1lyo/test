import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../product_detail_page.dart';
import '../services/consumption_defaults.dart';

class PredictionTab extends StatelessWidget {
  const PredictionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    final colors = AppColors.of(context);

    return FutureBuilder<PredictionData>(
      future: _loadPredictions(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kDarkGreen),
          );
        }
        final data = snapshot.data;
        if (data == null || data.items.isEmpty) {
          return const Center(
            child: Text(
              '購入履歴がありません\nレシートをスキャンしてみましょう',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => (context as Element).markNeedsBuild(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            itemCount: data.items.length,
            itemBuilder: (context, index) {
              final item = data.items[index];
              return PredictionBar(item: item, colors: colors);
            },
          ),
        );
      },
    );
  }

  Future<PredictionData> _loadPredictions(String uid) async {
    final productsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('my_products')
        .orderBy('purchaseDate', descending: true)
        .get();

    final receiptsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('receipts')
        .orderBy('createdAt')
        .get();

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

    final Map<String, Map<String, dynamic>> latestProducts = {};
    final Map<String, String> productDocIds = {};
    for (final doc in productsSnap.docs) {
      final data = doc.data();
      final name = data['name'] as String? ?? '';
      if (name.isEmpty) continue;
      if (!latestProducts.containsKey(name)) {
        latestProducts[name] = data;
        productDocIds[name] = doc.id;
      }
    }

    final List<PredictionItem> items = [];
    for (final entry in latestProducts.entries) {
      final name = entry.key;
      final data = entry.value;
      final genre = data['genre'] as String? ?? 'その他';
      final ts = data['purchaseDate'] as Timestamp?;
      final lastPurchase = ts?.toDate() ?? DateTime.now();
      final aiEstimatedDays = (data['aiEstimatedDays'] as num?)?.toInt();

      final dates = purchaseDates[name] ?? [lastPurchase];
      dates.sort();

      // パーソナライズ: 購入回数が増えるほど実績値を重視、初回はAI推測をデフォルトに使用
      final avgDays = ConsumptionDefaults.personalized(
        name: name,
        genre: genre,
        sortedDates: dates,
        aiEstimatedDays: aiEstimatedDays,
      );
      final isAiDefault = dates.length < 2;

      final predictedDate = lastPurchase.add(Duration(days: avgDays));
      final daysElapsed = DateTime.now().difference(lastPurchase).inDays;
      final daysLeft = predictedDate.difference(DateTime.now()).inDays;
      final progress = (daysElapsed / avgDays).clamp(0.0, 1.0);

      items.add(
        PredictionItem(
          docId: productDocIds[name] ?? '',
          name: name,
          genre: genre,
          lastPurchase: lastPurchase,
          predictedDate: predictedDate,
          daysLeft: daysLeft,
          progress: progress,
          avgDays: avgDays,
          purchaseCount: dates.length,
          isAiDefault: isAiDefault,
        ),
      );
    }

    items.sort((a, b) => b.progress.compareTo(a.progress));

    return PredictionData(items: items);
  }
}

class PredictionData {
  final List<PredictionItem> items;
  PredictionData({required this.items});
}

class PredictionItem {
  final String docId;
  final String name;
  final String genre;
  final DateTime lastPurchase;
  final DateTime predictedDate;
  final int daysLeft;
  final double progress;
  final int avgDays;
  final int purchaseCount;
  final bool isAiDefault;

  PredictionItem({
    required this.docId,
    required this.name,
    required this.genre,
    required this.lastPurchase,
    required this.predictedDate,
    required this.daysLeft,
    required this.progress,
    required this.avgDays,
    required this.purchaseCount,
    this.isAiDefault = false,
  });
}

class PredictionBar extends StatelessWidget {
  final PredictionItem item;
  final AppColors colors;
  const PredictionBar({super.key, required this.item, required this.colors});

  Color get _barColor {
    if (item.progress >= 0.85) return Colors.red;
    if (item.progress >= 0.6) return kMint;
    return kDarkGreen;
  }

  String get _statusText {
    if (item.daysLeft < 0) return 'もうすぐ切れそう';
    if (item.daysLeft == 0) return '今日なくなる予測';
    return 'あと${item.daysLeft}日';
  }

  String get _sourceLabel {
    if (item.purchaseCount >= 3) {
      return '${item.purchaseCount}回の実績から最適化';
    }
    if (item.purchaseCount == 2) {
      return '購入実績+AI補正';
    }
    return 'AIが推測';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.docId.isNotEmpty
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(docId: item.docId),
                ),
              )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 10,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${DateFormat('M/d').format(item.lastPurchase)}購入  ·  ${item.avgDays}日周期',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              Row(
                children: [
                  if (item.isAiDefault)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.auto_awesome,
                          size: 11, color: Colors.grey[400]),
                    ),
                  Text(
                    _sourceLabel,
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}
