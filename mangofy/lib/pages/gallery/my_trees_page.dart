import 'package:flutter/material.dart';
import 'album_photos_page.dart';

class MyTreesPage extends StatelessWidget {
  final bool isSelectionMode;
  final ValueChanged<String>? onAlbumSelected;
  final List<Map<String, dynamic>> albums; 

  const MyTreesPage({
    super.key,
    this.isSelectionMode = false,
    this.onAlbumSelected,
    this.albums = const [], 
  });

  @override
  Widget build(BuildContext context) {
    final displayAlbums = albums.isEmpty
        ? [
            {
              'title': 'My First Album',
              'location': 'Backyard',
              'images': ['images/leaf.png'],
              'cover_image': 'images/leaf.png',
            },
          ]
        : albums;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: displayAlbums.length,
      itemBuilder: (context, index) {
        final album = displayAlbums[index];
        final title = album['title'] as String;
        final location = album['location'] as String? ?? '';
        final images = album['images'] as List<String>? ?? [];
        final String coverImage;
        if (album.containsKey('cover_image') && (album['cover_image'] as String).isNotEmpty) {
           coverImage = album['cover_image'] as String;
        } else if (images.isNotEmpty && (images.last.contains('/') || images.last.contains('.'))) {
          coverImage = images.last;
        } else {
          coverImage = 'images/leaf.png'; 
        }

        return GestureDetector(
          onTap: () {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
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
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (location.isNotEmpty)
                      Text(
                        location,
                        style: TextStyle(
                          color: Colors.black.withAlpha(178),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}