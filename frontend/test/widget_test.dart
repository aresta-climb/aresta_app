import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/sync_service.dart';

void main() {
  testWidgets('Home page loads test', (WidgetTester tester) async {
    // Create repository and sync service instances for testing.
    final testRepo = DatasetRepository();
    final testSync = SyncService(testRepo);
    
    testRepo.activeDataset.value = TopoDataset(
      availablePicos: [],
      downloadedPicos: [],
    );

    // Provide the required dependencies to MainNavigationWrapper
    await tester.pumpWidget(MaterialApp(
      home: MainNavigationWrapper(
        datasetRepo: testRepo,
        syncService: testSync,
      ),
    ));

    // Verify that the HomePage is present within the navigation wrapper.
    expect(find.byType(HomePage), findsOneWidget);
    
    // Verify that the navigation bar labels are present.
    // Use findsWidgets because 'Home' might appear in both the AppBar and BottomNavBar
    expect(find.text('Home'), findsWidgets);
    expect(find.text('GPS'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
  });
}
