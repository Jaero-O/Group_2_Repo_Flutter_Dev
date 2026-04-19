import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'photo_widgets.dart';
import 'gallery_dialogs.dart';
import '../../model/photo.dart';

// Widget that displays a grid or list of photos depending on the view mode.
class PhotoGridContent extends StatelessWidget {
  final String viewMode;
  final ValueChanged<String>? onPhotoLongPress;
  final List<PhotoMetadata> photos;
  final bool isLoadingMore;

  const PhotoGridContent({
    super.key,
    this.viewMode = 'All Photos',
    this.onPhotoLongPress,
    required this.photos,
    this.isLoadingMore = false,
  });

  DateTime? _parseTimestamp(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parsed =
        DateTime.tryParse(trimmed) ??
        DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
    if (parsed != null) return parsed.toLocal();

    final m = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2}):(\d{2}))?',
    ).firstMatch(trimmed);
    if (m == null) return null;

    final y = int.tryParse(m.group(1) ?? '');
    final mo = int.tryParse(m.group(2) ?? '');
    final d = int.tryParse(m.group(3) ?? '');
    final h = int.tryParse(m.group(4) ?? '0');
    final mi = int.tryParse(m.group(5) ?? '0');
    final s = int.tryParse(m.group(6) ?? '0');

    if (y == null || mo == null || d == null) return null;
    return DateTime(y, mo, d, h ?? 0, mi ?? 0, s ?? 0);
  }

  int _comparePhotosByTimestampDesc(PhotoMetadata a, PhotoMetadata b) {
    final at = _parseTimestamp(a.timestamp);
    final bt = _parseTimestamp(b.timestamp);

    if (at != null && bt != null) return bt.compareTo(at);
    if (at != null) return -1;
    if (bt != null) return 1;
    return (b.id ?? 0).compareTo(a.id ?? 0);
  }

  void _openFullScreenView(
    BuildContext context,
    String imagePath, [
    dynamic photo,
  ]) {
    Photo? resolvedPhoto;
    if (photo is Photo) {
      resolvedPhoto = photo;
    } else if (photo is PhotoMetadata) {
      resolvedPhoto = Photo(
        id: photo.id,
        name: photo.name,
        data: '',
        timestamp: photo.timestamp,
        path: photo.path,
        title: photo.title,
        description: photo.description,
        imageUrl: photo.imageUrl,
        checksum: photo.checksum,
        source: photo.source,
        updatedAt: photo.updatedAt,
        disease: photo.disease,
        severityLabel: photo.severityLabel,
        confidence: photo.confidence,
        severityValue: photo.severityValue,
        photoId: photo.photoId,
        scanDir: photo.scanDir,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FullScreenPhotoView(imagePath: imagePath, photo: resolvedPhoto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Center(
        child: Text(
          'No images available',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
      );
    }
    if (viewMode == 'All Photos') {
      final sortedPhotos = List<PhotoMetadata>.from(photos)
        ..sort(_comparePhotosByTimestampDesc);
      return PhotoGrid(
        photos: List<dynamic>.from(sortedPhotos),
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        padding: const EdgeInsets.all(4),
        borderRadius: 4,
        isLoadingMore: isLoadingMore,
        onItemTap: (index) {
          _openFullScreenView(
            context,
            sortedPhotos[index].path ?? sortedPhotos[index].id.toString(),
            sortedPhotos[index],
          );
        },
        onItemLongPress: (index) {
          if (onPhotoLongPress != null) {
            onPhotoLongPress!(sortedPhotos[index].id.toString());
          } else {
            GalleryDialogs.showDeleteConfirmationDialog(
              context,
              'Photo',
              sortedPhotos[index].id.toString(),
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Photo ${sortedPhotos[index].name} marked for deletion!',
                    ),
                  ),
                );
              },
            );
          }
        },
      );
    } else {
      try {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: _buildGroupedSections(context),
        );
      } catch (_) {
        final sortedPhotos = List<PhotoMetadata>.from(photos)
          ..sort(_comparePhotosByTimestampDesc);
        return PhotoGrid(
          photos: List<dynamic>.from(sortedPhotos),
          crossAxisCount: 4,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          padding: const EdgeInsets.all(4),
          borderRadius: 4,
          onItemTap: (index) {
            _openFullScreenView(
              context,
              sortedPhotos[index].path ?? sortedPhotos[index].id.toString(),
              sortedPhotos[index],
            );
          },
          onItemLongPress: (index) {
            final id = sortedPhotos[index].id;
            if (id == null) return;
            if (onPhotoLongPress != null) {
              onPhotoLongPress!(id.toString());
            }
          },
        );
      }
    }
  }

  List<Widget> _buildGroupedSections(BuildContext context) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final datedPhotos = photos
        .map((p) => (photo: p, time: _parseTimestamp(p.timestamp)))
        .where((x) => x.time != null)
        .toList();
    final undatedPhotos = photos
      .where((p) => _parseTimestamp(p.timestamp) == null)
      .toList();

    // If timestamps are missing/unparseable, fall back to all-photos.
    if (datedPhotos.isEmpty) {
      if (undatedPhotos.isNotEmpty) {
        undatedPhotos.sort(_comparePhotosByTimestampDesc);
        return [
          _buildGroupedColumn(context, 'Undated', undatedPhotos),
        ];
      }

      return [
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Center(
            child: Text(
              'No dated photos available.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ];
    }

    List<Widget> sections = [];

    if (viewMode == 'Years') {
      final Map<int, Map<int, List<PhotoMetadata>>> grouped = {};
      for (final x in datedPhotos) {
        final t = x.time!;
        ((grouped[t.year] ??= {})[t.month] ??= []).add(x.photo);
      }

      final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
      for (final year in years) {
        sections.add(
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 10, bottom: 12),
            child: Text(
              '$year',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        );

        final months = grouped[year]!.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        for (final month in months) {
          final monthPhotos = grouped[year]![month]!
            ..sort(_comparePhotosByTimestampDesc);
          sections.add(
            _buildGroupedColumn(
              context,
              monthNames[month - 1],
              monthPhotos,
              leftPadding: 24,
            ),
          );
        }
      }

      if (undatedPhotos.isNotEmpty) {
        undatedPhotos.sort(_comparePhotosByTimestampDesc);
        sections.add(
          _buildGroupedColumn(
            context,
            'Undated',
            undatedPhotos,
            leftPadding: 24,
          ),
        );
      }

      return sections;
    }

    if (viewMode == 'Months') {
      final Map<String, List<PhotoMetadata>> grouped = {};
      for (final x in datedPhotos) {
        final t = x.time!;
        final key = '${t.year}-${t.month.toString().padLeft(2, '0')}';
        (grouped[key] ??= []).add(x.photo);
      }

      final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
      for (final key in keys) {
        final parts = key.split('-');
        final year = int.tryParse(parts[0]) ?? 0;
        final month = int.tryParse(parts[1]) ?? 1;
        final title = '${monthNames[month - 1]} $year';
        final monthPhotos = grouped[key]!
          ..sort(_comparePhotosByTimestampDesc);
        sections.add(_buildGroupedColumn(context, title, monthPhotos));
      }
      if (undatedPhotos.isNotEmpty) {
        undatedPhotos.sort(_comparePhotosByTimestampDesc);
        sections.add(_buildGroupedColumn(context, 'Undated', undatedPhotos));
      }

      return sections;
    }

    // Days
    final Map<String, List<PhotoMetadata>> grouped = {};
    for (final x in datedPhotos) {
      final t = x.time!;
      final key =
          '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
      (grouped[key] ??= []).add(x.photo);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final key in keys) {
      final parts = key.split('-');
      final year = int.tryParse(parts[0]) ?? 0;
      final month = int.tryParse(parts[1]) ?? 1;
      final day = int.tryParse(parts[2]) ?? 1;
      final title = '${monthNames[month - 1]} $day, $year';
      final dayPhotos = grouped[key]!
        ..sort(_comparePhotosByTimestampDesc);
      sections.add(
        _buildGroupedColumn(context, title, dayPhotos, titleSize: 16),
      );
    }
    if (undatedPhotos.isNotEmpty) {
      undatedPhotos.sort(_comparePhotosByTimestampDesc);
      sections.add(
        _buildGroupedColumn(context, 'Undated', undatedPhotos, titleSize: 16),
      );
    }

    return sections;
  }

  Widget _buildGroupedColumn(
    BuildContext context,
    String title,
    List<PhotoMetadata> groupedPhotos, {
    double leftPadding = 12,
    double titleSize = 20,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: leftPadding, top: 10, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildPhotoGrid(context, groupedPhotos),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(
    BuildContext context,
    List<PhotoMetadata> groupedPhotos,
  ) {
    return PhotoGrid(
      photos: List<dynamic>.from(groupedPhotos),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      padding: EdgeInsets.zero,
      borderRadius: 8,
      onItemTap: (index) => _openFullScreenView(
        context,
        groupedPhotos[index].path ?? groupedPhotos[index].id.toString(),
        groupedPhotos[index],
      ),
      onItemLongPress: (index) {
        final id = groupedPhotos[index].id;
        if (id == null) return;
        if (onPhotoLongPress != null) {
          onPhotoLongPress!(id.toString());
        } else {
          GalleryDialogs.showDeleteConfirmationDialog(
            context,
            'Photo',
            id.toString(),
            () {},
          );
        }
      },
    );
  }
}

// --- Main Photos View with Thinner Responsive Mode Selector ---

class PhotosView extends StatefulWidget {
  final ValueChanged<String>? onPhotoLongPress;
  final List<PhotoMetadata> photos;
  final bool isLoadingMore;

  const PhotosView({
    super.key,
    this.onPhotoLongPress,
    required this.photos,
    this.isLoadingMore = false,
  });

  @override
  State<PhotosView> createState() => _PhotosViewState();
}

class _PhotosViewState extends State<PhotosView> {
  String viewMode = 'All Photos';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: PhotoGridContent(
            viewMode: viewMode,
            onPhotoLongPress: widget.onPhotoLongPress,
            photos: widget.photos,
            isLoadingMore: widget.isLoadingMore,
          ),
        ),

        // Thinner Bottom Navigation Selector
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              // THINNER PADDING
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildModeButton('Years'),
                  _buildModeButton('Months'),
                  _buildModeButton('Days'),
                  _buildModeButton('All Photos'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton(String label) {
    final bool isActive = viewMode == label;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => viewMode = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          // THINNER VERTICAL PADDING
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            // ORIGINAL GREY
            color: isActive ? Colors.grey : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              // ORIGINAL GREY
              color: isActive ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
