import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'app_theme.dart';
import 'main_screen.dart';

const _kDarkGreen = Color(0xFF428475);
const _kLightGreen = Color(0xFF89D7B7);
const _kFont = 'NotoSansJP';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin = true;
  bool _showLoginForm = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _goToMain() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _goToMain();
    } on FirebaseAuthException catch (e) {
      _showError('Googleログインに失敗しました（${e.code}）');
    } catch (_) {
      _showError('Googleログインに失敗しました。');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _authenticate() async {
    if (!_isLogin && _nameCtrl.text.trim().isEmpty) {
      _showError('お名前を入力してください。');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      _showError('すべての項目を入力してください。');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
        await cred.user?.updateDisplayName(_nameCtrl.text.trim());
        await cred.user?.sendEmailVerification();
      }
      _goToMain();
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email' => 'メールアドレスの形式が正しくありません。',
        'user-disabled' => 'このユーザーは無効化されています。',
        'wrong-password' || 'invalid-credential' =>
          'メールアドレスまたはパスワードが正しくありません。',
        'email-already-in-use' => 'このメールアドレスはすでに登録されています。',
        'weak-password' => 'パスワードは6文字以上で入力してください。',
        _ => 'エラーが発生しました。',
      };
      _showError(msg);
    } catch (_) {
      _showError('予期せぬエラーが発生しました。');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1D1B20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).bg,
      resizeToAvoidBottomInset: false,
      body: _isLogin
          ? _LoginView(
              emailCtrl: _emailCtrl,
              passwordCtrl: _passwordCtrl,
              showForm: _showLoginForm,
              onLoginButtonTap: () => setState(() => _showLoginForm = true),
              onSubmit: _authenticate,
              onRegister: () => setState(() {
                _isLogin = false;
                _showLoginForm = false;
              }),
              onGoogleSignIn: _signInWithGoogle,
              loading: _loading,
            )
          : _RegisterView(
              nameCtrl: _nameCtrl,
              emailCtrl: _emailCtrl,
              passwordCtrl: _passwordCtrl,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit: _authenticate,
              onBack: () => setState(() => _isLogin = true),
              loading: _loading,
            ),
    );
  }
}

// ── ログイン画面 ──────────────────────────────────────────────
class _LoginView extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool showForm;
  final VoidCallback onLoginButtonTap;
  final VoidCallback onSubmit;
  final VoidCallback onRegister;
  final VoidCallback onGoogleSignIn;
  final bool loading;

  const _LoginView({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.showForm,
    required this.onLoginButtonTap,
    required this.onSubmit,
    required this.onRegister,
    required this.onGoogleSignIn,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ベースUI
        _LoginContent(
          buttonColor: _kDarkGreen,
          showForm: showForm,
          onLoginButtonTap: onLoginButtonTap,
          onSubmit: onSubmit,
          onRegister: onRegister,
          onGoogleSignIn: onGoogleSignIn,
          loading: loading,
          emailCtrl: emailCtrl,
          passwordCtrl: passwordCtrl,
        ),

        // 右下 9-sided cookie（dark green）+ 色反転UI
        ClipPath(
          clipper: _CookieClipper(
            points: 9,
            size: size.width * 1.2,
            offset: Offset(size.width * 0.38, size.height * 0.55),
          ),
          child: Stack(
            children: [
              const ColoredBox(color: _kDarkGreen, child: SizedBox.expand()),
              _LoginContent(
                buttonColor: _kLightGreen,
                showForm: showForm,
                onLoginButtonTap: onLoginButtonTap,
                onSubmit: onSubmit,
                onRegister: onRegister,
                onGoogleSignIn: onGoogleSignIn,
                loading: loading,
                emailCtrl: emailCtrl,
                passwordCtrl: passwordCtrl,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginContent extends StatelessWidget {
  final Color buttonColor;
  final bool showForm;
  final VoidCallback onLoginButtonTap;
  final VoidCallback onSubmit;
  final VoidCallback onRegister;
  final VoidCallback onGoogleSignIn;
  final bool loading;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;

  const _LoginContent({
    required this.buttonColor,
    required this.showForm,
    required this.onLoginButtonTap,
    required this.onSubmit,
    required this.onRegister,
    required this.onGoogleSignIn,
    required this.loading,
    required this.emailCtrl,
    required this.passwordCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              // ── 上エリア：タイトル + コンテンツ ──
              Expanded(
                flex: 5,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'まだある？',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: _kDarkGreen,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!showForm)
                        const Text(
                          'レシートを撮影して、\n日常の在庫を管理しよう！',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.7,
                            color: Color(0xFF333333),
                          ),
                        ),
                      if (showForm) ...[
                        _Field(
                          ctrl: emailCtrl,
                          label: 'メールアドレス',
                          icon: Icons.mail_outline,
                          type: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          ctrl: passwordCtrl,
                          label: 'パスワード',
                          icon: Icons.lock_outline,
                          obscure: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── 下エリア：ボタン + リンク ──
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // メールログインボタン
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: loading
                              ? null
                              : (showForm ? onSubmit : onLoginButtonTap),
                          style: FilledButton.styleFrom(
                            backgroundColor: buttonColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text(
                                  'ログイン',
                                  style: TextStyle(
                                    fontFamily: _kFont,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Google ログインボタン
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: loading ? null : onGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: buttonColor, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Googleでログイン',
                            style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: buttonColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      TextButton(
                        onPressed: onRegister,
                        style: TextButton.styleFrom(
                            foregroundColor: _kLightGreen),
                        child: const Text(
                          '新規登録',
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 新規登録画面 ──────────────────────────────────────────────
class _RegisterView extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final bool loading;

  const _RegisterView({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onBack,
    required this.loading,
  });

  Widget _buildButton(Color bgColor) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onSubmit,
        style: FilledButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : const Text(
                'アカウント作成',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // ボタン + リンク の高さ = 56 + 12 + 48(TextButton) = ~116
    // bottom padding = safeArea + 32
    final bottomAreaH = 56.0 + 12 + 48 + 32 + MediaQuery.of(context).padding.bottom;
    final hPad = size.width * 0.12;

    return Stack(
      children: [
        ClipPath(
          clipper: _CookieClipper(
            points: 9,
            size: size.width * 1.2,
            offset: Offset(size.width * 0.38, size.height * 0.55),
          ),
          child: const ColoredBox(color: _kDarkGreen, child: SizedBox.expand()),
        ),

        // スクロールフォーム（ボタン固定エリア分だけ下に余白）
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 40,
              right: 40,
              top: 16,
              bottom: bottomAreaH + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: _kDarkGreen),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                const Text(
                  'アカウント作成',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _kDarkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '新しいアカウントを\n作成してください。',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 16,
                    color: Color(0xFF555555),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                _Field(
                    ctrl: nameCtrl,
                    label: 'お名前',
                    icon: Icons.person_outline),
                const SizedBox(height: 14),
                _Field(
                  ctrl: emailCtrl,
                  label: 'メールアドレス',
                  icon: Icons.mail_outline,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _Field(
                  ctrl: passwordCtrl,
                  label: 'パスワード',
                  icon: Icons.lock_outline,
                  obscure: obscure,
                  suffix: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _kDarkGreen,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ボタン ベース層（darkGreen）
        Positioned(
          bottom: 32 + MediaQuery.of(context).padding.bottom,
          left: hPad,
          right: hPad,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton(_kDarkGreen),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(foregroundColor: _kLightGreen),
                child: const Text(
                  'ログインはこちら',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ボタン クリップ層（darkGreen背景上でlightGreen）
        ClipPath(
          clipper: _CookieClipper(
            points: 9,
            size: size.width * 1.2,
            offset: Offset(size.width * 0.38, size.height * 0.55),
          ),
          child: Stack(
            children: [
              const ColoredBox(color: _kDarkGreen, child: SizedBox.expand()),
              Positioned(
                bottom: 32 + MediaQuery.of(context).padding.bottom,
                left: hPad,
                right: hPad,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildButton(_kLightGreen),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: onBack,
                      style:
                          TextButton.styleFrom(foregroundColor: _kLightGreen),
                      child: const Text(
                        'ログインはこちら',
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;
  final bool obscure;
  final Widget? suffix;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.type = TextInputType.text,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? const Color(0xFF2E3330)
        : Colors.white.withAlpha(220);
    final textColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: TextStyle(fontSize: 15, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 14),
        prefixIcon: Icon(icon, color: _kDarkGreen, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: fillColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0E9E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kDarkGreen, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}

// ── M3 StarBorder クッキー形状クリッパー ──────────────────────
class _CookieClipper extends CustomClipper<Path> {
  final int points;
  final double size;
  final Offset offset;

  const _CookieClipper({
    required this.points,
    required this.size,
    required this.offset,
  });

  @override
  Path getClip(Size s) {
    final shape = StarBorder(
      points: points.toDouble(),
      innerRadiusRatio: 0.85,
      pointRounding: 0.45,
      valleyRounding: 0.45,
    );
    final rect = Rect.fromLTWH(offset.dx, offset.dy, size, size);
    return shape.getOuterPath(rect);
  }

  @override
  bool shouldReclip(covariant _CookieClipper old) =>
      old.points != points || old.size != size || old.offset != offset;
}
