import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mangofy/pages/home_page.dart';
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
      home: const MyHomePage(),
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Image.asset(
          'images/logo.png', 
          height: 150, 
        ),
      ),
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
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) {
            final color = states.contains(WidgetState.selected)
                ? selectedColor 
                : Colors.grey;    

            return TextStyle(
              color: color,
            );
          },
        ),
        destinations: [
          NavigationDestination(
            icon: SvgPicture.asset(
              'images/home.svg',
              height: 34,
              width: 34,
              colorFilter: const ColorFilter.mode(
                Colors.grey,
                BlendMode.srcIn,
              ), 
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