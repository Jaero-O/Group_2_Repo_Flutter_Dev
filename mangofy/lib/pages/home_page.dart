import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const healthyGradient = LinearGradient(
      colors: [Color(0xFF85D133), Color(0xFF06850C)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    const moderateGradient = LinearGradient(
      colors: [Color(0xFF85D133), Color(0xFFFFCC00)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    const severeGradient = LinearGradient(
      colors: [Color(0xFFFFCC00), Color(0xFFFF0000)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF007700),
                            Color(0xFF238F19),
                            Color(0xFFC9FF8E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 30,
                              top: 20,
                              right: 0,
                              bottom: 20,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '26',
                                      style: GoogleFonts.inter(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                    Text(
                                      'Leaves Scanned',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '1,999',
                                      style: GoogleFonts.inter(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                    Text(
                                      'Healthy Leaves',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '1,999',
                                      style: GoogleFonts.inter(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                    Text(
                                      'Diseased Leaves',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Image.asset(
                              'images/mangoleaves.png',
                              height: 110,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'Recommended Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),

                    Card(
                      color: const Color(0xFFFAFAFA),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          // Donut Chart
                          Positioned(
                            top: 30,
                            right: 20,
                            child: SizedBox(
                              height: 150,
                              width: 150,
                              child: PieChart(
                                PieChartData(
                                  centerSpaceRadius: 50,
                                  sectionsSpace: 1,
                                  sections: [
                                    PieChartSectionData(
                                      value: 75,
                                      color: const Color(0xFF06850C),
                                      radius: 35,
                                      title: '',
                                    ),
                                    PieChartSectionData(
                                      value: 20,
                                      color: const Color(0xFF85D133),
                                      radius: 35,
                                      title: '',
                                    ),
                                    PieChartSectionData(
                                      value: 5,
                                      color: const Color(0xFFA5E358),
                                      radius: 35,
                                      title: '',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 150.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '75%',
                                        style: GoogleFonts.inter(
                                          fontSize: 56,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF06850C),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          'Apply organic fungicide: Use neem oil or sulfur-based spray.',
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
                                const Divider(),
                                _buildActionRow(
                                  percentage: '25%',
                                  color: const Color(0xFF85D133),
                                  description:
                                      'Improve irrigation drainage: Avoid water accumulation near roots.',
                                ),
                                const Divider(),
                                _buildActionRow(
                                  percentage: '5%',
                                  color: const Color(0xFFA5E358),
                                  description:
                                      'Remove infected leaves: Dispose of affected areas properly.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'Severity Distributions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),

                    Card(
                      color: const Color(0xFFFAFAFA),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSeverityBar(
                              label: 'Healthy',
                              percentage: '35%',
                              range: '(0% - 5%)',
                              gradient: healthyGradient,
                            ),
                            _buildSeverityBar(
                              label: 'Moderate',
                              percentage: '20%',
                              range: '(6% - 40%)',
                              gradient: moderateGradient,
                            ),
                            _buildSeverityBar(
                              label: 'Severe',
                              percentage: '45%',
                              range: '(>40%)',
                              gradient: severeGradient,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required String percentage,
    required Color color,
    required String description,
    Color descriptionColor = const Color(0xFF555555),
  }) {
    return Row(
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
              color: descriptionColor,
            ),
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityBar({
    required String label,
    required String percentage,
    required String range,
    required LinearGradient gradient,
  }) {
    final String numericString = percentage.replaceAll(RegExp(r'[^\d.]'), '');
    final double value = double.tryParse(numericString) ?? 0.0;
    final double progressValue = value / 100.0;
    const double radius = 12.0; 

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    range,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF555555),
                    ),
                  ),
                ],
              ),
              
              Text(
                percentage,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF555555),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                Container(height: 16, color: Colors.grey[300]),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progressValue.clamp(0.0, 1.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(gradient: gradient),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
