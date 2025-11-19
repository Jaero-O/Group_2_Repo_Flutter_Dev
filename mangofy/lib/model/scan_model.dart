import 'package:flutter/material.dart';

// Data model for a single scan record.
class ScanRecord {
  final int id;
  final String disease;
  final double severityValue;
  final String date;

  // Calculates the status based on severityValue.
  String get status {
    if (severityValue > 40.0) {
      return 'Severe';
    } else if (severityValue > 5.0) {
      return 'Moderate';
    } else {
      return 'Healthy';
    }
  }

  // Color is based on the determined status.
  Color get primaryColor {
    switch (status.toLowerCase()) {
      case 'healthy':
        return const Color(0xFF4CAF50);
      case 'moderate':
        return const Color(0xFFF2DA00);
      case 'severe':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  // Constructor now only needs the stored data fields
  ScanRecord({
    required this.id,
    required this.disease,
    required this.severityValue,
    required this.date,
  });

  // Factory method to create a ScanRecord from a database map.
  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'] as int,
      disease: map['disease'] as String,
      // Safely converts both int and double to double
      severityValue: map['severity_value'] is int
          ? (map['severity_value'] as int).toDouble()
          : map['severity_value'] as double,
      date: map['date'] as String,
    );
  }

  // New: Converts the ScanRecord object to a map for database insertion/update.
  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'disease': disease,
      'severity_value': severityValue,
      'status': status, 
      'date': date,
    };
  }
}
