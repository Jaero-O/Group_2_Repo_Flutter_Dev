// my_trees_page.dart
import 'package:flutter/material.dart';
import 'album_photos_page.dart';

class MyTreesPage extends StatelessWidget {
  // 💡 NEW: Properties for selection mode
  final bool isSelectionMode;
  final ValueChanged<String>? onAlbumSelected;

  const MyTreesPage({
    super.key,
    this.isSelectionMode = false, // Default to viewing mode
    this.onAlbumSelected,
  });

  @override
  Widget build(BuildContext context) {
    final albums = [
      {'title': 'Mango Trees', 'cover': 'images/leaf.png'},
      {'title': 'Banana Grove', 'cover': 'images/leaf.png'},
      {'title': 'Coconut Field', 'cover': 'images/leaf.png'},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return GestureDetector(
          onTap: () {
            if (isSelectionMode && onAlbumSelected != null) {
              // ✅ SELECTION MODE: Trigger the callback to start photo selection for this album
              onAlbumSelected!(album['title']!);
            } else {
              // ✅ VIEW MODE (Gallery default): Navigate to the album viewing page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AlbumPhotosPage(albumTitle: album['title']!),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage('assets/sample0.jpg'), 
                fit: BoxFit.cover,
              ),
            ),
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Text(
                album['title']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}