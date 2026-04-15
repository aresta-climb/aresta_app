import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/services/dataset_repository.dart';

void main() {
  testWidgets('Home page loads test', (WidgetTester tester) async {
    // Create a repository instance for testing.
    final testRepo = DatasetRepository();
    
    // Manually set a mock state so the UI doesn't get stuck on the loading spinner.
    testRepo.activeDataset.value = TopoDataset(availablePicos: []);

    // We test the MainNavigationWrapper directly
    await tester.pumpWidget(MaterialApp(
      home: MainNavigationWrapper(datasetRepo: testRepo),
    ));

    // Verify that the HomePage is present within the navigation wrapper.
    expect(find.byType(HomePage), findsOneWidget);
    
    // Verify that the navigation bar items are present.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('GPS'), findsWidgets);
    expect(find.text('Explorar'), findsWidgets);
  });
}
