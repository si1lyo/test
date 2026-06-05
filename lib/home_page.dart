import 'package:flutter/material.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color themeColor = const Color(0xFF0F624C);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'マイリスト',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: themeColor,
          labelColor: themeColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'すべて'),
            Tab(text: '食品'),
            Tab(text: '日用品'),
            Tab(text: 'その他'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductList(),
          const Center(child: Text('食品の一覧')),
          const Center(child: Text('日用品の一覧')),
          const Center(child: Text('その他の一覧')),
        ],
      ),
    );
  }
}

Widget _buildProductList() {
  final List<Map<String, dynamic>> products = [
    {'name': '牛乳', 'days': '残り約2日', 'percent': 0.2, 'color': Colors.orange},
    {
      'name': 'シャンプー',
      'days': '残り約12日',
      'percent': 0.4,
      'color': const Color(0xFF0F624C),
    },
    {'name': '歯ブラシ', 'days': '残り約7日', 'percent': 0.1, 'color': Colors.orange},
    {
      'name': '洗剤',
      'days': '残り約25日',
      'percent': 0.6,
      'color': const Color(0xFF0F624C),
    },
  ];

  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: products.length,
    itemBuilder: (context, index) {
      final product = products[index];
      return Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    product['days'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: product['percent'],
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          product['color'],
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  SizedBox(
                    width: 35,
                    child: Text(
                      '${(product['percent'] * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
