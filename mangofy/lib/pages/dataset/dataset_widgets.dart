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
                      Colors.black.withValues(alpha: 0.85),
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
  bool _isImageDeleteMode = false;
  final List<String> _selectedImagesForDelete = [];

  @override
  void initState() {
    super.initState();
    _currentImages = widget.images
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    _loadImagePaths();
  }

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

  String _normalizeLocalPath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return trimmed;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.isAbsolute && uri.scheme == 'file') {
      try {
        return uri.toFilePath();
      } catch (_) {
        return trimmed.replaceFirst('file://', '');
      }
    }
    return trimmed;
  }

  bool _isRemoteUrl(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
  }

  bool _looksLikeDirectImageSource(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (_isRemoteUrl(trimmed)) return true;
    if (trimmed.startsWith('file://')) return true;
    if (trimmed.startsWith('/')) return true;
    if (trimmed.contains('\\')) return true;
    return false;
  }

  Future<void> _loadImagePaths() async {
    final paths = Map<String, String?>.from(_imagePaths);
    final urls = Map<String, String?>.from(_imageUrls);
    final scans = Map<String, ScanItem?>.from(_scanItems);
    final scanKeys = <String>[];
    final scanFutures = <Future<ScanItem?>>[];

    for (final img in _currentImages) {
      final key = img.toString().trim();
      if (key.isEmpty) continue;

      final id = int.tryParse(key);
      if (id != null) {
        scanKeys.add(key);
        scanFutures.add(LocalDb.instance.getScanById(id));
        continue;
      }

      if (_isRemoteUrl(key)) {
        urls[key] = key;
        continue;
      }

      if (_looksLikeDirectImageSource(key)) {
        final normalized = _normalizeLocalPath(key);
        if (!normalized.startsWith('/home/') &&
            !normalized.startsWith('/opt/') &&
            !normalized.startsWith('/var/')) {
          paths[key] = normalized;
        }
      }
    }

    if (!mounted) return;

    // Render immediately when raw IDs already contain usable paths/URLs.
    setState(() {
      _imagePaths = paths;
      _imageUrls = urls;
      _scanItems = scans;
    });

    if (scanFutures.isEmpty) return;

    final scanResults = await Future.wait(scanFutures);

    for (var i = 0; i < scanResults.length; i++) {
      final scan = scanResults[i];
      final key = scanKeys[i];
      if (scan == null) continue;

      scans[key] = scan;

      final rawImagePath = scan.imagePath.trim();
      if (rawImagePath.isNotEmpty) {
        final normalized = _normalizeLocalPath(rawImagePath);
        if (!normalized.startsWith('/home/') &&
            !normalized.startsWith('/opt/') &&
            !normalized.startsWith('/var/')) {
          paths[key] = normalized;
        }
      }

      final imageUrl = scan.imageUrl.trim();
      if (imageUrl.isNotEmpty) {
        urls[key] = imageUrl;
      }
    }

    if (!mounted) return;

    setState(() {
      _imagePaths = paths;
      _imageUrls = urls;
      _scanItems = scans;
    });
  }

  void _enterImageDeleteMode(String imageId) {
    setState(() {
      _isImageDeleteMode = true;
      _selectedImagesForDelete
        ..clear()
        ..add(imageId);
    });
  }

  void _exitImageDeleteMode() {
    setState(() {
      _isImageDeleteMode = false;
      _selectedImagesForDelete.clear();
    });
  }

  void _toggleImageSelection(String imageId) {
    setState(() {
      _selectedImagesForDelete.contains(imageId)
          ? _selectedImagesForDelete.remove(imageId)
          : _selectedImagesForDelete.add(imageId);
    });
  }

  void _toggleSelectAllImages() {
    final allImageIds = _currentImages
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final allSelected =
        allImageIds.isNotEmpty &&
        allImageIds.every(_selectedImagesForDelete.contains);

    setState(() {
      if (allSelected) {
        _selectedImagesForDelete.clear();
      } else {
        _selectedImagesForDelete
          ..clear()
          ..addAll(allImageIds);
      }
    });
  }

  Future<void> _confirmDeleteSelectedImages() async {
    if (_selectedImagesForDelete.isEmpty) return;

    final count = _selectedImagesForDelete.length;
    final bool? confirmDelete = await showDialog<bool>(
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Delete Selected Images?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to remove $count image${count == 1 ? '' : 's'} from ${widget.folderName}?',
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
                        onPressed: () => Navigator.pop(dialogContext, true),
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

    if (confirmDelete != true || !mounted) return;

    final targets = List<String>.from(_selectedImagesForDelete);
    for (final imageId in targets) {
      await LocalDb.instance.removeImageFromDatasetFolder(
        widget.folderName,
        imageId,
      );
    }

    if (!mounted) return;
    setState(() {
      _currentImages.removeWhere(
        (image) => targets.contains(image.toString().trim()),
      );
      _selectedImagesForDelete.clear();
      _isImageDeleteMode = false;
    });

    widget.onImageRemoved();
    _showNotification(
      '$count image${count == 1 ? '' : 's'} removed.',
      isDelete: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isImageDeleteMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isImageDeleteMode) {
          _exitImageDeleteMode();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          title: Text(
            _isImageDeleteMode ? 'Select Images' : widget.folderName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.green),
          elevation: 0,
          actions: _isImageDeleteMode
              ? [
                  TextButton(
                    onPressed: _toggleSelectAllImages,
                    child: Text(
                      _currentImages.isNotEmpty &&
                              _currentImages
                                  .map((e) => e.toString().trim())
                                  .every(_selectedImagesForDelete.contains)
                          ? 'Deselect All'
                          : 'Select All',
                      style: GoogleFonts.inter(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ]
              : null,
        ),

        // Grid displaying folder photos
        body: _currentImages.isEmpty
            ? const Center(child: Text("This folder is empty."))
            : GridView.builder(
                padding: const EdgeInsets.all(16),

                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 columns
                  crossAxisSpacing: 6, // Horizontal spacing
                  mainAxisSpacing: 6, // Vertical spacing
                ),

                itemCount: _currentImages.length,
                itemBuilder: (context, index) {
                  final img = _currentImages[index].toString().trim();
                  final isSelected = _selectedImagesForDelete.contains(img);
                  final path = _imagePaths[img];
                  final url = _imageUrls[img]?.trim() ?? '';
                  final scan = _scanItems[img];
                  final localPath = (path ?? '').trim();
                  final isRemotePath =
                      localPath.startsWith('http://') ||
                      localPath.startsWith('https://');
                  final isLocalFile = localPath.isNotEmpty && !isRemotePath;
                  final networkSource = isRemotePath
                      ? localPath
                      : (url.startsWith('http://') || url.startsWith('https://')
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
                      : statusForScan(
                          scan,
                          notApplicableLabel: 'Not Applicable',
                        );

                  return GestureDetector(
                    // Tap to view full screen
                    onTap: () {
                      if (_isImageDeleteMode) {
                        _toggleImageSelection(img);
                      } else {
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
                      }
                    },
                    // Long Press to enter or extend selection delete mode
                    onLongPress: () {
                      if (_isImageDeleteMode) {
                        _toggleImageSelection(img);
                      } else {
                        _enterImageDeleteMode(img);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: _isImageDeleteMode && isSelected
                            ? Border.all(color: Colors.green, width: 2)
                            : null,
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
                                              (context, error, stackTrace) {
                                                if (networkSource.isNotEmpty) {
                                                  return Image.network(
                                                    networkSource,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => const Icon(
                                                          Icons
                                                              .image_not_supported,
                                                        ),
                                                  );
                                                }
                                                return const Icon(
                                                  Icons.image_not_supported,
                                                );
                                              },
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
                                              Colors.black.withValues(
                                                alpha: 0.7,
                                              ),
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
                                  if (_isImageDeleteMode && isSelected)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withValues(
                                          alpha: 0.25,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                    ),
                  );
                },
              ),
        bottomNavigationBar: _isImageDeleteMode
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selectedImagesForDelete.length} selected',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _selectedImagesForDelete.isEmpty
                          ? null
                          : _confirmDeleteSelectedImages,
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
      ),
    );
  }
}
