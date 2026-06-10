import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // 名前、メール、パスワードの入力を管理するコントローラー
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogin = true; // ログインか新規登録かを切り替えるフラグ

  @override
  void dispose() {
    // 画面が閉じるときにメモリを解放する
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ログイン・登録処理
  Future<void> _authenticate() async {
    // 新規登録時のみ、名前が空でないかチェック
    if (!_isLogin && _nameController.text.trim().isEmpty) {
      _showErrorDialog('お名前を入力してください。');
      return;
    }

    try {
      if (_isLogin) {
        // --- ログイン処理 ---
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // --- 新規登録処理 ---
        // 1. まずはメールとパスワードでアカウント作成
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. 作成に成功したら、入力された名前をユーザー情報に登録
        await userCredential.user?.updateDisplayName(_nameController.text.trim());
        
        // 3. (オプション) 確認メールを送信
        await userCredential.user?.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      String message = 'エラーが発生しました';
      switch (e.code) {
        case 'invalid-email':
          message = 'メールアドレスの形式が正しくありません。';
          break;
        case 'user-disabled':
          message = 'このユーザーは無効化されています。';
          break;
        case 'wrong-password':
          message = 'パスワードが間違っています。';
          break;
        case 'email-already-in-use':
          message = 'このメールアドレスはすでに登録されています。';
          break;
        case 'weak-password':
          message = 'パスワードが短すぎます（6文字以上必要です）。';
          break;
        case 'invalid-credential':
          message = 'メールアドレスまたはパスワードが正しくありません。';
          break;
      }
      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog('予期せぬエラーが発生しました。');
    }
  }

  // エラーダイアログを表示する共通メソッド
  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'ログイン' : '新規登録'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView( // キーボードが出ても隠れないようにスクロール可能にする
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 【ポイント】新規登録の時だけ名前の入力欄を出す
              if (!_isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'お名前',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity, // ボタンを横いっぱいに広げる
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F624C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _authenticate,
                  child: Text(_isLogin ? 'ログイン' : 'アカウント作成'),
                ),
              ),
              
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(_isLogin ? '新規登録はこちら' : 'すでにアカウントをお持ちの方はこちら'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}