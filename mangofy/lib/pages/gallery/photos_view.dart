import 'package:flutter/material.dart';

class PhotoGridContent extends StatelessWidget {
  final String viewMode;

  const PhotoGridContent({
    super.key,
    this.viewMode = 'All Photos',
  });

  @override
  Widget build(BuildContext context) {
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
      return ListView(
        padding: const EdgeInsets.all(12),
        children: _buildGroupedSections(),
      );
    }
  }

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
                    style:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildPhotoGrid(int count) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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

class PhotosView extends StatefulWidget {
  const PhotosView({super.key});

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
          child: PhotoGridContent(viewMode: viewMode),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 217) ,
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