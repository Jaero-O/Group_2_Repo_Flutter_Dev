import 'package:flutter/material.dart';

/// Page that displays photos within a specific album.
/// 
/// [albumTitle] is the name of the album displayed in the AppBar.
/// [images] is the list of image identifiers or paths (currently unused for placeholder images).
class AlbumPhotosPage extends StatelessWidget {
  final String albumTitle;
  final List<String> images; 

  /// Constructor for AlbumPhotosPage.
  /// [albumTitle] is required, [images] defaults to an empty list.
  const AlbumPhotosPage({
    super.key,
    required this.albumTitle,
    this.images = const [], 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar showing the album title
      appBar: AppBar(
        title: Text(
          albumTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        backgroundColor: Colors.white, // AppBar background
        iconTheme: const IconThemeData(color: Colors.green), // Back arrow color
        elevation: 0, // Remove shadow
      ),
      backgroundColor: Colors.white, // Page background

      // Grid displaying album photos
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 columns in the grid
          crossAxisSpacing: 6, // Horizontal spacing between items
          mainAxisSpacing: 6, // Vertical spacing between items
        ),
        itemCount: 15, // Number of items (placeholder)
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[200], // Placeholder background color
              borderRadius: BorderRadius.circular(8), // Rounded corners
            ),
            // Placeholder icon for images
            child: const Icon(
              Icons.photo,
              color: Colors.grey,
              size: 40,
            ),
          );
        },
      ),
    );
  }
}
