import 'package:flutter/material.dart';
import 'photo_widgets.dart';
import 'gallery_dialogs.dart';
import '../../model/photo.dart';

// Widget that displays a grid or list of photos depending on the view mode.
class PhotoGridContent extends StatelessWidget {
  final String viewMode;
  final ValueChanged<String>? onPhotoLongPress;
  final List<Photo> photos;

  const PhotoGridContent({
    super.key,
    this.viewMode = 'All Photos',
    this.onPhotoLongPress,
    required this.photos,
  });

  void _openFullScreenView(BuildContext context, String imagePath, [Photo? photo]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoView(imagePath: imagePath, photo: photo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (viewMode == 'All Photos') {
      return PhotoGrid(
        photos: photos,
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        padding: const EdgeInsets.all(4),
        borderRadius: 4,
        onItemTap: (index) {
          _openFullScreenView(context, photos[index].id.toString(), photos[index]);
        },
        onItemLongPress: (index) {
          if (onPhotoLongPress != null) {
            onPhotoLongPress!(photos[index].id.toString());
          } else {
            GalleryDialogs.showDeleteConfirmationDialog(
              context,
              'Photo',
              photos[index].id.toString(),
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Photo ${photos[index].name} marked for deletion!')),
                );
              },
            );
          }
        },
      );
    } else {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: _buildGroupedSections(context),
      );
    }
  }

  List<Widget> _buildGroupedSections(BuildContext context) {
    final yearData = {
      '2025': {
        'December': ['01', '02', '05'],
        'November': ['10', '12', '15', '20'],
        'October': ['25', '28'],
      },
    };

    List<Widget> sections = [];
    int photoIndex = 0;

    yearData.forEach((year, months) {
      if (viewMode == 'Years') {
        sections.add(
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 10, bottom: 12),
            child: Text(year, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        );
        months.forEach((month, days) {
          final count = 16;
          final currentPhotos = List.generate(count, (i) => 'Y:$year/M:$month/P:${photoIndex + i}');
          photoIndex += count;
          sections.add(_buildGroupedColumn(context, month, count, currentPhotos, leftPadding: 24));
        });
      } else if (viewMode == 'Months') {
        months.forEach((month, days) {
          final count = 16;
          final currentPhotos = List.generate(count, (i) => 'M:$month/Y:$year/P:${photoIndex + i}');
          photoIndex += count;
          sections.add(_buildGroupedColumn(context, '$month $year', count, currentPhotos));
        });
      } else if (viewMode == 'Days') {
        months.forEach((month, days) {
          for (var day in days) {
            final count = 8;
            final currentPhotos = List.generate(count, (i) => 'D:$day/M:$month/Y:$year/P:${photoIndex + i}');
            photoIndex += count;
            sections.add(_buildGroupedColumn(context, '$month $day, $year', count, currentPhotos, titleSize: 16));
          }
        });
      }
    });
    return sections;
  }

  Widget _buildGroupedColumn(BuildContext context, String title, int count, List<String> ids, {double leftPadding = 12, double titleSize = 20}) {
    return Padding(
      padding: EdgeInsets.only(left: leftPadding, top: 10, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildPhotoGrid(context, count, ids),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, int count, List<String> imageIds) {
    return PhotoGridPlaceholder(
      itemCount: count,
      imageIds: imageIds,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      borderRadius: 8,
      onItemTap: (index) => _openFullScreenView(context, imageIds[index]),
      onItemLongPress: (index) {
        if (onPhotoLongPress != null) {
          onPhotoLongPress!(imageIds[index]);
        } else {
          GalleryDialogs.showDeleteConfirmationDialog(context, 'Photo', imageIds[index], () {});
        }
      },
    );
  }
}

// --- Main Photos View with Thinner Responsive Mode Selector ---

class PhotosView extends StatefulWidget {
  final ValueChanged<String>? onPhotoLongPress;
  final List<Photo> photos;

  const PhotosView({super.key, this.onPhotoLongPress, required this.photos});

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
          ),
        ),

        // Thinner Bottom Navigation Selector
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
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