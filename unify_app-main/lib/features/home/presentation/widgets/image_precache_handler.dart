import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unify_events/core/services/r2_image_service.dart';
import 'package:unify_events/shared/widgets/app_cached_image.dart';

class ImagePrecacheHandler extends ConsumerWidget {
  final List<String> imageKeys;
  const ImagePrecacheHandler({super.key, required this.imageKeys});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    for (final key in imageKeys) {
      if (key.isNotEmpty) {
        final urlAsync = ref.watch(eventImageProvider(key));
        urlAsync.whenData((url) {
          if (url != null && url.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              precacheImage(
                CachedNetworkImageProvider(
                  url,
                  cacheManager: R2CacheManager.instance,
                ),
                context,
              );
            });
          }
        });
      }
    }
    return const SizedBox.shrink();
  }
}
