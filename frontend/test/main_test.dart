import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/pages/terms_of_use.dart';

void main() {
  late DatasetRepository mockRepo;
  late SyncService mockSync;
  late EditorDeCroqui mockEditor;

  setUp(() {
    mockEditor = EditorDeCroqui();
    mockRepo = DatasetRepository(editorDeCroqui: mockEditor);
    mockSync = SyncService(mockRepo);
  });

  testWidgets('MyApp shows TermsOfUsePage when acceptedTerms is false', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      datasetRepo: mockRepo,
      syncService: mockSync,
      acceptedTerms: false,
    ));

    expect(find.byType(TermsOfUsePage), findsOneWidget);
    expect(find.byType(TreeNavigationWrapper), findsNothing);
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
