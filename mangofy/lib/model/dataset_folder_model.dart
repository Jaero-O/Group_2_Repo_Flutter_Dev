// model/dataset_folder_model.dart

class DatasetFolder {
  final int? id;
  final String name;
  final List<String> images; // List of image IDs/paths
  final String dateCreated;

  DatasetFolder({
    this.id,
    required this.name,
    required this.images,
    required this.dateCreated,
  });

  // Convert a DatasetFolder object into a Map. The keys must correspond to the names
  // of the columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      // Store the list as a comma-separated String in SQLite
      'images': images.join(','), 
      'date_created': dateCreated,
    };
  }

  // Convert a Map (from the database) into a DatasetFolder object.
  static DatasetFolder fromMap(Map<String, dynamic> map) {
    return DatasetFolder(
      id: map['id'] as int?,
      name: map['name'] as String,
      // Parse the comma-separated String back into a List<String>
      images: (map['images'] as String).split(','),
      dateCreated: map['date_created'] as String,
    );
  }
}