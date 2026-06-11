import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import 'setting_widgets.dart';

String _hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;

  String _generateGroupId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(5,
        (_) => chars[Random().nextInt(chars.length)]).join();
  }

  void _createGroup() {
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => ThemedDialog(
        title: 'グループを新規作成',
        fields: [
          TextField(
              controller: nameCtrl,
              maxLength: 30,
              decoration:
                  const InputDecoration(labelText: 'グループ名（例：田中家）')),
          TextField(
              controller: passCtrl,
              obscureText: true,
              maxLength: 50,
              decoration: const InputDecoration(labelText: '参加用パスワード')),
        ],
        confirmLabel: '作成',
        onConfirm: () async {
          if (nameCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('グループ名とパスワードを入力してください')));
            return;
          }
          final nav = Navigator.of(context);
          final newId = _generateGroupId();
          await _db.collection('groups').doc(newId).set({
            'groupName': nameCtrl.text.trim(),
            'passwordHash': _hashPassword(passCtrl.text),
            'ownerId': user?.uid,
            'members': [user?.uid],
          });
          await _db
              .collection('users')
              .doc(user?.uid)
              .set({'groupId': newId}, SetOptions(merge: true));
          if (mounted) nav.pop();
        },
      ),
    );
  }

  void _joinGroup() {
    final idCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => ThemedDialog(
        title: 'グループに参加',
        fields: [
          TextField(
              controller: idCtrl,
              maxLength: 5,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'グループIDを入力')),
          TextField(
              controller: passCtrl,
              obscureText: true,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'パスワードを入力')),
        ],
        confirmLabel: '参加',
        onConfirm: () async {
          final groupId = idCtrl.text.trim().toUpperCase();
          final nav = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);
          final doc = await _db.collection('groups').doc(groupId).get();
          final stored = doc.data()?['passwordHash'] as String?;
          if (doc.exists && stored == _hashPassword(passCtrl.text)) {
            await _db.collection('groups').doc(groupId).update({
              'members': FieldValue.arrayUnion([user?.uid]),
            });
            await _db
                .collection('users')
                .doc(user?.uid)
                .set({'groupId': groupId}, SetOptions(merge: true));
            if (mounted) nav.pop();
          } else {
            messenger.showSnackBar(
                const SnackBar(content: Text('IDまたはパスワードが違います')));
          }
        },
      ),
    );
  }

  Future<void> _handleExitOrDeleteGroup(String groupId) async {
    if (user == null) return;

    final groupDoc = await _db.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) return;

    final List<dynamic> members = groupDoc.data()?['members'] ?? [];

    if (members.length > 1) {
      await _db.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([user!.uid])
      });
      await _db
          .collection('users')
          .doc(user!.uid)
          .update({'groupId': FieldValue.delete()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('グループを脱退しました')));
      }
    } else {
      final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('グループの削除'),
          content: const Text(
              'あなたが最後のメンバーです。グループを削除すると、登録された商品データもすべて消去されます。よろしいですか？'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('削除する',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmDelete == true) {
        final batch = _db.batch();
        final productsSnap = await _db
            .collection('groups')
            .doc(groupId)
            .collection('group_products')
            .get();
        for (final doc in productsSnap.docs) {
          batch.delete(doc.reference);
        }
        batch.delete(_db.collection('groups').doc(groupId));
        batch.update(_db.collection('users').doc(user!.uid),
            {'groupId': FieldValue.delete()});
        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('グループとすべてのデータを削除しました')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kDarkGreen,
        foregroundColor: Colors.white,
        title: const Text('アカウント・グループ管理',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final String? groupId = data?['groupId'];

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            children: [
              const SettingSectionHeader(title: 'ユーザー情報'),
              ThemedInfoTile(
                icon: Icons.person,
                text: user?.displayName ?? user?.email ?? '未設定',
              ),
              const SizedBox(height: 8),
              const SettingSectionHeader(title: 'グループ設定'),
              if (groupId == null) ...[
                ThemedNavTile(
                    icon: Icons.group_add,
                    title: 'グループを作成する',
                    onTap: _createGroup),
                ThemedNavTile(
                    icon: Icons.login,
                    title: 'グループに参加する',
                    onTap: _joinGroup),
              ] else ...[
                FutureBuilder<DocumentSnapshot>(
                  future: _db.collection('groups').doc(groupId).get(),
                  builder: (context, gSnap) {
                    final gData =
                        gSnap.data?.data() as Map<String, dynamic>?;
                    return Column(
                      children: [
                        ThemedInfoTile(
                          icon: Icons.verified_user,
                          text:
                              '所属：${gData?['groupName'] ?? "読込中..."}  (ID: $groupId)',
                        ),
                        ThemedNavTile(
                          icon: Icons.exit_to_app,
                          iconColor: Colors.red,
                          title: 'グループを脱退/削除',
                          onTap: () => _handleExitOrDeleteGroup(groupId),
                        ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 8),
              const SettingSectionHeader(title: 'アカウント'),
              ThemedNavTile(
                icon: Icons.logout,
                iconColor: Colors.orange,
                title: 'ログアウト',
                onTap: () async {
                  final nav = Navigator.of(context);
                  await FirebaseAuth.instance.signOut();
                  if (mounted) nav.pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
