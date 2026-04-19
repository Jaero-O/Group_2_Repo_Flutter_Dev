import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../../services/local_db.dart';
import '../../model/scan_item.dart';
import '../../model/scan_classification.dart';

// SVG folder icon.
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

// Displays a single image in a full-screen view.
class FullScreenPhotoPage extends StatelessWidget {
  final String imageId;
  final String? imagePath;
  final String? imageUrl;
  final String? disease;
  final String? severityLabel;
  final String? dateScanned;

  const FullScreenPhotoPage({
    super.key,
    required this.imageId,
    this.imagePath,
    this.imageUrl,
    this.disease,
    this.severityLabel,
    this.dateScanned,
  });

  bool _isRemote(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set background to black for a typical photo viewer experience
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: () {
              final localPath = (imagePath ?? '').trim();
              final fallbackUrl = (imageUrl ?? '').trim();

              if (localPath.isNotEmpty && !_isRemote(localPath)) {
                return Image.file(
                  File(localPath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    if (fallbackUrl.isNotEmpty && _isRemote(fallbackUrl)) {
                      return Image.network(
                        fallbackUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.white70,
                          size: 42,
                        ),
                      );
                    }
                    return const Icon(
                      Icons.image_not_supported,
                      color: Colors.white70,
                      size: 42,
                    );
                  },
                );
              }

              final remoteSource = _isRemote(localPath)
                  ? localPath
                  : (_isRemote(fallbackUrl) ? fallbackUrl : '');
              if (remoteSource.isNotEmpty) {
                return Image.network(
                  remoteSource,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported,
                    color: Colors.white70,
                    size: 42,
                  ),
                );
              }

              return Text(
                imageId,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              );
            }(),
          ),

          if ((disease != null && disease!.isNotEmpty) ||
              (severityLabel != null && severityLabel!.isNotEmpty) ||
              (dateScanned != null && dateScanned!.isNotEmpty))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (disease != null && disease!.isNotEmpty)
                      Text(
                        'Disease: $disease',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (severityLabel != null && severityLabel!.isNotEmpty)
                      Text(
                        'Classification: $severityLabel',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    if (dateScanned != null && dateScanned!.isNotEmpty)
                      Text(
                        'Scanned: $dateScanned',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Close Button
          Positioned(
            top: 40,
            right: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Shows images inside the selected folder
class FolderViewPage extends StatefulWidget {
  final String folderName;
  final List<dynamic> images;
  // Callback when an image is removed
  final VoidCallback onImageRemoved;

  const FolderViewPage({
    super.key,
    required this.folderName,
    required this.images,
    required this.onImageRemoved,
  });

  @override
  State<FolderViewPage> createState() => _FolderViewPageState();
}

class _FolderViewPageState extends State<FolderViewPage> {
  // Use a local state for images so it can be updated after deletion
  late List<dynamic> _currentImages;
  Map<String, String?> _imagePaths = {};
  Map<String, String?> _imageUrls = {};
  Map<String, ScanItem?> _scanItems = {};

  @override
  void initState() {
    super.initState();
    _currentImages = widget.images
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    _loadImagePaths();
  }

  Future<void> _loadImagePaths() async {
    final paths = <String, String?>{};
    final urls = <String, String?>{};
    final scans = <String, ScanItem?>{};
    for (final img in _currentImages) {
      final key = img.toString().trim();
      if (key.isEmpty) continue;

      final id = int.tryParse(key);
      if (id != null) {
        final scan = await LocalDb.instance.getScanById(id);
        paths[key] = scan?.imagePath;
        urls[key] = scan?.imageUrl;
        scans[key] = scan;
      }
    }
    if (!mounted) return;

    setState(() {
      _imagePaths = paths;
      _imageUrls = urls;
      _scanItems = scans;
    });
  }

  // Helper to show the delete confirmation dialog for an image
  // Helper to show the delete confirmation dialog for an image
  void _showDeleteImageDialog(BuildContext context, String imageId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Centered like Gallery
              children: [
                Text(
                  'Delete Image?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to remove this image ($imageId) from the folder ${widget.folderName}?',
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);

                          // Call DB service to remove the image
                          await LocalDb.instance.removeImageFromDatasetFolder(
                            widget.folderName,
                            imageId,
                          );

                          // Update the local state
                          setState(() {
                            _currentImages.remove(imageId);
                          });

                          // Notify parent
                          widget.onImageRemoved();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Image $imageId removed.')),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Text(
          widget.folderName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.green),
        elevation: 0,
      ),

      // Grid displaying folder photos
      body: _currentImages.isEmpty
          ? const Center(child: Text("This folder is empty."))
          : GridView.builder(
              padding: const EdgeInsets.all(16),

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 columns
                crossAxisSpacing: 6, // Horizontal spacing
                mainAxisSpacing: 6, // Vertical spacing
              ),

              itemCount: _currentImages.length,
              itemBuilder: (context, index) {
                final img = _currentImages[index].toString().trim();
                final path = _imagePaths[img];
                final url = _imageUrls[img]?.trim() ?? '';
                final scan = _scanItems[img];
                final localPath = (path ?? '').trim();
                final isLocalFile =
                    localPath.isNotEmpty &&
                    !localPath.startsWith('http://') &&
                    !localPath.startsWith('https://') &&
                    File(localPath).existsSync();
                final networkSource =
                    localPath.startsWith('http://') ||
                        localPath.startsWith('https://')
                    ? localPath
                    : ((url.startsWith('http://') || url.startsWith('https://'))
                          ? url
                          : '');
                final parsed = DateTime.tryParse(scan?.timestamp ?? '');
                final dateLabel = parsed == null
                    ? (scan?.timestamp ?? '')
                    : '${parsed.toLocal().year.toString().padLeft(4, '0')}-${parsed.toLocal().month.toString().padLeft(2, '0')}-${parsed.toLocal().day.toString().padLeft(2, '0')}';
                final diseaseLabel = scan == null
                    ? ''
                    : displayDiseaseName(scan);
                final severityLabel = scan == null
                    ? ''
                    : statusForScan(scan, notApplicableLabel: 'Not Applicable');

                return GestureDetector(
                  // Tap to view full screen
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenPhotoPage(
                          imageId: img,
                          imagePath: path,
                          imageUrl: url,
                          disease: diseaseLabel,
                          severityLabel: severityLabel,
                          dateScanned: dateLabel,
                        ),
                      ),
                    );
                  },
                  // Long Press to delete
                  onLongPress: () {
                    _showDeleteImageDialog(context, img);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isLocalFile || networkSource.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                isLocalFile
                                    ? Image.file(
                                        File(localPath),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.image_not_supported,
                                                ),
                                      )
                                    : Image.network(
                                        networkSource,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.image_not_supported,
                                                ),
                                      ),
                                if (diseaseLabel.isNotEmpty ||
                                    severityLabel.isNotEmpty)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.7),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (diseaseLabel.isNotEmpty)
                                            Text(
                                              diseaseLabel,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          if (severityLabel.isNotEmpty)
                                            Text(
                                              severityLabel,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 8,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Center(
                            child: Text(
                              'No image',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
