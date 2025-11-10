import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../gallery/my_trees_page.dart';

class DatasetPage extends StatefulWidget {
  const DatasetPage({super.key});

  @override
  State<DatasetPage> createState() => _DatasetPageState();
}

class _DatasetPageState extends State<DatasetPage> {
  final List<Map<String, dynamic>> folders = [];
  String? pendingFolderName;

  static const Color topColorStart = Color(0xFF007700);
  static const Color topColorEnd = Color(0xFFC9FF8E);
  static const double kTopHeaderHeight = 220.0;
  static const double kTopRadius = 90.0;
  static const double kContainerOverlap = 60.0;
  static const double kBottomRadius = 24.0;
  static const double kTitleTopPadding = 45.0;

  static const LinearGradient kGreenGradient = LinearGradient(
    colors: [topColorStart, topColorEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

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
            height: kTopHeaderHeight,
            child: Container(decoration: const BoxDecoration(gradient: kGreenGradient)),
          ),
          Positioned(
            top: kTitleTopPadding,
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
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: kTopHeaderHeight - kContainerOverlap,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(kTopRadius),
                  bottom: Radius.circular(kBottomRadius),
                ),
              ),
              child: folders.isEmpty
                  ? const Center(
                      child: Text(
                        'No folders yet.\nTap + to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.green[100],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.folder, size: 48, color: Colors.green),
                              const SizedBox(height: 8),
                              Text(
                                folder['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${folder['images'].length} items',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _showCreateFolderDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext parentContext) {
    String folderName = pendingFolderName ?? '';
    showDialog(
      context: parentContext,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Create New Folder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (val) {
                    folderName = val;
                    pendingFolderName = val;
                  },
                  controller: TextEditingController(text: folderName),
                  decoration: const InputDecoration(
                    labelText: 'Folder Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select images from:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFolderChoice(
                      icon: Icons.photo_library,
                      label: 'Photos View',
                      onTap: () => _navigateToSelection(parentContext, folderName, false),
                    ),
                    _buildFolderChoice(
                      icon: Icons.folder_copy,
                      label: 'My Trees',
                      onTap: () => _navigateToSelection(parentContext, folderName, true),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _navigateToSelection(BuildContext parentContext, String folderName, bool isMyTreesMode) async {
    if (folderName.isEmpty) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('Please enter a folder name first')),
      );
      return;
    }
    Navigator.pop(parentContext);
    final selected = await Navigator.push<List<String>>(
      parentContext,
      MaterialPageRoute(
        builder: (_) => PhotoSelectionView(isMyTreesMode: isMyTreesMode),
      ),
    );
    if (!mounted) return;
    if (selected != null) {
      setState(() {
        folders.add({'name': folderName, 'images': selected});
        pendingFolderName = null;
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreateFolderDialog(parentContext);
      });
    }
  }

  Widget _buildFolderChoice({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 50, color: Colors.green),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class PhotoSelectionView extends StatefulWidget {
  final bool isMyTreesMode;
  const PhotoSelectionView({super.key, required this.isMyTreesMode});
  @override
  State<PhotoSelectionView> createState() => _PhotoSelectionViewState();
}

class _PhotoSelectionViewState extends State<PhotoSelectionView> {
  final List<String> selectedImages = [];
  String? selectedAlbumTitle;

  @override
  Widget build(BuildContext context) {
    String displayTitle;
    if (widget.isMyTreesMode && selectedAlbumTitle == null) {
      displayTitle = 'Select Album';
    } else if (widget.isMyTreesMode && selectedAlbumTitle != null) {
      displayTitle = 'Select from ${selectedAlbumTitle!}';
    } else {
      displayTitle = 'Select from Photos View';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: selectedAlbumTitle != null,
        leading: selectedAlbumTitle != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.green),
                onPressed: () {
                  setState(() {
                    selectedAlbumTitle = null;
                  });
                },
              )
            : null,
      ),
      body: _buildBody(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () {
                if (widget.isMyTreesMode && selectedAlbumTitle != null) {
                  setState(() {
                    selectedAlbumTitle = null;
                  });
                } else {
                  Navigator.pop(context, null);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
              child: Text(widget.isMyTreesMode && selectedAlbumTitle != null ? 'Back to Albums' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedImages.isEmpty ? null : () => Navigator.pop(context, selectedImages),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Save (${selectedImages.length})'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.isMyTreesMode && selectedAlbumTitle == null) {
      return MyTreesPage(
        isSelectionMode: true,
        onAlbumSelected: (title) {
          setState(() {
            selectedAlbumTitle = title;
          });
        },
      );
    } else {
      final contentKey = selectedAlbumTitle ?? 'AllPhotos';
      return PhotosSelectionGrid(
        contentKey: contentKey,
        selectedImages: selectedImages,
        onToggleSelection: (id) {
          setState(() {
            selectedImages.contains(id) ? selectedImages.remove(id) : selectedImages.add(id);
          });
        },
      );
    }
  }
}

class PhotosSelectionGrid extends StatelessWidget {
  final String contentKey;
  final List<String> selectedImages;
  final ValueChanged<String> onToggleSelection;
  const PhotosSelectionGrid({
    super.key,
    required this.contentKey,
    required this.selectedImages,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = contentKey == 'AllPhotos' ? 16 : 8;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final imageId = '${contentKey}_photo_$index';
        final selected = selectedImages.contains(imageId);
        return GestureDetector(
          onTap: () => onToggleSelection(imageId),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? Colors.green[200] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: selected
                ? const Icon(Icons.check_circle, size: 30, color: Colors.green)
                : const Icon(Icons.photo, size: 40, color: Colors.grey),
          ),
        );
      },
    );
  }
}
