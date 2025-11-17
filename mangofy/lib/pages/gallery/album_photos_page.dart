import 'package:flutter/material.dart';
import 'photo_widgets.dart'; 

/// Page that displays photos within a specific album.
class AlbumPhotosPage extends StatelessWidget {
  final String albumTitle;
  final List<String> images; 

  const AlbumPhotosPage({
    super.key,
    required this.albumTitle,
    this.images = const [], 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          albumTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        backgroundColor: Colors.white, 
        iconTheme: const IconThemeData(color: Colors.green), 
        elevation: 0, 
      ),
      backgroundColor: Colors.white, 

      // Grid displaying album photos 
      body: const PhotoGridPlaceholder(
        itemCount: 15, // Number of items (placeholder)
        crossAxisCount: 3, // 3 columns in the grid
        crossAxisSpacing: 6, // Horizontal spacing between items
        mainAxisSpacing: 6, // Vertical spacing between items
        padding: EdgeInsets.all(16),
        borderRadius: 8,
        iconSize: 40,
      ),
    );
  }
}