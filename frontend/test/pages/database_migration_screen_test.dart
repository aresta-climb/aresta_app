import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/pages/database_migration_screen.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

class FakeSyncService extends Fake implements SyncService {
  int syncCallCount = 0;
  bool shouldFail = false;
  bool shouldThrow = false;
  bool shouldBeOffline = false;
  bool migrationConfirmed = false;
  ValueNotifier<SyncStatus> status = ValueNotifier(SyncStatus.updating);

  @override
  ValueNotifier<SyncStatus> get syncStatus => status;

  @override
  Future<List<String>> syncIndex({
    bool auto = true,
    bool forceBypassCache = false,
  }) async {
    syncCallCount++;
    if (shouldThrow) {
      throw Exception('Falha inesperada no sync');
    }
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
  Future<void> confirmMigrationComplete() async {
    migrationConfirmed = true;
  }
}

void main() {
  group('DatabaseMigrationScreen Widget Tests', () {
    late FakeSyncService fakeSyncService;
    late StreamController<List<ConnectivityResult>> connectivityController;

    setUp(() {
      TelemetryService.instance = MockTelemetryService();
      fakeSyncService = FakeSyncService();
      connectivityController = StreamController<List<ConnectivityResult>>.broadcast();
    });

    tearDown(() {
      connectivityController.close();
    });

    testWidgets(
      'Deve exibir fases de progresso e mensagem contextual de diagnóstico',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DatabaseMigrationScreen(
              syncService: fakeSyncService,
              connectivityStream: connectivityController.stream,
              onMigrationComplete: () {},
            ),
          ),
        );

        // Deve exibir mensagem contextual clara
        expect(
          find.textContaining('Esta nova versão do aplicativo inclui atualizações'),
          findsOneWidget,
        );

        // Deve ter executado syncIndex e completado com sucesso
        await tester.pumpAndSettle();
        expect(fakeSyncService.syncCallCount, 1);
        expect(fakeSyncService.migrationConfirmed, isTrue);
      },
    );

    testWidgets(
      'Deve exibir mensagem de erro e permitir retentativa manual com botão',
      (WidgetTester tester) async {
        fakeSyncService.shouldFail = true;

        await tester.pumpWidget(
          MaterialApp(
            home: DatabaseMigrationScreen(
              syncService: fakeSyncService,
              connectivityStream: connectivityController.stream,
              onMigrationComplete: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Deve mostrar ícone de erro e botão Tentar Novamente
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Tentar Novamente'), findsOneWidget);
        expect(fakeSyncService.syncCallCount, 1);

        // Ao clicar no botão, tenta novamente com sucesso
        fakeSyncService.shouldFail = false;
        await tester.tap(find.text('Tentar Novamente'));
        await tester.pumpAndSettle();

        expect(fakeSyncService.syncCallCount, 2);
        expect(fakeSyncService.migrationConfirmed, isTrue);
      },
    );

    testWidgets(
      'Deve capturar exceções inesperadas e entrar em estado de erro',
      (WidgetTester tester) async {
        fakeSyncService.shouldThrow = true;

        await tester.pumpWidget(
          MaterialApp(
            home: DatabaseMigrationScreen(
              syncService: fakeSyncService,
              connectivityStream: connectivityController.stream,
              onMigrationComplete: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Tentar Novamente'), findsOneWidget);
      },
    );

    testWidgets(
      'Deve executar auto-retry reativo quando a conexão for restabelecida pelo Connectivity stream',
      (WidgetTester tester) async {
        fakeSyncService.shouldBeOffline = true;

        await tester.pumpWidget(
          MaterialApp(
            home: DatabaseMigrationScreen(
              syncService: fakeSyncService,
              connectivityStream: connectivityController.stream,
              onMigrationComplete: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(fakeSyncService.syncCallCount, 1);
        expect(find.text('Tentar Novamente'), findsOneWidget);

        // Restabelece a conexão de internet via stream
        fakeSyncService.shouldBeOffline = false;
        connectivityController.add([ConnectivityResult.wifi]);

        // Aguarda debounce / execução automática da retentativa
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // O auto-retry deve ter disparado nova tentativa automaticamente
        expect(fakeSyncService.syncCallCount, 2);
        expect(fakeSyncService.migrationConfirmed, isTrue);
      },
    );
  });
}
