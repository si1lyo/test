import 'package:flutter/material.dart';

const kDarkGreen = Color(0xFF428475);
const kMint = Color(0xFF89D7B7);
const kBg = Color(0xFFFFFDFB);
const kFont = 'NotoSansJP';

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
    return Stack(
      children: [
        const ColoredBox(color: kBg, child: SizedBox.expand()),
        ClipPath(
          clipper: CookieClipper(
            points: 6,
            size: size.width * 1.0,
            offset: Offset(-size.width * 0.35, -size.height * 0.15),
          ),
          child: const ColoredBox(color: kMint, child: SizedBox.expand()),
        ),
        ClipPath(
          clipper: CookieClipper(
            points: 9,
            size: size.width * 1.2,
            offset: Offset(size.width * 0.38, size.height * 0.55),
          ),
          child: const ColoredBox(color: kDarkGreen, child: SizedBox.expand()),
        ),
        child,
      ],
    );
  }
}
