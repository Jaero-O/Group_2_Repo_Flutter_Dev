import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dataset_widgets.dart';
import '../gallery/gallery_page.dart';

/// Type definition for the callback when a folder is created.
typedef FolderCreationCallback =
    void Function(String finalFolderName, List<String> selectedImages);

// Type definition for actions on an existing folder
enum FolderAction { rename, delete }

// A set of static methods to manage all dialogs and navigation logic
// for creating a new dataset folder.
class DatasetDialogs {
  // Shows a dialog to select source images when creating a new dataset
  static void showCreateFolderDialog(
    BuildContext parentContext,
    FolderCreationCallback onFolderCreated,
  ) {
    showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          title: Text(
            'Create new dataset',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Select images from',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Option to select images from Gallery
                  _buildFolderChoice(
                    svgIcon: const SvgFolderIcon(size: 90),
                    label: 'Gallery',
                    onTap: () => _navigateToSelection(
                      parentContext,
                      null,
                      onFolderCreated,
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Option to select images from My Trees
                  _buildFolderChoice(
                    svgIcon: const SvgFolderIcon(size: 90),
                    label: 'My Trees',
                    onTap: () => _navigateToSelection(
                      parentContext,
                      'My Trees',
                      onFolderCreated,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF393939),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 5), 
              ],
            ),
          ],
        );
      },
    );
  }

  // Shows a dialog for entering/editing a folder name
  static Future<String?> _showNameInputDialog(
    BuildContext context, {
    required String title,
    required String actionButtonText,
    String initialName = '',
    String hintText = 'e.g., My Mango Farm',
  }) async {
    String folderName = initialName;
    // Controller to manage the TextField content
    final TextEditingController controller = TextEditingController(text: initialName);

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          // Set contentPadding to ensure minimal bottom space after the content items.
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            8,
          ),
          actionsPadding: EdgeInsets.zero, 
          actions: [], 
          title: Text(
            title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set name of the dataset',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),

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
                  child: const SvgFolderIcon(size: 90),
                ),
              ),
              const SizedBox(height: 6),

              TextField(
                controller: controller,
                autofocus: true,
                onChanged: (val) => folderName = val,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, null),
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
                      if (folderName.trim().isNotEmpty) {
                        Navigator.pop(dialogContext, folderName.trim());
                      } else {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Folder name cannot be empty'),
                          ),
                        );
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.black54),
                    child: Text(
                      actionButtonText,
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

  // Shows a dialog for entering the new folder name
  static Future<String?> _showFolderNameDialog(BuildContext context) async {
    return _showNameInputDialog(
      context,
      title: 'Create new dataset',
      actionButtonText: 'Save',
    );
  }

  // Shows a dialog for renaming an existing folder
  static Future<String?> showRenameFolderDialog(
    BuildContext context,
    String currentName,
  ) async {
    return _showNameInputDialog(
      context,
      title: 'Rename dataset',
      actionButtonText: 'Rename',
      initialName: currentName,
      hintText: currentName,
    );
  }


  // Shows a dialog to choose between renaming or deleting a dataset folder
  static Future<FolderAction?> showFolderActionDialog(
    BuildContext context,
    String folderName,
  ) async {
    return showModalBottomSheet<FolderAction?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          // Adjusted padding to match the image's minimal content spacing
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Removed folderName text and Divider to match the image
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 'Edit Name' option
              InkWell(
                onTap: () => Navigator.pop(context, FolderAction.rename),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0), // Padding to mimic ListTile
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.black87),
                      const SizedBox(width: 32),
                      Text(
                        'Rename', // Changed label
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 'Delete Tree' option
              InkWell(
                onTap: () => Navigator.pop(context, FolderAction.delete),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0), // Padding to mimic ListTile
                  child: Row(
                    children: [
                      const Icon(Icons.delete_forever, color: Colors.red),
                      const SizedBox(width: 32),
                      Text(
                        'Delete Dataset', // Changed label
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Navigates to the gallery selection page and handles folder creation
  static void _navigateToSelection(
    BuildContext parentContext,
    String? initialMode,
    FolderCreationCallback onFolderCreated,
  ) async {
    Navigator.pop(parentContext); 

    // GalleryPage accepts 'isSelectionMode: true' and 'initialMode'
    final selected = await Navigator.push<List<String>>(
      parentContext,
      MaterialPageRoute(
        builder: (_) =>
            GalleryPage(isSelectionMode: true, initialMode: initialMode),
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      final finalFolderName = await _showFolderNameDialog(parentContext);

      if (finalFolderName != null && finalFolderName.isNotEmpty) {
        // Use the callback to update the state of the DatasetPage
        onFolderCreated(finalFolderName, selected);
      } else {
        // If folder name not entered, reopen the creation dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCreateFolderDialog(parentContext, onFolderCreated);
        });
      }
    }
  }

  // Builds an individual folder choice card in the creation dialog
  static Widget _buildFolderChoice({
    required SvgFolderIcon svgIcon,
    required String label,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFFE4E4E4),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            svgIcon,
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}