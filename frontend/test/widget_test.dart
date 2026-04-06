import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/home.dart';

void main() {
  testWidgets('Home page loads test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the HomePage is present.
    expect(find.byType(HomePage), findsOneWidget);
  });
}
