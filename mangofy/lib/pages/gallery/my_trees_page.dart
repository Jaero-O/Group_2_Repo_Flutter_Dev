import 'package:flutter/material.dart';
import 'album_photos_page.dart';

/// Displays a grid of photo albums (user's trees).
/// 
/// Supports two modes:
/// - Normal browsing: tap an album to view its photos
/// - Selection mode: tap an album to select it (for creating datasets or albums)
class MyTreesPage extends StatelessWidget {
  /// If true, page is in selection mode
  final bool isSelectionMode;

  /// Callback when an album is selected in selection mode
  final ValueChanged<String>? onAlbumSelected;

  /// List of albums to display
  /// Each album is a map with keys: 'title', 'location', 'images', 'cover_image'
  final List<Map<String, dynamic>> albums;

  const MyTreesPage({
    super.key,
    this.isSelectionMode = false,
    this.onAlbumSelected,
    this.albums = const [],
  });

  @override
  Widget build(BuildContext context) {
    // If no albums are provided, display a default placeholder album
    final displayAlbums = albums.isEmpty
        ? [
            {
              'title':
                  'My First Album with a Very Very Long Name That Should Not Overflow',
              'location': 'Backyard',
              'images': ['images/leaf.png'],
              'cover_image': 'images/leaf.png',
            },
          ]
        : albums;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // two albums per row
        crossAxisSpacing: 15, // horizontal spacing between albums
        mainAxisSpacing: 1, // vertical spacing
        childAspectRatio: 0.70, // height-to-width ratio of album tiles
      ),
      itemCount: displayAlbums.length,
      itemBuilder: (context, index) {
        final album = displayAlbums[index];
        final title = album['title'] as String;
        final location = album['location'] as String? ?? '';
        final images = album['images'] as List<String>? ?? [];
        final String coverImage;

        // Determine which image to use as the album cover
        if (album.containsKey('cover_image') &&
            (album['cover_image'] as String).isNotEmpty) {
          coverImage = album['cover_image'] as String;
        } else if (images.isNotEmpty &&
            (images.last.contains('/') || images.last.contains('.'))) {
          coverImage = images.last;
        } else {
          coverImage = 'images/leaf.png';
        }

        return GestureDetector(
          onTap: () {
            // If in selection mode, trigger callback instead of navigating
            if (isSelectionMode && onAlbumSelected != null) {
              onAlbumSelected!(title);
            } else {
              // Normal browsing: open AlbumPhotosPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AlbumPhotosPage(albumTitle: title, images: images),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album cover image
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
                      image: DecorationImage(
                        image: AssetImage(coverImage),
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
                      // Album title (ellipsis if too long)
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
                      // Album location (optional)
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
