import 'package:flutter/material.dart';
import 'generalsetting_page.dart'; // セミコロン忘れがないか確認

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _buildSettingsItem(
            context,
            icon: Icons.settings,
            title: '一般',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GeneralPage(), // constを外しました
                ),
              );
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.manage_accounts,
            title: 'アカウント・データ管理',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountPage(), // constを外しました
                ),
              );
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.notifications,
            title: '通知設定',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPage(), // constを外しました
                ),
              );
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.link,
            title: '外部サービスの連携',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExternalServicePage(), // constを外しました
                ),
              );
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.inventory_2,
            title: '登録商品',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisteredProductsPage(), // constを外しました
                ),
              );
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.analytics,
            title: '購入周期分析アルゴリズム',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalysisAlgorithmPage(), // constを外しました
                ),
              );
            },
          ),
        ],
      ),
    );
  }

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
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}

// --- 下に書くクラスからも const を一度外してシンプルにします ---

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アカウント・データ管理')),
      body: const Center(child: Text('アカウント管理のコンテンツ')),
    );
  }
}

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知設定')),
      body: const Center(child: Text('通知設定のコンテンツ')),
    );
  }
}

class ExternalServicePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('外部サービスの連携')),
      body: const Center(child: Text('外部連携のコンテンツ')),
    );
  }
}

class RegisteredProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登録商品')),
      body: const Center(child: Text('登録商品の一覧')),
    );
  }
}

class AnalysisAlgorithmPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分析アルゴリズム')),
      body: const Center(child: Text('アルゴリズム設定のコンテンツ')),
    );
  }
}