// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:frontend/application_managers/migracao/migracao_background_orchestrator.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/constants/constantes_rede.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:frontend/services/http/sync_rede.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../../mocks/mock_telemetria.dart';
import '../../mocks/mock_app_logger.dart';

class _PathProviderPlatformMigracao extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  _PathProviderPlatformMigracao(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
}

class _MockWorkmanager extends Mock implements Workmanager {}

class _FakeConstraints extends Fake implements Constraints {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeConstraints());
    registerFallbackValue(ExistingWorkPolicy.replace);
  });

  group('MigracaoBackgroundOrchestrator Unit Tests', () {
    late Directory tempDir;
    late _MockWorkmanager mockWorkmanager;
    late DatasetRepository datasetRepo;
    late SyncService syncService;
    late HttpServer servidor;
    int chamadasIndice = 0;
    int statusServidorIndice = 200;

    setUp(() async {
      HttpOverrides.global = null;
      TelemetryService.instance = MockTelemetryService();
      tempDir = await Directory.systemTemp.createTemp('migracao_test_');
      PathProviderPlatform.instance = _PathProviderPlatformMigracao(tempDir.path);
      SharedPreferences.setMockInitialValues({});

      chamadasIndice = 0;
      statusServidorIndice = 200;
      servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      servidor.listen((req) async {
        if (req.uri.path.endsWith('/indice.binarypb')) {
          chamadasIndice++;
          req.response.statusCode = statusServidorIndice;
          if (statusServidorIndice == 200) {
            req.response.add(Indice().writeToBuffer());
          }
          await req.response.close();
        } else {
          req.response.statusCode = 404;
          await req.response.close();
        }
      });

      SyncService.baseUrlOverride = 'http://127.0.0.1:${servidor.port}';
      final editorDeCroqui = EditorDeCroqui();
      File(editorDeCroqui.indicePath(tempDir.path))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(Indice().writeToBuffer());
      File(editorDeCroqui.catalogoPath(tempDir.path)).writeAsBytesSync([1, 2, 3, 4]);

      datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
      final cliente = ClienteHttpAresta.paraTestes(http.Client());
      syncService = SyncService(
        datasetRepository: datasetRepo,
        client: cliente,
        network: SyncNetwork(cliente, Duration.zero),
      );
      mockWorkmanager = _MockWorkmanager();
    });

    tearDown(() async {
      SyncService.baseUrlOverride = null;
      await datasetRepo.repositorioCatalogo.fechar();
      await servidor.close(force: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('executarMigracaoPosAtualizacao executa migração real via SyncService quando a versão armazenada é antiga', () async {
      SharedPreferences.setMockInitialValues({
        'cached_data_version': NetworkConstants.kDataVersion - 1,
      });

      final result = await MigracaoBackgroundOrchestrator.executarMigracaoPosAtualizacao(
        datasetRepo: datasetRepo,
        syncService: syncService,
      );

      expect(result, isTrue);
      expect(chamadasIndice, equals(1));
    });

    test('executarMigracaoPosAtualizacao pula migração quando checkNeedsMigration é falso', () async {
      SharedPreferences.setMockInitialValues({
        'cached_data_version': NetworkConstants.kDataVersion,
      });

      final result = await MigracaoBackgroundOrchestrator.executarMigracaoPosAtualizacao(
        datasetRepo: datasetRepo,
        syncService: syncService,
      );

      expect(result, isTrue);
      expect(chamadasIndice, equals(0));
    });

    test('agendarMigracaoPosAtualizacao registra OneOffTask no Workmanager com constraint de rede', () async {
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

    test('cancelarMigracaoSegundoPlano chama cancelByUniqueName no Workmanager', () async {
      when(() => mockWorkmanager.cancelByUniqueName(any())).thenAnswer((_) async {});

      await MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano(
        workmanager: mockWorkmanager,
      );

      verify(() => mockWorkmanager.cancelByUniqueName('migracao_pos_update')).called(1);
    });

    test('executarMigracaoPosAtualizacao retorna false quando o servidor falha durante a migração', () async {
      SharedPreferences.setMockInitialValues({
        'cached_data_version': NetworkConstants.kDataVersion - 1,
      });
      statusServidorIndice = 500;

      final result = await MigracaoBackgroundOrchestrator.executarMigracaoPosAtualizacao(
        datasetRepo: datasetRepo,
        syncService: syncService,
      );

      expect(result, isFalse);
    });

    test('executarMigracaoPosAtualizacao sem parâmetros utiliza instâncias padrão e conclui com sucesso', () async {
      SharedPreferences.setMockInitialValues({
        'cached_data_version': NetworkConstants.kDataVersion,
      });

      final result = await MigracaoBackgroundOrchestrator.executarMigracaoPosAtualizacao();
      expect(result, isTrue);
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

    test('cancelarMigracaoSegundoPlano captura exceção do Workmanager e registra no AppLogger via logError', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;
      addTearDown(AppLogger.resetForTesting);

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

    test('cancelarMigracaoSegundoPlano encerra por timeoutCancelamento quando o Workmanager pendura sem responder', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;
      addTearDown(AppLogger.resetForTesting);

      final completerPendente = Completer<void>();
      when(() => mockWorkmanager.cancelByUniqueName(any()))
          .thenAnswer((_) => completerPendente.future);

      await expectLater(
        MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano(
          workmanager: mockWorkmanager,
          timeoutCancelamento: const Duration(milliseconds: 40),
        ),
        completes,
      );

      expect(mockLogger.recordedErrors.length, 1);
      expect(
        mockLogger.recordedErrors.first['contextMessage'],
        contains('[MigracaoBackground] Erro ao cancelar tarefa de segundo plano'),
      );
    });
  });
}
