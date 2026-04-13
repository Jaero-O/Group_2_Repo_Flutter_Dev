import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'album_photos_page.dart';
import '../../model/my_tree_model.dart'; 
import '../../model/photo.dart';
import 'photo_widgets.dart';

// Type definition for the callback when an album is long-pressed
typedef AlbumLongPressCallback = void Function(MyTree album);

// Displays a grid of photo albums
class MyTreesPage extends StatelessWidget {
  // If true, page is in selection mode
  final bool isSelectionMode;

  // Callback when an album is selected in selection mode
  final ValueChanged<String>? onAlbumSelected;

  // Callback when an album is long-pressed
  final AlbumLongPressCallback? onAlbumLongPress;

  // List of albums to display
  final List<MyTree> albums;

  // Optional lookup for real photo thumbnails (keyed by Photo.id)
  final Map<int, PhotoMetadata> photosById;

  const MyTreesPage({
    super.key,
    this.isSelectionMode = false,
    this.onAlbumSelected,
    this.albums = const [],
    this.onAlbumLongPress, 
    this.photosById = const {},
  });

  @override
  Widget build(BuildContext context) {
    final displayAlbums = albums;

    if (displayAlbums.isEmpty) {
      final message = isSelectionMode ? 'No albums available' : 'No albums yet. \nTap + create one.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        crossAxisSpacing: 15, 
        mainAxisSpacing: 1, 
        childAspectRatio: 0.70, 
      ),
      itemCount: displayAlbums.length,
      itemBuilder: (context, index) {
        final album = displayAlbums[index];
        final title = album.title;
        final location = album.location;
        final images = album.images;

        PhotoMetadata? coverPhoto;
        for (final rawId in images.reversed) {
          final id = int.tryParse(rawId);
          if (id == null) continue;
          final photo = photosById[id];
          if (photo != null) {
            coverPhoto = photo;
            break;
          }
        }

        final String coverImage = album.coverImage.isNotEmpty ? album.coverImage : 'images/leaf.png';

        return GestureDetector(
          onTap: () {
            // If in selection mode, trigger callback instead of navigating
            if (isSelectionMode && onAlbumSelected != null) {
              onAlbumSelected!(title);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AlbumPhotosPage(albumTitle: title, images: images),
                ),
              );
            }
          },
          onLongPress: onAlbumLongPress == null || isSelectionMode
              ? null // Disable long press if no handler is provided or in selection mode
              : () => onAlbumLongPress!(album), // Pass the album object
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(38),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: coverPhoto != null
                          ? PhotoGridItem(photo: coverPhoto, borderRadius: 0)
                          : Image.asset(
                              coverImage,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Album title and location
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                      if (location.isNotEmpty)
                        Text(
                          location,
                          style: TextStyle(
                            color: Colors.black.withAlpha(178),
                            fontSize: 12,
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
        );
      },
    );
  }
}