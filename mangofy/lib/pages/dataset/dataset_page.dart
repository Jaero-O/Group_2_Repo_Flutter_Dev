// dataset_page.dart
import 'package:flutter/material.dart';
import '../gallery/my_trees_page.dart';
//import '../gallery/photos_view.dart'; x

class DatasetPage extends StatefulWidget {
  const DatasetPage({super.key});

  @override
  State<DatasetPage> createState() => _DatasetPageState();
}

class _DatasetPageState extends State<DatasetPage> {
  final List<Map<String, dynamic>> folders = [];
  String? pendingFolderName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dataset',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      body: folders.isEmpty
          ? const Center(
              child: Text(
                'No folders yet.\nTap + to create one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green[100],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder, size: 48, color: Colors.green),
                      const SizedBox(height: 8),
                      Text(
                        folder['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${folder['images'].length} items',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                );
              },
            ),

      // Floating button to create new folder
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _showCreateFolderDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 🔹 Modal to create folder and select source
  void _showCreateFolderDialog(BuildContext parentContext) {
    String folderName = pendingFolderName ?? '';

    showDialog(
      context: parentContext,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Create New Folder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (val) {
                    folderName = val;
                    pendingFolderName = val;
                  },
                  controller: TextEditingController(text: folderName),
                  decoration: const InputDecoration(
                    labelText: 'Folder Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select images from:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFolderChoice(
                      icon: Icons.photo_library,
                      label: 'Photos View',
                      onTap: () => _navigateToSelection(
                        parentContext,
                        folderName,
                        false, // isMyTreesMode = false (use Photos View)
                      ),
                    ),
                    _buildFolderChoice(
                      icon: Icons.folder_copy,
                      label: 'My Trees',
                      onTap: () => _navigateToSelection(
                        parentContext,
                        folderName,
                        true, // isMyTreesMode = true (use My Trees Page)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // 🔹 Navigation to Selection Flow
  void _navigateToSelection(BuildContext parentContext, String folderName,
      bool isMyTreesMode) async {
    if (folderName.isEmpty) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
          content: Text('Please enter a folder name first'),
        ),
      );
      return;
    }

    Navigator.pop(parentContext); // Close the dialog

    // Navigate to the reusable selection flow
    final selected = await Navigator.push<List<String>>(
      parentContext,
      MaterialPageRoute(
        builder: (_) => PhotoSelectionView(
          isMyTreesMode: isMyTreesMode,
        ),
      ),
    );

    if (!mounted) return;
    if (selected != null) {
      setState(() {
        folders.add({
          'name': folderName,
          'images': selected,
        });
        pendingFolderName = null;
      });
    } else {
      // Re-open the dialog if the user backed out without saving
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreateFolderDialog(parentContext);
      });
    }
  }

  Widget _buildFolderChoice({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 50, color: Colors.green),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ----------------------
// ✅ PhotoSelectionView - Orchestrates reuse of MyTreesPage and Photo Grid
// ----------------------

class PhotoSelectionView extends StatefulWidget {
  final bool isMyTreesMode;

  const PhotoSelectionView({
    super.key,
    required this.isMyTreesMode,
  });

  @override
  State<PhotoSelectionView> createState() => _PhotoSelectionViewState();
}

class _PhotoSelectionViewState extends State<PhotoSelectionView> {
  final List<String> selectedImages = [];
  String? selectedAlbumTitle; // State for My Trees album selection

  @override
  Widget build(BuildContext context) {
    // Dynamic title logic
    String displayTitle;
    if (widget.isMyTreesMode && selectedAlbumTitle == null) {
      displayTitle = 'Select Album';
    } else if (widget.isMyTreesMode && selectedAlbumTitle != null) {
      displayTitle = 'Select from ${selectedAlbumTitle!}';
    } else {
      displayTitle = 'Select from Photos View';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          displayTitle,
          style: const TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        // Allow automatic leading button only when going back from album photo grid
        automaticallyImplyLeading: selectedAlbumTitle != null, 
        leading: selectedAlbumTitle != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.green),
                onPressed: () {
                  setState(() {
                    selectedAlbumTitle = null; // Go back to album list
                  });
                },
              )
            : null,
      ),
      body: _buildBody(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ✅ Back/Cancel button
            OutlinedButton(
              onPressed: () {
                if (widget.isMyTreesMode && selectedAlbumTitle != null) {
                  // Go back from photo grid to album list
                  setState(() {
                    selectedAlbumTitle = null;
                  });
                } else {
                  // Go back to folder creation dialog (returns null)
                  Navigator.pop(context, null); 
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
              child: Text(
                widget.isMyTreesMode && selectedAlbumTitle != null
                    ? 'Back to Albums'
                    : 'Cancel',
              ),
            ),
            // ✅ Save button
            ElevatedButton(
              onPressed: selectedImages.isEmpty
                  ? null // Disable if no images are selected
                  : () {
                      Navigator.pop(context, selectedImages);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('Save (${selectedImages.length})'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // 1. My Trees Mode: Show the album list, utilizing the MyTreesPage.
    if (widget.isMyTreesMode && selectedAlbumTitle == null) {
      return MyTreesPage(
        isSelectionMode: true,
        onAlbumSelected: (title) {
          setState(() {
            selectedAlbumTitle = title;
          });
        },
      );
    } 
    // 2. Photos View Mode OR My Trees Album Selected: Show the Photo Selection Grid.
    else {
      // The content key generates unique image IDs for selection
      final contentKey = selectedAlbumTitle ?? 'AllPhotos'; 
      return PhotosSelectionGrid(
        contentKey: contentKey, 
        selectedImages: selectedImages,
        onToggleSelection: (id) {
          setState(() {
            selectedImages.contains(id)
                ? selectedImages.remove(id)
                : selectedImages.add(id);
          });
        },
      );
    }
  }
}

// ----------------------
// ✅ PhotosSelectionGrid - A reusable selection component derived from the core of PhotosView
// ----------------------

class PhotosSelectionGrid extends StatelessWidget {
  final String contentKey;
  final List<String> selectedImages;
  final ValueChanged<String> onToggleSelection;

  const PhotosSelectionGrid({
    super.key,
    required this.contentKey,
    required this.selectedImages,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder logic: 16 photos for "Photos View" (AllPhotos), 8 for a specific album
    final itemCount = contentKey == 'AllPhotos' ? 16 : 8;
    
    // This grid component reuses the photo-grid structure common to PhotosView and AlbumPhotosPage
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Ensure imageId is unique for selection across different content sources
        final imageId = '${contentKey}_photo_$index'; 
        final selected = selectedImages.contains(imageId);
        return GestureDetector(
          onTap: () => onToggleSelection(imageId),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? Colors.green[200] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: selected
                ? const Icon(Icons.check_circle, size: 30, color: Colors.green)
                : const Icon(Icons.photo, size: 40, color: Colors.grey),
          ),
        );
      },
    );
  }
}