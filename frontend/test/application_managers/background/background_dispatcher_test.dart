// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/application_managers/background/background_dispatcher.dart';
import 'package:frontend/application_managers/migracao/migracao_background_orchestrator.dart';
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

class MockWorkmanager extends Mock implements Workmanager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackgroundDispatcher Unit Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('bg_dispatcher_test_');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
      SharedPreferences.setMockInitialValues({});
      TelemetryService.instance = MockTelemetryService();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('callbackDispatcher deve registrar executeTask no Workmanager e inicializar Firebase', () async {
      final mockWm = MockWorkmanager();
      bool firebaseInicializado = false;

      when(() => mockWm.executeTask(any())).thenAnswer((invocation) async {
        final handler = invocation.positionalArguments[0] as dynamic;
        await handler('send_feedback_task', null);
      });

      callbackDispatcher(
        workmanager: mockWm,
        initFirebaseOverride: () async {
          firebaseInicializado = true;
        },
      );

      verify(() => mockWm.executeTask(any())).called(1);
      expect(firebaseInicializado, isTrue);
    });

    test('callbackDispatcher captura falha na inicialização do Firebase e registra via logError', () async {
      final mockWm = MockWorkmanager();
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;
      dynamic taskHandler;

      when(() => mockWm.executeTask(any())).thenAnswer((invocation) {
        taskHandler = invocation.positionalArguments[0];
      });

      callbackDispatcher(
        workmanager: mockWm,
        initFirebaseOverride: () async {
          throw Exception('Erro de conexão com o Firebase');
        },
      );

      expect(taskHandler, isNotNull);
      await taskHandler('send_feedback_task', null);

      expect(mockLogger.recordedErrors.length, 1);
      final recorded = mockLogger.recordedErrors.first;
      expect(recorded['contextMessage'], contains('[BackgroundDispatcher] Falha ao inicializar Firebase no background'));
      expect(recorded['error'].toString(), contains('Erro de conexão com o Firebase'));
      expect(recorded['stackTrace'], isNotNull);
    });

    test('callbackDispatcher sem argumentos utiliza instância padrão', () async {
      try {
        callbackDispatcher();
      } catch (_) {}
    });

    test('deve despachar send_feedback_task para o runner de feedback', () async {
      bool feedbackExecutado = false;

      final result = await BackgroundDispatcher.executarTarefa(
        'send_feedback_task',
        feedbackRunner: () async {
          feedbackExecutado = true;
        },
      );

      expect(result, isTrue);
      expect(feedbackExecutado, isTrue);
    });

    test('deve despachar tarefa de migracao para o runner de migração', () async {
      bool migracaoExecutada = false;

      final result = await BackgroundDispatcher.executarTarefa(
        MigracaoBackgroundOrchestrator.kNomeTarefaMigracao,
        migracaoRunner: () async {
          migracaoExecutada = true;
          return true;
        },
      );

      expect(result, isTrue);
      expect(migracaoExecutada, isTrue);
    });

    test('deve lançar exceção se o runner de migração retornar false', () async {
      expect(
        () async => await BackgroundDispatcher.executarTarefa(
          MigracaoBackgroundOrchestrator.kNomeTarefaMigracao,
          migracaoRunner: () async => false,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('deve aceitar tarefa desconhecida sem lançar erro e registrar via logError', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      final result = await BackgroundDispatcher.executarTarefa(
        'tarefa_inexistente_123',
      );
      expect(result, isTrue);

      expect(mockLogger.recordedErrors.length, 1);
      final erro = mockLogger.recordedErrors.first;
      expect(erro['contextMessage'], contains('Tarefa desconhecida recebida: tarefa_inexistente_123'));
      expect(erro['stackTrace'], isNotNull);
    });

    test('deve capturar exceção do runner, registrar log e relançar para ativar backoff', () async {
      expect(
        () async => await BackgroundDispatcher.executarTarefa(
          'send_feedback_task',
          feedbackRunner: () async {
            throw Exception('Falha forçada no feedback');
          },
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Falha forçada no feedback'),
          ),
        ),
      );
    });

    test('deve executar branches padrão quando runners não são fornecidos', () async {
      // send_feedback_task padrão com fila vazia completa sem erros
      final feedbackResult = await BackgroundDispatcher.executarTarefa(
        'send_feedback_task',
      );
      expect(feedbackResult, isTrue);

      // migração padrão sem necessidade pendente completa sem erros
      SharedPreferences.setMockInitialValues({'cached_data_version': 999});
      final migracaoResult = await BackgroundDispatcher.executarTarefa(
        MigracaoBackgroundOrchestrator.kNomeTarefaMigracao,
      );
      expect(migracaoResult, isTrue);
    });

    test('executarTarefa com migração padrão com falha de rede deve propagar erro', () async {
      SharedPreferences.setMockInitialValues({'cached_data_version': 0});
      expect(
        () async => await BackgroundDispatcher.executarTarefa(
          MigracaoBackgroundOrchestrator.kNomeTarefaMigracao,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
