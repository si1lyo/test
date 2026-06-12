import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'setting_widgets.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isAllNotificationsEnabled = true;
  bool _stockAlert = true;
  bool _analysisAlert = true;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.navBg,
        foregroundColor: Colors.white,
        title: const Text('通知設定',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        children: [
          const SettingSectionHeader(title: '全般設定'),
          ThemedSwitchTile(
            icon: _isAllNotificationsEnabled
                ? Icons.notifications_active
                : Icons.notifications_off,
            title: '通知全般',
            subtitle: 'アプリからのすべての通知をコントロールします',
            value: _isAllNotificationsEnabled,
            onChanged: (val) => setState(() {
              _isAllNotificationsEnabled = val;
              if (!val) {
                _stockAlert = false;
                _analysisAlert = false;
              }
            }),
          ),
          const SizedBox(height: 8),
          const SettingSectionHeader(title: '項目別の通知'),
          ThemedSwitchTile(
            icon: Icons.inventory_2_outlined,
            title: '在庫不足アラート',
            subtitle: '商品の残りが少なくなった時',
            value: _stockAlert,
            onChanged: _isAllNotificationsEnabled
                ? (val) => setState(() => _stockAlert = val)
                : null,
          ),
          ThemedSwitchTile(
            icon: Icons.analytics_outlined,
            title: '購入周期の予測通知',
            subtitle: '分析による買い時のお知らせ',
            value: _analysisAlert,
            onChanged: _isAllNotificationsEnabled
                ? (val) => setState(() => _analysisAlert = val)
                : null,
          ),
        ],
      ),
    );
  }
}
