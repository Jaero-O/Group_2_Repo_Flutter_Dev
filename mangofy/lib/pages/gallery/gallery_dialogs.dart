import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gallery_page.dart';

/// Type definition for the callback when a new album is created
typedef AlbumCreationCallback =
    void Function(String albumName, List<String> selectedImageIds);

/// Static class to manage all dialogs and navigation logic for album creation
class GalleryDialogs {
  /// Shows a dialog to create a new album
  static void showCreateAlbumDialog(
    BuildContext parentContext,
    AlbumCreationCallback onAlbumCreated,
  ) {
    
    // Controller to manage the TextField content
    final TextEditingController controller = TextEditingController(); 

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), 
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8), 
          actionsPadding: EdgeInsets.zero,
          actions: [], 
          
          title: Text(
            'Create New "My Tree"',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                'Set name of your tree',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),

              // Icon with Background/Shadow
              Align(
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ], 
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Icon(
                    Icons.eco,
                    size: 90, 
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              
              // Text Field 
              TextField(
                controller: controller, 
                autofocus: true,
                onChanged: (value) {}, 
                decoration: InputDecoration(
                  hintText: 'e.g., My Mango Tree',
                  hintStyle: GoogleFonts.inter(),
                  border: InputBorder.none, 
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                ),
              ),
              
              const SizedBox(height: 10),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final albumName = controller.text.trim(); 
                      if (albumName.isEmpty) return;

                      Navigator.pop(dialogContext);

                      _navigateToSelectionForAlbum(
                        parentContext,
                        albumName,
                        onAlbumCreated,
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.black54),
                    child: Text(
                      'Next',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens selection page to add images to a new album
  static void _navigateToSelectionForAlbum(
    BuildContext activeContext,
    String albumName,
    AlbumCreationCallback onAlbumCreated,
  ) async {
    final selectedImageIds = await Navigator.push<List<String>>(
      activeContext, // Use the active context for pushing the new page
      MaterialPageRoute(
        // Navigate to the GalleryPage in selection mode
        builder: (context) =>
            const GalleryPage(isSelectionMode: true, initialMode: null),
      ),
    );

    if (selectedImageIds != null && selectedImageIds.isNotEmpty) {
      // Use the callback to update the state in GalleryPage
      onAlbumCreated(albumName, selectedImageIds);

      // Use the activeContext for ScaffoldMessenger
      ScaffoldMessenger.of(activeContext).showSnackBar(
        SnackBar(
          content: Text(
            'Album "$albumName" created with ${selectedImageIds.length} photos!',
          ),
        ),
      );
    }
  }
}