import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'product_detail_page.dart';

class HomePage extends StatefulWidget {
  final String searchQuery;
  const HomePage({super.key, this.searchQuery = ''});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _mainTabController;
  int _selectedCategoryIndex = 0;
  String? _groupName;
  String? _groupId;

  static const _categories = ['すべて', '食品', '日用品', 'その他'];

  Color get activeColor => kDarkGreen;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      if (!_mainTabController.indexIsChanging) setState(() {});
    });
    _fetchGroupInfo();
  }

  Future<void> _fetchGroupInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).get();
    final gid = userDoc.data()?['groupId'] as String?;
    if (gid != null && gid.isNotEmpty) {
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups').doc(gid).get();
      if (mounted) {
        setState(() {
          _groupId = gid;
          _groupName = groupDoc.data()?['groupName'] as String?;
        });
      }
    }
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(Icons.menu, color: kDarkGreen),
        ),
        title: _buildTitleToggle(),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: kDarkGreen,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildCategoryBar(),
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _MyList(
            searchQuery: widget.searchQuery,
            selectedCategory: _categories[_selectedCategoryIndex],
            activeColor: activeColor,
          ),
          _groupId != null
              ? _GroupList(
                  groupId: _groupId!,
                  searchQuery: widget.searchQuery,
                  selectedCategory: _categories[_selectedCategoryIndex],
                  activeColor: activeColor,
                )
              : const Center(
                  child: Text('グループに所属していません',
                      style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildTitleToggle() {
    final isGroup = _mainTabController.index == 1;
    final surfaceColor = AppColors.of(context).surface;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem('マイリスト', !isGroup,
              () => _mainTabController.animateTo(0)),
          if (_groupName != null)
            _toggleItem(_groupName!, isGroup,
                () => _mainTabController.animateTo(1)),
        ],
      ),
    );
  }

  Widget _toggleItem(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[600])),
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return InkWell(
            onTap: () =>
                setState(() => _selectedCategoryIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? activeColor
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: isSelected
                      ? activeColor
                      : Colors.grey[600],
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── マイリスト ──────────────────────────────────────────────────
class _MyList extends StatelessWidget {
  final String searchQuery;
  final String selectedCategory;
  final Color activeColor;

  const _MyList({
    required this.searchQuery,
    required this.selectedCategory,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('my_products')
          .orderBy('purchaseDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kDarkGreen));
        }

        var docs = snapshot.data?.docs ?? [];

        if (searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final name = ((doc.data() as Map)['name'] ?? '')
                .toString()
                .toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();
        }

        if (selectedCategory != 'すべて') {
          docs = docs.where((doc) {
            return (doc.data() as Map)['genre'] == selectedCategory;
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isNotEmpty
                  ? '「$searchQuery」は見つかりません'
                  : '商品がありません',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _ProductCard(
              docId: docs[i].id,
              name: data['name'] ?? '',
              genre: data['genre'] ?? '',
              price: (data['price'] as num?)?.toDouble() ?? 0,
              purchaseDate:
                  (data['purchaseDate'] as Timestamp?)?.toDate(),
              icon: data['icon'] as String? ?? '',
              activeColor: activeColor,
              isGroup: false,
            );
          },
        );
      },
    );
  }
}

// ── グループリスト ────────────────────────────────────────────
class _GroupList extends StatelessWidget {
  final String groupId;
  final String searchQuery;
  final String selectedCategory;
  final Color activeColor;

  const _GroupList({
    required this.groupId,
    required this.searchQuery,
    required this.selectedCategory,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('group_products')
          .orderBy('purchaseDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kDarkGreen));
        }

        var docs = snapshot.data?.docs ?? [];

        if (searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final name = ((doc.data() as Map)['name'] ?? '')
                .toString()
                .toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();
        }

        if (selectedCategory != 'すべて') {
          docs = docs.where((doc) {
            return (doc.data() as Map)['genre'] == selectedCategory;
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isNotEmpty
                  ? '「$searchQuery」は見つかりません'
                  : 'グループに商品がありません',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _ProductCard(
              docId: docs[i].id,
              name: data['name'] ?? '',
              genre: data['genre'] ?? '',
              price: (data['price'] as num?)?.toDouble() ?? 0,
              purchaseDate:
                  (data['purchaseDate'] as Timestamp?)?.toDate(),
              icon: data['icon'] as String? ?? '',
              activeColor: activeColor,
              isGroup: true,
              groupId: groupId,
            );
          },
        );
      },
    );
  }
}

// ── 商品カード ────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final String docId;
  final String name;
  final String genre;
  final double price;
  final DateTime? purchaseDate;
  final String icon;
  final Color activeColor;
  final bool isGroup;
  final String? groupId;

  const _ProductCard({
    required this.docId,
    required this.name,
    required this.genre,
    this.price = 0,
    this.purchaseDate,
    this.icon = '',
    required this.activeColor,
    this.isGroup = false,
    this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.of(context).surface;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            docId: docId,
            isGroup: isGroup,
            groupId: groupId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: () {
                  final code = int.tryParse(icon);
                  if (code != null) {
                    return Icon(
                      IconData(code, fontFamily: 'MaterialIcons'),
                      color: activeColor,
                      size: 22,
                    );
                  }
                  return Icon(Icons.inventory_2_outlined,
                      color: activeColor, size: 22);
                }(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (genre.isNotEmpty)
                        Text(genre,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500])),
                      if (genre.isNotEmpty && price > 0)
                        Text('  ·  ',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400])),
                      if (price > 0)
                        Text(
                          '¥${NumberFormat('#,###').format(price.toInt())}',
                          style: TextStyle(
                              fontSize: 12,
                              color: activeColor,
                              fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                  if (purchaseDate != null)
                    Text(
                      _daysAgoText(purchaseDate!),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[400]),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }
}

String _daysAgoText(DateTime date) {
  final days = DateTime.now().difference(date).inDays;
  if (days == 0) return '今日購入';
  if (days == 1) return '昨日購入';
  return '$days日前に購入';
}
