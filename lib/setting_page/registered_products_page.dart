import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';

class RegisteredProductsPage extends StatelessWidget {
  const RegisteredProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kDarkGreen,
        foregroundColor: Colors.white,
        title: const Text('登録商品一覧',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('my_products')
            .orderBy('purchaseDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kDarkGreen));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('登録された商品はまだありません',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final Timestamp? ts = data['purchaseDate'];
              final dateStr = ts != null
                  ? DateFormat('yyyy/MM/dd').format(ts.toDate())
                  : '日付不明';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kDarkGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: kDarkGreen, size: 20),
                  ),
                  title: Text(data['name'] ?? '商品名なし',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text('購入日: $dateStr',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kDarkGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      data['genre'] ?? '',
                      style: const TextStyle(
                          fontSize: 11,
                          color: kDarkGreen,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
