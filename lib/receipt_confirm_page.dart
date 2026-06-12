import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'services/receipt_recognition_service.dart';
import 'widgets/icon_picker.dart';

class ReceiptConfirmPage extends StatefulWidget {
  final ReceiptResult result;
  const ReceiptConfirmPage({super.key, required this.result});

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
    _items = widget.result.items
        .map((e) => _EditableItem(
              nameController: TextEditingController(text: e.name),
              typeController: TextEditingController(text: e.type),
              genre: e.genre,
              price: e.price,
              quantity: e.quantity,
              aiEstimatedDays: e.aiEstimatedDays,
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.nameController.dispose();
      item.typeController.dispose();
      item.priceController.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_EditableItem(
        nameController: TextEditingController(),
        typeController: TextEditingController(),
        priceController: TextEditingController(),
        genre: 'その他',
        price: 0,
        quantity: 1,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].nameController.dispose();
      _items[index].typeController.dispose();
      _items[index].priceController.dispose();
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

      final productCollection = _saveToGroup && groupId != null
          ? FirebaseFirestore.instance
              .collection('groups')
              .doc(groupId)
              .collection('group_products')
          : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('my_products');

      final now = Timestamp.now();
      final batch = FirebaseFirestore.instance.batch();

      // レシートを保存
      final receiptRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('receipts')
          .doc();

      final receiptItems = _items
          .where((e) => e.nameController.text.trim().isNotEmpty)
          .map((e) => {
                'name': e.nameController.text.trim(),
                'price': double.tryParse(e.priceController.text) ?? e.price,
                'quantity': e.quantity,
                'genre': e.genre,
              })
          .toList();

      batch.set(receiptRef, {
        'date': widget.result.date,
        'storeName': widget.result.storeName,
        'total': widget.result.total ??
            receiptItems.fold<double>(
                0, (sum, e) => sum + (e['price'] as double) * (e['quantity'] as int)),
        'createdAt': now,
        'items': receiptItems,
      });

      // 商品を保存
      for (final item in _items) {
        final name = item.nameController.text.trim();
        if (name.isEmpty) continue;
        final price = double.tryParse(item.priceController.text) ?? item.price;
        final ref = productCollection.doc();
        batch.set(ref, {
          'name': name,
          'type': item.typeController.text.trim(),
          'genre': item.genre,
          'price': price,
          'icon': item.icon,
          'purchaseDate': now,
          'registeredBy': user.displayName ?? user.email,
          if (item.aiEstimatedDays != null)
            'aiEstimatedDays': item.aiEstimatedDays,
        });
      }

      await batch.commit();

      if (mounted) {
        Navigator.of(context)
          ..pop()
          ..pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_items.where((e) => e.nameController.text.trim().isNotEmpty).length}件を登録しました'),
            backgroundColor: kDarkGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('登録に失敗しました: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '認識結果の確認',
          style: TextStyle(
            fontFamily: kFont,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.accent,
          ),
        ),
      ),
      body: Column(
        children: [
          if (widget.result.storeName != null || widget.result.date != null)
            _buildReceiptHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _items.length + 1,
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  final colors = AppColors.of(context);
                  return TextButton.icon(
                    onPressed: _addItem,
                    icon: Icon(Icons.add, color: colors.accent),
                    label: Text('商品を追加',
                        style: TextStyle(fontFamily: kFont, color: colors.accent)),
                  );
                }
                return _ItemCard(
                  item: _items[index],
                  onDelete: () => _removeItem(index),
                  onGenreChanged: (val) =>
                      setState(() => _items[index].genre = val),
                  onIconChanged: (val) =>
                      setState(() => _items[index].icon = val),
                );
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildReceiptHeader() {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: colors.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.result.storeName != null)
                  Text(
                    widget.result.storeName!,
                    style: TextStyle(
                      fontFamily: kFont,
                      fontWeight: FontWeight.bold,
                      color: colors.accent,
                    ),
                  ),
                if (widget.result.date != null)
                  Text(
                    widget.result.date!,
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 12,
                      color: colors.accent.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.result.total != null)
            Text(
              '合計 ¥${widget.result.total!.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: kFont,
                fontWeight: FontWeight.bold,
                color: colors.accent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
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
            secondary: Icon(Icons.groups, color: colors.accent),
            activeThumbColor: colors.accent,
            value: _saveToGroup,
            onChanged: (val) => setState(() => _saveToGroup = val),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
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
  TextEditingController priceController;
  String genre;
  double price;
  int quantity;
  String icon;
  int? aiEstimatedDays;

  _EditableItem({
    required this.nameController,
    required this.typeController,
    TextEditingController? priceController,
    required this.genre,
    this.price = 0,
    this.quantity = 1,
    this.icon = '',
    this.aiEstimatedDays,
  }) : priceController = priceController ??
            TextEditingController(
                text: price > 0 ? price.toStringAsFixed(0) : '');
}

class _ItemCard extends StatelessWidget {
  final _EditableItem item;
  final VoidCallback onDelete;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onIconChanged;

  const _ItemCard({
    required this.item,
    required this.onDelete,
    required this.onGenreChanged,
    required this.onIconChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // アイコン選択ボタン
            GestureDetector(
              onTap: () async {
                final picked =
                    await showIconPicker(context, current: item.icon);
                if (picked != null) onIconChanged(picked);
              },
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 8, top: 8),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: colors.accent.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: () {
                    final code = int.tryParse(item.icon);
                    if (code != null) {
                      return Icon(
                        IconData(code, fontFamily: 'MaterialIcons'),
                        color: colors.accent,
                        size: 22,
                      );
                    }
                    return Icon(Icons.add_photo_alternate_outlined,
                        color: colors.accent, size: 18);
                  }(),
                ),
              ),
            ),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: item.typeController,
                          maxLength: 50,
                          style:
                              const TextStyle(fontFamily: kFont, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: '種類（例：牛乳）',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                            border: UnderlineInputBorder(),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: item.priceController,
                          keyboardType: TextInputType.number,
                          style:
                              const TextStyle(fontFamily: kFont, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: '価格 (¥)',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: item.genre,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'ジャンル',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                      border: UnderlineInputBorder(),
                    ),
                    items: ['食品', '日用品', 'その他'].map((v) {
                      return DropdownMenuItem(
                          value: v,
                          child:
                              Text(v, style: const TextStyle(fontFamily: kFont)));
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
