// gallery_page.dart (Modified)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'my_trees_page.dart';
import 'photos_view.dart';
import 'gallery_selection_widgets.dart'; 
import 'gallery_dialogs.dart'; 
import '../../services/database_service.dart';
import '../../model/my_tree_model.dart'; 

// Page for viewing photos, albums, and optionally selecting images.
class GalleryPage extends StatefulWidget {
  // If true, page is in selection mode for picking images
  final bool isSelectionMode;

  // Initial view mode: 'My Trees' or null
  final String? initialMode;

  // Callback when selection is done (returns list of selected image IDs)
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
  // True if displaying photos; false if displaying albums ('My Trees')
  bool isPhotosView = true;

  // List of selected image IDs in selection mode
  final List<String> selectedImages = [];

  // Album currently selected in selection mode
  String? selectedAlbumTitle;

  /// List of user's albums for 'My Trees'
  List<MyTree> myTreesAlbums = [];

  // Method to load My Trees from the database
  Future<void> _loadMyTreesFromDb() async {
    final myTrees = await DatabaseService.instance.getAllMyTrees(); 
    setState(() {
      myTreesAlbums = myTrees;
    });
  }
  
  // Generates a list of current image IDs based on view
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

    _loadMyTreesFromDb();
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

  // Toggles selection state of a single image
  void _toggleSelection(String id) {
    setState(() {
      selectedImages.contains(id)
          ? selectedImages.remove(id)
          : selectedImages.add(id);
    });
  }

  // Selects or deselects all images currently displayed
  void _toggleSelectAll() {
    setState(() {
      final currentImageIds = _getCurrentImageIds();
      // Ensure we only check images in the current view
      final allSelected = currentImageIds.every(selectedImages.contains);

      if (allSelected) {
        // Only remove images that are currently in view
        selectedImages.removeWhere(currentImageIds.contains);
      } else {
        // Add all images currently in view
        for (var id in currentImageIds) {
          if (!selectedImages.contains(id)) {
            selectedImages.add(id);
          }
        }
      }
    });
  }

  // Handles back button behavior based on mode
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
      // In selection mode, if going back from main selection screen, pop with empty list
      Navigator.pop(context, <String>[]);
    }
  }

  /// Callback used by GalleryDialogs to update album list after creation
  void _handleAlbumCreation(String albumName, List<String> selectedImageIds) async {
    await DatabaseService.instance.insertMyTree( 
      title: albumName,
      location: 'New Album Location', 
      imageIds: selectedImageIds,
    );
    
    await _loadMyTreesFromDb();

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Album "$albumName" created!'),
        ),
      );
  }
  
  /// Handles photo long press for deletion (for simplicity, only shows dialog)
  void _handlePhotoLongPress(String imageId) {
    GalleryDialogs.showDeleteConfirmationDialog(
      context,
      'Photo',
      imageId,
      () {
        // In a real app, logic to delete the photo from DB/storage would go here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo "$imageId" deleted!'),
          ),
        );
        // Note: We don't call setState because we're using mock data and not deleting it
        // from the list generation logic, but in a real app, you would reload/update the list.
      },
    );
  }

  /// Handles album long press for edit/delete options
  void _handleAlbumLongPress(MyTree album) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  GalleryDialogs.showEditAlbumNameDialog(
                    context,
                    album.title,
                    _handleAlbumNameUpdate,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Tree', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  GalleryDialogs.showDeleteConfirmationDialog(
                    context,
                    'Tree',
                    album.title,
                    () => _handleAlbumDeletion(album.title),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Handles album name update
  void _handleAlbumNameUpdate(String oldName, String newName) async {
    await DatabaseService.instance.updateMyTreeTitle(oldName, newName);
    await _loadMyTreesFromDb();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tree "$oldName" renamed to "$newName".'),
      ),
    );
  }

  /// Handles album deletion
  void _handleAlbumDeletion(String albumName) async {
    await DatabaseService.instance.deleteMyTree(albumName);
    await _loadMyTreesFromDb();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tree "$albumName" deleted.'),
      ),
    );
  }


  // Builds the main body content depending on mode
  Widget _buildBodyContent() {
    final bool isPhotoSelectionScreen =
        widget.isSelectionMode && (isPhotosView || selectedAlbumTitle != null);

    if (!widget.isSelectionMode) {
      return isPhotosView
          ? PhotosView(onPhotoLongPress: _handlePhotoLongPress) // Pass handler
          : MyTreesPage(
              albums: myTreesAlbums,
              onAlbumLongPress: _handleAlbumLongPress, // Pass handler
            ); 
    }

    if (isPhotoSelectionScreen) {
      final contentKey = isPhotosView ? 'AllPhotos' : selectedAlbumTitle!;
      final allImageIds = _getCurrentImageIds();

      // In selection mode, long press is usually disabled or irrelevant
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
        // Long press for albums is not typically active in album selection mode
        onAlbumLongPress: null, 
      );
    }
  }

  // Displays a small chip showing the count of selected images
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
      body: Stack(children: [
        _buildBodyContent(),
        _buildSelectedCountChip()
      ]),
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
              // Call the extracted static dialog method
              onPressed: () => GalleryDialogs.showCreateAlbumDialog(
                  context, _handleAlbumCreation),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}