import 'package:flutter/material.dart';

class CyberGridBackground extends StatelessWidget {
  final Widget child;

  const CyberGridBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0E11),
      child: child,
    );
  }
}

