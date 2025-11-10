import 'package:flutter/material.dart';
import 'my_trees_page.dart';
import 'photos_view.dart'; // ✅ New Photos View

class GalleryPage extends StatefulWidget {
  final bool isSelectionMode; // 🔹 whether we are selecting photos for Dataset
  final String? initialMode; // 🔹 start either in "Photos" or "My Trees"
  final Function(List<String>)? onSelectionDone; // 🔹 callback for selected items

  const GalleryPage({
    super.key,
    this.isSelectionMode = false,
    this.initialMode,
    this.onSelectionDone,
  });

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}


class _GalleryPageState extends State<GalleryPage> {
  // Now only manages the high-level view state
  bool isPhotosView = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialMode == 'My Trees') {
      isPhotosView = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ TOP BAR (Switching logic remains here)
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title text (Photos or My Trees)
            Text(
              isPhotosView ? 'Photos' : 'My Trees',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            
            // Toggle button
            GestureDetector(
              onTap: () {
                setState(() {
                  isPhotosView = !isPhotosView;
                });
              },
              child: Row(
                children: [
                  Text(
                    isPhotosView ? 'My Trees' : 'Photos',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Icon(
                    isPhotosView ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ✅ BODY (Now uses the dedicated child widgets)
      body: isPhotosView ? const PhotosView() : const MyTreesPage(),

      // ✅ FLOATING BUTTON (Only visible in My Trees view)
      floatingActionButton: !isPhotosView
          ? FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () {
                // ... (Album creation logic remains here)
                showDialog(
                  context: context,
                  builder: (context) {
                    String newAlbum = '';
                    return AlertDialog(
                      title: const Text('Create New Album'),
                      content: TextField(
                        onChanged: (value) => newAlbum = value,
                        decoration: const InputDecoration(
                          hintText: 'Enter album name',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Add album logic here
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Album "$newAlbum" created!'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Create'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      
      // Removed bottomNavigationBar property as it is now inside PhotosView
    );
  }
}