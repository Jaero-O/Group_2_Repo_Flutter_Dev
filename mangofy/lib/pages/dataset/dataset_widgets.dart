import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/database_service.dart'; 

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

// Displays a single image in a full-screen view.
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
          // Center the photo content 
          Center(
            child: Text(
              imageId,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white, 
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Close Button 
          Positioned(
            top: 40, 
            right: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(), 
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Shows images inside the selected folder
class FolderViewPage extends StatefulWidget {
  final String folderName;
  final List<dynamic> images;
  // Callback when an image is removed
  final VoidCallback onImageRemoved; 

  const FolderViewPage({
    super.key,
    required this.folderName,
    required this.images,
    required this.onImageRemoved, 
  });

  @override
  State<FolderViewPage> createState() => _FolderViewPageState();
}

class _FolderViewPageState extends State<FolderViewPage> {
  // Use a local state for images so it can be updated after deletion
  late List<dynamic> _currentImages; 

  @override
  void initState() {
    super.initState();
    _currentImages = widget.images; 
  }

  // Helper to show the delete confirmation dialog for an image
  void _showDeleteImageDialog(BuildContext context, String imageId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Image'),
        content: Text('Are you sure you want to remove this image ($imageId) from the folder ${widget.folderName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); 

              // Call DB service to remove the image
              await DatabaseService.instance.removeImageFromDatasetFolder(
                widget.folderName,
                imageId,
              );

              // Update the local state
              setState(() {
                _currentImages.remove(imageId);
              });

              // Notify the parent (DatasetPage) that the folder content changed
              widget.onImageRemoved(); 

              // Optionally show a confirmation snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Image $imageId removed from ${widget.folderName}')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Text(
          widget.folderName,
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
      body: _currentImages.isEmpty
          ? const Center(child: Text("This folder is empty."))
          : GridView.builder(
              padding: const EdgeInsets.all(16), 

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 columns
                crossAxisSpacing: 6, // Horizontal spacing 
                mainAxisSpacing: 6, // Vertical spacing 
              ),
              
              itemCount: _currentImages.length,
              itemBuilder: (context, index) {
                final img = _currentImages[index].toString();

                return GestureDetector( 
                  // Tap to view full screen
                  onTap: () { 
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenPhotoPage(imageId: img),
                      ),
                    );
                  },
                  // Long Press to delete
                  onLongPress: () {
                    _showDeleteImageDialog(context, img);
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