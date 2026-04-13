import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'my_trees_page.dart';
import 'photos_view.dart';
import 'gallery_selection_widgets.dart';
import 'gallery_dialogs.dart';
import '../../services/sync_service.dart';
import '../../services/local_db.dart';
import '../../model/my_tree_model.dart';
import '../../model/photo.dart';

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
  List<MyTree> myTreesAlbums = [];
  List<PhotoMetadata> photos = [];
  int _activeLoadId = 0;
  bool _isLoadingData = false;
  bool _hasPendingReload = false;

  String _normalizeTimestamp(String raw, {String? fallbackRaw}) {
    final trimmed = raw.trim().isNotEmpty ? raw.trim() : (fallbackRaw ?? '').trim();
    if (trimmed.isEmpty) return trimmed;

    final normalized = trimmed.replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) return parsed.toIso8601String();

    // Tolerate timestamps with trailing Z/milliseconds in non-standard variants.
    final simplified = normalized.replaceAll('Z', '').split('.').first;
    final reparsed = DateTime.tryParse(simplified);
    if (reparsed != null) return reparsed.toIso8601String();

    final regexMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(trimmed);
    if (regexMatch != null) {
      return '${regexMatch.group(1)}-${regexMatch.group(2)}-${regexMatch.group(3)}T00:00:00.000';
    }

    return trimmed;
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
    _loadData();
    SyncService.instance.lastSyncNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    _activeLoadId++;
    SyncService.instance.lastSyncNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoadingData) {
      _hasPendingReload = true;
      return;
    }

    _isLoadingData = true;
    final loadId = ++_activeLoadId;

    try {
      final myTreesData = await LocalDb.instance.getAllMyTrees();
      final myTrees = myTreesData.map((map) => MyTree.fromMap(map)).toList();

      final scans = await LocalDb.instance.getAllScans();
      final List<PhotoMetadata> allPhotos = scans
          .where(
            (scan) =>
                scan.imagePath.trim().isNotEmpty ||
                scan.imageUrl.trim().isNotEmpty,
          )
          .map(
            (scan) => PhotoMetadata(
              id: scan.id,
              name: scan.diseaseName.isNotEmpty ? scan.diseaseName : scan.title,
              timestamp: _normalizeTimestamp(
                scan.timestamp,
                fallbackRaw: scan.updatedAt,
              ),
              path: scan.imagePath,
              imageUrl: scan.imageUrl,
              disease: scan.diseaseName.isNotEmpty ? scan.diseaseName : scan.disease,
              severityLabel: scan.severityLevelName.isNotEmpty
                  ? scan.severityLevelName
                  : null,
              confidence: scan.confidence,
              severityValue: scan.severityValue,
            ),
          )
          .toList();

      if (!mounted || loadId != _activeLoadId) return;

      setState(() {
        myTreesAlbums = myTrees;
        photos = allPhotos;
      });
    } catch (_) {
      if (!mounted || loadId != _activeLoadId) return;
      // If loading fails, show empty gallery instead of crashing
      setState(() {
        myTreesAlbums = [];
        photos = [];
      });
    } finally {
      _isLoadingData = false;
      if (_hasPendingReload && mounted) {
        _hasPendingReload = false;
        _loadData();
      }
    }
  }

  // --- CUSTOM MODAL NOTIFICATION HELPER ---
  void _showNotification(String message, {bool isDelete = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Clear existing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isDelete ? Icons.delete_outline : Icons.check_circle,
              color: isDelete ? Colors.red : const Color(0xFF4CAF50),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 200,
          left: 20,
          right: 20,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- HANDLERS ---

  void _handleAlbumCreation(
    String albumName,
    List<String> selectedImageIds,
  ) async {
    await LocalDb.instance.insertMyTree(
      title: albumName,
      location: 'New Album Location',
      images: selectedImageIds.join(','),
    );
    await _loadData();
    if (!mounted) return;
    _showNotification('Tree "$albumName" created successfully!');
  }

  void _handleAlbumNameUpdate(String oldName, String newName) async {
    await LocalDb.instance.updateMyTreeTitle(oldName, newName);
    await _loadData();
    if (!mounted) return;
    _showNotification('Tree renamed to "$newName"');
  }

  void _handleAlbumDeletion(String albumName) async {
    await LocalDb.instance.deleteMyTreeByTitle(albumName);
    await _loadData();
    if (!mounted) return;
    _showNotification('Tree "$albumName" deleted.', isDelete: true);
  }

  void _handlePhotoLongPress(String imageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 1,
                ),
                leading: const Icon(Icons.edit, color: Colors.black87),
                title: Text(
                  'Rename Photo',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  GalleryDialogs.showRenamePhotoDialog(context, imageId, (
                    oldId,
                    newName,
                  ) {
                    setState(() {
                      _showNotification('Photo renamed to "$newName"');
                    });
                  });
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  thickness: 1.2,
                  color: Color(0xFFE0E0E0),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 1,
                ),
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Photo',
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  GalleryDialogs.showDeleteConfirmationDialog(
                    context,
                    'Photo',
                    imageId,
                    () async {
                      await LocalDb.instance.deletePhoto(int.parse(imageId));
                      await _loadData();
                      _showNotification('Photo deleted!', isDelete: true);
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _handleAlbumLongPress(MyTree album) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 1,
                ),
                leading: const Icon(Icons.edit, color: Colors.black87),
                title: Text(
                  'Rename Tree',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  GalleryDialogs.showEditAlbumNameDialog(
                    context,
                    album.title,
                    _handleAlbumNameUpdate,
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  thickness: 1.2,
                  color: Color(0xFFE0E0E0),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 1,
                ),
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Tree',
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // --- UTILS ---

  List<String> _getCurrentImageIds() {
    if (isPhotosView) {
      return photos.map((photo) => photo.id.toString()).toList();
    } else {
      final title = selectedAlbumTitle;
      if (title == null) return <String>[];
      final album = myTreesAlbums.where((a) => a.title == title).toList();
      if (album.isEmpty) return <String>[];
      return album.first.images;
    }
  }

  String _getAppBarTitle() {
    if (!widget.isSelectionMode) return isPhotosView ? 'Gallery' : 'My Trees';
    return isPhotosView
        ? 'Select Images'
        : (selectedAlbumTitle ?? 'Select Album');
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
          if (!selectedImages.contains(id)) selectedImages.add(id);
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
      setState(() => selectedAlbumTitle = null);
    } else {
      Navigator.pop(context, <String>[]);
    }
  }

  // --- BUILD METHODS ---

  Widget _buildBodyContent() {
    final bool isPhotoSelectionScreen =
        widget.isSelectionMode && (isPhotosView || selectedAlbumTitle != null);
    final Map<int, PhotoMetadata> photosById = {
      for (final p in photos)
        if (p.id != null) p.id!: p,
    };
    if (!widget.isSelectionMode) {
      return isPhotosView
          ? PhotosView(onPhotoLongPress: _handlePhotoLongPress, photos: photos)
          : MyTreesPage(
              albums: myTreesAlbums,
              onAlbumLongPress: _handleAlbumLongPress,
              photosById: photosById,
            );
    }
    if (isPhotoSelectionScreen) {
      return PhotosSelectionGrid(
        contentKey: isPhotosView ? 'AllPhotos' : selectedAlbumTitle!,
        allImageIds: _getCurrentImageIds(),
        selectedImages: selectedImages,
        onToggleSelection: _toggleSelection,
      );
    } else {
      return MyTreesPage(
        albums: myTreesAlbums,
        isSelectionMode: true,
        onAlbumSelected: (title) => setState(() => selectedAlbumTitle = title),
        onAlbumLongPress: null,
        photosById: photosById,
      );
    }
  }

  Widget _buildSelectedCountChip() {
    if (!widget.isSelectionMode || selectedImages.isEmpty)
      return const SizedBox.shrink();
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
          '${selectedImages.length} selected',
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                onTap: () => setState(() => isPhotosView = !isPhotosView),
                child: Row(
                  children: [
                    if (!isPhotosView)
                      const Icon(Icons.chevron_left, color: Colors.green),
                    Text(
                      isPhotosView ? 'My Trees' : 'Photos',
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
        actions:
            widget.isSelectionMode &&
                (isPhotosView || selectedAlbumTitle != null)
            ? [
                TextButton(
                  onPressed: _toggleSelectAll,
                  child: Text(
                    _getCurrentImageIds().every(selectedImages.contains)
                        ? 'Deselect All'
                        : 'Select All',
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
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                    child: Row(
                      children: [
                        const Icon(Icons.chevron_left),
                        Text(
                          (!isPhotosView && selectedAlbumTitle != null)
                              ? 'Back to Albums'
                              : 'Back',
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: selectedImages.isEmpty
                        ? null
                        : () => Navigator.pop(context, selectedImages),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
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
              onPressed: () => GalleryDialogs.showCreateAlbumDialog(
                context,
                _handleAlbumCreation,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
