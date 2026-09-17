// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/view_functions/via_functions.dart';

void main() {
  group('via_functions _buildTopBadges (Map Buttons)', () {
    testWidgets('nao deve exibir botao se escalada nao tiver referencia', (
      WidgetTester tester,
    ) async {
      final mapa = Mapa(pontosDeInteresse: []);
      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste');
      final setor = Setor(
        nome: 'Setor A',
        mapas: [mapa],
        escaladas: [escalada],
      );
      final pico = Pico()
        ..setoresOuGrupos.add(
          SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
        );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return buildViaBody(
                  context,
                  escalada,
                  'cragId',
                  pico: pico,
                  setor: setor,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('VER NO CROQUI INTERATIVO'), findsNothing);
    });

    testWidgets(
      'deve exibir botao agrupado quando tiver multiplos mapas contendo a referencia',
      (WidgetTester tester) async {
        final mapa1 = Mapa(
          referencias: [
            Mapa_Referencia(escalada: 'Via Dupla', ids: ['p1']),
          ],
        );
        final mapa2 = Mapa(
          referencias: [
            Mapa_Referencia(escalada: 'Via Dupla', ids: ['p2']),
          ],
        );
        final mapa3 = Mapa(referencias: []);
        final escalada = Escalada()
          ..viaEsportiva = (ViaEsportiva()..nome = 'Via Dupla');
        final setor = Setor(
          nome: 'Setor B',
          mapas: [mapa1, mapa2, mapa3],
          escaladas: [escalada],
        );
        final pico = Pico()
          ..setoresOuGrupos.add(
            SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
          );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return buildViaBody(
                    context,
                    escalada,
                    'cragId',
                    pico: pico,
                    setor: setor,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('VER NO CROQUI INTERATIVO'), findsOneWidget);
      },
    );
  });

  group('via_functions layout e seções', () {
    testWidgets(
      'deve exibir cartão unificado de proteções X+Y e não exibir cartão de paradas',
      (WidgetTester tester) async {
        final escalada = Escalada()
          ..viaEsportiva = (ViaEsportiva()
            ..nome = 'Vale Perdido'
            ..dificuldade = GrauVia_GrauVia.BR_6SUP
            ..quantidadeProtecoesIntermediarias = 3
            ..quantidadeProtecoesParada = 2);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => buildViaBody(
                  context,
                  escalada,
                  'crag1',
                ),
              ),
            ),
          ),
        );

        expect(find.text('PROTEÇÕES'), findsOneWidget);
        expect(find.text('3+2'), findsOneWidget);
        expect(find.text('PARADAS'), findsNothing);
      },
    );

    testWidgets(
      'deve posicionar Descrição antes de Informações/Histórico e ações no rodapé',
      (WidgetTester tester) async {
        final escalada = Escalada()
          ..viaEsportiva = (ViaEsportiva()
            ..nome = 'Vale Perdido'
            ..dificuldade = GrauVia_GrauVia.BR_6SUP
            ..quantidadeProtecoesIntermediarias = 3
            ..quantidadeProtecoesParada = 2
            ..tipoAncoragem = 'Dupla com corrente'
            ..descricao = 'Via mista, laçar a ponte de pedra.'
            ..conquistadores.add('Emerson Alves')
            ..dataAbertura = '1993'
            ..chavePixManutencao = 'pix@aresta.app');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Builder(
                  builder: (context) => buildViaBody(
                    context,
                    escalada,
                    'crag1',
                  ),
                ),
              ),
            ),
          ),
        );

        final dyDescricao = tester.getTopLeft(find.text('Descrição')).dy;
        final dyInformacoes = tester.getTopLeft(find.text('Informações')).dy;
        final dyHistorico = tester.getTopLeft(find.text('HISTÓRICO & CONQUISTA')).dy;
        final dyAcoes = tester.getTopLeft(find.textContaining('Apoie a Manutenção')).dy;

        // Descrição deve vir antes de Informações e Histórico
        expect(dyDescricao < dyInformacoes, isTrue,
            reason: 'Descrição ($dyDescricao) deve vir antes de Informações ($dyInformacoes)');
        expect(dyInformacoes < dyHistorico, isTrue,
            reason: 'Informações ($dyInformacoes) deve vir antes de Histórico ($dyHistorico)');
        // Ações devem vir após Histórico
        expect(dyHistorico < dyAcoes, isTrue,
            reason: 'Histórico ($dyHistorico) deve vir antes das Ações ($dyAcoes)');
      },
    );

    testWidgets(
      'não deve exibir cartão de Dificuldade nem de Proteções quando forem indefinidos ou zero',
      (WidgetTester tester) async {
        final escalada = Escalada()
          ..viaEsportiva = (ViaEsportiva()
            ..nome = 'Via Sem Grau Nem Protecao'
            ..dificuldade = GrauVia_GrauVia.INDEFINIDO
            ..quantidadeProtecoesIntermediarias = 0
            ..quantidadeProtecoesParada = 0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => buildViaBody(
                  context,
                  escalada,
                  'crag1',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DIFICULDADE'), findsNothing);
        expect(find.text('PROTEÇÕES'), findsNothing);
        expect(find.textContaining(RegExp(r'indefinido', caseSensitive: false)), findsNothing);
      },
    );
  });
}

