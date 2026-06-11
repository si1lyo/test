import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'home_page.dart';
import 'calender_page.dart';
import 'camera_page.dart';
import 'setting_page/setting_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddProductSheet() {
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    String selectedGenre = '食品';
    bool saveToGroup = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('詳細登録',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kDarkGreen)),
              const SizedBox(height: 20),
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: '商品名', hintText: '例：明治おいしい牛乳')),
              TextField(
                  controller: typeController,
                  decoration:
                      const InputDecoration(labelText: '物', hintText: '例：牛乳')),
              const SizedBox(height: 20),
              const Text('ジャンル'),
              DropdownButton<String>(
                value: selectedGenre,
                isExpanded: true,
                items: ['食品', '日用品', 'その他']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (val) =>
                    setSheetState(() => selectedGenre = val!),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('グループに共有する'),
                secondary: const Icon(Icons.groups, color: kDarkGreen),
                activeThumbColor: kDarkGreen,
                value: saveToGroup,
                onChanged: (val) => setSheetState(() => saveToGroup = val),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: kDarkGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('商品名を入力してください')));
                      return;
                    }
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();
                    final String? groupId =
                        userDoc.data()?['groupId'] as String?;
                    if (saveToGroup &&
                        (groupId == null || groupId.isEmpty)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('グループに所属していません。'),
                              backgroundColor: Colors.red),
                        );
                      }
                      return;
                    }
                    final target = saveToGroup && groupId != null
                        ? FirebaseFirestore.instance
                            .collection('groups')
                            .doc(groupId)
                            .collection('group_products')
                        : FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('my_products');
                    await target.add({
                      'name': nameController.text.trim(),
                      'type': typeController.text.trim(),
                      'genre': selectedGenre,
                      'purchaseDate': Timestamp.now(),
                      'registeredBy': user.displayName ?? user.email,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text('${nameController.text} を追加しました')));
                    }
                  },
                  child: const Text('リストに追加',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final pages = [
      CalendarPage(searchQuery: _searchQuery),
      HomePage(searchQuery: _searchQuery),
      SettingPage(searchQuery: _searchQuery),
    ];

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // ── 右下 cookie（dark green） ──
          ClipPath(
            clipper: CookieClipper(
              points: 9,
              size: size.width * 1.2,
              offset: Offset(size.width * 0.38, size.height * 0.55),
            ),
            child: const ColoredBox(color: kDarkGreen, child: SizedBox.expand()),
          ),

          // ── ページ + ボトムナビ（縦に確定） ──
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(child: pages[_currentIndex]),
                _BottomNavBar(
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
              ],
            ),
          ),

          // ── 検索 + FAB（ページの上に浮遊、リストは下を流れる） ──
          Positioned(
            left: 16,
            right: 16,
            bottom: _navBarHeight(context),
            child: Row(
              children: [
                Expanded(
                  child: _SearchCapsule(controller: _searchController),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onLongPress: _showAddProductSheet,
                  child: Material(
                    color: kDarkGreen,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CameraPage())),
                      child: const SizedBox(
                        width: 52,
                        height: 52,
                        child: Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ナビバーの高さ（SafeArea下部 + padding + items行）を返す
double _navBarHeight(BuildContext context) {
  final bottomPadding = MediaQuery.of(context).padding.bottom;
  return bottomPadding + 52 + 20 + 8; // SafeArea + items + padding上下 + margin
}

// ── 検索カプセル（ボトムナビとは別レイヤー） ──────────────────
class _SearchCapsule extends StatelessWidget {
  final TextEditingController controller;
  const _SearchCapsule({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: kDarkGreen, fontSize: 15),
        cursorColor: kDarkGreen,
        decoration: InputDecoration(
          hintText: '商品を検索',
          hintStyle: TextStyle(color: kDarkGreen.withValues(alpha: 0.5), fontSize: 15),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: kDarkGreen, size: 20),
                  onPressed: () => controller.clear(),
                )
              : const Icon(Icons.search, color: kDarkGreen, size: 22),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}

// ── ボトムナビバー（ナビのみ、ダークティール背景） ────────────
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.calendar_month_outlined, label: 'カレンダー'),
    (icon: Icons.list_alt_outlined, label: 'リスト'),
    (icon: Icons.settings_outlined, label: '設定'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kDarkGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SizedBox(
            height: 52,
            child: Row(
              children: List.generate(_items.length, (i) {
                final selected = i == currentIndex;
                final item = _items[i];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        constraints: const BoxConstraints(maxWidth: 120),
                        padding: EdgeInsets.symmetric(
                          horizontal: selected ? 14 : 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              color: selected ? kDarkGreen : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: selected ? 12 : 10,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selected ? kDarkGreen : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
