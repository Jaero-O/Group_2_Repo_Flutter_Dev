import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mangofy/home_page.dart';
import 'package:mangofy/scan_page.dart';
import 'package:mangofy/gallery_page.dart';
import 'package:mangofy/dataset_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // title: const Text('Mangofy'),
      ),
      body: pages[currentPage],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPage,
        onDestinationSelected: (int index) {
          setState(() {
            currentPage = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: SvgPicture.asset(
              'images/home.svg',
              height: 34,
              width: 34,
              colorFilter:
                  const ColorFilter.mode(Color(0xFF007700), BlendMode.srcIn),
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: SvgPicture.asset(
              'images/scan.svg',
              height: 34,
              width: 34,
              colorFilter:
                  const ColorFilter.mode(Color(0xFF007700), BlendMode.srcIn),
            ),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: SvgPicture.asset(
              'images/gallery.svg',
              height: 34,
              width: 34,
              colorFilter:
                  const ColorFilter.mode(Color(0xFF007700), BlendMode.srcIn),
            ),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: SvgPicture.asset(
              'images/database.svg',
              height: 34,
              width: 34,
              colorFilter:
                  const ColorFilter.mode(Color(0xFF007700), BlendMode.srcIn),
            ),
            label: 'Dataset',
          ),
        ],
      ),
    );
  }
}
