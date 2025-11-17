import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'my_trees_page.dart';
import 'photos_view.dart';

/// Page for viewing photos, albums, and optionally selecting images.
/// Supports two modes:
/// - Normal browsing: viewing photos and albums
/// - Selection mode: selecting images for creating datasets or albums
class GalleryPage extends StatefulWidget {
  /// If true, page is in selection mode for picking images
  final bool isSelectionMode;

  /// Initial view mode: 'My Trees' or null
  final String? initialMode;

  /// Callback when selection is done (returns list of selected image IDs)
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
  /// True if displaying photos; false if displaying albums ('My Trees')
  bool isPhotosView = true;

  /// List of selected image IDs in selection mode
  final List<String> selectedImages = [];

  /// Album currently selected in selection mode
  String? selectedAlbumTitle;

  /// List of user's albums for 'My Trees'
  List<Map<String, dynamic>> myTreesAlbums = [];

  /// Generates a list of current image IDs based on view
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
    // Initialize view based on initial mode or selection mode
    if (widget.initialMode == 'My Trees') {
      isPhotosView = false;
    }
    if (widget.isSelectionMode && widget.initialMode == null) {
      isPhotosView = true;
    }
  }

  /// Returns the AppBar title based on current mode and selection
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

  /// Toggles selection state of a single image
  void _toggleSelection(String id) {
    setState(() {
      selectedImages.contains(id)
          ? selectedImages.remove(id)
          : selectedImages.add(id);
    });
  }

  /// Selects or deselects all images currently displayed
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

  /// Handles back button behavior based on mode
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

  /// Builds the main body content depending on mode
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

  /// Shows a dialog to create a new album

  void _showCreateAlbumDialog() {
    String newAlbum = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            10,
          ), // Example: Adjusted top/bottom padding
          // 2. SHAPE (Controls the roundness of the corners)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              16,
            ), // Increased roundness from default (usually 4.0)
          ),
          title: Text(
            'Create New Album',
            // Applying Inter font to the title
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: TextField(
            onChanged: (value) => newAlbum = value,
            decoration: InputDecoration(
              hintText: 'Enter album name',
              // Applying Inter font to the hint text
              hintStyle: GoogleFonts.inter(),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 8,
          ),
          actions: [
            // This TextButton is usually left-aligned within the actions group by default
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // ADD SPACE HERE
            const SizedBox(
              width: 2,
            ), // Adjust this value (e.g., 20) to change the gap

            TextButton(
              onPressed: () {
                if (newAlbum.trim().isEmpty) return;
                Navigator.pop(context);
                _navigateToSelectionForAlbum(newAlbum.trim());
              },
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: Text(
                'Next',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Opens selection page to add images to a new album
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

  /// Displays a small chip showing the count of selected images
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
                  TextButton(
                    onPressed: _handleBackButton,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chevron_left, size: 24),
                        Text(
                          (!isPhotosView && selectedAlbumTitle != null)
                              ? 'Back to Albums'
                              : 'Back',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: selectedImages.isEmpty
                        ? null
                        : () => widget.onSelectionDone != null
                              ? widget.onSelectionDone!(selectedImages)
                              : Navigator.pop(context, selectedImages),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    icon: const Icon(Icons.save),
                    label: Text('Save (${selectedImages.length})'),
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

/// Grid widget for selecting photos in selection mode
class PhotosSelectionGrid extends StatelessWidget {
  /// Key representing current content (AllPhotos or album name)
  final String contentKey;

  /// List of all image IDs in the current view
  final List<String> allImageIds;

  /// Currently selected images
  final List<String> selectedImages;

  /// Callback for toggling selection of an image
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
