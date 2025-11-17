import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dataset_constants.dart';
import 'dataset_dialogs.dart';
import 'dataset_widgets.dart'; 

/// The DatasetPage widget displays a list of dataset folders
/// and allows users to create new datasets by selecting images.
class DatasetPage extends StatefulWidget {
  const DatasetPage({super.key});

  @override
  State<DatasetPage> createState() => _DatasetPageState();
}

class _DatasetPageState extends State<DatasetPage> {
  /// List of folders containing folder name and images
  final List<Map<String, dynamic>> folders = [
    {'name': 'Training Data 1', 'images': List.generate(25, (i) => 'td1_$i')},
    {'name': 'Test Samples', 'images': List.generate(12, (i) => 'ts_$i')},
    {'name': 'My Trees Export', 'images': List.generate(40, (i) => 'mte_$i')},
  ];

  /// Stores a temporary folder name during creation - kept for state management
  String? pendingFolderName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top header with green gradient
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

          // Page title
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
              // Display either a message or grid of folders
              child: folders.isEmpty
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FolderViewPage(
                                  folderName: folder['name'],
                                  images: folder['images'],
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(child: SvgFolderIcon(size: 120)),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 30),
                                child: Text(
                                  folder['name'],
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
                                  '${folder['images'].length} items',
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
          (String finalFolderName, List<String> selectedImages) {
            if (!mounted) return;
            setState(() {
              folders.add(
                  {'name': finalFolderName, 'images': selectedImages});
              pendingFolderName = null;
            });
          },
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}