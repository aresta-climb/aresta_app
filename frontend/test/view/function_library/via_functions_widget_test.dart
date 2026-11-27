// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/function_library/via_functions.dart';
import 'package:frontend/view/view_models/secao_caderneta_via_view_model.dart';
import 'package:frontend/view/view_models/via_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/comunidade/repositorio_interacoes_via_fake.dart';

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
      'deve posicionar Grau Oficial e Especificações antes da Descrição e Histórico/Pix no rodapé',
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

        final dyGrau = tester.getTopLeft(find.text('GRAU OFICIAL')).dy;
        final dyAncoragem = tester.getTopLeft(find.textContaining('Dupla com corrente')).dy;
        final dyDescricao = tester.getTopLeft(find.text('DESCRIÇÃO')).dy;
        final dyHistorico = tester.getTopLeft(find.text('HISTÓRICO & CONQUISTA')).dy;
        final dyAcoes = tester.getTopLeft(find.textContaining('Apoie a Manutenção')).dy;

        expect(dyGrau < dyAncoragem, isTrue);
        expect(dyAncoragem < dyDescricao, isTrue);
        expect(dyDescricao < dyHistorico, isTrue);
        expect(dyHistorico < dyAcoes, isTrue);
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

    testWidgets(
      'exibe botão e selo de caderneta por padrão',
      (WidgetTester tester) async {
        final escalada = Escalada()
          ..uid = 'escalada_teste_2'
          ..viaEsportiva = (ViaEsportiva()
            ..nome = 'Via Teste Caderneta 2');

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: const [AppColors.dark]),
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

        expect(find.byKey(const Key('btn_registrar_cadena')), findsOneWidget);
      },
    );

    testWidgets(
      'persiste grauSugerido oficial da escalada ao registrar cadena pelo modal da ViaPage',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = RepositorioCadernetaLocal(preferencias: prefs);
        await repo.inicializar();

        final escalada = Escalada(
          uid: 'viaGrauOficial1',
          viaEsportiva: ViaEsportiva(
            nome: 'Via Sete Bê',
            dificuldade: GrauVia_GrauVia.BR_7B,
          ),
        );

        final cadernetaVm = SecaoCadernetaViaViewModel(
          escalada: escalada,
          repositorio: repo,
        );
        addTearDown(cadernetaVm.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
            home: Scaffold(
              body: Builder(
                builder: (context) => buildViaBody(
                  context,
                  escalada,
                  'crag1',
                  cadernetaViewModel: cadernetaVm,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_registrar_cadena')));
        await tester.pumpAndSettle();

        final btnSalvar = find.byKey(const Key('btn_salvar_cadena'));
        await tester.ensureVisible(btnSalvar);
        await tester.tap(btnSalvar);
        await tester.pumpAndSettle();

        expect(repo.cadenasNotifier.value, hasLength(1));
        expect(
          repo.cadenasNotifier.value.first.grauSugerido,
          equals(GrauVia_GrauVia.BR_7B.value),
        );
      },
    );

    testWidgets(
      'atualiza o ViewModel interno de CorpoDetalhesVia ao trocar a Escalada',
      (WidgetTester tester) async {
        final primeira = Escalada(
          uid: 'viaPrimeira0001',
          viaEsportiva: ViaEsportiva(
            nome: 'Via Alfa',
            dificuldade: GrauVia_GrauVia.BR_6,
          ),
        );
        final segunda = Escalada(
          uid: 'viaSegunda00002',
          viaEsportiva: ViaEsportiva(
            nome: 'Via Beta',
            dificuldade: GrauVia_GrauVia.BR_8A,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
            home: Scaffold(
              body: Builder(
                builder: (context) => buildViaBody(context, primeira, 'crag1'),
              ),
            ),
          ),
        );
        expect(find.text('Via Alfa'), findsOneWidget);
        expect(find.text('6º'), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
            home: Scaffold(
              body: Builder(
                builder: (context) => buildViaBody(context, segunda, 'crag1'),
              ),
            ),
          ),
        );
        expect(find.text('Via Beta'), findsOneWidget);
        expect(find.text('8a'), findsOneWidget);
      },
    );
  });
}

