import 'package:flutter/material.dart';

// Widget that displays a grid or list of photos depending on the view mode.
// Supports four view modes:
// - "All Photos": simple grid of 40 placeholder images
// - "Years": grouped by year -> month -> photo grid
// - "Months": grouped by month -> photo grid
// - "Days": grouped by day -> photo grid
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
      return GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 40,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.image,
              color: Colors.grey,
              size: 40,
            ),
          );
        },
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
    // Sample structured data: year -> month -> days
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
        // Year heading
        sections.add(
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 10, bottom: 12),
            child: Text(
              year,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        );
        // Month headings with photo grids
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
        // Month headings with year, then photo grids
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
        // Day-level sections with photo grids
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // allow parent ListView scrolling
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.photo,
            color: Colors.grey,
            size: 40,
          ),
        );
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
                color: Colors.white.withAlpha(217),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          color: isActive ? Colors.green[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.green : Colors.black54,
          ),
        ),
      ),
    );
  }
}
