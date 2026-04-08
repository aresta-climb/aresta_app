import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/services/dataset_repository.dart';

void main() {
  testWidgets('Home page loads test', (WidgetTester tester) async {

    final testRepo = DatasetRepository();

    // Pass the repo into MyApp
    await tester.pumpWidget(MyApp(datasetRepo: testRepo));

    // Verify that the HomePage is present.
    expect(find.byType(HomePage), findsOneWidget);
  });
}