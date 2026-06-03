import 'package:flutter/material.dart';
import 'app_cached_image.dart';

class R2ImageWidget extends StatelessWidget {
  final String? imageKey;
  final double height;
  final double width;
  final BoxFit fit;
  final double borderRadius;

  const R2ImageWidget({
    super.key,
    required this.imageKey,
    this.height = 150,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return AppCachedImage(
      imageKey: imageKey,
      height: height,
      width: width,
      fit: fit,
      borderRadius: borderRadius,
    );
  }
}
