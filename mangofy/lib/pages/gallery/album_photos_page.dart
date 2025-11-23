import 'package:flutter/material.dart';
import 'photo_widgets.dart'; 
import 'gallery_dialogs.dart'; 

// Page that displays photos within a specific album.
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
    // Generate placeholder image IDs if the list is empty
    final imageList = images.isEmpty ? List.generate(15, (i) => 'album_photo_$i') : images;

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
      body: PhotoGridPlaceholder(
        itemCount: imageList.length, 
        imageIds: imageList, 
        crossAxisCount: 3, 
        crossAxisSpacing: 6, 
        mainAxisSpacing: 6, 
        padding: const EdgeInsets.all(16),
        borderRadius: 8,
        iconSize: 40,
        // Add onTap handler for full screen view
        onItemTap: (index) {
          final imageId = imageList[index];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenPhotoView(
                imagePath: imageId,
              ),
            ),
          );
        },
        // Add onItemLongPress handler for photo deletion
        onItemLongPress: (index) {
          final imageId = imageList[index];
          // Default action for long press on a photo in an album
          GalleryDialogs.showDeleteConfirmationDialog(
            context,
            'Photo',
            imageId,
            () {
              // This would call a service to delete the photo from the album
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Photo "$imageId" removed from $albumTitle!'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}