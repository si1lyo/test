import 'package:flutter/material.dart';
import '../app_theme.dart';

// アイコンはコードポイント文字列で保存。空文字列 = なし。
const List<IconData> kProductIconData = [
  // 食品・飲料
  Icons.local_drink,
  Icons.lunch_dining,
  Icons.dinner_dining,
  Icons.bakery_dining,
  Icons.egg_outlined,
  Icons.rice_bowl_outlined,
  Icons.ramen_dining,
  Icons.fastfood,
  Icons.coffee_outlined,
  Icons.local_bar,
  Icons.cake_outlined,
  Icons.icecream,
  Icons.emoji_food_beverage,
  Icons.set_meal,
  Icons.kitchen_outlined,
  Icons.blender_outlined,
  Icons.liquor,
  Icons.grass,
  Icons.agriculture,
  // 日用品・雑貨
  Icons.soap_outlined,
  Icons.cleaning_services,
  Icons.shower_outlined,
  Icons.medication_outlined,
  Icons.battery_full,
  Icons.lightbulb_outline,
  Icons.delete_outline,
  Icons.brush_outlined,
  Icons.local_laundry_service,
  Icons.sanitizer_outlined,
  Icons.dry_cleaning_outlined,
  Icons.recycling,
  Icons.compost,
  Icons.home_repair_service,
  Icons.electric_bolt_outlined,
  // その他
  Icons.shopping_bag_outlined,
  Icons.home_outlined,
  Icons.pets,
  Icons.local_florist_outlined,
  Icons.star_outline,
  Icons.phone_android,
  Icons.card_giftcard,
  Icons.inventory_2_outlined,
  Icons.nature,
  Icons.sports_score,
  Icons.child_care,
  Icons.face,
  Icons.fitness_center,
  Icons.music_note_outlined,
  Icons.palette_outlined,
];

// IconData → 保存用文字列
String iconToString(IconData icon) => icon.codePoint.toString();

// 保存文字列 → IconData (空文字列 or 不正 → null)
IconData? iconFromString(String? s) {
  if (s == null || s.isEmpty) return null;
  final code = int.tryParse(s);
  if (code == null) return null;
  return IconData(code, fontFamily: 'MaterialIcons');
}

String defaultIconForGenre(String genre) {
  return switch (genre) {
    '食品' => iconToString(Icons.shopping_cart_outlined),
    '日用品' => iconToString(Icons.soap_outlined),
    _ => iconToString(Icons.inventory_2_outlined),
  };
}

Future<String?> showIconPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.of(context).bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _IconPickerSheet(current: current),
  );
}

class _IconPickerSheet extends StatelessWidget {
  final String? current;
  const _IconPickerSheet({this.current});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // 先頭に「なし」を追加するため +1
    final total = kProductIconData.length + 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'アイコンを選択',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: total,
              itemBuilder: (context, i) {
                // index 0 = なし
                if (i == 0) {
                  final selected = current == null || current!.isEmpty;
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, ''),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: selected
                            ? Border.all(color: colors.accent, width: 2)
                            : Border.all(color: colors.accent.withValues(alpha: 0.2), width: 1),
                      ),
                      child: const Center(
                        child: Text(
                          'なし',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }

                final iconData = kProductIconData[i - 1];
                final codeStr = iconToString(iconData);
                final selected = current == codeStr;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, codeStr),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.accent.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: selected
                          ? Border.all(color: colors.accent, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        iconData,
                        size: 24,
                        color: colors.accent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
