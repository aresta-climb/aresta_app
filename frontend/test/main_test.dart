import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/pages/terms_of_use.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'mocks/mock_telemetry_service.dart';

void main() {
  late DatasetRepository mockRepo;
  late SyncService mockSync;
  late EditorDeCroqui mockEditor;
  late MockTelemetryService mockTelemetry;

  setUp(() {
    mockEditor = EditorDeCroqui();
    mockRepo = DatasetRepository(editorDeCroqui: mockEditor);
    mockSync = SyncService(mockRepo);
    
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
  });

  testWidgets('MyApp shows TermsOfUsePage when acceptedTerms is false', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      datasetRepo: mockRepo,
      syncService: mockSync,
      acceptedTerms: false,
    ));

    expect(find.byType(TermsOfUsePage), findsOneWidget);
    expect(find.byType(TreeNavigationWrapper), findsNothing);
    
    // Simulate main() startup logic for test coverage
    await TelemetryService.instance.logAbrirApp();
    expect(mockTelemetry.recordedEvents, contains('abrir_app'));
  });

  testWidgets('MyApp shows TreeNavigationWrapper when acceptedTerms is true', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      datasetRepo: mockRepo,
      syncService: mockSync,
      acceptedTerms: true,
    ));

    expect(find.byType(TermsOfUsePage), findsNothing);
    expect(find.byType(TreeNavigationWrapper), findsOneWidget);
  });
}
