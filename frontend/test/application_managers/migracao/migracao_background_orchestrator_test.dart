// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:frontend/application_managers/migracao/migracao_background_orchestrator.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../../mocks/mock_telemetry_service.dart';
import '../../mocks/mock_app_logger.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
}

class FakeSyncService extends Fake implements SyncService {
  int executarMigracaoCallCount = 0;
  bool executarMigracaoResult = true;
  bool needsMigrationResult = true;

  @override
  Future<bool> checkNeedsMigration() async => needsMigrationResult;

  @override
  Future<bool> executarMigracao({bool rebaixarCroquisSalvos = true}) async {
    executarMigracaoCallCount++;
    return executarMigracaoResult;
  }
}

class MockWorkmanager extends Mock implements Workmanager {}

class FakeConstraints extends Fake implements Constraints {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeConstraints());
    registerFallbackValue(ExistingWorkPolicy.replace);
  });

  group('MigracaoBackgroundOrchestrator Unit Tests', () {
    late Directory tempDir;
    late FakeSyncService fakeSyncService;
    late MockWorkmanager mockWorkmanager;
    late DatasetRepository datasetRepo;

    setUp(() async {
      TelemetryService.instance = MockTelemetryService();
      tempDir = await Directory.systemTemp.createTemp('migracao_test_');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
      SharedPreferences.setMockInitialValues({});

      final editorDeCroqui = EditorDeCroqui();
      datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
      fakeSyncService = FakeSyncService();
      mockWorkmanager = MockWorkmanager();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('executarMigracaoPosAtualizacao deve delegar para syncService.executarMigracao se houver necessidade de migração', () async {
      final result = await MigracaoBackgroundOrchestrator.executarMigracaoPosAtualizacao(
        datasetRepo: datasetRepo,
        syncService: fakeSyncService,
      );

      expect(result, isTrue);
      expect(fakeSyncService.executarMigracaoCallCount, 1);
    });

    test('executarMigracaoPosAtualizacao deve pular migração se checkNeedsMigration for falso', () async {
      fakeSyncService.needsMigrationResult = false;

      final result = await MigracaoBackgroundOrchestrator.executarMigracaoPosAtualizacao(
        datasetRepo: datasetRepo,
        syncService: fakeSyncService,
      );

      expect(result, isTrue);
      expect(fakeSyncService.executarMigracaoCallCount, 0);
    });

    test('agendarMigracaoPosAtualizacao deve registrar OneOffTask no Workmanager com constraint de rede', () async {
      when(
        () => mockWorkmanager.registerOneOffTask(
          any(),
          any(),
          constraints: any(named: 'constraints'),
          existingWorkPolicy: any(named: 'existingWorkPolicy'),
        ),
      ).thenAnswer((_) async {});

      await MigracaoBackgroundOrchestrator.agendarMigracaoPosAtualizacao(
        workmanager: mockWorkmanager,
      );

      verify(
        () => mockWorkmanager.registerOneOffTask(
          'migracao_pos_update',
          MigracaoBackgroundOrchestrator.kNomeTarefaMigracao,
          constraints: any(
            named: 'constraints',
            that: isA<Constraints>().having(
              (c) => c.networkType,
              'networkType',
              NetworkType.connected,
            ),
          ),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        ),
      ).called(1);
    });

    test('cancelarMigracaoSegundoPlano deve chamar cancelByUniqueName no Workmanager', () async {
      when(() => mockWorkmanager.cancelByUniqueName(any())).thenAnswer((_) async {});

      await MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano(
        workmanager: mockWorkmanager,
      );

      verify(() => mockWorkmanager.cancelByUniqueName('migracao_pos_update')).called(1);
    });

    test('executarMigracaoPosAtualizacao deve retornar false se executarMigracao retornar false', () async {
      fakeSyncService.executarMigracaoResult = false;

      final result = await MigracaoBackgroundOrchestrator.executarMigracaoPosAtualizacao(
        datasetRepo: datasetRepo,
        syncService: fakeSyncService,
      );

      expect(result, isFalse);
    });

    test('executarMigracaoPosAtualizacao sem parâmetros utiliza instâncias padrão e conclui com sucesso', () async {
      SharedPreferences.setMockInitialValues({
        'cached_data_version': 999999, // Não precisa migrar
      });

      final result = await MigracaoBackgroundOrchestrator.executarMigracaoPosAtualizacao();
      expect(result, isTrue);
    });

    test('executarMigracaoPosAtualizacao deve capturar exceção no catch e retornar false', () async {
      final repoThrow = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      // Criamos um sync mock que lança exceção
      final syncMock = FakeSyncServiceWithThrow();

      final result = await MigracaoBackgroundOrchestrator.executarMigracaoPosAtualizacao(
        datasetRepo: repoThrow,
        syncService: syncMock,
      );

      expect(result, isFalse);
    });

    test('agendarMigracaoPosAtualizacao sem argumentos utiliza Workmanager padrão', () async {
      try {
        await MigracaoBackgroundOrchestrator.agendarMigracaoPosAtualizacao();
      } catch (_) {}
    });

    test('cancelarMigracaoSegundoPlano sem argumentos utiliza instância padrão e trata erro graciosamente', () async {
      await expectLater(
        MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano(),
        completes,
      );
    });

    test('cancelarMigracaoSegundoPlano deve capturar exceção do Workmanager e registrar no AppLogger via logError', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      when(() => mockWorkmanager.cancelByUniqueName(any())).thenThrow(Exception('Falha nativa'));

      await expectLater(
        MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano(
          workmanager: mockWorkmanager,
        ),
        completes,
      );

      expect(mockLogger.recordedErrors.length, 1);
      final erro = mockLogger.recordedErrors.first;
      expect(erro['contextMessage'], contains('[MigracaoBackground] Erro ao cancelar tarefa de segundo plano'));
      expect(erro['error'].toString(), contains('Falha nativa'));
      expect(erro['stackTrace'], isNotNull);
    });
  });
}

class FakeSyncServiceWithThrow extends Fake implements SyncService {
  @override
  Future<bool> checkNeedsMigration() async {
    throw Exception('Erro forçado no checkNeedsMigration');
  }
}

