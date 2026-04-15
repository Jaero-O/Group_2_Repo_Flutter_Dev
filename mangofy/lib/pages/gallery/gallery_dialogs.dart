import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gallery_page.dart';
import '../../model/my_tree_model.dart';

typedef AlbumCreationCallback = void Function(String albumName, String location, List<String> selectedImageIds);
typedef AlbumUpdateCallback = void Function(String oldName, String newName);
typedef AlbumDeletionCallback = void Function(String albumName);
typedef PhotoRenameCallback = void Function(String oldId, String newName);

class GalleryDialogs {
  // --- CREATE NEW ALBUM DIALOG ---
  static void showCreateAlbumDialog(
    BuildContext parentContext,
    AlbumCreationCallback onAlbumCreated,
  ) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    
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
                  controller: nameController,
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
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    hintText: 'e.g., Brgy. San Isidro',
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
                          final albumName = nameController.text.trim();
                          if (albumName.isEmpty) return;
                          final location = locationController.text.trim();
                          Navigator.pop(dialogContext);
                          _navigateToSelectionForAlbum(
                            parentContext,
                            albumName,
                            location,
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
    String location,
    AlbumCreationCallback onAlbumCreated,
  ) async {
    final selectedImageIds = await Navigator.push<List<String>>(
      activeContext,
      MaterialPageRoute(
        builder: (context) => const GalleryPage(isSelectionMode: true, initialMode: null),
      ),
    );

    if (selectedImageIds != null && selectedImageIds.isNotEmpty) {
      onAlbumCreated(albumName, location, selectedImageIds);

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

  static Future<MyTree?> showAddToAlbumDialog(
    BuildContext context,
    List<MyTree> albums,
  ) async {
    return showModalBottomSheet<MyTree>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                'Add To My Tree',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              if (albums.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No trees yet. Create one first.',
                    style: GoogleFonts.inter(color: Colors.black54),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: albums.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return ListTile(
                        leading: const Icon(Icons.park_outlined, color: Colors.green),
                        title: Text(album.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: album.location.isEmpty ? null : Text(album.location),
                        onTap: () => Navigator.pop(sheetContext, album),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static Future<String?> showCreateAlbumBasicDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create New Tree',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tree name',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    hintText: 'Location (optional)',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;
                          final location = locationController.text.trim();
                          Navigator.pop(dialogContext, '$name|$location');
                        },
                        child: const Text('Create'),
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

  static Future<String?> showAddToDatasetDialog(
    BuildContext context,
    List<String> folderNames,
  ) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                'Add To Dataset',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined, color: Colors.green),
                title: Text('Create New Dataset Folder', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(sheetContext, '__CREATE_NEW__'),
              ),
              const Divider(height: 1),
              if (folderNames.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No existing dataset folders.', style: GoogleFonts.inter(color: Colors.black54)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: folderNames.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final folder = folderNames[index];
                      return ListTile(
                        leading: const Icon(Icons.folder_open, color: Colors.orange),
                        title: Text(folder, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        onTap: () => Navigator.pop(sheetContext, folder),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static Future<String?> showCreateDatasetFolderNameDialog(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Dataset Folder',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Folder name',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = controller.text.trim();
                          if (name.isEmpty) return;
                          Navigator.pop(dialogContext, name);
                        },
                        child: const Text('Create'),
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
}