import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/database_service.dart'; 

class RecommendedActionsCard extends StatelessWidget {
  final ScanSummary summary; 

  const RecommendedActionsCard({super.key, required this.summary});

  // Define a Helper Class to hold Action Data
  static final List<Map<String, dynamic>> _actionDefinitions = [
    {
      'id': 'severe',
      'color': const Color(0xFF06850C),
      'desc': 'Apply organic fungicide: Use neem oil or sulfur-based spray.',
    },
    {
      'id': 'moderate',
      'color': const Color(0xFF85D133),
      'desc': 'Improve irrigation drainage: Avoid water accumulation near roots.',
    },
    {
      'id': 'other',
      'color': const Color(0xFFA5E358),
      'desc': 'Remove infected leaves: Dispose of affected areas properly.',
    },
  ];

  // Helper to build the smaller list rows
  Widget _buildActionRow({
    required String percentage, 
    required Color color, 
    required String description, 
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80.0,
            child: Text(
              percentage,
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF555555),
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalDiseased = summary.moderateCount + summary.severeCount;

    // Calculate Values (Remainder Method) 
    double severeDouble = 0;
    double moderateDouble = 0;
    double otherDouble = 100; // Default if no disease

    int sInt = 0;
    int mInt = 0;
    int oInt = 100;

    if (totalDiseased > 0) {
      // Calculate doubles for the Chart
      severeDouble = (summary.severeCount / totalDiseased) * 100;
      moderateDouble = (summary.moderateCount / totalDiseased) * 100;
      otherDouble = 100 - severeDouble - moderateDouble;

      // Calculate integers for Text
      sInt = severeDouble.round();
      mInt = moderateDouble.round();
      oInt = 100 - sInt - mInt;
      
      // Remainder safety check and 0% rounding adjustment 
      if (oInt < 0) {
         // This ensures the sum is 100% by decrementing the largest percentage
         if (sInt > mInt) sInt += oInt; else mInt += oInt;
         oInt = 0;
      } 
      // If the floating point value was > 0, but integer rounding made it 0,
      // force it to be 1 to ensure it appears on the chart/list .
      else if (oInt == 0 && otherDouble > 0.0) {
          oInt = 1;
          // Decrement the largest existing category to maintain a 100% sum
          if (sInt > mInt) sInt -= 1; else mInt -= 1;
      }
    }

    // Create a list of all three potential actions with their calculated percentages (value)
    final List<Map<String, dynamic>> allActions = [
      {
        ..._actionDefinitions[0], // Severe Action
        // Use the integer value for the display, but the double for sorting and the pie chart
        'value': severeDouble, 
        'display': '$sInt%'    
      },
      {
        ..._actionDefinitions[1], // Moderate Action
        'value': moderateDouble,
        'display': '$mInt%'
      },
      {
        ..._actionDefinitions[2], // Other Action (General)
        // Use the new adjusted integer value for display
        'value': otherDouble,
        'display': '$oInt%'
      },
    ];

    // Filter out actions with 0% and sort the remaining list by 'value' (percentage) 
    // in descending order to make the highest severity the 'heroAction'.
    final List<Map<String, dynamic>> activeActions = allActions
        .where((action) => (action['value'] as double) > 0.0 || (action['display'] != '0%'))
        .toList();
    
    // Sort by the floating point percentage (descending)
    activeActions.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));


    // Handle empty state
    if (activeActions.isEmpty) {
       return const SizedBox.shrink();
    }

    // The first item in filtered list is the highest-percentage action
    final heroAction = activeActions.first;
    // The list rows are the rest
    final listActions = activeActions.skip(1).toList();

    // Prepare Pie Chart Sections based on active items
    final List<PieChartSectionData> pieSections = activeActions.map((action) {
      // Use the integer value for the chart section for perfect alignment with text
      final int chartValue = int.parse((action['display'] as String).replaceAll('%', ''));
      return PieChartSectionData(
        value: chartValue.toDouble(),
        color: action['color'] as Color,
        radius: 35,
        title: '',
      );
    }).toList();


    return Card(
      color: const Color(0xFFFAFAFA), 
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Pie Chart
          Positioned(
            top: 30,
            right: 20,
            child: SizedBox(
              height: 150,
              width: 150,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 50, 
                  sectionsSpace: 2, 
                  sections: pieSections,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HERO SECTION 
                Padding(
                  padding: const EdgeInsets.only(right: 150.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heroAction['display'], 
                        style: GoogleFonts.inter(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: heroAction['color'],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          heroAction['desc'],
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF555555),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (listActions.isNotEmpty) const Divider(height: 32),

                // Lists
                ...listActions.map((action) {
                  return Column(
                    children: [
                      _buildActionRow(
                        percentage: action['display'],
                        color: action['color'],
                        description: action['desc'],
                      ),
                      // Divider 
                      if (action != listActions.last) const Divider(),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}