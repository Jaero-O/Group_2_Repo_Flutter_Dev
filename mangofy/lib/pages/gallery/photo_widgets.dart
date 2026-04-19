import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../../model/photo.dart';

// Displays a single photo in full screen with a close button.
class FullScreenPhotoView extends StatelessWidget {
  // The photo to display (for actual photos from database)
  final Photo? photo;
  // Fallback for placeholder images
  final String? imagePath;

  const FullScreenPhotoView({super.key, this.photo, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Black background for a typical full-screen photo view
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo Display Area
          Center(
            child: photo != null
                ? _buildFullScreenImage()
                : Container(
                    // Placeholder for albums or other cases
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(50),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo,
                          color: Colors.white70,
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Viewing: $imagePath',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Scan Information Panel (if available)
          if (photo != null &&
              (photo!.disease != null ||
                  photo!.title != null ||
                  photo!.description != null))
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (photo!.title != null && photo!.title!.isNotEmpty)
                      Text(
                        photo!.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (photo!.disease != null && photo!.disease!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.science,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Disease: ${photo!.disease!}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (photo!.confidence != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Confidence: ${(photo!.confidence! * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (photo!.severityLabel != null &&
                        photo!.severityLabel!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_offer_outlined,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Classification: ${photo!.severityLabel!}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (photo!.severityValue != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Severity: ${photo!.severityValue!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (photo!.description != null &&
                        photo!.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          photo!.description!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (photo!.timestamp.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Scanned: ${DateTime.tryParse(photo!.timestamp)?.toLocal().toString().split('.')[0] ?? photo!.timestamp}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Close Button
          Positioned(
            top: 40,
            right: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenImage() {
    final currentPhoto = photo!;
    final imagePath = currentPhoto.path?.trim() ?? '';
    final imageUrl = currentPhoto.imageUrl?.trim() ?? '';
    final imageData = currentPhoto.data.trim();

    if (imagePath.isNotEmpty) {
      final isRemotePath =
          imagePath.startsWith('http://') || imagePath.startsWith('https://');
      if (isRemotePath) {
        return Image.network(
          imagePath,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.image_not_supported, color: Colors.white70),
        );
      }
      return Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) {
          if (imageUrl.isNotEmpty) {
            return Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported, color: Colors.white70),
            );
          }
          return const Icon(Icons.image_not_supported, color: Colors.white70);
        },
      );
    }

    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported, color: Colors.white70),
      );
    }

    if (imageData.isNotEmpty) {
      try {
        final bytes = base64Decode(imageData);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (_) {
        return const Icon(Icons.broken_image, color: Colors.white70);
      }
    }

    return const Icon(Icons.photo, color: Colors.white70, size: 80);
  }
}

// A reusable grid item widget for displaying a generic photo placeholder.
class PhotoGridItemPlaceholder extends StatelessWidget {
  final double iconSize;
  final double borderRadius;

  const PhotoGridItemPlaceholder({
    super.key,
    this.iconSize = 40,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.photo, color: Colors.grey, size: iconSize),
    );
  }
}

// A wrapper to add tap and long press functionality to a grid item.
class LongPressableGridItemPlaceholder extends StatelessWidget {
  final double iconSize;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  const LongPressableGridItemPlaceholder({
    super.key,
    this.iconSize = 40,
    this.borderRadius = 8,
    this.onTap,
    this.onLongPress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Wrapped with GestureDetector to handle taps and long presses
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }
}

// A reusable widget to display a grid of photo placeholders.
class PhotoGridPlaceholder extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double borderRadius;
  final double iconSize;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
  // Property for tap handler
  final ValueChanged<int>? onItemTap;
  // Property for long press handler
  final ValueChanged<int>? onItemLongPress;
  // List of placeholder image IDs - used to pass context to the full screen view
  final List<String> imageIds;

  const PhotoGridPlaceholder({
    super.key,
    required this.itemCount,
    this.crossAxisCount = 4,
    this.crossAxisSpacing = 4,
    this.mainAxisSpacing = 4,
    this.borderRadius = 8,
    this.iconSize = 40,
    this.shrinkWrap = false,
    this.physics,
    this.padding = EdgeInsets.zero,
    this.onItemTap,
    this.onItemLongPress,
    this.imageIds = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return LongPressableGridItemPlaceholder(
          borderRadius: borderRadius,
          iconSize: iconSize,
          // Pass the tap handler to the grid item
          onTap: () {
            if (onItemTap != null) {
              onItemTap!(index);
            }
          },
          // Pass the long press handler to the grid item
          onLongPress: () {
            if (onItemLongPress != null) {
              onItemLongPress!(index);
            }
          },
          child: PhotoGridItemPlaceholder(
            iconSize: iconSize,
            borderRadius: borderRadius,
          ),
        );
      },
    );
  }
}

// A reusable widget to display a grid of actual photos (supports both Photo and PhotoMetadata).
class PhotoGrid extends StatelessWidget {
  final List<dynamic> photos; // Can be List<Photo> or List<PhotoMetadata>
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double borderRadius;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
  final bool isLoadingMore;
  // Property for tap handler
  final ValueChanged<int>? onItemTap;
  // Property for long press handler
  final ValueChanged<int>? onItemLongPress;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.crossAxisCount = 4,
    this.crossAxisSpacing = 4,
    this.mainAxisSpacing = 4,
    this.borderRadius = 8,
    this.shrinkWrap = false,
    this.physics,
    this.padding = EdgeInsets.zero,
    this.isLoadingMore = false,
    this.onItemTap,
    this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: photos.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == photos.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.green,
                ),
              ),
            ),
          );
        }

        final photo = photos[index];
        return LongPressableGridItemPlaceholder(
          borderRadius: borderRadius,
          // Pass the tap handler to the grid item
          onTap: () {
            if (onItemTap != null) {
              onItemTap!(index);
            }
          },
          // Pass the long press handler to the grid item
          onLongPress: () {
            if (onItemLongPress != null) {
              onItemLongPress!(index);
            }
          },
          child: PhotoGridItem(photo: photo, borderRadius: borderRadius),
        );
      },
    );
  }
}

// A reusable grid item widget for displaying an actual photo.
class PhotoGridItem extends StatelessWidget {
  final dynamic photo; // Can be Photo or PhotoMetadata
  final double borderRadius;

  const PhotoGridItem({super.key, required this.photo, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    try {
      Widget imageWidget;
      final String? imagePath = photo.path;
      final String? imageUrl = photo.imageUrl;
      final String? imageData = photo is Photo ? photo.data : null;

      if (imagePath != null && imagePath.isNotEmpty) {
        final normalizedPath = imagePath.trim();
        final isRemotePath =
            normalizedPath.startsWith('http://') ||
            normalizedPath.startsWith('https://');

        if (isRemotePath) {
          imageWidget = Image.network(
            normalizedPath,
            fit: BoxFit.cover,
            cacheWidth: 200,
            cacheHeight: 200,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        } else {
          imageWidget = Image.file(
            File(normalizedPath),
            fit: BoxFit.cover,
            cacheWidth: 200,
            cacheHeight: 200,
            errorBuilder: (context, error, stackTrace) {
              if (imageUrl != null && imageUrl.isNotEmpty) {
                return Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 200,
                  cacheHeight: 200,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, color: Colors.grey),
                );
              }
              return const Icon(Icons.image_not_supported, color: Colors.grey);
            },
          );
        }
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        imageWidget = Image.network(
          imageUrl,
          fit: BoxFit.cover,
          cacheWidth: 200,
          cacheHeight: 200,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported, color: Colors.grey),
        );
      } else if (imageData != null && imageData.isNotEmpty) {
        // Use base64-backed image for legacy items
        try {
          final bytes = base64Decode(imageData);
          imageWidget = Image.memory(
            bytes,
            fit: BoxFit.cover,
            cacheWidth: 200,
            cacheHeight: 200,
          );
        } catch (e) {
          // Fallback if base64 decode fails
          imageWidget = const Icon(Icons.broken_image, color: Colors.grey);
        }
      } else {
        // No path and no data - show placeholder
        imageWidget = const Icon(Icons.photo, color: Colors.grey);
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          color: Colors.grey[200],
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageWidget,
              // Overlay with scan information if available
              if (photo.disease != null && photo.disease!.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          photo.disease!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (photo.severityLabel != null &&
                            photo.severityLabel!.isNotEmpty)
                          Text(
                            photo.severityLabel!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (photo.confidence != null)
                          Text(
                            '${(photo.confidence! * 100).round()}% confidence',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Fallback to placeholder if decoding or file loading fails
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }
}
