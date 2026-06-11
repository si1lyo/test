import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'services/receipt_recognition_service.dart';

class ReceiptConfirmPage extends StatefulWidget {
  final List<RecognizedItem> items;
  const ReceiptConfirmPage({super.key, required this.items});

  @override
  State<ReceiptConfirmPage> createState() => _ReceiptConfirmPageState();
}

class _ReceiptConfirmPageState extends State<ReceiptConfirmPage> {
  late List<_EditableItem> _items;
  bool _saveToGroup = false;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _items = widget.items
        .map((e) => _EditableItem(
              nameController: TextEditingController(text: e.name),
              typeController: TextEditingController(text: e.type),
              genre: e.genre,
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.nameController.dispose();
      item.typeController.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_EditableItem(
        nameController: TextEditingController(),
        typeController: TextEditingController(),
        genre: 'その他',
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].nameController.dispose();
      _items[index].typeController.dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _register() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final valid = _items.any((e) => e.nameController.text.trim().isNotEmpty);
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品名を1つ以上入力してください')));
      return;
    }

    setState(() => _isRegistering = true);

    try {
      String? groupId;
      if (_saveToGroup) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        groupId = userDoc.data()?['groupId'] as String?;
        if (groupId == null || groupId.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('グループに所属していません'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isRegistering = false);
          return;
        }
      }

      final collection = _saveToGroup && groupId != null
          ? FirebaseFirestore.instance
              .collection('groups')
              .doc(groupId)
              .collection('group_products')
          : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('my_products');

      final batch = FirebaseFirestore.instance.batch();
      for (final item in _items) {
        final name = item.nameController.text.trim();
        if (name.isEmpty) continue;
        final ref = collection.doc();
        batch.set(ref, {
          'name': name,
          'type': item.typeController.text.trim(),
          'genre': item.genre,
          'purchaseDate': Timestamp.now(),
          'registeredBy': user.displayName ?? user.email,
        });
      }
      await batch.commit();

      if (mounted) {
        Navigator.of(context)
          ..pop() // confirm page
          ..pop(); // camera page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_items.where((e) => e.nameController.text.trim().isNotEmpty).length}件を登録しました'),
            backgroundColor: kDarkGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登録に失敗しました: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kDarkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '認識結果の確認',
          style: TextStyle(
            fontFamily: kFont,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kDarkGreen,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _items.length + 1,
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  return TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, color: kDarkGreen),
                    label: const Text('商品を追加',
                        style: TextStyle(fontFamily: kFont, color: kDarkGreen)),
                  );
                }
                return _ItemCard(
                  item: _items[index],
                  onDelete: () => _removeItem(index),
                  onGenreChanged: (val) =>
                      setState(() => _items[index].genre = val),
                );
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: kBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('グループに共有する',
                style: TextStyle(fontFamily: kFont)),
            secondary: const Icon(Icons.groups, color: kDarkGreen),
            activeThumbColor: kDarkGreen,
            value: _saveToGroup,
            onChanged: (val) => setState(() => _saveToGroup = val),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kDarkGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isRegistering ? null : _register,
              child: _isRegistering
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('リストに登録',
                      style: TextStyle(fontFamily: kFont, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableItem {
  TextEditingController nameController;
  TextEditingController typeController;
  String genre;

  _EditableItem({
    required this.nameController,
    required this.typeController,
    required this.genre,
  });
}

class _ItemCard extends StatelessWidget {
  final _EditableItem item;
  final VoidCallback onDelete;
  final ValueChanged<String> onGenreChanged;

  const _ItemCard({
    required this.item,
    required this.onDelete,
    required this.onGenreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: item.nameController,
                    maxLength: 100,
                    style: const TextStyle(
                        fontFamily: kFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    decoration: const InputDecoration(
                      labelText: '商品名',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                      border: UnderlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: item.typeController,
                    maxLength: 50,
                    style: const TextStyle(fontFamily: kFont, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: '種類（例：牛乳）',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                      border: UnderlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: item.genre,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'ジャンル',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 6),
                      border: UnderlineInputBorder(),
                    ),
                    items: ['食品', '日用品', 'その他'].map((v) {
                      return DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontFamily: kFont)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onGenreChanged(val);
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
