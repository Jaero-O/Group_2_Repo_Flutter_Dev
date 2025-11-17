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

  @override
  Widget build(BuildContext context) {
    // Display a simple 4-column grid for "All Photos"
    if (viewMode == 'All Photos') {
      // Use the reusable PhotoGridPlaceholder
      return const PhotoGridPlaceholder(
        itemCount: 40,
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        padding: EdgeInsets.all(4),
        borderRadius: 4, 
        iconSize: 40,
      );
    } else {
      // For grouped views: Years, Months, or Days
      return ListView(
        padding: const EdgeInsets.all(12),
        children: _buildGroupedSections(),
      );
    }
  }

  // Builds sections for the grouped views (Years, Months, Days)
  List<Widget> _buildGroupedSections() {
    final yearData = {
      '2025': {
        'December': ['01', '02', '05'],
        'November': ['10', '12', '15', '20'],
        'October': ['25', '28'],
      },
    };

    List<Widget> sections = [];

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
                  _buildPhotoGrid(16), 
                ],
              ),
            ),
          );
        });
      } else if (viewMode == 'Months') {
        months.forEach((month, days) {
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
                  _buildPhotoGrid(16),
                ],
              ),
            ),
          );
        });
      } else if (viewMode == 'Days') {
        months.forEach((month, days) {
          for (var day in days) {
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
                    _buildPhotoGrid(8),
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
  Widget _buildPhotoGrid(int count) {
    // Use the reusable PhotoGridPlaceholder
    return PhotoGridPlaceholder(
      itemCount: count,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      borderRadius: 8,
      iconSize: 40,
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