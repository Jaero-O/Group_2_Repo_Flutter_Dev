import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Mangofy/pages/home/home_page.dart';
import 'package:Mangofy/pages/scan/scan_page.dart';
import 'package:Mangofy/pages/gallery/gallery_page.dart';
import 'package:Mangofy/pages/dataset/dataset_page.dart';
import 'splash_screen.dart'; 

/// Entry point of the application.
void main() {
  runApp(const MyApp());
}

/// Root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), // Base color theme
      ),
      home: const SplashScreen(
        targetPage: MyHomePage(), // Navigate to home page after splash
      ),
    );
  }
}

/// Main home page widget that contains bottom navigation
/// and manages switching between app sections.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPage = 0; // Index of the currently selected page

  /// List of pages corresponding to bottom navigation items
  final List<Widget> pages = const [
    HomePage(),
    ScanPage(),
    GalleryPage(),
    DatasetPage(),
  ];

  static const Color selectedColor = Color(0xFF007700); // Color for selected navigation item

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF555555), // App background color
      body: pages[currentPage], // Display the currently selected page
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFFAFAFA), // Bottom bar background
        selectedIndex: currentPage, // Currently selected index
        onDestinationSelected: (int index) {
          // Update selected page when a navigation item is tapped
          setState(() {
            currentPage = index;
          });
        },
        indicatorColor: Colors.transparent, // Remove default selection indicator
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) {
            // Text style for selected and unselected labels
            final color = states.contains(WidgetState.selected)
                ? selectedColor
                : Colors.grey;
            return TextStyle(color: color);
          },
        ),
        destinations: [
          // Home navigation item
          NavigationDestination(
            icon: SvgPicture.asset(
              'images/home.svg',
              height: 34,
              width: 34,
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
            ),
            selectedIcon: SvgPicture.asset(
              'images/home.svg',
              height: 34,
              width: 34,
              colorFilter: const ColorFilter.mode(
                selectedColor,
                BlendMode.srcIn,
              ),
            ),
            label: 'Home',
          ),

          // Scan navigation item
          NavigationDestination(
            icon: SvgPicture.asset(
              'images/scan.svg',
              height: 34,
              width: 34,
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
            ),
            selectedIcon: SvgPicture.asset(
              'images/scan.svg',
              height: 34,
              width: 34,
              colorFilter: const ColorFilter.mode(
                selectedColor,
                BlendMode.srcIn,
              ),
            ),
            label: 'Scan',
          ),

          // Gallery navigation item
          NavigationDestination(
            icon: SvgPicture.asset(
              'images/gallery.svg',
              height: 34,
              width: 34,
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
            ),
            selectedIcon: SvgPicture.asset(
              'images/gallery.svg',
              height: 34,
              width: 34,
              colorFilter: const ColorFilter.mode(
                selectedColor,
                BlendMode.srcIn,
              ),
            ),
            label: 'Gallery',
          ),

          // Dataset navigation item
          NavigationDestination(
            icon: SvgPicture.asset(
              'images/database.svg',
              height: 34,
              width: 34,
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
            ),
            selectedIcon: SvgPicture.asset(
              'images/database.svg',
              height: 34,
              width: 34,
              colorFilter: const ColorFilter.mode(
                selectedColor,
                BlendMode.srcIn,
              ),
            ),
            label: 'Dataset',
          ),
        ],
      ),
    );
  }
}
