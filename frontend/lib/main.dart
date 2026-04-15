import 'package:flutter/material.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/pages/browse.dart';
import 'package:frontend/pages/gps.dart';
import 'package:frontend/services/dataset_repository.dart';

void main() async {
  // Ensure Flutter bindings are ready before doing file I/O
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate and initialize the repository
  final datasetRepo = DatasetRepository();
  await datasetRepo.initialize();

  // Pass it into the app
  runApp(MyApp(datasetRepo: datasetRepo));
}

class MyApp extends StatelessWidget {
  final DatasetRepository datasetRepo;

  const MyApp({super.key, required this.datasetRepo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kmon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Montserrat',
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      // Pass the repo down to the navigation wrapper
      home: MainNavigationWrapper(
        datasetRepo: datasetRepo,
        key: MainNavigationWrapper.navKey,
      ),
    );
  }
}

/// The main entry point for the app's navigation.
class MainNavigationWrapper extends StatefulWidget {
  final DatasetRepository datasetRepo;

  const MainNavigationWrapper({
    super.key,
    required this.datasetRepo
  });

  static final GlobalKey<_MainNavigationWrapperState> navKey = GlobalKey<_MainNavigationWrapperState>();

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();

  /// Switches the active tab of the MainNavigationWrapper.
  static void switchTab(int index) {
    navKey.currentState?._onItemTapped(index);
  }
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  static const Color nobleBlack = Color(0xFF1F2128);
  static const Color beastHide = Color(0xFFAE8F68);
  static const Color fishBone = Color(0xFFE4DAC5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomePageWrapper(
            datasetRepo: widget.datasetRepo,
            onSwitchTab: _onItemTapped,
          ),
          _GPSPageWrapper(datasetRepo: widget.datasetRepo),
          _BrowsePageWrapper(datasetRepo: widget.datasetRepo),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: nobleBlack,
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_rounded),
              label: 'GPS',
            ),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _HomePageWrapper extends StatelessWidget {
  final DatasetRepository datasetRepo;
  final Function(int) onSwitchTab;
  
  const _HomePageWrapper({
    required this.datasetRepo,
    required this.onSwitchTab
  });

  @override
  Widget build(BuildContext context) => HomePage(
    datasetRepo: datasetRepo,
    onSwitchTab: onSwitchTab,
  );
}

class _GPSPageWrapper extends StatelessWidget {
  final DatasetRepository datasetRepo;
  const _GPSPageWrapper({required this.datasetRepo});
  @override Widget build(BuildContext context) => GPSPage(datasetRepo: datasetRepo);
}

class _BrowsePageWrapper extends StatelessWidget {
  final DatasetRepository datasetRepo;
  const _BrowsePageWrapper({required this.datasetRepo});
  @override Widget build(BuildContext context) => BrowsePage(datasetRepo: datasetRepo);
}
