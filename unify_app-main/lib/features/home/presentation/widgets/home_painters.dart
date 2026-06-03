import 'package:flutter/material.dart';

// Network Mesh Painter (Phase Shift)
class NetworkMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFECF65).withOpacity(0.06)
      ..strokeWidth = 1.0;
    final dotPaint = Paint()
      ..color = const Color(0xFFFECF65).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final pts = [
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.45, size.height * 0.15),
      Offset(size.width * 0.8, size.height * 0.35),
      Offset(size.width * 0.25, size.height * 0.75),
      Offset(size.width * 0.65, size.height * 0.85),
    ];

    canvas.drawLine(pts[0], pts[1], paint);
    canvas.drawLine(pts[1], pts[2], paint);
    canvas.drawLine(pts[0], pts[3], paint);
    canvas.drawLine(pts[3], pts[4], paint);
    canvas.drawLine(pts[1], pts[4], paint);
    canvas.drawLine(pts[2], pts[4], paint);

    for (var pt in pts) {
      canvas.drawCircle(pt, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Waves Painter (Utsav Fest)
class WavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFECF65).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.65);
    path1.quadraticBezierTo(size.width * 0.3, size.height * 0.45, size.width * 0.65, size.height * 0.8);
    path1.quadraticBezierTo(size.width * 0.8, size.height * 0.95, size.width, size.height * 0.75);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    final paint2 = Paint()
      ..color = const Color(0xFFFECF65).withOpacity(0.03)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height * 0.8);
    path2.quadraticBezierTo(size.width * 0.45, size.height * 0.65, size.width, size.height * 0.85);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Geometric Particles Painter (Third Parent Event)
class GeometricParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFECF65).withOpacity(0.04)
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size.width * 0.7, size.height * 0.2)
      ..lineTo(size.width * 0.85, size.height * 0.4)
      ..lineTo(size.width * 0.7, size.height * 0.6)
      ..lineTo(size.width * 0.55, size.height * 0.4)
      ..close();
    canvas.drawPath(path, paint);

    final path2 = Path()
      ..moveTo(size.width * 0.3, size.height * 0.5)
      ..lineTo(size.width * 0.4, size.height * 0.65)
      ..lineTo(size.width * 0.3, size.height * 0.8)
      ..lineTo(size.width * 0.2, size.height * 0.65)
      ..close();
    canvas.drawPath(path2, paint);

    final paintDot = Paint()
      ..color = const Color(0xFFFECF65).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.25), 8, paintDot);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.75), 14, paintDot);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
