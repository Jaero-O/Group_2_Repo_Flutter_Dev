import 'package:flutter/material.dart';
import 'album_photos_page.dart';

class MyTreesPage extends StatelessWidget {
  final bool isSelectionMode;
  final ValueChanged<String>? onAlbumSelected;

  const MyTreesPage({
    super.key,
    this.isSelectionMode = false, 
    this.onAlbumSelected,
  });

  @override
  Widget build(BuildContext context) {
    final albums = [
      {'title': 'Ahsilei Tree', 'location': 'Caloocan City', 'cover_image': 'images/leaf.png'},
      {'title': 'Kuru Tree', 'location': 'Las Pinas City', 'cover_image': 'images/leaf.png'},
      {'title': 'Mango Trees', 'location': 'Cavite', 'cover_image': 'images/leaf.png'},
      {'title': 'Banana Grove', 'location': 'Laguna', 'cover_image': 'images/leaf.png'},
      {'title': 'Coconut Field', 'location': 'Quezon', 'cover_image': 'images/leaf.png'},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return GestureDetector(
          onTap: () {
            if (isSelectionMode && onAlbumSelected != null) {
              onAlbumSelected!(album['title']!);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AlbumPhotosPage(albumTitle: album['title']!),
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
                      image: AssetImage(album['cover_image']!),
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
                      album['title']!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      album['location']!,
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