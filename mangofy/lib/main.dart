import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mangofy/pages/home/home_page.dart';
import 'package:mangofy/pages/scan/scan_page.dart';
import 'package:mangofy/pages/gallery/gallery_page.dart';
import 'package:mangofy/pages/dataset/dataset_page.dart';

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
      home: const SplashScreen(), // 👈 Start with splash screen
    );
  }
}

/// 🌿 Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MyHomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset('images/logo.png', width: 160, height: 160),
        ),
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
  int currentPage = 0;

  final List<Widget> pages = const [
    HomePage(),
    ScanPage(),
    GalleryPage(),
    DatasetPage(),
  ];

  static const Color selectedColor = Color(0xFF007700);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF555555),
      body: pages[currentPage],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFFAFAFA),
        selectedIndex: currentPage,
        onDestinationSelected: (int index) {
          setState(() {
            currentPage = index;
          });
        },
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
          Set<WidgetState> states,
        ) {
          final color = states.contains(WidgetState.selected)
              ? selectedColor
              : Colors.grey;
          return TextStyle(color: color);
        }),
        destinations: [
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
