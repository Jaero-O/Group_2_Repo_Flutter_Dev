import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/photo.dart';
import '../../services/local_db.dart';
import '../gallery/photo_widgets.dart';

class ScanDetailsPage extends StatelessWidget {
  final String scanTitle;
  final String disease;
  final String dateScanned;
  final String severityValue;
  final Color severityColor;
  final int? photoId;
  final String? localImagePath;
  final String statusLabel;
  final String treeName;
  final String treeLocation;
  final String diseaseDescription;
  final String diseasePrevention;

  const ScanDetailsPage({
    super.key,
    required this.scanTitle,
    required this.disease,
    required this.dateScanned,
    required this.severityValue,
    required this.severityColor,
    this.photoId,
    this.localImagePath,
    this.statusLabel = '',
    this.treeName = '',
    this.treeLocation = '',
    this.diseaseDescription = '',
    this.diseasePrevention = '',
  });

  static const String kLongDescription =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.';

  static const String kRecommendedActions =
      'Apply a broad-spectrum fungicide (such as chlorothalonil or mancozeb) every 7-14 days. Ensure proper tree pruning to improve air circulation and sunlight penetration. Rake and dispose of all fallen infected leaves to reduce the source of fungal spores.';

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF48742C),
                  size: 20,
                ),
                Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF48742C),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              'Scan Details',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildDiseaseTag(String value) {
    final tagBackgroundColor = severityColor.withValues(alpha: 0.2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tagBackgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: severityColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (photoId != null) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: LocalDb.instance.getPhotoById(photoId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data != null) {
            final photo = Photo.fromMap(data);
            return PhotoGridItem(photo: photo, borderRadius: 8);
          }
          return Image.asset(
            'images/leaf.png',
            fit: BoxFit.cover,
            height: 200,
            width: double.infinity,
          );
        },
      );
    }

    final path = localImagePath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          height: 200,
          width: double.infinity,
        );
      }
    }

    return Image.asset(
      'images/leaf.png',
      fit: BoxFit.cover,
      height: 200,
      width: double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayTreeName = treeName.trim();
    final displayTreeLocation = treeLocation.trim();
    final displayTree = displayTreeName.isNotEmpty
        ? (displayTreeLocation.isNotEmpty
            ? '$displayTreeName ($displayTreeLocation)'
            : displayTreeName)
        : (displayTreeLocation.isNotEmpty ? displayTreeLocation : '');
    final displayDescription = diseaseDescription.trim().isNotEmpty
        ? diseaseDescription.trim()
        : kLongDescription;
    final displayPrevention = diseasePrevention.trim().isNotEmpty
        ? diseasePrevention.trim()
        : kRecommendedActions;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomAppBar(context),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 200,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 0.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildImagePreview(),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '$severityValue%',
                                style: GoogleFonts.inter(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: severityColor,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildDiseaseTag(disease),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SEVERITY LEVEL',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (statusLabel.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              statusLabel,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: severityColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          Text(
                            'Description',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayDescription,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Date Scanned',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                dateScanned,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          if (displayTree.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tree',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    displayTree,
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 32),
                          Text(
                            'Recommended Actions',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayPrevention,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
