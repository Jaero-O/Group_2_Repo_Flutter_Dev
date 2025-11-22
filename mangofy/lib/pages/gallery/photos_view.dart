import 'package:flutter/material.dart';
import 'photo_widgets.dart';

// Widget that displays a grid or list of photos depending on the view mode.
// Supports four view modes: 'All Photos', 'Years', 'Months', or 'Days'.
class PhotoGridContent extends StatelessWidget {
  /// Current view mode: 'All Photos', 'Years', 'Months', or 'Days'
  final String viewMode;

  const PhotoGridContent({
    super.key,
    this.viewMode = 'All Photos',
  });

  // Helper method to navigate to the full screen view
  void _openFullScreenView(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoView(imagePath: imagePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- "All Photos" view ---
    if (viewMode == 'All Photos') {
      const int count = 40;
      final List<String> allPhotos = List.generate(count, (i) => 'AllPhotos_photo_$i');

      return PhotoGridPlaceholder(
        itemCount: count,
        imageIds: allPhotos,
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        padding: const EdgeInsets.all(4),
        borderRadius: 4, 
        iconSize: 40,
        onItemTap: (index) {
          _openFullScreenView(context, allPhotos[index]);
        },
      );
    } else {
    // --- Grouped views (Years, Months, or Days) ---
      return ListView(
        padding: const EdgeInsets.all(12),
        children: _buildGroupedSections(context), // Pass context here
      );
    }
  }

  // Builds sections for the grouped views (Years, Months, Days)
  List<Widget> _buildGroupedSections(BuildContext context) { // Accept context
    final yearData = {
      '2025': {
        'December': ['01', '02', '05'],
        'November': ['10', '12', '15', '20'],
        'October': ['25', '28'],
      },
    };

    List<Widget> sections = [];
    int photoIndex = 0; // Use an index to generate unique IDs for the placeholders

    yearData.forEach((year, months) {
      if (viewMode == 'Years') {
        sections.add(
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 10, bottom: 12),
            child: Text(
              year,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        );
        months.forEach((month, days) {
          final count = 16;
          final currentPhotos = List.generate(count, (i) => 'Y:$year/M:$month/P:${photoIndex + i}');
          photoIndex += count;

          sections.add(
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 6, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    month,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildPhotoGrid(context, count, currentPhotos), // Pass context and photos
                ],
              ),
            ),
          );
        });
      } else if (viewMode == 'Months') {
        months.forEach((month, days) {
          final count = 16;
          final currentPhotos = List.generate(count, (i) => 'M:$month/Y:$year/P:${photoIndex + i}');
          photoIndex += count;

          sections.add(
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 10, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$month $year',
                    style:
                        const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildPhotoGrid(context, count, currentPhotos), // Pass context and photos
                ],
              ),
            ),
          );
        });
      } else if (viewMode == 'Days') {
        months.forEach((month, days) {
          for (var day in days) {
            final count = 8;
            final currentPhotos = List.generate(count, (i) => 'D:$day/M:$month/Y:$year/P:${photoIndex + i}');
            photoIndex += count;

            sections.add(
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 10, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$month $day, $year',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildPhotoGrid(context, count, currentPhotos), // Pass context and photos
                  ],
                ),
              ),
            );
          }
        });
      }
    });

    return sections;
  }

  // Helper method to build a placeholder photo grid of [count] items
  Widget _buildPhotoGrid(
    BuildContext context, 
    int count, 
    List<String> imageIds,
  ) {
    // Use the reusable PhotoGridPlaceholder
    return PhotoGridPlaceholder(
      itemCount: count,
      imageIds: imageIds,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      borderRadius: 8,
      iconSize: 40,
      onItemTap: (index) {
        _openFullScreenView(context, imageIds[index]);
      },
    );
  }
}

// Main widget for displaying photos with a bottom view mode selector
class PhotosView extends StatefulWidget {
  const PhotosView({super.key});

  @override
  State<PhotosView> createState() => _PhotosViewState();
}

class _PhotosViewState extends State<PhotosView> {
  // Current view mode
  String viewMode = 'All Photos';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main photo grid/list content
        Positioned.fill(
          child: PhotoGridContent(viewMode: viewMode),
        ),

        // Bottom view mode selector
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(190),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomButton('Years'),
                  _buildBottomButton('Months'),
                  _buildBottomButton('Days'),
                  _buildBottomButton('All Photos'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Builds a bottom navigation button for switching view modes
  Widget _buildBottomButton(String label) {
    final isActive = viewMode == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          viewMode = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.grey : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}