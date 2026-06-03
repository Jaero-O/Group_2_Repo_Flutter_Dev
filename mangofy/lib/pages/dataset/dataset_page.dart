import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dataset_constants.dart';
import 'dataset_dialogs.dart';
import 'dataset_widgets.dart';
import '../../services/local_db.dart';
import '../../services/sync_service.dart';
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
  bool _isLoadingFolders = false;
  bool _isFolderDeleteMode = false;
  final List<String> _selectedFoldersForDelete = [];

  // Stores a temporary folder name during creation - kept for state management
  String? pendingFolderName;

  void _showNotification(String message, {bool isDelete = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
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

  @override
  void initState() {
    super.initState();
    _loadFolders();
    SyncService.instance.lastSyncNotifier.addListener(_loadFolders);
  }

  @override
  void dispose() {
    SyncService.instance.lastSyncNotifier.removeListener(_loadFolders);
    super.dispose();
  }

  // Method to fetch dataset folders from the database
  Future<void> _loadFolders() async {
    if (!mounted || _isLoadingFolders) return;

    _isLoadingFolders = true;

    try {
      await LocalDb.instance.generateDatasetsFromTrees();
      final loadedFolders = await LocalDb.instance.getAllDatasetFolders();
      if (!mounted) return;

      setState(() {
        folders = loadedFolders;
        isLoading = false;
      });
    } finally {
      _isLoadingFolders = false;
    }
  }

  void _enterFolderDeleteMode(String folderName) {
    setState(() {
      _isFolderDeleteMode = true;
      _selectedFoldersForDelete
        ..clear()
        ..add(folderName);
    });
  }

  void _exitFolderDeleteMode() {
    setState(() {
      _isFolderDeleteMode = false;
      _selectedFoldersForDelete.clear();
    });
  }

  void _toggleFolderSelection(String folderName) {
    setState(() {
      _selectedFoldersForDelete.contains(folderName)
          ? _selectedFoldersForDelete.remove(folderName)
          : _selectedFoldersForDelete.add(folderName);
    });
  }

  void _toggleSelectAllFolders() {
    final allFolderNames = folders.map((folder) => folder.name).toList();
    final allSelected =
        allFolderNames.isNotEmpty &&
        allFolderNames.every(_selectedFoldersForDelete.contains);

    setState(() {
      if (allSelected) {
        _selectedFoldersForDelete.clear();
      } else {
        _selectedFoldersForDelete
          ..clear()
          ..addAll(allFolderNames);
      }
    });
  }

  Future<void> _renameFolder(String folderName) async {
    final newName = await DatasetDialogs.showRenameFolderDialog(
      context,
      folderName,
    );

    if (!mounted) return;

    if (newName != null && newName.isNotEmpty && newName != folderName) {
      await LocalDb.instance.updateDatasetFolderName(folderName, newName);
      await _loadFolders();
      if (!mounted) return;
      _showNotification('Folder renamed to $newName');
    }
  }

  Future<void> _deleteFolder(String folderName) async {
    final bool confirmDelete =
        await DatasetDialogs.showDeleteConfirmationDialog(context, folderName);

    if (!mounted || !confirmDelete) return;

    await LocalDb.instance.deleteDatasetFolder(folderName);
    await _loadFolders();
    if (!mounted) return;
    _showNotification('Folder "$folderName" deleted.', isDelete: true);
  }

  Future<void> _confirmDeleteSelectedFolders() async {
    if (_selectedFoldersForDelete.isEmpty) return;

    final count = _selectedFoldersForDelete.length;
    final bool confirmDelete =
        await DatasetDialogs.showDeleteConfirmationDialog(
          context,
          '$count selected folder${count == 1 ? '' : 's'}',
        );

    if (!mounted || !confirmDelete) return;

    final targets = List<String>.from(_selectedFoldersForDelete);
    for (final folderName in targets) {
      await LocalDb.instance.deleteDatasetFolder(folderName);
    }

    await _loadFolders();
    if (!mounted) return;

    _showNotification(
      '$count folder${count == 1 ? '' : 's'} deleted.',
      isDelete: true,
    );
    _exitFolderDeleteMode();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFolderDeleteMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFolderDeleteMode) {
          _exitFolderDeleteMode();
        }
      },
      child: Scaffold(
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
                  gradient: DatasetConstants.kGreenGradient,
                ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      Text(
                        _isFolderDeleteMode ? 'Select Folders' : 'Dataset',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      _isFolderDeleteMode
                          ? TextButton(
                              onPressed: _toggleSelectAllFolders,
                              child: Text(
                                folders.isNotEmpty &&
                                        folders
                                            .map((folder) => folder.name)
                                            .every(
                                              _selectedFoldersForDelete
                                                  .contains,
                                            )
                                    ? 'Deselect All'
                                    : 'Select All',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),

            // Main container displaying folders
            Positioned.fill(
              top:
                  DatasetConstants.kTopHeaderHeight -
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
                              childAspectRatio: 0.80,
                            ),
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          final folder = folders[index];
                          final isSelected = _selectedFoldersForDelete.contains(
                            folder.name,
                          );
                          return GestureDetector(
                            // Normal tap to view folder content
                            onTap: () {
                              if (_isFolderDeleteMode) {
                                _toggleFolderSelection(folder.name);
                              } else {
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
                              }
                            },
                            onLongPress: () {
                              if (_isFolderDeleteMode) {
                                _toggleFolderSelection(folder.name);
                              } else {
                                _enterFolderDeleteMode(folder.name);
                              }
                            },
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Center(
                                      child: SvgFolderIcon(size: 120),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 30),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              folder.name,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (!_isFolderDeleteMode)
                                            PopupMenuButton<String>(
                                              icon: const Icon(
                                                Icons.more_vert,
                                                size: 18,
                                                color: Colors.black54,
                                              ),
                                              color: Colors.white,
                                              onSelected: (value) {
                                                if (value == 'rename') {
                                                  _renameFolder(folder.name);
                                                } else if (value == 'delete') {
                                                  _deleteFolder(folder.name);
                                                }
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem<String>(
                                                  value: 'rename',
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  child: Text('Rename'),
                                                ),
                                                PopupMenuItem<String>(
                                                  value: 'delete',
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  child: Text('Delete'),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 30),
                                      child: Text(
                                        '${folder.images.length} items',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isFolderDeleteMode && isSelected)
                                  Positioned(
                                    top: 14,
                                    right: 12,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 26,
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
        bottomNavigationBar: _isFolderDeleteMode
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selectedFoldersForDelete.length} selected',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _selectedFoldersForDelete.isEmpty
                          ? null
                          : _confirmDeleteSelectedFolders,
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              )
            : null,
        // Floating action button to create a new dataset
        floatingActionButton: _isFolderDeleteMode
            ? null
            : FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: () =>
                    DatasetDialogs.showCreateFolderDialog(context, (
                      String finalFolderName,
                      String location,
                      List<String> selectedImages,
                    ) async {
                      if (!mounted) return;

                      // Save the new folder to the database
                      await LocalDb.instance.insertDatasetFolder(
                        name: finalFolderName,
                        location: location,
                        imageIds: selectedImages,
                        dateCreated: DateTime.now()
                            .toIso8601String(), // Store creation date
                      );

                      // Reload the list from the database to update the UI
                      _loadFolders();
                      _showNotification('Folder "$finalFolderName" created.');
                    }),
                child: const Icon(Icons.create_new_folder, color: Colors.white),
              ),
      ),
    );
  }
}
