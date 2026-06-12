import 'package:flutter/material.dart';

const kDarkGreen = Color(0xFF428475);
const kMint = Color(0xFF89D7B7);
const kBg = Color(0xFFFFFDFB);
const kFont = 'NotoSansJP';

// ── ダークモード用カラー ───────────────────────────────────────
const kBgDark = Color(0xFF1B1D1C);        // ほぼ黒・わずかに温かみ
const kSurfaceDark = Color(0xFF262928);   // ダークチャコール（青みなし）
const kAccentDark = Color(0xFF5EA896);    // 落ち着いたティール
const kNavBgDark = Color(0xFF2B4540);     // ブランドティール感を残したナビ
const kCookieBgDark = Color(0xFF283C38); // 控えめなダーククッキー

// ── テーマ対応カラーセット ─────────────────────────────────────
class AppColors {
  final Color bg;
  final Color surface;
  final Color accent;
  final Color navBg;
  final Color cookieBg;

  const AppColors._({
    required this.bg,
    required this.surface,
    required this.accent,
    required this.navBg,
    required this.cookieBg,
  });

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  static const _light = AppColors._(
    bg: kBg,
    surface: Color(0xFFFFFFFF),
    accent: kDarkGreen,
    navBg: kDarkGreen,
    cookieBg: kDarkGreen,
  );

  static const _dark = AppColors._(
    bg: kBgDark,
    surface: kSurfaceDark,
    accent: kAccentDark,
    navBg: kNavBgDark,
    cookieBg: kCookieBgDark,
  );
}

// ── クッキー形状クリッパー ──────────────────────────────────────
class CookieClipper extends CustomClipper<Path> {
  final int points;
  final double size;
  final Offset offset;
  const CookieClipper({required this.points, required this.size, required this.offset});

  @override
  Path getClip(Size s) {
    final shape = StarBorder(
      points: points.toDouble(),
      innerRadiusRatio: 0.85,
      pointRounding: 0.45,
      valleyRounding: 0.45,
    );
    return shape.getOuterPath(Rect.fromLTWH(offset.dx, offset.dy, size, size));
  }

  @override
  bool shouldReclip(covariant CookieClipper old) =>
      old.points != points || old.size != size || old.offset != offset;
}

// ── 背景クッキー装飾（全画面共通） ────────────────────────────
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cookieColor1 = isDark ? const Color(0xFF2E4A44) : kMint;
    final cookieColor2 = isDark ? kNavBgDark : kDarkGreen;
    return Stack(
      children: [
        ColoredBox(color: colors.bg, child: const SizedBox.expand()),
        ClipPath(
          clipper: CookieClipper(
            points: 6,
            size: size.width * 1.0,
            offset: Offset(-size.width * 0.35, -size.height * 0.15),
          ),
          child: ColoredBox(color: cookieColor1, child: const SizedBox.expand()),
        ),
        ClipPath(
          clipper: CookieClipper(
            points: 9,
            size: size.width * 1.2,
            offset: Offset(size.width * 0.38, size.height * 0.55),
          ),
          child: ColoredBox(color: cookieColor2, child: const SizedBox.expand()),
        ),
        child,
      ],
    );
  }
}
