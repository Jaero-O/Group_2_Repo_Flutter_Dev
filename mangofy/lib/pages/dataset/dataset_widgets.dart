// dataset_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// SVG folder icon.
class SvgFolderIcon extends StatelessWidget {
  final double size;
  final String assetPath;

  const SvgFolderIcon({
    super.key,
    this.assetPath = 'images/folder.svg',
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(assetPath, width: size, height: size);
  }
}

/// Displays a single image (or image ID placeholder) in a full-screen view.
class FullScreenPhotoPage extends StatelessWidget {
  final String imageId;

  const FullScreenPhotoPage({super.key, required this.imageId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set background to black for a typical photo viewer experience
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          // Center the photo content (currently the ID placeholder)
          Center(
            child: Text(
              imageId,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white, // White text on black background
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Close Button (Top Left)
          Positioned(
            top: 40, // Space from the top safe area
            right: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(), // Close the page
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Shows images inside the selected folder
class FolderViewPage extends StatelessWidget {
  final String folderName;
  final List<dynamic> images;

  const FolderViewPage({
    super.key,
    required this.folderName,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Text(
          folderName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        backgroundColor: Colors.white, 
        iconTheme: const IconThemeData(color: Colors.green), 
        elevation: 0, 
      ),
      
      // Grid displaying folder photos 
      body: GridView.builder(
        padding: const EdgeInsets.all(16), 

        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 columns
          crossAxisSpacing: 6, // Horizontal spacing 
          mainAxisSpacing: 6, // Vertical spacing 
        ),
        
        itemCount: images.length,
        itemBuilder: (context, index) {
          final img = images[index].toString();

          return GestureDetector( // <--- Added GestureDetector to enable tapping
            onTap: () {
              // Navigate to the full screen photo view on tap
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenPhotoPage(imageId: img),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8), 
              ),
              child: Center(
                child: Text(
                  img,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}