import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gallery_page.dart';

typedef AlbumCreationCallback = void Function(String albumName, List<String> selectedImageIds);
typedef AlbumUpdateCallback = void Function(String oldName, String newName);
typedef AlbumDeletionCallback = void Function(String albumName);
typedef PhotoRenameCallback = void Function(String oldId, String newName);

class GalleryDialogs {
  // --- CREATE NEW ALBUM DIALOG ---
  static void showCreateAlbumDialog(
    BuildContext parentContext,
    AlbumCreationCallback onAlbumCreated,
  ) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: null, 
          content: Container(
            width: MediaQuery.of(parentContext).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'Create New "My Tree"',
                  textAlign: TextAlign.left,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 2),
                // Subtitle
                Text(
                  'Set the name of your tree',
                  textAlign: TextAlign.left,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                // Styled TextField (Matching Rename UI)
                TextField(
                  controller: controller,
                  autofocus: true,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    hintText: 'e.g., My Mango Tree',
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Side-by-Side Expanded Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
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
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Next', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- EDIT ALBUM/TREE NAME DIALOG ---
  static void showEditAlbumNameDialog(
    BuildContext context,
    String currentName,
    AlbumUpdateCallback onNameUpdated,
  ) {
    final TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: null, 
          content: Container(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Rename Tree',
                  textAlign: TextAlign.left,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 2), 
                Text(
                  'Set the name of your tree',
                  textAlign: TextAlign.left,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    hintText: 'e.g., My Mango Tree',
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: const Color(0xFF4CAF50), width: 2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          final newName = controller.text.trim();
                          if (newName.isNotEmpty && newName != currentName) {
                            Navigator.pop(dialogContext);
                            onNameUpdated(currentName, newName);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Rename', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- RENAME PHOTO DIALOG ---
  static void showRenamePhotoDialog(
    BuildContext context,
    String currentName,
    PhotoRenameCallback onNameUpdated,
  ) {
    final TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: null, 
          content: Container(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Rename Photo',
                  textAlign: TextAlign.left,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 2), 
                Text(
                  'Set the name of your photo',
                  textAlign: TextAlign.left,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    hintText: 'e.g., Garden View',
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: const Color(0xFF4CAF50), width: 2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          final newName = controller.text.trim();
                          if (newName.isNotEmpty && newName != currentName) {
                            Navigator.pop(dialogContext);
                            onNameUpdated(currentName, newName);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Rename', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- DELETE CONFIRMATION DIALOG ---
  static void showDeleteConfirmationDialog(
    BuildContext context,
    String itemType,
    String itemName,
    VoidCallback onDeleteConfirmed,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          content: Container(
            width: MediaQuery.of(context).size.width, 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Text(
                  'Delete "$itemName"?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to \ndelete "$itemName"? \nThis action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Cancel', 
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          onDeleteConfirmed();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Delete', 
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HELPER FOR NAVIGATION ---
  static void _navigateToSelectionForAlbum(
    BuildContext activeContext,
    String albumName,
    AlbumCreationCallback onAlbumCreated,
  ) async {
    final selectedImageIds = await Navigator.push<List<String>>(
      activeContext,
      MaterialPageRoute(
        builder: (context) => const GalleryPage(isSelectionMode: true, initialMode: null),
      ),
    );

    if (selectedImageIds != null && selectedImageIds.isNotEmpty) {
      onAlbumCreated(albumName, selectedImageIds);

      // --- CUSTOM NOTIFICATION-STYLE SNACKBAR ---
      ScaffoldMessenger.of(activeContext).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Successfully created new tree!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFFFFFF),
          behavior: SnackBarBehavior.floating, // Lifts it off the bottom
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(activeContext).size.height - 200, // Pushes it to the top
            left: 20,
            right: 20,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}