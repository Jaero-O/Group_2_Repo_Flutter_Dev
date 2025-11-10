import 'package:flutter/material.dart';
import 'my_trees_page.dart';
import 'photos_view.dart'; 

class GalleryPage extends StatefulWidget {
  final bool isSelectionMode;
  final String? initialMode; 
  final Function(List<String>)? onSelectionDone; 

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

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isPhotosView ? 'Photos' : 'My Trees',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            
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

      body: isPhotosView 
          ? PhotosView(isSelectionMode: widget.isSelectionMode, onSelectionDone: widget.onSelectionDone,) 
          : MyTreesPage(isSelectionMode: widget.isSelectionMode), 

      floatingActionButton: !isPhotosView
          ? FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () {
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
    );
  }
}