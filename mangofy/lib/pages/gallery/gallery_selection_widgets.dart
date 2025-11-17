import 'package:flutter/material.dart';

/// Grid widget for selecting photos in selection mode
class PhotosSelectionGrid extends StatelessWidget {
  /// Key representing current content (AllPhotos or album name)
  final String contentKey;

  /// List of all image IDs in the current view
  final List<String> allImageIds;

  /// Currently selected images
  final List<String> selectedImages;

  /// Callback for toggling selection of an image
  final ValueChanged<String> onToggleSelection;

  const PhotosSelectionGrid({
    super.key,
    required this.contentKey,
    required this.allImageIds,
    required this.selectedImages,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = allImageIds.length;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final imageId = allImageIds[index];
        final selected = selectedImages.contains(imageId);

        return GestureDetector(
          onTap: () => onToggleSelection(imageId),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? Colors.green[200] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Icon(Icons.photo, size: 40, color: Colors.grey),
                if (selected)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(127),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}