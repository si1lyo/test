import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import '../app_theme.dart';
import 'setting_widgets.dart';

class GeneralPage extends StatefulWidget {
  const GeneralPage({super.key});

  @override
  State<GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {
  bool _isVibrationOn = true;

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode.isDark;

    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.navBg,
        foregroundColor: Colors.white,
        title: const Text('一般設定',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        children: [
          const SettingSectionHeader(title: 'デザイン'),
          ThemedSwitchTile(
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            title: 'ダークモード',
            subtitle: isDark ? '背景を暗くします' : '背景を明るくします',
            value: isDark,
            onChanged: (val) {
              val
                  ? AdaptiveTheme.of(context).setDark()
                  : AdaptiveTheme.of(context).setLight();
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          const SettingSectionHeader(title: 'スキャン時の挙動'),
          ThemedSwitchTile(
            icon: Icons.vibration,
            title: 'スキャン成功時の振動',
            subtitle: _isVibrationOn ? '振動する' : '振動しない',
            value: _isVibrationOn,
            onChanged: (val) => setState(() => _isVibrationOn = val),
          ),
          const SizedBox(height: 8),
          const SettingSectionHeader(title: 'サポート'),
          ThemedNavTile(
              icon: Icons.help_outline, title: 'ヘルプ', onTap: () {}),
          ThemedNavTile(
              icon: Icons.description_outlined, title: '利用規約', onTap: () {}),
        ],
      ),
    );
  }
}
