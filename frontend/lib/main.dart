import 'package:flutter/material.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/pages/browse.dart';

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
        fontFamily: 'Montserrat',
        useMaterial3: true,
      ),
      // Pass the global key to the wrapper
      home: MainNavigationWrapper(key: MainNavigationWrapper.navKey),
    );
  }
}

// -----------------------------------------------------------------------------
// Main Navigation Wrapper
class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  // Global key allows us to access the state of the navigation from other files
  static final GlobalKey<_MainNavigationWrapperState> navKey = GlobalKey<_MainNavigationWrapperState>();

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();

  // Helper method to switch tabs from anywhere
  static void switchTab(int index) {
    navKey.currentState?._onItemTapped(index);
  }
}

//------------------------------------------------------------------------------
class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  // Color pallet
  static const Color nobleBlack = Color(0xFF1F2128);
  static const Color beastHide = Color(0xFFAE8F68);
  static const Color fishBone = Color(0xFFE4DAC5);

  final List<Widget> _pages = [
    const HomePage(),
    const GPSPlaceholder(),
    const BrowsePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: nobleBlack,
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            // Home icon
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            // Gps icon
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_rounded),
              label: 'GPS',
            ),
            // Browse icon
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded),
              label: 'Explorar',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: beastHide,
          unselectedItemColor: fishBone.withValues(alpha: 0.5),
          backgroundColor: nobleBlack,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// TODO: An actual gps page
class GPSPlaceholder extends StatelessWidget {
  const GPSPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    const Color nobleBlack = Color(0xFF1F2128);

    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: AppBar(
        title: const Text(
          'GPS',
          style: TextStyle(
            color: nobleBlack,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFAE8F68),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Funcionalidades GPS em breve',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
