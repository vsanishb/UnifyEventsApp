import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/services/r2_image_service.dart';

class R2CacheManager {
  static const String key = 'r2ImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
    ),
  );
}

class AppCachedImage extends ConsumerWidget {
  final String? imageKey;
  final double height;
  final double width;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;

  const AppCachedImage({
    super.key,
    required this.imageKey,
    this.height = 150,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.borderRadius = 16.0,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageKey == null || imageKey!.isEmpty) {
      return _buildErrorPlaceholder();
    }

    final imageAsync = ref.watch(eventImageProvider(imageKey!));

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageAsync.when(
        data: (imageUrl) {
          if (imageUrl == null || imageUrl.isEmpty) {
            return _buildErrorPlaceholder();
          }
          return CachedNetworkImage(
            imageUrl: imageUrl,
            cacheManager: R2CacheManager.instance,
            height: height,
            width: width,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (context, url) => placeholder ?? _buildShimmerLoading(),
            errorWidget: (context, url, error) => _buildErrorPlaceholder(),
          );
        },
        loading: () => placeholder ?? _buildShimmerLoading(),
        error: (err, stack) => _buildErrorPlaceholder(),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF16151A),
      highlightColor: const Color(0xFF2C2A35),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFF16151A),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF16151A),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF2C2A35)),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFFFECF65),
          size: 40,
        ),
      ),
    );
  }
}
