import 'package:flutter/material.dart';
import '../app_theme.dart';

/// セクション見出し
class SettingSectionHeader extends StatelessWidget {
  final String title;
  const SettingSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: kDarkGreen,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// スイッチ付きカード行
class ThemedSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ThemedSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)
        ],
      ),
      child: SwitchListTile(
        secondary: _iconCircle(icon),
        title: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        value: value,
        activeTrackColor: kMint,
        activeThumbColor: kDarkGreen,
        onChanged: onChanged,
      ),
    );
  }
}

/// 矢印付きナビカード行
class ThemedNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const ThemedNavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? kDarkGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)
        ],
      ),
      child: ListTile(
        leading: _iconCircle(icon, color: color),
        title: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: kDarkGreen, size: 20),
        onTap: onTap,
      ),
    );
  }
}

/// 情報表示カード行（ナビなし）
class ThemedInfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const ThemedInfoTile({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          _iconCircle(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

/// テーマ統一ダイアログ
class ThemedDialog extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final Future<void> Function() onConfirm;
  final String confirmLabel;

  const ThemedDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.onConfirm,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: const TextStyle(
              color: kDarkGreen, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: fields),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: kDarkGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          onPressed: onConfirm,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

Widget _iconCircle(IconData icon, {Color color = kDarkGreen}) {
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 18),
  );
}
