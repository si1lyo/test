import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // ランダムID生成用

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;

  // --- ランダムなグループIDを生成 (例: A1B2C) ---
  String _generateGroupId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 読み間違いにくい文字
    return List.generate(5, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  // --- 1. グループを作成する ---
  void _createGroup() {
    final nameController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループを新規作成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "グループ名（例：田中家）")),
            TextField(controller: passController, decoration: const InputDecoration(labelText: "参加用パスワード")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              final newId = _generateGroupId();
              // A. groupsコレクションに登録
              await _db.collection('groups').doc(newId).set({
                'groupName': nameController.text,
                'password': passController.text,
                'ownerId': user?.uid,
                'members': [user?.uid],
              });
              // B. 自分のユーザー情報にgroupIdを紐付け
              await _db.collection('users').doc(user?.uid).set({'groupId': newId}, SetOptions(merge: true));
              if (mounted) Navigator.pop(context);
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  // --- 2. グループに参加する ---
  void _joinGroup() {
    final idController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループに参加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: idController, decoration: const InputDecoration(labelText: "グループIDを入力")),
            TextField(controller: passController, decoration: const InputDecoration(labelText: "パスワードを入力")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              final doc = await _db.collection('groups').doc(idController.text.toUpperCase()).get();
              if (doc.exists && doc.data()?['password'] == passController.text) {
                // パスワード一致：参加処理
                await _db.collection('groups').doc(idController.text.toUpperCase()).update({
                  'members': FieldValue.arrayUnion([user?.uid]) // リストに追加
                });
                await _db.collection('users').doc(user?.uid).set({'groupId': idController.text.toUpperCase()}, SetOptions(merge: true));
                if (mounted) Navigator.pop(context);
              } else {
                // 不一致
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IDまたはパスワードが違います')));
              }
            },
            child: const Text('参加'),
          ),
        ],
      ),
    );
  }

  // --- 3. グループを削除する（オーナーのみ） ---
  Future<void> _deleteGroup(String groupId) async {
    final doc = await _db.collection('groups').doc(groupId).get();
    if (doc.data()?['ownerId'] == user?.uid) {
      await _db.collection('groups').doc(groupId).delete();
      await _db.collection('users').doc(user?.uid).update({'groupId': FieldValue.delete()});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('オーナーのみ削除可能です')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アカウント・グループ管理')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final String? groupId = userData?['groupId'];

          return ListView(
            children: [
              const _SectionHeader(title: 'ユーザー情報'),
              ListTile(leading: const Icon(Icons.person), title: Text(user?.displayName ?? '未設定')),
              
              const Divider(),
              const _SectionHeader(title: 'グループ設定'),
              if (groupId == null) ...[
                ListTile(leading: const Icon(Icons.group_add), title: const Text('グループを作成する'), onTap: _createGroup),
                ListTile(leading: const Icon(Icons.login), title: const Text('グループに参加する'), onTap: _joinGroup),
              ] else ...[
                FutureBuilder<DocumentSnapshot>(
                  future: _db.collection('groups').doc(groupId).get(),
                  builder: (context, gSnap) {
                    final gData = gSnap.data?.data() as Map<String, dynamic>?;
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.verified_user),
                          title: Text('所属：${gData?['groupName'] ?? "読込中..."}'),
                          subtitle: Text('グループID: $groupId (招待時に共有)'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('グループを削除/脱退'),
                          onTap: () => _deleteGroup(groupId),
                        ),
                      ],
                    );
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text('ログアウト'),
                onTap: () async {
    // 1. 先にログアウトを実行
                  await FirebaseAuth.instance.signOut();
    
    // 2. ログアウトしたら、この「アカウント管理画面」を閉じる
    // これをしないと、裏側のメイン画面でエラーが出ることがあります
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)));
  }
}