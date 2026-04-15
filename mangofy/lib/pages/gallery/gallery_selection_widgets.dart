import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/photo.dart';
import 'photo_widgets.dart';

// Grid widget for selecting photos in selection mode
class PhotosSelectionGrid extends StatelessWidget {
  // Key representing current content (AllPhotos or album name)
  final String contentKey;

  // List of all image IDs in the current view
  final List<String> allImageIds;

  // Currently selected images
  final List<String> selectedImages;

  // Photo metadata map for rendering thumbnails by image ID.
  final Map<int, PhotoMetadata> photosById;

  // Callback for toggling selection of an image
  final ValueChanged<String> onToggleSelection;

  const PhotosSelectionGrid({
    super.key,
    required this.contentKey,
    required this.allImageIds,
    required this.selectedImages,
    required this.photosById,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = allImageIds.length;

    if (itemCount == 0) {
      return Center(
        child: Text(
          'No images available',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
      );
    }

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
        final id = int.tryParse(imageId);
        final photo = id == null ? null : photosById[id];

        return GestureDetector(
          onTap: () => onToggleSelection(imageId),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: PhotoGridItem(photo: photo, borderRadius: 0),
                  )
                else
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