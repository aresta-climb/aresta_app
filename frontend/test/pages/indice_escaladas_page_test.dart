// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/pages/indice_escaladas_page.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/utils/indexador_escaladas.dart';
import 'package:frontend/widgets/painel_filtros_indice.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  Widget criarAmbiente({
    required Pico pico,
    required Croqui croqui,
    required String cragId,
    void Function(ItemIndiceEscalada item)? onViaTap,
  }) {
    return MaterialApp(
      theme: construirTemaEscuro(),
      home: IndiceEscaladasPage(
        pico: pico,
        croqui: croqui,
        cragId: cragId,
        onViaTap: onViaTap,
      ),
    );
  }

  group('IndiceEscaladasPage - Widget Tests', () {
    late Pico pico;
    late Croqui croqui;

    setUp(() {
      pico = Pico()..nome = 'Falésia da Serra';

      final viaEsportiva1 = ViaEsportiva()
        ..nome = 'Sol Nascente'
        ..dificuldade = GrauVia_GrauVia.BR_6SUP
        ..destaque = true
        ..conquistadores.add('Renato');

      final viaEsportiva2 = ViaEsportiva()
        ..nome = 'Lua Cheia'
        ..dificuldade = GrauVia_GrauVia.BR_8A
        ..destaque = false
        ..conquistadores.add('Bruno');

      final boulder1 = Boulder()
        ..nome = 'Pedra Redonda'
        ..dificuldade = GrauBoulder_GrauBoulder.V3
        ..destaque = false
        ..conquistadores.add('Lucas');

      final setor1 = Setor()
        ..nome = 'Setor Principal'
        ..escaladas.addAll([
          Escalada()..viaEsportiva = viaEsportiva1,
          Escalada()..viaEsportiva = viaEsportiva2,
        ]);

      final setor2 = Setor()
        ..nome = 'Blocos da Mata'
        ..escaladas.add(Escalada()..boulder = boulder1);

      pico.setoresOuGrupos.addAll([
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor1)),
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor2)),
      ]);

      croqui = Croqui()..picos.add(pico);
    });

    testWidgets('renderiza abas dinâmicas apenas para modalidades existentes', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(pico: pico, croqui: croqui, cragId: 'crag-1'),
      );
      await tester.pumpAndSettle();

      // Devem existir as abas Esportivas e Boulders
      expect(find.textContaining('Esportivas'), findsOneWidget);
      expect(find.textContaining('Boulders'), findsOneWidget);
      // Não deve existir abas para móveis nem multienfiadas
      expect(find.textContaining('Móveis'), findsNothing);
      expect(find.textContaining('Multienfiadas'), findsNothing);

      // Aba inicial é Esportivas
      expect(find.text('Sol Nascente'), findsOneWidget);
      expect(find.text('Lua Cheia'), findsOneWidget);
      expect(find.text('Pedra Redonda'), findsNothing);
    });

    testWidgets('não exibe caixa de busca textual (TextField)', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(pico: pico, croqui: croqui, cragId: 'crag-1'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('setores e conquistadores são filtrados estritamente pela modalidade ativa', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(pico: pico, croqui: croqui, cragId: 'crag-1'),
      );
      await tester.pumpAndSettle();

      // Na aba Esportivas: o PainelFiltrosIndice deve ter apenas 'Setor Principal' e não 'Blocos da Mata'
      final painelEsportivas = tester.widget<PainelFiltrosIndice>(
        find.byType(PainelFiltrosIndice),
      );
      expect(painelEsportivas.setoresDisponiveis, ['Setor Principal']);
      expect(painelEsportivas.conquistadoresDisponiveis, ['Bruno', 'Renato']);
      expect(painelEsportivas.setoresDisponiveis.contains('Blocos da Mata'), isFalse);
      expect(painelEsportivas.conquistadoresDisponiveis.contains('Lucas'), isFalse);

      // Alterna para a aba Boulders
      await tester.tap(find.textContaining('Boulders'));
      await tester.pumpAndSettle();

      // Na aba Boulders: deve ter apenas 'Blocos da Mata' e autor 'Lucas'
      final painelBoulders = tester.widget<PainelFiltrosIndice>(
        find.byType(PainelFiltrosIndice),
      );
      expect(painelBoulders.setoresDisponiveis, ['Blocos da Mata']);
      expect(painelBoulders.conquistadoresDisponiveis, ['Lucas']);
      expect(painelBoulders.setoresDisponiveis.contains('Setor Principal'), isFalse);
      expect(painelBoulders.conquistadoresDisponiveis.contains('Renato'), isFalse);
    });

    testWidgets('alterna para a aba Boulders e renderiza os boulders', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(pico: pico, croqui: croqui, cragId: 'crag-1'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Boulders'));
      await tester.pumpAndSettle();

      expect(find.text('Pedra Redonda'), findsOneWidget);
      expect(find.text('Sol Nascente'), findsNothing);
    });

    testWidgets('tocar no card da via dispara onViaTap com os dados da escalada', (tester) async {
      ItemIndiceEscalada? itemClicado;

      await tester.pumpWidget(
        criarAmbiente(
          pico: pico,
          croqui: croqui,
          cragId: 'crag-1',
          onViaTap: (item) {
            itemClicado = item;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sol Nascente'));
      await tester.pumpAndSettle();

      expect(itemClicado, isNotNull);
      expect(itemClicado?.nome, 'Sol Nascente');
      expect(itemClicado?.setor.nome, 'Setor Principal');
      expect(itemClicado?.cragId, 'crag-1');
    });

    testWidgets('atualiza conquistadores disponíveis dinamicamente com base nas restrições de grau e setor', (tester) async {
      // Cria pico com 2 setores esportivos e conquistadores distintos
      final picoTeste = Pico()..nome = 'Pico de Teste';
      final via1 = ViaEsportiva()
        ..nome = 'Via do Setor 1'
        ..dificuldade = GrauVia_GrauVia.BR_6SUP
        ..destaque = false
        ..conquistadores.add('Renato');
      final via2 = ViaEsportiva()
        ..nome = 'Via Difícil Setor 1'
        ..dificuldade = GrauVia_GrauVia.BR_8A
        ..destaque = false
        ..conquistadores.add('Bruno');
      final via3 = ViaEsportiva()
        ..nome = 'Via do Setor 2'
        ..dificuldade = GrauVia_GrauVia.BR_5
        ..destaque = false
        ..conquistadores.add('Carlos');

      final s1 = Setor()
        ..nome = 'Setor Alpha'
        ..escaladas.addAll([
          Escalada()..viaEsportiva = via1,
          Escalada()..viaEsportiva = via2,
        ]);
      final s2 = Setor()
        ..nome = 'Setor Beta'
        ..escaladas.add(Escalada()..viaEsportiva = via3);

      picoTeste.setoresOuGrupos.addAll([
        SetorOuGrupo(setor: ArquivoSetor(conteudo: s1)),
        SetorOuGrupo(setor: ArquivoSetor(conteudo: s2)),
      ]);

      final croquiTeste = Croqui()..picos.add(picoTeste);

      await tester.pumpWidget(
        criarAmbiente(pico: picoTeste, croqui: croquiTeste, cragId: 'c1'),
      );
      await tester.pumpAndSettle();

      // Inicialmente, sem filtros ativos:
      var painel = tester.widget<PainelFiltrosIndice>(find.byType(PainelFiltrosIndice));
      expect(painel.conquistadoresDisponiveis, ['Bruno', 'Carlos', 'Renato']);
      expect(painel.setoresDisponiveis, ['Setor Alpha', 'Setor Beta']);

      // Expande o painel de filtros
      await tester.tap(find.text('Filtros'));
      await tester.pumpAndSettle();

      // Seleciona o setor 'Setor Alpha' no dropdown
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setor Alpha').last);
      await tester.pumpAndSettle();

      // Com 'Setor Alpha' selecionado, 'Carlos' (que só conquistou no Setor Beta) não deve estar disponível!
      painel = tester.widget<PainelFiltrosIndice>(find.byType(PainelFiltrosIndice));
      expect(painel.conquistadoresDisponiveis, ['Bruno', 'Renato']);
      expect(painel.conquistadoresDisponiveis.contains('Carlos'), isFalse);
    });

    testWidgets('oculta botão de apenas clássicas quando os filtros selecionados não contêm nenhuma via clássica', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(pico: pico, croqui: croqui, cragId: 'crag-1'),
      );
      await tester.pumpAndSettle();

      // Expande filtros na aba Esportivas
      await tester.tap(find.text('Filtros'));
      await tester.pumpAndSettle();

      // Inicialmente Sol Nascente é clássica, então o botão deve estar visível
      expect(find.text('Apenas Clássicas (★)'), findsOneWidget);

      // Adiciona o conquistador 'Bruno' (cuja única via é Lua Cheia, que não é clássica)
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bruno').last);
      await tester.pumpAndSettle();

      // Agora não há clássicas com autor Bruno: o botão deve ser ocultado
      expect(find.text('Apenas Clássicas (★)'), findsNothing);
    });

    testWidgets('dispara telemetria ao alternar abas de modalidade', (tester) async {
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      await tester.pumpWidget(
        criarAmbiente(pico: pico, croqui: croqui, cragId: 'crag-1'),
      );
      await tester.pumpAndSettle();

      // Alterna para aba Boulders
      await tester.tap(find.textContaining('Boulders'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      final params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag-1');
      expect(params['acao'], 'trocar_aba');
      expect(params['origem'], 'indice_boulder');
      expect(params['detalhe'], 'Boulder');
    });

    testWidgets('dispara telemetria ao tocar em um card de escalada', (tester) async {
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      await tester.pumpWidget(
        criarAmbiente(
          pico: pico,
          croqui: croqui,
          cragId: 'crag-1',
          onViaTap: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // Clica no card da via 'Sol Nascente'
      await tester.tap(find.text('Sol Nascente'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_escalada'));
      final params = mockTelemetry.recordedParams['acao_escalada']!;
      expect(params['id_croqui'], 'crag-1');
      expect(params['nome_setor'], 'Setor Principal');
      expect(params['nome_escalada'], 'Sol Nascente');
      expect(params['acao'], 'abrir_detalhes');
      expect(params['origem'], 'indice_esportiva');
    });
  });
}

