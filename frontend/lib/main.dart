import 'package:flutter/material.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/pages/browse.dart';
import 'package:frontend/pages/gps.dart';
import 'package:frontend/functions/common_functions.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/sync_service.dart';

void main() async {
  // Garante que o Flutter esteja pronto antes de fazer I/O de arquivo
  WidgetsFlutterBinding.ensureInitialized();

  // Instancia e inicializa o repositório
  final datasetRepo = DatasetRepository();
  final syncService = SyncService(datasetRepo);
  
  // Sincronização inicial na inicialização
  syncService.syncOnLaunch();

  // Passa isso para o aplicativo
  runApp(MyApp(datasetRepo: datasetRepo, syncService: syncService));
}

class MyApp extends StatelessWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;

  const MyApp({
    super.key, 
    required this.datasetRepo,
    required this.syncService,
  });

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
      // Passa o repositório e o serviço de sincronização para o wrapper de navegação
      home: MainNavigationWrapper(
        datasetRepo: datasetRepo,
        syncService: syncService,
        key: MainNavigationWrapper.navKey,
      ),
    );
  }
}

/// O ponto de entrada principal para a navegação do aplicativo.
class MainNavigationWrapper extends StatefulWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;

  const MainNavigationWrapper({
    super.key,
    required this.datasetRepo,
    required this.syncService,
  });

  static final GlobalKey<_MainNavigationWrapperState> navKey = GlobalKey<_MainNavigationWrapperState>();

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();

  /// Alterna a aba ativa do MainNavigationWrapper.
  static void switchTab(int index) {
    navKey.currentState?._onItemTapped(index);
  }
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomePageWrapper(
            datasetRepo: widget.datasetRepo,
            syncService: widget.syncService,
            onSwitchTab: _onItemTapped,
          ),
          _GPSPageWrapper(datasetRepo: widget.datasetRepo),
          _BrowsePageWrapper(datasetRepo: widget.datasetRepo),
        ],
      ),
      bottomNavigationBar: buildPrimaryBottomNav(context, _selectedIndex, _onItemTapped),
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
  final SyncService syncService;
  final Function(int) onSwitchTab;
  
  const _HomePageWrapper({
    required this.datasetRepo,
    required this.syncService,
    required this.onSwitchTab
  });

  @override
  Widget build(BuildContext context) => HomePage(
    datasetRepo: datasetRepo,
    syncService: syncService,
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
