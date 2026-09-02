// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/http/servico_download_segundo_plano.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/services/http/sync_service.dart';

class MockSyncService extends Mock implements SyncService {}

void main() {
  setUpAll(() {
    registerFallbackValue(ResumoCroqui());
  });

  group('ServicoDownloadSegundoPlano', () {
    late MockSyncService mockSyncService;
    late ServicoDownloadSegundoPlano servico;

    setUp(() {
      mockSyncService = MockSyncService();
      servico = ServicoDownloadSegundoPlano(syncService: mockSyncService);
    });

    test('enfileirarDownload adiciona item e dispara download no syncService', () async {
      final resumo = ResumoCroqui(id: 'crag_1', nome: 'Pedra Grande');

      when(() => mockSyncService.downloadCrag(any())).thenAnswer((_) async => true);

      final sucesso = await servico.executarDownload(resumo);

      expect(sucesso, isTrue);
      verify(() => mockSyncService.downloadCrag(resumo)).called(1);
    });

    test('retorna false e registra falha quando syncService falha', () async {
      final resumo = ResumoCroqui(id: 'crag_2', nome: 'Falha Baú');

      when(() => mockSyncService.downloadCrag(any())).thenAnswer((_) async => false);

      final sucesso = await servico.executarDownload(resumo);

      expect(sucesso, isFalse);
    });
  });
}
