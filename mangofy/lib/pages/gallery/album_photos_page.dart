import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'photo_widgets.dart'; 
import 'gallery_dialogs.dart'; 
import '../../model/photo.dart';
import '../../services/local_db.dart';

class AlbumPhotosPage extends StatefulWidget {
  final String albumTitle;
  final List<String> images; 

  const AlbumPhotosPage({
    super.key,
    required this.albumTitle,
    this.images = const [], 
  });

  @override
  State<AlbumPhotosPage> createState() => _AlbumPhotosPageState();
}

class _AlbumPhotosPageState extends State<AlbumPhotosPage> {
  late Future<List<Photo>> _albumPhotosFuture;

  @override
  void initState() {
    super.initState();
    _albumPhotosFuture = _loadAlbumPhotos();
  }

  Future<List<Photo>> _loadAlbumPhotos() async {
    final ids = widget.images.map(int.tryParse).whereType<int>().toList();
    if (ids.isEmpty) return <Photo>[];
    final maps = await LocalDb.instance.getPhotosByIds(ids);
    final photos = maps.map((m) => Photo.fromMap(m)).where((p) => p.id != null).toList();
    final byId = {for (final p in photos) p.id!: p};
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  // --- HELPER TO SHOW CENTERED SUCCESS ANIMATION ---
  void _showSuccessAnimation(BuildContext context, String message) {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedSuccessOverlay(
        message: message,
        onFinished: () {
          // This logic is handled inside the widget's state
        },
      ),
    );

    overlayState.insert(overlayEntry);
    
    // Remove the overlay after the animation duration
    Future.delayed(const Duration(milliseconds: 2000), () {
      overlayEntry.remove();
    });
  }

  void _showPhotoOptions(BuildContext context, String imageId) {
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                leading: const Icon(Icons.edit, color: Colors.black87),
                title: Text('Rename', 
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  GalleryDialogs.showRenamePhotoDialog(
                    context,
                    imageId,
                    (oldName, newName) {
                      _showSuccessAnimation(context, 'Renamed to $newName');
                    },
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                child: Divider(height: 1, thickness: 1.2, color: Color(0xFFE0E0E0)),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Remove from Album',
                  style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  GalleryDialogs.showDeleteConfirmationDialog(
                    context,
                    'Photo',
                    imageId,
                    () {
                      _showSuccessAnimation(context, 'Removed');
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final placeholderIds = widget.images.isEmpty ? List.generate(15, (i) => 'album_photo_$i') : widget.images;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.albumTitle,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        backgroundColor: Colors.white, 
        iconTheme: const IconThemeData(color: Colors.green), 
        elevation: 0, 
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: FutureBuilder<List<Photo>>(
          future: _albumPhotosFuture,
          builder: (context, snapshot) {
            final photos = snapshot.data ?? const <Photo>[];
            if (snapshot.connectionState == ConnectionState.waiting && photos.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (photos.isNotEmpty) {
              return PhotoGrid(
                photos: photos,
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                padding: const EdgeInsets.all(4),
                borderRadius: 8,
                onItemTap: (index) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenPhotoView(photo: photos[index]),
                    ),
                  );
                },
                onItemLongPress: (index) {
                  final id = photos[index].id;
                  if (id != null) _showPhotoOptions(context, id.toString());
                },
              );
            }

            // Fallback: placeholder grid for non-ID album entries.
            return PhotoGridPlaceholder(
              itemCount: placeholderIds.length,
              imageIds: placeholderIds,
              crossAxisCount: 3,
              onItemTap: (index) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenPhotoView(imagePath: placeholderIds[index]),
                  ),
                );
              },
              onItemLongPress: (index) {
                _showPhotoOptions(context, placeholderIds[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

// --- CUSTOM ANIMATED OVERLAY WIDGET ---
class _AnimatedSuccessOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onFinished;

  const _AnimatedSuccessOverlay({required this.message, required this.onFinished});

  @override
  State<_AnimatedSuccessOverlay> createState() => _AnimatedSuccessOverlayState();
}

class _AnimatedSuccessOverlayState extends State<_AnimatedSuccessOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Start exit animation after delay
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.1), // Dim background slightly
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    widget.message,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}