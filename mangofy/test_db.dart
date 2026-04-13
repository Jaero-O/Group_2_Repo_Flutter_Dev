import 'package:flutter/material.dart';
import 'package:mangofy/services/database_service.dart';
import 'package:mangofy/services/local_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Checking databases...');

  // Check LocalDb scans
  final scans = await LocalDb.instance.getAllScans();
  print('Scans in LocalDb: ${scans.length}');
  if (scans.isNotEmpty) {
    print('  First scan: ${scans.first.id}: ${scans.first.title} - ${scans.first.imagePath}');
    print('  Last scan: ${scans.last.id}: ${scans.last.title} - ${scans.last.imagePath}');
  }

  // Check DatabaseService photos
  final photos = await DatabaseService.instance.getAllPhotos();
  print('Photos in DatabaseService: ${photos.length}');
  if (photos.isNotEmpty) {
    print('  First photo: ${photos.first['name']} - ${photos.first['path']}');
    print('  Last photo: ${photos.last['name']} - ${photos.last['path']}');
  }

  print('Done.');
}