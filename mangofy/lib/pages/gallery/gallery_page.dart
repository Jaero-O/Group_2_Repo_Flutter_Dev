import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final List<String> selectedImages = [];
  String? selectedAlbumTitle;

  List<Map<String, dynamic>> myTreesAlbums = [];

  List<String> _getCurrentImageIds() {
    final String contentKey = isPhotosView ? 'AllPhotos' : selectedAlbumTitle!;
    final int itemCount = contentKey == 'AllPhotos' ? 40 : 15;
    return List<String>.generate(
      itemCount,
      (index) => '${contentKey}_photo_$index',
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialMode == 'My Trees') {
      isPhotosView = false;
    }
    if (widget.isSelectionMode && widget.initialMode == null) {
      isPhotosView = true;
    }
  }

  String _getAppBarTitle() {
    if (!widget.isSelectionMode) {
      return isPhotosView ? 'Gallery' : 'My Trees';
    }
    if (isPhotosView) {
      return 'Select Images';
    } else {
      if (selectedAlbumTitle == null) {
        return 'Select Album';
      } else {
        return 'Select from ${selectedAlbumTitle!}';
      }
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      selectedImages.contains(id)
          ? selectedImages.remove(id)
          : selectedImages.add(id);
    });
  }

  void _toggleSelectAll() {
    setState(() {
      final currentImageIds = _getCurrentImageIds();

      final allSelected = currentImageIds.every(selectedImages.contains);

      if (allSelected) {
        selectedImages.removeWhere(currentImageIds.contains);
      } else {
        for (var id in currentImageIds) {
          if (!selectedImages.contains(id)) {
            selectedImages.add(id);
          }
        }
      }
    });
  }

  void _handleBackButton() {
    if (!widget.isSelectionMode) {
      Navigator.pop(context);
      return;
    }
    if (!isPhotosView && selectedAlbumTitle != null) {
      setState(() {
        selectedAlbumTitle = null;
      });
    } else {
      Navigator.pop(context, <String>[]);
    }
  }

  Widget _buildBodyContent() {
    final bool isPhotoSelectionScreen =
        widget.isSelectionMode && (isPhotosView || selectedAlbumTitle != null);

    if (!widget.isSelectionMode) {
      return isPhotosView
          ? const PhotosView()
          : MyTreesPage(albums: myTreesAlbums);
    }

    if (isPhotoSelectionScreen) {
      final contentKey = isPhotosView ? 'AllPhotos' : selectedAlbumTitle!;
      final allImageIds = _getCurrentImageIds();

      return PhotosSelectionGrid(
        contentKey: contentKey,
        allImageIds: allImageIds, 
        selectedImages: selectedImages,
        onToggleSelection: _toggleSelection,
      );
    } else {
      return MyTreesPage(
        albums: myTreesAlbums,
        isSelectionMode: true,
        onAlbumSelected: (title) {
          setState(() {
            selectedAlbumTitle = title;
          });
        },
      );
    }
  }

  void _showCreateAlbumDialog() {
    String newAlbum = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Album'),
          content: TextField(
            onChanged: (value) => newAlbum = value,
            decoration: const InputDecoration(hintText: 'Enter album name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newAlbum.trim().isEmpty) return;
                Navigator.pop(context);
                _navigateToSelectionForAlbum(newAlbum.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Next'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSelectionForAlbum(String albumName) async {
    final selectedImageIds = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GalleryPage(isSelectionMode: true, initialMode: null),
      ),
    );

    if (selectedImageIds != null && selectedImageIds.isNotEmpty) {
      setState(() {
        myTreesAlbums.add({
          'title': albumName,
          'images': selectedImageIds,
          'location': 'New Album Location',
          'cover_image': 'images/leaf.png',
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Album "$albumName" created with ${selectedImageIds.length} photos!',
          ),
        ),
      );
    }
  }

  Widget _buildSelectedCountChip() {
    if (!widget.isSelectionMode || selectedImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 30,
      right: 25,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${selectedImages.length} image${selectedImages.length == 1 ? '' : 's'} selected',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String toggleText = isPhotosView ? 'My Trees' : 'Photos';

    final bool isPhotoSelectionScreen =
        widget.isSelectionMode && (isPhotosView || selectedAlbumTitle != null);

    final int totalImagesInView = isPhotoSelectionScreen
        ? _getCurrentImageIds().length
        : 0;

    final bool allImagesSelected =
        totalImagesInView > 0 &&
        _getCurrentImageIds().every(selectedImages.contains);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: null,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _getAppBarTitle(),
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            if (!widget.isSelectionMode)
              GestureDetector(
                onTap: () {
                  setState(() {
                    isPhotosView = !isPhotosView;
                  });
                },
                child: Row(
                  children: [
                    if (!isPhotosView)
                      const Icon(Icons.chevron_left, color: Colors.green),
                    Text(
                      toggleText,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (isPhotosView)
                      const Icon(Icons.chevron_right, color: Colors.green),
                  ],
                ),
              ),
          ],
        ),
        actions: isPhotoSelectionScreen
            ? [
                TextButton(
                  onPressed: _toggleSelectAll,
                  child: Text(
                    allImagesSelected ? 'Deselect All' : 'Select All',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: Stack(children: [_buildBodyContent(), _buildSelectedCountChip()]),
      bottomNavigationBar: widget.isSelectionMode
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _handleBackButton,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                    child: Text(
                      (!isPhotosView && selectedAlbumTitle != null)
                          ? 'Back to Albums'
                          : 'Cancel',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: selectedImages.isEmpty
                        ? null
                        : () => widget.onSelectionDone != null
                              ? widget.onSelectionDone!(
                                  selectedImages,
                                ) 
                              : Navigator.pop(context, selectedImages),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text('Save (${selectedImages.length})'),
                  ),
                ],
              ),
            )
          : null,
      floatingActionButton: !widget.isSelectionMode && !isPhotosView
          ? FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: _showCreateAlbumDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class PhotosSelectionGrid extends StatelessWidget {
  final String contentKey;
  final List<String>
  allImageIds; 
  final List<String> selectedImages;
  final ValueChanged<String> onToggleSelection;

  const PhotosSelectionGrid({
    super.key,
    required this.contentKey,
    required this.allImageIds, 
    required this.selectedImages,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = allImageIds.length;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final imageId = allImageIds[index];
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Icon(Icons.photo, size: 40, color: Colors.grey),
                if (selected)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(127),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
