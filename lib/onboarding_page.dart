import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_page.dart';

const _kDarkGreen = Color(0xFF428475);
const _kLightGreen = Color(0xFF89D7B7);
const _kBg = Color(0xFFFFFDFB);
const _kFont = 'NotoSansJP';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _page = 0;

  static const _pages = [
    _PageData('まだある？', 'レシートを撮影して、\n日常の在庫を管理しよう！'),
    _PageData('賢く管理', '買いすぎ・買い忘れを\nなくして節約しよう！'),
    _PageData('みんなで共有', 'グループ機能で家族や\nパートナーと在庫を共有！'),
  ];

  Future<void> _goToAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }

  void _next() {
    if (_page < _pages.length - 1) {
      setState(() => _page++);
    } else {
      _goToAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── ベースコンテンツ（白地） ──
          _PageContent(
            data: _pages[_page],
            buttonColor: _kDarkGreen,
            page: _page,
            pageCount: _pages.length,
            onNext: _next,
            onSkip: _goToAuth,
          ),

          // ── 右下 9-sided cookie（dark green）+ 反転UI ──
          ClipPath(
            clipper: _CookieClipper(
              points: 9,
              size: size.width * 1.2,
              offset: Offset(size.width * 0.38, size.height * 0.55),
            ),
            child: Stack(
              children: [
                const ColoredBox(color: _kDarkGreen, child: SizedBox.expand()),
                _PageContent(
                  data: _pages[_page],
                  buttonColor: _kLightGreen,
                  page: _page,
                  pageCount: _pages.length,
                  onNext: _next,
                  onSkip: _goToAuth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── ページコンテンツ（固定位置で2層が完全一致） ──────────────────
class _PageContent extends StatelessWidget {
  final _PageData data;
  final Color buttonColor;
  final int page;
  final int pageCount;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _PageContent({
    super.key,
    required this.data,
    required this.buttonColor,
    required this.page,
    required this.pageCount,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = page == pageCount - 1;

    return SizedBox.expand(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              // ── 上エリア：タイトル + サブタイトル ──
              Expanded(
                flex: 5,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: _kDarkGreen,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        data.body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.7,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 下エリア：ドット + ボタン + スキップ ──
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ドットインジケーター
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(pageCount, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: page == i ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: page == i ? buttonColor : _kLightGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // 次へ / 始めるボタン
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: onNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: buttonColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            isLast ? '始める' : '次へ',
                            style: const TextStyle(
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

                      // スキップ（最後以外）／高さを確保するための透明スペース
                      if (!isLast)
                        TextButton(
                          onPressed: onSkip,
                          style: TextButton.styleFrom(
                              foregroundColor: _kLightGreen),
                          child: const Text(
                            'スキップ',
                            style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 48),
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

class _PageData {
  final String title;
  final String body;
  const _PageData(this.title, this.body);
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
