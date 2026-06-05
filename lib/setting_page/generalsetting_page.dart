import 'package:flutter/material.dart';

class GeneralPage extends StatefulWidget {
  const GeneralPage({super.key});

  @override
  State<GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {
  // --- その場で変更するための状態（変数） ---
  bool _isDarkMode = false;      // ダークモード
  bool _isVibrationOn = true;    // スキャン時の振動

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('一般設定'),
      ),
      body: ListView(
        children: [
          // 【デザイン設定】
          const _SectionHeader(title: 'デザイン'),
          SwitchListTile(
            secondary: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
            title: const Text('ダークモード'),
            subtitle: Text(_isDarkMode ? '背景を暗くします' : '背景を明るくします'),
            value: _isDarkMode,
            onChanged: (bool value) {
              // setStateを使うことで、スイッチの見た目がその場で変わります
              setState(() {
                _isDarkMode = value;
              });
            },
          ),
          const Divider(),

          // 【スキャン時の挙動】
          const _SectionHeader(title: 'スキャン時の挙動'),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('スキャン成功時の振動'),
            subtitle: Text(_isVibrationOn ? '振動する' : '振動しない'),
            value: _isVibrationOn,
            onChanged: (bool value) {
              setState(() {
                _isVibrationOn = value;
              });
            },
          ),
          const Divider(),

          // 【ヘルプ・利用規約】
          const _SectionHeader(title: 'サポート'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('ヘルプ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // ヘルプページへの遷移処理など
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('利用規約'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 利用規約ページへの遷移処理など
            },
          ),
        ],
      ),
    );
  }
}

// セクション区切り用の見出しパーツ
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}