import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WardiatyLogoWidget extends StatelessWidget {
  final double size;
  final bool showText;
  final bool useImage;

  const WardiatyLogoWidget({
    super.key,
    this.size = 48.0,
    this.showText = false,
    this.useImage = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;

    if (useImage) {
      iconWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/images/logo.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildVectorLogo(),
        ),
      );

    } else {
      iconWidget = _buildVectorLogo();
    }

    if (!showText) return iconWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ورديتي',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.42,
                color: AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'وقتك محسوب.. ويوميتك بالملّيم',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: size * 0.22,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVectorLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _WardiatyLogoPainter(),
      ),
    );
  }
}

class _WardiatyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    // 12-hour tick marks / dial arc
    final dialPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, dialPaint);

    // Golden Arc rim
    final goldArcPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius * 1.05);
    canvas.drawArc(arcRect, 0.4, 2.2, false, goldArcPaint);

    // Checkmark hands in cyan / mint
    final checkPaint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(center.dx - radius * 0.45, center.dy + radius * 0.05)
      ..lineTo(center.dx - radius * 0.1, center.dy + radius * 0.42)
      ..lineTo(center.dx + radius * 0.52, center.dy - radius * 0.35);

    canvas.drawPath(checkPath, checkPaint);

    // Golden center core coin
    final corePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.08, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
