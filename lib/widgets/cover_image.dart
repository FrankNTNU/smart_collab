import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.imageUrl,
    this.isRoundedBorder = true,
    this.height = 128,
  });

  final String imageUrl;
  final bool isRoundedBorder;
  final double height;
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: isRoundedBorder
          ? ShapeBorderClipper(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            )
          : null,
      child: Hero(
        tag: imageUrl,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
}
