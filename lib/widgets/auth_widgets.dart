import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AuthHint extends StatelessWidget {
  final String text;

  const AuthHint({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.soft,
        height: 1.35,
      ),
    );
  }
}

class AuthProviderButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget logo;
  final String label;

  const AuthProviderButton({
    super.key,
    required this.onPressed,
    required this.logo,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 28,
              child: Center(child: logo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size.square(24),
      painter: _GoogleLogoPainter(),
    );
  }
}

class FacebookLogo extends StatelessWidget {
  const FacebookLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'f',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.18,
      size.width * 0.64,
      size.height * 0.64,
    );
    final stroke = size.width * 0.15;

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.square,
      );
    }

    arc(const Color(0xFFEA4335), 3.65, 1.42);
    arc(const Color(0xFFFBBC05), 2.45, 1.25);
    arc(const Color(0xFF34A853), 1.20, 1.20);
    arc(const Color(0xFF4285F4), -0.10, 1.35);

    final blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.50),
      Offset(size.width * 0.84, size.height * 0.50),
      blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
