import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ArkanLogo extends StatelessWidget {
  const ArkanLogo({
    super.key,
    this.size = 64,
    this.showBadge = false,
    this.badgeIcon = Icons.lock_outline_rounded,
    this.showGlow = false,
  });

  final double size;
  final bool showBadge;
  final IconData badgeIcon;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.28);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F5A4B),
            AppColors.emerald,
            Color(0xFF072721),
          ],
        ),
        border: Border.all(
          color: AppColors.gold,
          width: size > 40 ? 2.2 : 1.4,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  blurRadius: size * 0.35,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.5),
                  blurRadius: size * 0.2,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner subtle outline
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.all(size * 0.05),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.24),
                border: Border.all(
                  color: const Color(0xFFF3DC9F).withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
            ),
          ),
          // Custom painted Architectural Emblem
          CustomPaint(
            size: Size(size * 0.72, size * 0.72),
            painter: _ArkanEmblemPainter(),
          ),
          // Optional security badge
          if (showBadge)
            Positioned(
              bottom: size * 0.04,
              right: size * 0.04,
              child: Container(
                padding: EdgeInsets.all(size * 0.05),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  badgeIcon,
                  size: size * 0.22,
                  color: const Color(0xFF07221D),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArkanEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final goldPaint = Paint()
      ..color = const Color(0xFFE0B858)
      ..style = PaintingStyle.fill;

    final brightGoldPaint = Paint()
      ..color = const Color(0xFFF8E7BE)
      ..style = PaintingStyle.fill;

    final darkGoldPaint = Paint()
      ..color = const Color(0xFFC59B38)
      ..style = PaintingStyle.fill;

    final deepEmeraldPaint = Paint()
      ..color = const Color(0xFF07241F)
      ..style = PaintingStyle.fill;

    final bottomY = h * 0.94;

    // --- Side Left Tower ---
    final ltwW = w * 0.22;
    final ltwH = h * 0.52;
    final ltwLeft = w * 0.12;
    final ltwTop = bottomY - ltwH;
    final ltwRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(ltwLeft, ltwTop, ltwW, ltwH),
      const Radius.circular(2),
    );
    canvas.drawRRect(ltwRect, darkGoldPaint);
    // Roof slope
    final lPath = Path()
      ..moveTo(ltwLeft, ltwTop)
      ..lineTo(ltwLeft + ltwW / 2, ltwTop - h * 0.08)
      ..lineTo(ltwLeft + ltwW, ltwTop)
      ..close();
    canvas.drawPath(lPath, brightGoldPaint);
    // Left tower windows
    for (double wy = ltwTop + h * 0.06; wy < bottomY - h * 0.08; wy += h * 0.1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(ltwLeft + ltwW * 0.2, wy, ltwW * 0.6, h * 0.04),
          const Radius.circular(1.5),
        ),
        deepEmeraldPaint,
      );
    }

    // --- Side Right Tower ---
    final rtwW = w * 0.22;
    final rtwH = h * 0.52;
    final rtwRight = w * 0.88;
    final rtwLeft = rtwRight - rtwW;
    final rtwTop = bottomY - rtwH;
    final rtwRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rtwLeft, rtwTop, rtwW, rtwH),
      const Radius.circular(2),
    );
    canvas.drawRRect(rtwRect, darkGoldPaint);
    // Roof slope
    final rPath = Path()
      ..moveTo(rtwLeft, rtwTop)
      ..lineTo(rtwLeft + rtwW / 2, rtwTop - h * 0.08)
      ..lineTo(rtwRight, rtwTop)
      ..close();
    canvas.drawPath(rPath, brightGoldPaint);
    // Right tower windows
    for (double wy = rtwTop + h * 0.06; wy < bottomY - h * 0.08; wy += h * 0.1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rtwLeft + rtwW * 0.2, wy, rtwW * 0.6, h * 0.04),
          const Radius.circular(1.5),
        ),
        deepEmeraldPaint,
      );
    }

    // --- Central Grand Tower ---
    final ctwW = w * 0.36;
    final ctwH = h * 0.72;
    final ctwLeft = cx - ctwW / 2;
    final ctwTop = bottomY - ctwH;
    final ctwRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(ctwLeft, ctwTop, ctwW, ctwH),
      const Radius.circular(3),
    );
    canvas.drawRRect(ctwRect, goldPaint);

    // Central Pinnacle / Arch Roof
    final cPath = Path()
      ..moveTo(ctwLeft, ctwTop)
      ..lineTo(cx, ctwTop - h * 0.14)
      ..lineTo(ctwLeft + ctwW, ctwTop)
      ..close();
    canvas.drawPath(cPath, brightGoldPaint);

    // Finial Star / Diamond
    final fSize = w * 0.045;
    final fCenterY = ctwTop - h * 0.16;
    final finialPath = Path()
      ..moveTo(cx, fCenterY - fSize)
      ..lineTo(cx + fSize, fCenterY)
      ..lineTo(cx, fCenterY + fSize)
      ..lineTo(cx - fSize, fCenterY)
      ..close();
    canvas.drawPath(finialPath, brightGoldPaint);

    // Arched Grand Portal (Gateway)
    final archW = ctwW * 0.54;
    final archH = h * 0.32;
    final archLeft = cx - archW / 2;
    final archTop = bottomY - archH;

    final archPath = Path()
      ..moveTo(archLeft, bottomY)
      ..lineTo(archLeft, archTop + archW / 2)
      ..arcTo(
        Rect.fromLTWH(archLeft, archTop, archW, archW),
        3.14159,
        3.14159,
        false,
      )
      ..lineTo(archLeft + archW, bottomY)
      ..close();
    canvas.drawPath(archPath, deepEmeraldPaint);

    // Inner Portal Arch
    final inArchW = archW * 0.55;
    final inArchH = archH * 0.65;
    final inArchLeft = cx - inArchW / 2;
    final inArchTop = bottomY - inArchH;

    final inArchPath = Path()
      ..moveTo(inArchLeft, bottomY)
      ..lineTo(inArchLeft, inArchTop + inArchW / 2)
      ..arcTo(
        Rect.fromLTWH(inArchLeft, inArchTop, inArchW, inArchW),
        3.14159,
        3.14159,
        false,
      )
      ..lineTo(inArchLeft + inArchW, bottomY)
      ..close();
    canvas.drawPath(inArchPath, const Color(0xFF0C4A3E).paint);

    // Central Tower Windows (Upper floors)
    final winW = ctwW * 0.28;
    final winH = h * 0.055;
    for (double wy = ctwTop + h * 0.05; wy < archTop - h * 0.04; wy += h * 0.09) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - winW - w * 0.02, wy, winW, winH),
          const Radius.circular(1.5),
        ),
        deepEmeraldPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + w * 0.02, wy, winW, winH),
          const Radius.circular(1.5),
        ),
        deepEmeraldPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension on Color {
  Paint get paint => Paint()..color = this;
}

