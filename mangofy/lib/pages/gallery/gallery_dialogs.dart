import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gallery_page.dart';

/// Type definition for the callback when a new album is created
typedef AlbumCreationCallback = void Function(
    String albumName, List<String> selectedImageIds);

/// Static class to manage all dialogs and navigation logic for album creation
class GalleryDialogs {
  /// Shows a dialog to create a new album
  static void showCreateAlbumDialog(
      BuildContext parentContext, AlbumCreationCallback onAlbumCreated) {
    String newAlbum = '';
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              16,
            ),
          ),
          title: Text(
            'Create New Album',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: TextField(
            onChanged: (value) => newAlbum = value,
            decoration: InputDecoration(
              hintText: 'Enter album name',
              hintStyle: GoogleFonts.inter(),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 8,
          ),
          actions: [
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
            const SizedBox(width: 2),
            TextButton(
              onPressed: () {
                if (newAlbum.trim().isEmpty) return;
                
                // Close the dialog using its local context.
                Navigator.pop(dialogContext); 
                
                // Navigate and show SnackBar using the persistent parentContext.
                _navigateToSelectionForAlbum(
                    parentContext, 
                    newAlbum.trim(), 
                    onAlbumCreated);
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