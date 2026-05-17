import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class NLMark extends StatelessWidget {
  const NLMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: kAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text('NL', style: GoogleFonts.sora(
          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.5,
        )),
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autocorrect;
  final Widget? suffix;
  final int maxLength;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.autocorrect = true,
    this.suffix,
    this.maxLength = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F2333),
        )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autocorrect: autocorrect,
          maxLength: maxLength,
          maxLines: 1,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF0F2333)),
          decoration: InputDecoration(
            hintText: label,
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class AuthErrorBox extends StatelessWidget {
  final String message;
  const AuthErrorBox(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFFDC2626), fontSize: 13,
        ))),
      ]),
    );
  }
}

class NetworkPainter extends CustomPainter {
  const NetworkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.22);
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final pts = [
      Offset(w * 0.18, h * 0.28),
      Offset(w * 0.52, h * 0.12),
      Offset(w * 0.84, h * 0.35),
      Offset(w * 0.32, h * 0.68),
      Offset(w * 0.68, h * 0.75),
      Offset(w * 0.08, h * 0.82),
      Offset(w * 0.92, h * 0.80),
    ];
    const edges = [(0, 1), (1, 2), (0, 3), (2, 4), (3, 4), (5, 3), (4, 6)];

    for (final (a, b) in edges) {
      canvas.drawLine(pts[a], pts[b], line);
    }
    for (final p in pts) {
      canvas.drawCircle(p, 3.5, dot);
    }
    canvas.drawCircle(pts[2], 12, ring);
    canvas.drawCircle(pts[4], 10, ring);
  }

  @override
  bool shouldRepaint(_) => false;
}
