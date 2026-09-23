// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/view_functions/pico_functions.dart';
import 'package:frontend/view_functions/via_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  test('Pico functions should dispatch logAbrirSetor', () {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    TelemetryService.instance.logAbrirSetor('crag1', 'Setor 1');
    expect(mockTelemetry.recordedEvents, contains('abrir_setor'));
    expect(
      mockTelemetry.recordedParams['abrir_setor']!['nome_setor'],
      'Setor 1',
    );
  });

  test('Pico functions should dispatch logAbrirGrupo', () {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    TelemetryService.instance.logAbrirGrupo('crag1', 'Grupo 1');
    expect(mockTelemetry.recordedEvents, contains('abrir_grupo'));
    expect(
      mockTelemetry.recordedParams['abrir_grupo']!['nome_grupo'],
      'Grupo 1',
    );
  });

  test(
    'Pico functions should dispatch logAcaoCroqui when a generic button is tapped',
    () {
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      TelemetryService.instance.logAcaoCroqui('crag1', 'Sobre o Pico');
      expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['acao'],
        'Sobre o Pico',
      );
    },
  );

  test(
    'PicoSearchDelegate fetches setores and escaladas and sets correct label',
    () {
      final pico = Pico()
        ..setoresOuGrupos.add(
          SetorOuGrupo()
            ..setor = (ArquivoSetor()
              ..conteudo = (Setor()
                ..nome = 'Setor A'
                ..escaladas.add(
                  Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via 1'),
                ))),
        );

      final delegate = PicoSearchDelegate(pico, 'crag1');

      expect(delegate.allEscaladas.length, 1);
      expect(getEscaladaNome(delegate.allEscaladas.first), 'Via 1');

      expect(delegate.allSetores.length, 1);
      expect(delegate.allSetores.first.nome, 'Setor A');

      expect(delegate.searchFieldLabel, 'Buscar escalada (ex: 7a) ou setor...');
    },
  );

  group('formatarTextoUltimaAtualizacao', () {
    test('retorna "Última atualização: Não informada" quando a data é nula', () {
      expect(
        formatarTextoUltimaAtualizacao(null),
        'Última atualização: Não informada',
      );
    });

    test('retorna "Última atualização: Hoje às HH:mm" para data de hoje', () {
      final now = DateTime.now();
      final hoje = DateTime(now.year, now.month, now.day, 14, 30);
      expect(
        formatarTextoUltimaAtualizacao(hoje),
        'Última atualização: Hoje às 14:30',
      );
    });

    test('retorna "Última atualização: Ontem às HH:mm" para data de ontem', () {
      final now = DateTime.now();
      final ontem = DateTime(now.year, now.month, now.day, 9, 15).subtract(const Duration(days: 1));
      expect(
        formatarTextoUltimaAtualizacao(ontem),
        'Última atualização: Ontem às 09:15',
      );
    });

    test('retorna formato DD/MM/YYYY às HH:mm para datas anteriores', () {
      final dataPassada = DateTime(2026, 9, 18, 1, 54);
      expect(
        formatarTextoUltimaAtualizacao(dataPassada),
        'Última atualização: 18/09/2026 às 01:54',
      );
    });
  });
}

