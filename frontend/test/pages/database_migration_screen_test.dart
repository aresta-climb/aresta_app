import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/database_migration_screen.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

// Fake implementation
class FakeSyncService extends Fake implements SyncService {
  bool didSync = false;
  bool shouldFail = false;
  bool shouldBeOffline = false;
  ValueNotifier<SyncStatus> status = ValueNotifier(SyncStatus.updating);

  @override
  ValueNotifier<SyncStatus> get syncStatus => status;

  @override
  Future<List<String>> syncIndex({bool auto = true, bool forceBypassCache = false}) async {
    didSync = true;
    if (shouldBeOffline) {
      status.value = SyncStatus.offline;
      return [];
    } else if (shouldFail) {
      status.value = SyncStatus.error;
      return ['fake_error'];
    } else {
      status.value = SyncStatus.updated;
      return [];
    }
  }

  @override
  Future<void> confirmMigrationComplete() async {}
}

void main() {
  group('DatabaseMigrationScreen Widget Tests', () {
    setUp(() {
      TelemetryService.instance = MockTelemetryService();
    });

    testWidgets('Deve mostrar loader inicialmente e chamar syncIndex', (WidgetTester tester) async {
      final fakeSyncService = FakeSyncService();

      await tester.pumpWidget(
        MaterialApp(
          home: DatabaseMigrationScreen(
            syncService: fakeSyncService,
            onMigrationComplete: () {},
          ),
        ),
      );

      // Deve mostrar CircularProgressIndicator inicialmente
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Atualizando o banco de dados. Isso exigirá internet.'), findsOneWidget);
      
      // Deve ter chamado syncIndex
      expect(fakeSyncService.didSync, isTrue);

      final mockTelemetry = TelemetryService.instance as MockTelemetryService;
      expect(mockTelemetry.recordedEvents.contains('migracao_db'), isTrue);
      expect(mockTelemetry.recordedParams['migracao_db']?['acao'], 'aberta_tela_migracao');
    });

    testWidgets('Deve mostrar erro se syncIndex falhar e permitir Tentar Novamente', (WidgetTester tester) async {
      final fakeSyncService = FakeSyncService()..shouldFail = true;

      await tester.pumpWidget(
        MaterialApp(
          home: DatabaseMigrationScreen(
            syncService: fakeSyncService,
            onMigrationComplete: () {},
          ),
        ),
      );

      // Aguarda a execução do Future no initState
      await tester.pumpAndSettle();

      // Deve mostrar erro
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Não foi possível atualizar o banco de dados. Verifique sua conexão com a internet.'), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);

      // Reset para sucesso
      fakeSyncService.shouldFail = false;
      fakeSyncService.didSync = false;

      // Clica em tentar novamente
      await tester.tap(find.text('Tentar Novamente'));
      await tester.pump(); // Inicia a troca de state
      
      // Pula a animação do Future de sync
      await tester.pump(const Duration(milliseconds: 100));

      final mockTelemetry = TelemetryService.instance as MockTelemetryService;
      expect(mockTelemetry.recordedEvents.contains('migracao_db'), isTrue);
      expect(mockTelemetry.recordedParams['migracao_db']?['acao'], 'tentar_novamente_clicado_tela_migracao');
    });

    testWidgets('Deve mostrar erro se syncIndex retornar SyncStatus.offline (falta de internet)', (WidgetTester tester) async {
      final fakeSyncService = FakeSyncService();
      fakeSyncService.shouldBeOffline = true;

      await tester.pumpWidget(
        MaterialApp(
          home: DatabaseMigrationScreen(
            syncService: fakeSyncService,
            onMigrationComplete: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Não foi possível atualizar o banco de dados. Verifique sua conexão com a internet.'), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);
    });
  });
}
