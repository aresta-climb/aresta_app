// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/http/servico_download_segundo_plano.dart';
import 'package:frontend/services/notificacoes/gerenciador_notificacao_download.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../../mocks/mock_app_logger.dart';

class MockSyncService extends Mock implements SyncService {}

class MockGerenciadorNotificacaoDownload extends Mock
    implements GerenciadorNotificacaoDownload {}

void main() {
  setUpAll(() {
    registerFallbackValue(ResumoCroqui());
  });

  group('ServicoDownloadSegundoPlano com GerenciadorNotificacaoDownload', () {
    late MockSyncService mockSyncService;
    late MockGerenciadorNotificacaoDownload mockNotificador;
    late MockAppLogger mockLogger;
    late ServicoDownloadSegundoPlano servico;
    late ValueNotifier<Map<String, double>> downloadingCragsNotifier;

    setUp(() {
      mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;
      mockSyncService = MockSyncService();
      mockNotificador = MockGerenciadorNotificacaoDownload();
      downloadingCragsNotifier = ValueNotifier({});

      when(() => mockSyncService.downloadingCrags)
          .thenReturn(downloadingCragsNotifier);

      when(() => mockNotificador.solicitarPermissoes())
          .thenAnswer((_) async => true);
      when(() => mockNotificador.atualizarProgresso(any(), any(), any()))
          .thenAnswer((_) async {});
      when(() => mockNotificador.notificarConclusao(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockNotificador.notificarFalha(any(), any(), any()))
          .thenAnswer((_) async {});

      servico = ServicoDownloadSegundoPlano(
        syncService: mockSyncService,
        gerenciadorNotificacao: mockNotificador,
      );
    });

    test('executarDownload solicita permissões, executa download e notifica conclusão', () async {
      final resumo = ResumoCroqui(id: 'crag_1', nome: 'Pedra Grande');

      when(() => mockSyncService.downloadCrag(any())).thenAnswer((_) async {
        downloadingCragsNotifier.value = {'crag_1': 0.5};
        return true;
      });

      final sucesso = await servico.executarDownload(resumo);

      expect(sucesso, isTrue);
      verify(() => mockNotificador.solicitarPermissoes()).called(1);
      verify(() => mockSyncService.downloadCrag(resumo)).called(1);
      verify(() => mockNotificador.atualizarProgresso('crag_1', 'Pedra Grande', 0.5)).called(1);
      verify(() => mockNotificador.notificarConclusao('crag_1', 'Pedra Grande')).called(1);
    });

    test('executarDownload notifica falha e registra crash quando syncService retorna false', () async {
      final resumo = ResumoCroqui(id: 'crag_2', nome: 'Falha Baú');

      when(() => mockSyncService.downloadCrag(any())).thenAnswer((_) async => false);

      final sucesso = await servico.executarDownload(resumo);

      expect(sucesso, isFalse);
      verify(() => mockNotificador.solicitarPermissoes()).called(1);
      verify(() => mockNotificador.notificarFalha('crag_2', 'Falha Baú', any())).called(1);

      final crashErrors = mockLogger.recordedErrors.where((e) => e['fatal'] == true).toList();
      expect(crashErrors, isNotEmpty);
      expect(crashErrors.first['contextMessage'], contains('crag_2'));
    });

    test('executarDownload captura exceção de rede e registra como logAviso sem abrir issue fatal', () async {
      final resumo = ResumoCroqui(id: 'crag_3', nome: 'Erro Rede');

      when(() => mockSyncService.downloadCrag(any())).thenThrow(Exception('Falha de rede'));

      final sucesso = await servico.executarDownload(resumo);

      expect(sucesso, isFalse);
      verify(() => mockNotificador.notificarFalha('crag_3', 'Erro Rede', any())).called(1);

      // Não deve ter gerado erro no recordedErrors, pois falhas de rede viram avisos contextuais (breadcrumbs)
      expect(mockLogger.recordedErrors, isEmpty);

      // Deve ter sido registrado como aviso
      expect(mockLogger.recordedWarnings, isNotEmpty);
      expect(mockLogger.recordedWarnings.first, contains('crag_3'));
    });

    test('executarDownload captura erro de integridade e DEVE gerar crash fatal', () async {
      final resumo = ResumoCroqui(id: 'crag_4', nome: 'Erro Hash');

      when(() => mockSyncService.downloadCrag(any()))
          .thenThrow(Exception('Checksum SHA-256 mismatch'));

      final sucesso = await servico.executarDownload(resumo);

      expect(sucesso, isFalse);
      verify(() => mockNotificador.notificarFalha('crag_4', 'Erro Hash', any())).called(1);

      final crashErrors = mockLogger.recordedErrors.where((e) => e['fatal'] == true).toList();
      expect(crashErrors, isNotEmpty);
      expect(crashErrors.first['contextMessage'], contains('crag_4'));
    });
  });
}
