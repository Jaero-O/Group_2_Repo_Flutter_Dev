import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dataset_widgets.dart';
import '../gallery/gallery_page.dart';

typedef FolderCreationCallback =
    void Function(String finalFolderName, String location, List<String> selectedImages);
enum FolderAction { rename, delete }

class _DatasetFolderInputResult {
  final String name;
  final String location;

  const _DatasetFolderInputResult({required this.name, this.location = ''});
}

class DatasetDialogs {
  // --- CREATE NEW DATASET DIALOG (SOURCE SELECTION) ---
  static void showCreateFolderDialog(
    BuildContext parentContext,
    FolderCreationCallback onFolderCreated,
  ) {
    showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SizedBox(
            width: MediaQuery.of(parentContext).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create New Dataset',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  'Select images from',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildFolderChoice(
                        svgIcon: const SvgFolderIcon(size: 80),
                        label: 'Gallery',
                        onTap: () => _navigateToSelection(parentContext, null, onFolderCreated),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFolderChoice(
                        svgIcon: const SvgFolderIcon(size: 80),
                        label: 'My Trees',
                        onTap: () => _navigateToSelection(parentContext, 'My Trees', onFolderCreated),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- NAME INPUT DIALOG ---
  static Future<_DatasetFolderInputResult?> _showNameInputDialog(
    BuildContext context, {
    required String title,
    required String actionButtonText,
    String initialName = '',
    String initialLocation = '',
    bool includeLocation = false,
    String hintText = 'e.g., My Mango Farm',
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initialName,
    );
    final TextEditingController locationController = TextEditingController(
      text: initialLocation,
    );

    return showDialog<_DatasetFolderInputResult>(
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
                  title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  'Set the name of your dataset',
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
                  decoration: InputDecoration(
                    hintText: hintText,
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
                if (includeLocation) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      hintText: 'Location (optional)',
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF4CAF50),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext, null),
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
                          final name = controller.text.trim();
                          final location = locationController.text.trim();
                          if (name.isNotEmpty) {
                            Navigator.pop(
                              dialogContext,
                              _DatasetFolderInputResult(
                                name: name,
                                location: includeLocation ? location : '',
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(actionButtonText, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
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

  static Future<String?> showRenameFolderDialog(BuildContext context, String currentName) async {
    final result = await _showNameInputDialog(
      context,
      title: 'Rename Dataset',
      actionButtonText: 'Rename',
      initialName: currentName,
    );
    return result?.name;
  }

  // --- DELETE CONFIRMATION DIALOG (COPIED DESIGN) ---
  // --- DELETE CONFIRMATION DIALOG (MATCHING GALLERY STYLE) ---
  static Future<bool> showDeleteConfirmationDialog(BuildContext context, String folderName) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Text(
                  'Delete "$folderName"?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to \ndelete "$folderName"? \nThis action cannot be undone.',
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
                        onPressed: () => Navigator.pop(dialogContext, false),
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
                        onPressed: () => Navigator.pop(dialogContext, true),
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
    ) ?? false;
  }

  // --- ACTION SHEET ---
  // --- BOTTOM ACTION SHEET (MATCHING GALLERY STYLE) ---
  static Future<FolderAction?> showFolderActionDialog(
    BuildContext context,
    String folderName,
  ) async {
    return await showModalBottomSheet<FolderAction>(
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
              
              // --- RENAME OPTION ---
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                leading: const Icon(Icons.edit, color: Colors.black87),
                title: Text(
                  'Rename',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                splashColor: Colors.green.withOpacity(0.1),
                onTap: () => Navigator.pop(sheetContext, FolderAction.rename),
              ),

              // --- DIVIDER LINE ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                child: Divider(
                  height: 1,
                  thickness: 1.2,
                  color: Color(0xFFE0E0E0),
                ),
              ),

              // --- DELETE OPTION ---
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Dataset',
                  style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w500),
                ),
                splashColor: Colors.red.withOpacity(0.1),
                onTap: () => Navigator.pop(sheetContext, FolderAction.delete),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // --- NAVIGATION LOGIC ---
  static void _navigateToSelection(
    BuildContext parentContext,
    String? initialMode,
    FolderCreationCallback onFolderCreated,
  ) async {
    Navigator.pop(parentContext); 

    final selected = await Navigator.push<List<String>>(
      parentContext,
      MaterialPageRoute(
        builder: (_) => GalleryPage(isSelectionMode: true, initialMode: initialMode),
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      final folderInput = await _showNameInputDialog(
        parentContext, 
        title: 'Create Dataset', 
        actionButtonText: 'Save',
        includeLocation: true,
      );

      if (folderInput != null && folderInput.name.isNotEmpty) {
        onFolderCreated(folderInput.name, folderInput.location, selected);
      }
    }
  }

  static Widget _buildFolderChoice({
    required SvgFolderIcon svgIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          children: [
            svgIcon,
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}