import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../gallery/gallery_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgFolderIcon extends StatelessWidget {
  final double size;
  final String assetPath;

  const SvgFolderIcon({
    super.key,
    this.assetPath = 'images/folder.svg',
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(assetPath, width: size, height: size);
  }
}

class DatasetPage extends StatefulWidget {
  const DatasetPage({super.key});

  @override
  State<DatasetPage> createState() => _DatasetPageState();
}

class _DatasetPageState extends State<DatasetPage> {
  final List<Map<String, dynamic>> folders = [
    {'name': 'Training Data 1', 'images': List.generate(25, (i) => 'td1_$i')},
    {'name': 'Test Samples', 'images': List.generate(12, (i) => 'ts_$i')},
    {'name': 'My Trees Export', 'images': List.generate(40, (i) => 'mte_$i')},
  ];

  String? pendingFolderName;

  static const Color topColorStart = Color(0xFF007700);
  static const Color topColorEnd = Color(0xFFC9FF8E);
  static const double kTopHeaderHeight = 220.0;
  static const double kTopRadius = 70.0;
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
            child: Container(
              decoration: const BoxDecoration(gradient: kGreenGradient),
            ),
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
                        fontWeight: FontWeight.w700,
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
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: SvgFolderIcon(size: 120)),
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
                  _buildFolderChoice(
                    svgIcon: const SvgFolderIcon(size: 90),
                    label: 'Gallery',
                    onTap: () => _navigateToSelection(parentContext, '', null),
                  ),
                  const SizedBox(width: 15),
                  _buildFolderChoice(
                    svgIcon: const SvgFolderIcon(size: 90),
                    label: 'My Trees',
                    onTap: () =>
                        _navigateToSelection(parentContext, '', 'My Trees'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF393939),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _showFolderNameDialog(BuildContext context) async {
    String folderName = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Enter Folder Name',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: TextField(
            autofocus: true,
            onChanged: (val) => folderName = val,
            decoration: InputDecoration(
              labelText: 'Folder Name',
              border: const OutlineInputBorder(),
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
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
              child: Text(
                'Create',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSelection(
    BuildContext parentContext,
    String folderName,
    String? initialMode,
  ) async {
    Navigator.pop(parentContext);
    final selected = await Navigator.push<List<String>>(
      parentContext,
      MaterialPageRoute(
        builder: (_) =>
            GalleryPage(isSelectionMode: true, initialMode: initialMode),
      ),
    );

    if (!mounted) return;

    if (selected != null && selected.isNotEmpty) {
      final finalFolderName = await _showFolderNameDialog(parentContext);

      if (!mounted) return;

      if (finalFolderName != null && finalFolderName.isNotEmpty) {
        setState(() {
          folders.add({'name': finalFolderName, 'images': selected});
          pendingFolderName = null;
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCreateFolderDialog(parentContext);
        });
      }
    }
  }

  Widget _buildFolderChoice({
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
