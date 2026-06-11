import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'generalsetting_page.dart';
import 'notificationsetting_page.dart';
import 'registered_products_page.dart';
import 'accountsetting_page.dart';

class SettingPage extends StatelessWidget {
  final String searchQuery;
  const SettingPage({super.key, this.searchQuery = ''});

  static const _allItems = [
    _SettingItem(icon: Icons.settings, title: '一般'),
    _SettingItem(icon: Icons.manage_accounts, title: 'アカウント・グループ管理'),
    _SettingItem(icon: Icons.notifications, title: '通知設定'),
    _SettingItem(icon: Icons.link, title: '外部サービスの連携'),
    _SettingItem(icon: Icons.inventory_2, title: '登録商品'),
    _SettingItem(icon: Icons.analytics, title: '購入周期分析アルゴリズム'),
  ];

  void _navigate(BuildContext context, String title) {
    Widget page;
    switch (title) {
      case '一般':
        page = GeneralPage();
      case 'アカウント・グループ管理':
        page = const AccountPage();
      case '通知設定':
        page = NotificationPage();
      case '外部サービスの連携':
        page = ExternalServicePage();
      case '登録商品':
        page = const RegisteredProductsPage();
      default:
        page = AnalysisAlgorithmPage();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final items = searchQuery.isEmpty
        ? _allItems
        : _allItems
            .where((item) =>
                item.title.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('設定',
            style: TextStyle(fontWeight: FontWeight.bold, color: kDarkGreen)),
        centerTitle: true,
      ),
      body: items.isEmpty
          ? Center(
              child: Text('「$searchQuery」は見つかりません',
                  style: const TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kDarkGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: kDarkGreen, size: 20),
                    ),
                    title: Text(item.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right,
                        color: kDarkGreen, size: 20),
                    onTap: () => _navigate(context, item.title),
                  ),
                );
              },
            ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  const _SettingItem({required this.icon, required this.title});
}

// ── サブページ ────────────────────────────────────────────────
class ExternalServicePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('外部サービスの連携'),
            backgroundColor: kDarkGreen,
            foregroundColor: Colors.white),
        body: const Center(child: Text('外部連携のコンテンツ')),
      );
}

class AnalysisAlgorithmPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('分析アルゴリズム'),
            backgroundColor: kDarkGreen,
            foregroundColor: Colors.white),
        body: const Center(child: Text('アルゴリズム設定のコンテンツ')),
      );
}
