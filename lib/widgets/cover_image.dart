import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.imageUrl,
    this.isRoundedBorder = true,
    this.height = 128,
    this.canViewFullImage = true,
  });

  final String imageUrl;
  final bool isRoundedBorder;
  final double height;
  final bool canViewFullImage;
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
        child: InkWell(
          // click to view full image
          onTap: !canViewFullImage
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (context) => Stack(
                      children: [
                        Container(
                          color: Colors.black,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.fitWidth,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                        Positioned(
                          top: 32,
                          right: 10,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
      ),
    );
  }
}
