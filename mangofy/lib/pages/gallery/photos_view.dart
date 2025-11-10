import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// REUSABLE COMPONENT: The Photos Grid Content
// -----------------------------------------------------------------------------
// This stateless widget only displays the content, making it reusable 
// with different parents (GalleryPage or DatasetPage).
class PhotoGridContent extends StatelessWidget {
  const PhotoGridContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          '2025',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildMonthSection('November', ['02', '01']),
        _buildMonthSection('October', ['30']),
      ],
    );
  }
  
  // Month/day photo grid logic (extracted from original _PhotosViewState)
  Widget _buildMonthSection(String month, List<String> days) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: days.map((day) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$month $day',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    // NOTE: This is where selection logic would be added if needed,
                    // but for this task, we'll keep it simple and focus on the structure.
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
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ORIGINAL PhotosView: Now acts as a stateful container for the grid and 
// bottom navigation in the main Gallery screen.
// -----------------------------------------------------------------------------
class PhotosView extends StatefulWidget {
  // NEW: Add properties for selection mode if needed for the main Gallery view
  final bool isSelectionMode;
  final Function(List<String>)? onSelectionDone;

  const PhotosView({
    super.key, 
    this.isSelectionMode = false, 
    this.onSelectionDone,
  });

  @override
  State<PhotosView> createState() => _PhotosViewState();
}

class _PhotosViewState extends State<PhotosView> {
  String viewMode = 'Days';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Use the new reusable component
        const Expanded(
          child: PhotoGridContent(),
        ),

        // Bottom Navigation Bar remains here as it's part of the main Gallery UI
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
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
      ],
    );
  }

  // Bottom navigation button (Extracted from old gallery_page.dart)
  Widget _buildBottomButton(String label) {
    final isActive = viewMode == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          viewMode = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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