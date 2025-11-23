import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dataset_constants.dart';
import 'dataset_dialogs.dart';
import 'dataset_widgets.dart'; 
import '../../services/database_service.dart'; 
import '../../model/dataset_folder_model.dart'; 

// The DatasetPage widget displays a list of dataset folders
// and allows users to create new datasets by selecting images.
class DatasetPage extends StatefulWidget {
  const DatasetPage({super.key});

  @override
  State<DatasetPage> createState() => _DatasetPageState();
}

class _DatasetPageState extends State<DatasetPage> {
  // List of folders now uses the DatasetFolder model and is initially empty
  List<DatasetFolder> folders = [];
  bool isLoading = true; // Added loading state

  // Stores a temporary folder name during creation - kept for state management
  String? pendingFolderName;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  // Method to fetch dataset folders from the database
  Future<void> _loadFolders() async {
    if (!mounted) return;

    final loadedFolders = await DatabaseService.instance.getAllDatasetFolders();

    setState(() {
      folders = loadedFolders;
      isLoading = false;
    });
  }

  // Handler for folder rename or delete actions
  void _handleFolderAction(String folderName) async {
    final action = await DatasetDialogs.showFolderActionDialog(
      context,
      folderName,
    );

    if (action == FolderAction.rename) {
      final newName = await DatasetDialogs.showRenameFolderDialog(
        context,
        folderName,
      );

      if (newName != null && newName.isNotEmpty && newName != folderName) {
        await DatabaseService.instance.updateDatasetFolderName(
          folderName,
          newName,
        );
        _loadFolders(); // Reload to update UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder renamed to $newName')),
        );
      }
    } else if (action == FolderAction.delete) {
      // Show confirmation dialog before deleting
      final bool confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the dataset "$folderName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;

      if (confirmDelete) {
        await DatabaseService.instance.deleteDatasetFolder(folderName);
        _loadFolders(); // Reload to update UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder "$folderName" deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: DatasetConstants.kTopHeaderHeight,
            child: Container(
              decoration: const BoxDecoration(
                  gradient: DatasetConstants.kGreenGradient),
            ),
          ),

          Positioned(
            top: DatasetConstants.kTitleTopPadding,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Dataset',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main container displaying folders
          Positioned.fill(
            top: DatasetConstants.kTopHeaderHeight -
                DatasetConstants.kContainerOverlap,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(DatasetConstants.kTopRadius),
                  bottom: Radius.circular(DatasetConstants.kBottomRadius),
                ),
              ),
              // Display loading indicator, empty message, or grid of folders
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : folders.isEmpty
                      ? Center(
                          child: Text(
                            'No folders yet.\nTap + to create one.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(30, 70, 16, 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            return GestureDetector(
                              // Normal tap to view folder content
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FolderViewPage(
                                      // Access properties from the DatasetFolder model
                                      folderName: folder.name,
                                      images: folder.images,
                                      // Pass _loadFolders to ensure the count updates if an image is removed
                                      onImageRemoved: _loadFolders, 
                                    ),
                                  ),
                                );
                              },
                              // Long press to trigger action dialog
                              onLongPress: () => _handleFolderAction(folder.name),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Center(child: SvgFolderIcon(size: 120)),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 30),
                                    child: Text(
                                      folder.name, // Use folder.name
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 30),
                                    child: Text(
                                      '${folder.images.length} items', // Use folder.images.length
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      // Floating action button to create a new dataset
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => DatasetDialogs.showCreateFolderDialog(
          context,
          (String finalFolderName, List<String> selectedImages) async {
            if (!mounted) return;

            // Save the new folder to the database
            await DatabaseService.instance.insertDatasetFolder(
              name: finalFolderName,
              imageIds: selectedImages,
              dateCreated: DateTime.now().toIso8601String(), // Store creation date
            );

            // Reload the list from the database to update the UI
            _loadFolders();
          },
        ),
        child: const Icon(Icons.create_new_folder, color: Colors.white),
      ),
    );
  }
}