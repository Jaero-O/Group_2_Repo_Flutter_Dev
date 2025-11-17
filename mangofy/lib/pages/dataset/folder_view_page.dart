import 'package:flutter/material.dart';

/// FolderViewPage – shows images inside the selected folder
class FolderViewPage extends StatelessWidget {
  final String folderName;
  final List<dynamic> images;

  const FolderViewPage({
    super.key,
    required this.folderName,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
        backgroundColor: Colors.green,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final img = images[index];

          return Container(
            color: Colors.green.shade100,
            child: Center(
              child: Text(
                img.toString(),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}