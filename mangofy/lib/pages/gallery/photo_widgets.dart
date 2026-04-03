import 'package:flutter/material.dart';
import 'dart:convert';
import '../../model/photo.dart';

// Displays a single photo in full screen with a close button.
class FullScreenPhotoView extends StatelessWidget {
  // The photo to display (for actual photos from database)
  final Photo? photo;
  // Fallback for placeholder images
  final String? imagePath;

  const FullScreenPhotoView({
    super.key,
    this.photo,
    this.imagePath,
  });

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
                ? PhotoGridItem(
                    photo: photo!,
                    borderRadius: 0, // No border radius for full screen
                  )
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
                          style: const TextStyle(color: Colors.white, fontSize: 16),
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
      child: Icon(
        Icons.photo,
        color: Colors.grey,
        size: iconSize,
      ),
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

// A reusable widget to display a grid of actual photos.
class PhotoGrid extends StatelessWidget {
  final List<Photo> photos;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double borderRadius;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
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
      itemCount: photos.length,
      itemBuilder: (context, index) {
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
          child: PhotoGridItem(
            photo: photo,
            borderRadius: borderRadius,
          ),
        );
      },
    );
  }
}

// A reusable grid item widget for displaying an actual photo.
class PhotoGridItem extends StatelessWidget {
  final Photo photo;
  final double borderRadius;

  const PhotoGridItem({
    super.key,
    required this.photo,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(photo.data);
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          image: DecorationImage(
            image: MemoryImage(bytes),
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (e) {
      // Fallback to placeholder if decoding fails
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(
          Icons.broken_image,
          color: Colors.grey,
        ),
      );
    }
  }
}