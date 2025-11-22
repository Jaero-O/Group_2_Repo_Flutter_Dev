// my_tree_model.dart

class MyTree {
  final int? id; 
  final String title;
  final String location;
  final List<String> images; // List of image IDs (stored as String in DB)
  final String coverImage;

  MyTree({
    this.id,
    required this.title,
    this.location = '',
    required this.images,
    this.coverImage = 'images/leaf.png',
  });

  /// Factory method to create a MyTree object from a database Map.
  factory MyTree.fromMap(Map<String, dynamic> map) {
    // Convert the comma-separated string back to a List<String>
    final String imagesString = map['images'] as String? ?? '';
    final List<String> imageList = 
        imagesString.isEmpty ? [] : imagesString.split(',');
        
    return MyTree(
      id: map['id'] as int?,
      title: map['title'] as String,
      location: map['location'] as String? ?? '',
      images: imageList,
      coverImage: map['cover_image'] as String? ?? 'images/leaf.png',
    );
  }

  /// Method to convert a MyTree object to a database Map for insertion/update.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'location': location,
      // Convert List<String> to a comma-separated string for storage
      'images': images.join(','), 
      'cover_image': coverImage,
    };
  }
}