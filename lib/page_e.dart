import 'package:flutter/material.dart';

class PageE extends StatelessWidget {
  const PageE({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'), // タイトルを「設定」に変更
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _buildSettingsItem(
            context,
            icon: Icons.settings,
            title: '一般',
            onTap: () {
              // 一般設定への遷移処理など
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.manage_accounts,
            title: 'アカウント・データ管理',
            onTap: () {
              // アカウント管理への遷移処理
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.notifications,
            title: '通知',
            onTap: () {
              // 通知設定への遷移処理
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.link,
            title: '外部サービスの連携',
            onTap: () {
              // 外部サービス連携への遷移処理
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.inventory_2,
            title: '登録商品',
            onTap: () {
              // 登録商品一覧への遷移処理
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.analytics,
            title: '購入周期分析アルゴリズム',
            onTap: () {
              // 分析設定への遷移処理
            },
          ),
        ],
      ),
    );
  }

  // 設定項目の共通パーツを作成するメソッド
  Widget _buildSettingsItem(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.blueGrey),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
          trailing: const Icon(Icons.chevron_right), // 右矢印を追加
          onTap: onTap,
        ),
        const Divider(height: 1), // 項目間の区切り線
      ],
    );
  }
}