import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mangofy/pages/home/home_page.dart';
import 'package:mangofy/pages/scan/scan_page.dart';
import 'package:mangofy/pages/gallery/gallery_page.dart';
import 'package:mangofy/pages/dataset/dataset_page.dart';
import 'package:mangofy/pages/scanner_page.dart';
import 'splash_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const SplashScreen(
        targetPage: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int navIndex = 0;
  int pageIndex = 0;

  final List<bool> _isPageBuilt = [true, false, false, false];

  static const Color selectedColor = Color(0xFF007700);

  Future<void> _openQrScanner() async {
    final imported = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );

    if (!mounted || imported != true) return;

    setState(() {
      navIndex = 0;
      pageIndex = 0;
      _isPageBuilt[0] = true;
    });
  }

  void _onDestinationSelected(int index) {
    if (index == 2) return; // Spacer slot
    final int nextPageIndex = index > 2 ? index - 1 : index;

    setState(() {
      navIndex = index;
      pageIndex = nextPageIndex;
      _isPageBuilt[nextPageIndex] = true;
    });
  }

  Widget _buildPageAt(int index) {
    if (!_isPageBuilt[index]) {
      return const SizedBox.shrink();
    }

    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const ScanPage();
      case 2:
        return const GalleryPage();
      case 3:
        return const DatasetPage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF555555),
      body: IndexedStack(
        index: pageIndex,
        children: List<Widget>.generate(4, _buildPageAt),
      ),
      bottomNavigationBar: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none, // Allows the button to overflow the top
        children: [
          // 1. The Actual Navigation Bar
          NavigationBar(
            height: 70, // Fixed height for the bar
            backgroundColor: const Color(0xFFFAFAFA),
            selectedIndex: navIndex,
            onDestinationSelected: _onDestinationSelected,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
              (Set<WidgetState> states) {
                final color = states.contains(WidgetState.selected)
                    ? selectedColor
                    : Colors.grey;
                return TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500);
              },
            ),
            destinations: [
              _buildNav('images/home.svg', 'Home'),
              _buildNav('images/clipboard.svg', 'History'),
              
              // 2. Dummy Spacer Destination (index 2)
              const NavigationDestination(
                icon: SizedBox(height: 34),
                label: '',
                enabled: false,
              ),

              _buildNav('images/gallery.svg', 'Gallery'),
              _buildNav('images/database.svg', 'Dataset'),
            ],
          ),

          // 3. The Raised Scan Button
          Positioned(
            top: -25, // This lifts the button higher than the navbar
            child: GestureDetector(
              onTap: _openQrScanner,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFFAFAFA), width: 3), // Optional ring
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'images/qr_code.svg',
                    height: 28,
                    width: 28,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to keep destinations clean
  NavigationDestination _buildNav(String asset, String label) {
    return NavigationDestination(
      icon: SvgPicture.asset(
        asset,
        height: 30,
        width: 30,
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
      ),
      selectedIcon: SvgPicture.asset(
        asset,
        height: 30,
        width: 30,
        colorFilter: const ColorFilter.mode(selectedColor, BlendMode.srcIn),
      ),
      label: label,
    );
  }
}