import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';

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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem('マイリスト', !isGroup, () => _mainTabController.animateTo(0)),
          if (_groupName != null)
            _toggleItem(_groupName!, isGroup, () => _mainTabController.animateTo(1)),
        ],
      ),
    );
  }

  Widget _toggleItem(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? activeColor : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kDarkGreen));
        }

        var docs = snapshot.data?.docs ?? [];

        if (searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final name =
                ((doc.data() as Map)['name'] ?? '').toString().toLowerCase();
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
              name: data['name'] ?? '',
              genre: data['genre'] ?? '',
              activeColor: activeColor,
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
  final Color activeColor;

  const _GroupList({
    required this.groupId,
    required this.searchQuery,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('group_products')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kDarkGreen));
        }

        var docs = snapshot.data?.docs ?? [];

        if (searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final name =
                ((doc.data() as Map)['name'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery.toLowerCase());
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
              name: data['name'] ?? '',
              genre: data['genre'] ?? '',
              activeColor: activeColor,
            );
          },
        );
      },
    );
  }
}

// ── 商品カード ────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final String name;
  final String genre;
  final Color activeColor;

  const _ProductCard({
    required this.name,
    required this.genre,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.inventory_2_outlined, color: activeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                if (genre.isNotEmpty)
                  Text(genre,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
