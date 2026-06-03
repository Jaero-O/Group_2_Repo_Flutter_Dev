import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../../model/photo.dart';
import '../../model/scan_classification.dart';

// Displays one or more photos in full screen with swipe navigation.
class FullScreenPhotoView extends StatefulWidget {
  final Photo? photo;
  final String? imagePath;
  final List<Photo>? photoList;
  final int initialIndex;

  const FullScreenPhotoView({
    super.key,
    this.photo,
    this.imagePath,
    this.photoList,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenPhotoView> createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<FullScreenPhotoView> {
  late final PageController _pageController;
  late int _currentIndex;

  List<Photo>? get _photos {
    final list = widget.photoList;
    if (list == null || list.isEmpty) return null;
    return list;
  }

  bool get _isMultiPhoto => (_photos?.length ?? 0) > 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = _coerceIndex(widget.initialIndex);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _coerceIndex(int index) {
    final list = _photos;
    if (list == null || list.isEmpty) return 0;
    if (index < 0) return 0;
    if (index >= list.length) return list.length - 1;
    return index;
  }

  Photo? get _currentPhoto {
    final list = _photos;
    if (list == null || list.isEmpty) return widget.photo;
    return list[_coerceIndex(_currentIndex)];
  }

  bool _hasInfo(Photo photo) {
    return (photo.disease?.isNotEmpty ?? false) ||
        (photo.title?.isNotEmpty ?? false) ||
        (photo.description?.isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = _currentPhoto;
    final photos = _photos;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isMultiPhoto && photos != null)
            PageView.builder(
              controller: _pageController,
              itemCount: photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Center(child: _buildPhotoImage(photos[index]));
              },
            )
          else
            Center(
              child: currentPhoto != null
                  ? _buildPhotoImage(currentPhoto)
                  : _buildPlaceholder(),
            ),
          if (currentPhoto != null && _hasInfo(currentPhoto))
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildInfoPanel(currentPhoto),
            ),
          if (_isMultiPhoto && photos != null)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 40,
            right: 8,
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

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo, color: Colors.white70, size: 80),
          const SizedBox(height: 16),
          Text(
            'Viewing: ${widget.imagePath}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(Photo photo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (photo.title != null && photo.title!.isNotEmpty)
            Text(
              photo.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (photo.disease != null && photo.disease!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.science, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Disease: ${photo.disease!}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (photo.confidence != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Confidence: ${(photo.confidence! * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (photo.severityLabel != null && photo.severityLabel!.isNotEmpty)
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
                    'Classification: ${photo.severityLabel!}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (photo.severityValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Severity: ${photo.severityValue!.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (photo.description != null && photo.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                photo.description!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (photo.timestamp.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Scanned: ${_formatTimestampLabel(photo.timestamp)}',
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestampLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;

    final hasZone =
        trimmed.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(trimmed);
    final normalizedBase = trimmed.replaceFirst(' ', 'T');
    final normalized = hasZone ? normalizedBase : '${normalizedBase}Z';
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed.toLocal().toString().split('.').first;
    }

    final m = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2}):(\d{2}))?',
    ).firstMatch(trimmed);
    if (m == null) return raw;

    final y = int.tryParse(m.group(1) ?? '');
    final mo = int.tryParse(m.group(2) ?? '');
    final d = int.tryParse(m.group(3) ?? '');
    final h = int.tryParse(m.group(4) ?? '0');
    final mi = int.tryParse(m.group(5) ?? '0');
    final s = int.tryParse(m.group(6) ?? '0');
    if (y == null || mo == null || d == null) return raw;

    return DateTime.utc(
      y,
      mo,
      d,
      h ?? 0,
      mi ?? 0,
      s ?? 0,
    ).toLocal().toString().split('.').first;
  }

  String _normalizeLocalImagePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return trimmed;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.isAbsolute && uri.scheme == 'file') {
      try {
        return uri.toFilePath();
      } catch (_) {
        return trimmed.replaceFirst('file://', '');
      }
    }
    return trimmed;
  }

  Widget _buildPhotoImage(Photo currentPhoto) {
    final imagePath = _normalizeLocalImagePath(currentPhoto.path?.trim() ?? '');
    final imageUrl = currentPhoto.imageUrl?.trim() ?? '';
    final imageData = currentPhoto.data.trim();
    final useLocalPath = imagePath.isNotEmpty && !isPiLinuxPath(imagePath);

    if (useLocalPath) {
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
        final useLocalPath = !isPiLinuxPath(normalizedPath);
        final isRemotePath =
            normalizedPath.startsWith('http://') ||
            normalizedPath.startsWith('https://');

        if (isRemotePath) {
          imageWidget = Image.network(
            normalizedPath,
            fit: BoxFit.cover,
            cacheWidth: 400,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        } else if (useLocalPath) {
          imageWidget = Image.file(
            File(normalizedPath),
            fit: BoxFit.cover,
            cacheWidth: 400,
            errorBuilder: (context, error, stackTrace) {
              if (imageUrl != null && imageUrl.isNotEmpty) {
                return Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 400,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, color: Colors.grey),
                );
              }
              return const Icon(Icons.image_not_supported, color: Colors.grey);
            },
          );
        } else if (imageUrl != null && imageUrl.isNotEmpty) {
          imageWidget = Image.network(
            imageUrl,
            fit: BoxFit.cover,
            cacheWidth: 400,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        } else {
          imageWidget = const Icon(
            Icons.image_not_supported,
            color: Colors.grey,
          );
        }
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        imageWidget = Image.network(
          imageUrl,
          fit: BoxFit.cover,
          cacheWidth: 400,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported, color: Colors.grey),
        );
      } else if (imageData != null && imageData.isNotEmpty) {
        // Use base64-backed image for legacy items
        try {
          final bytes = base64Decode(imageData);
          imageWidget = Image.memory(bytes, fit: BoxFit.cover, cacheWidth: 400);
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
                          Colors.black.withValues(alpha: 0.7),
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
