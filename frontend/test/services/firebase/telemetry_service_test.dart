// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../../mocks/mock_app_logger.dart';
import '../../mocks/mock_telemetry_service.dart';

void main() {
  group('TelemetryService Mock Tests', () {
    late MockTelemetryService mockTelemetry;

    setUp(() {
      mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;
    });

    test('logAcaoExplorar', () async {
      await TelemetryService.instance.logAcaoExplorar('crag1', 'baixar');
      expect(mockTelemetry.recordedEvents, contains('acao_explorar'));
      expect(
        mockTelemetry.recordedParams['acao_explorar']!['id_croqui'],
        'crag1',
      );
      expect(mockTelemetry.recordedParams['acao_explorar']!['acao'], 'baixar');
    });

    test('getAppInstanceId retorna valor mockado', () async {
      final appInstanceId = await TelemetryService.instance.getAppInstanceId();
      expect(appInstanceId, 'mock_app_instance_id');
    });

    test('logAtualizarCroqui', () async {
      await TelemetryService.instance.logAtualizarCroqui(
        'crag1',
        'sha123',
        '2026-06-04T10:00:00.000Z',
      );
      expect(mockTelemetry.recordedEvents, contains('atualizar_croqui'));
      expect(
        mockTelemetry.recordedParams['atualizar_croqui']!['id_croqui'],
        'crag1',
      );
      expect(
        mockTelemetry.recordedParams['atualizar_croqui']!['versao'],
        'sha123',
      );
      expect(
        mockTelemetry
            .recordedParams['atualizar_croqui']!['timestamp_atualizacao'],
        '2026-06-04T10:00:00.000Z',
      );
    });

    test('logAcaoCroqui com origem', () async {
      await TelemetryService.instance.logAcaoCroqui(
        'crag1',
        'abrir_croqui',
        origem: 'explorar',
      );
      expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['acao'],
        'abrir_croqui',
      );
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['origem'],
        'explorar',
      );
    });

    test('logAbrirSetor', () async {
      await TelemetryService.instance.logAbrirSetor('crag1', 'Setor 1');
      expect(mockTelemetry.recordedEvents, contains('abrir_setor'));
    });

    test('logAbrirGrupo', () async {
      await TelemetryService.instance.logAbrirGrupo('crag1', 'Grupo 1');
      expect(mockTelemetry.recordedEvents, contains('abrir_grupo'));
    });

    test('logAbrirMapa', () async {
      await TelemetryService.instance.logAbrirMapa('crag1', 'Grupo 1');
      expect(mockTelemetry.recordedEvents, contains('abrir_mapa'));
    });

    test('logAcaoEscalada', () async {
      await TelemetryService.instance.logAcaoEscalada(
        'crag1',
        'Setor 1',
        'Via 1',
        'abrir_detalhes',
        'mapa',
      );
      expect(mockTelemetry.recordedEvents, contains('acao_escalada'));
      expect(
        mockTelemetry.recordedParams['acao_escalada']!['nome_escalada'],
        'Via 1',
      );
      expect(
        mockTelemetry.recordedParams['acao_escalada']!['acao'],
        'abrir_detalhes',
      );
      expect(mockTelemetry.recordedParams['acao_escalada']!['origem'], 'mapa');
    });
  });

  group('TelemetryService Real Instance Tests', () {
    test(
      'Should not throw exception when logging events before Firebase is initialized',
      () async {
        // Reseta para a instância real (que chamaria FirebaseAnalytics internamente)
        TelemetryService.resetForTesting();

        try {
          // Isso normalmente quebraria se Firebase.initializeApp() não tiver terminado,
          // mas o nosso try-catch interno na _logEvent deve absorver graciosamente.
          await TelemetryService.instance.logSincronizarApp(acao: 'automatica');
          // Passou sem quebrar = sucesso
        } catch (e) {
          fail('Should not throw uncaught exception: $e');
        }
      },
    );

    test(
      'Should logError when _logEvent fails',
      () async {
        TelemetryService.resetForTesting();
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        await TelemetryService.instance.logSincronizarApp(acao: 'automatica');

        expect(mockLogger.recordedErrors, isNotEmpty);
        expect(
          mockLogger.recordedErrors.first['contextMessage'],
          '⚠️ [Telemetry] Erro ao enviar evento (Firebase pronto?)',
        );
      },
    );

    test(
      'Should logError and return null when getAppInstanceId fails',
      () async {
        TelemetryService.resetForTesting();
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        final id = await TelemetryService.instance.getAppInstanceId();

        expect(id, isNull);
        expect(mockLogger.recordedErrors, isNotEmpty);
        expect(
          mockLogger.recordedErrors.first['contextMessage'],
          '⚠️ [Telemetry] Erro ao obter appInstanceId',
        );
      },
    );
  });
}
