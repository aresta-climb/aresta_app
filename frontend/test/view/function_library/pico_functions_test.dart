// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/performance_telemetria.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/view/function_library/pico_functions.dart';
import 'package:frontend/view/function_library/setor_functions.dart';
import 'package:frontend/view/function_library/via_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import '../../mocks/mock_telemetria.dart';

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

  testWidgets(
    'buildSectorTile, buildGrupoTile e buildSetorBody registram trace navegacao_interna_croqui ao tocar em setor, grupo e via',
    (tester) async {
      ServicoPerformance.resetarParaTestes();
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      final via = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Via Perf 1');
      final setor = Setor()
        ..nome = 'Setor Perf'
        ..escaladas.add(via);
      final grupo = Grupo()..nome = 'Grupo Perf';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => SingleChildScrollView(
                child: Column(
                  children: [
                    buildSectorTile(context, setor, 'crag_perf'),
                    buildGrupoTile(context, grupo, 'crag_perf'),
                    buildSetorBody(context, setor, 'crag_perf', [via]),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Setor Perf').first);
      await tester.pump();

      final traceSetor = ServicoPerformance.instancia.tracesRegistradas
          .where((t) => t.nome == 'navegacao_interna_croqui')
          .last;
      expect(traceSetor.atributos['destino'], equals('setor'));
      expect(mockTelemetry.recordedParams['abrir_setor']!['duracao_ms'], isA<int>());

      await tester.tap(find.text('Grupo Perf').first);
      await tester.pump();

      final traceGrupo = ServicoPerformance.instancia.tracesRegistradas
          .where((t) => t.nome == 'navegacao_interna_croqui')
          .last;
      expect(traceGrupo.atributos['destino'], equals('grupo'));
      expect(mockTelemetry.recordedParams['abrir_grupo']!['duracao_ms'], isA<int>());

      await tester.tap(find.text('Via Perf 1').first);
      await tester.pump();

      final traceVia = ServicoPerformance.instancia.tracesRegistradas
          .where((t) => t.nome == 'navegacao_interna_croqui')
          .last;
      expect(traceVia.atributos['destino'], equals('via'));
      expect(mockTelemetry.recordedParams['acao_escalada']!['duracao_ms'], isA<int>());
    },
  );
}

