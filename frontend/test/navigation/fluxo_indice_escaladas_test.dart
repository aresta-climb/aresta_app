// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/main.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/pages/pico_subpages/setores_page.dart';
import 'package:frontend/pages/pico.dart';
import 'package:frontend/pages/via.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/view/view_models/pico_view_model.dart';

import '../mocks/mock_telemetria.dart';

void main() {
  late MockTelemetryService mockTelemetry;
  late DatasetRepository datasetRepo;
  late SyncService syncService;

  setUp(() {
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
    datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
    syncService = SyncService(datasetRepository: datasetRepo);
  });

  Pico criarPicoCompleto() {
    final viaEsportiva = Escalada(
      viaEsportiva: ViaEsportiva(
        nome: 'Mister Magoo',
        dificuldade: GrauVia_GrauVia.BR_7A,
        quantidadeProtecoesIntermediarias: 5,
        quantidadeProtecoesParada: 2,
        destaque: true,
      ),
    );

    final viaMulti = Escalada(
      viaMultiplasEnfiadas: ViaMultiplasEnfiadas(
        nome: 'Fissura do Meio',
        dificuldadeMaxima: GrauVia_GrauVia.BR_6SUP,
        tipoViaMultiplasEnfiadas: ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas.TODA_FIXA,
      ),
    );

    final setor1 = Setor(
      nome: 'Setor do Meio',
      escaladas: [viaEsportiva],
    );

    final setor2 = Setor(
      nome: 'Paredão Norte',
      escaladas: [viaMulti],
    );

    final grupo = Grupo(
      nome: 'Complexo do Baú',
      setores: [ArquivoSetor(conteudo: setor2)],
    );

    final pico = Pico(
      nome: 'Pedra do Baú',
      estado: 'SP',
      setoresOuGrupos: [
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor1)),
        SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo)),
      ],
    );

    return pico;
  }

  testWidgets(
    'Fluxo integrado: Pico -> Índice -> Filtro Setor -> Via -> Voltar com filtros preservados e Salto para Setor',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final pico = criarPicoCompleto();
      final croqui = Croqui();

      final treeController = TreeNavigationController(
        estadoInicial: const ArvoreNavegacao(
          noAtual: PicoNode(cragId: 'bau', parent: HomeNode()),
        ),
      );

      Widget construirPaginaParaNo(NavNode node) {
        if (node is PicoNode) {
          return Scaffold(
            body: PicoDetailsPage(
              viewModel: PicoViewModel(
                pico: pico,
                croqui: croqui,
                cragId: 'bau',
                datasetRepo: datasetRepo,
              ),
            ),
          );
        } else if (node is SetoresNode) {
          return SetoresPage(
            pico: pico,
            croqui: croqui,
            cragId: 'bau',
            modalidadeInicial: node.modalidadeInicial,
          );
        } else if (node is IndiceEscaladasNode) {
          return SetoresPage(
            pico: pico,
            croqui: croqui,
            cragId: 'bau',
            modalidadeInicial: node.modalidadeInicial,
          );
        } else if (node is ViaNode) {
          Escalada? escaladaEncontrada;
          Setor? setorEncontrado;
          Grupo? grupoEncontrado;

          for (final sg in pico.setoresOuGrupos) {
            if (sg.hasSetor() && sg.setor.hasConteudo()) {
              final s = sg.setor.conteudo;
              for (final e in s.escaladas) {
                if (e.hasViaEsportiva() && e.viaEsportiva.nome == node.escaladaNome ||
                    e.hasViaMultiplasEnfiadas() && e.viaMultiplasEnfiadas.nome == node.escaladaNome) {
                  escaladaEncontrada = e;
                  setorEncontrado = s;
                  break;
                }
              }
            } else if (sg.hasGrupo() && sg.grupo.hasConteudo()) {
              final g = sg.grupo.conteudo;
              for (final sArq in g.setores) {
                if (sArq.hasConteudo()) {
                  final s = sArq.conteudo;
                  for (final e in s.escaladas) {
                    if (e.hasViaEsportiva() && e.viaEsportiva.nome == node.escaladaNome ||
                        e.hasViaMultiplasEnfiadas() && e.viaMultiplasEnfiadas.nome == node.escaladaNome) {
                      escaladaEncontrada = e;
                      setorEncontrado = s;
                      grupoEncontrado = g;
                      break;
                    }
                  }
                }
              }
            }
          }

          return ViaPage(
            escalada: escaladaEncontrada!,
            cragId: 'bau',
            pico: pico,
            setor: setorEncontrado,
            grupo: grupoEncontrado,
          );
        } else if (node is SetorNode) {
          return Scaffold(
            appBar: AppBar(title: Text(node.setorNome)),
            body: Center(
              child: Text('PÁGINA DO SETOR: ${node.setorNome}'),
            ),
          );
        }
        return const Scaffold();
      }

      Widget construirApp() {
        return MaterialApp(
          theme: construirTemaEscuro(),
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: datasetRepo,
            syncService: syncService,
            treeController: treeController,
            child: AnimatedBuilder(
              animation: treeController,
              builder: (context, _) {
                final pushedNodes = treeController.currentNode.path
                    .where((n) => n is! HomeNode)
                    .toList();

                return Navigator(
                  key: const ValueKey('NavTesteStack'),
                  // ignore: deprecated_member_use
                  onPopPage: (route, result) {
                    if (!route.didPop(result)) return false;
                    treeController.goBack();
                    return true;
                  },
                  pages: pushedNodes.map((node) {
                    return MaterialPage(
                      key: ValueKey(node.toString()),
                      child: construirPaginaParaNo(node),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      // 1. Validar que o Pico exibe o card unificado Setores & Escaladas
      expect(find.text('Setores & Escaladas'), findsOneWidget);

      // 2. Navegar para a exploração unificada
      await tester.tap(find.text('Setores & Escaladas'));
      await tester.pumpAndSettle();

      expect(treeController.currentNode, isA<SetoresNode>());
      expect(find.byType(SetoresPage), findsOneWidget);

      // Deve listar as abas "Setores (2)", "Esportivas (1)" e "Multienfiadas (1)"
      expect(find.textContaining('Setores (2)'), findsOneWidget);
      expect(find.textContaining('Esportivas (1)'), findsOneWidget);
      expect(find.textContaining('Multienfiadas (1)'), findsOneWidget);
      // Boulders não existem nesse pico, logo não deve renderizar a aba Boulders
      expect(find.textContaining('Boulders'), findsNothing);

      // 3. Mudar para a aba de Esportivas e expandir filtros
      await tester.tap(find.textContaining('Esportivas (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Mister Magoo'), findsOneWidget);

      await tester.tap(find.text('Filtros'));
      await tester.pumpAndSettle();

      expect(find.byType(RangeSlider), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Setor do Meio').last);
      await tester.pumpAndSettle();

      // Chip com 'Setor do Meio' e botão X deve estar presente
      expect(find.text('Setor do Meio'), findsWidgets);
      expect(find.text('Mister Magoo'), findsOneWidget);

      // 4. Clicar no card da via para abrir ViaPage
      await tester.tap(find.text('Mister Magoo'));
      await tester.pumpAndSettle();

      expect(treeController.currentNode, isA<ViaNode>());
      expect(find.byType(ViaPage), findsOneWidget);

      // 5. Na ViaPage, validar presença da LinhaLocalizacaoSetor e do botão de voltar
      expect(find.textContaining('Setor do Meio'), findsOneWidget);
      expect(find.text('Ver no croqui'), findsOneWidget);

      // 6. Clicar no botão de voltar da AppBar da ViaPage
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Deve ter retornado à exploração unificada preservando o chip do setor selecionado
      expect(treeController.currentNode, isA<SetoresNode>());
      expect(find.byType(SetoresPage), findsOneWidget);
      expect(find.text('Mister Magoo'), findsOneWidget);

      // Limpa os filtros ativos para voltar a listar todas as vias e modalidades
      await tester.ensureVisible(find.text('Limpar'));
      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      // 7. Mudar para a aba de Multienfiadas
      await tester.tap(find.textContaining('Multienfiadas (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Fissura do Meio'), findsOneWidget);

      // 8. Abrir a via multienfiada
      await tester.tap(find.text('Fissura do Meio'));
      await tester.pumpAndSettle();

      expect(treeController.currentNode, isA<ViaNode>());

      // Validar a hierarquia completa com grupo: "Complexo do Baú > Paredão Norte"
      expect(find.textContaining('Complexo do Baú > Paredão Norte'), findsOneWidget);
      expect(find.text('Ver no croqui'), findsOneWidget);

      // 9. Clicar em "Ver no croqui" diretamente na LinhaLocalizacaoSetor
      await tester.tap(find.text('Ver no croqui'));
      await tester.pumpAndSettle();

      // Deve ter navegado para SetorNode
      expect(treeController.currentNode, isA<SetorNode>());
      final setorNode = treeController.currentNode as SetorNode;
      expect(setorNode.setorNome, 'Paredão Norte');
      expect(setorNode.grupoNome, 'Complexo do Baú');
      expect(setorNode.scrollToEscaladaNome, 'Fissura do Meio');
      expect(find.text('PÁGINA DO SETOR: Paredão Norte'), findsOneWidget);
    },
  );

  testWidgets(
    'Compatibilidade declarativa: IndiceEscaladasNode resolve para SetoresPage',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final pico = criarPicoCompleto();
      final croqui = Croqui();

      final treeController = TreeNavigationController(
        estadoInicial: const ArvoreNavegacao(
          noAtual: IndiceEscaladasNode(
            cragId: 'bau',
            modalidadeInicial: 'Multienfiadas',
            parent: HomeNode(),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: datasetRepo,
            syncService: syncService,
            treeController: treeController,
            child: SetoresPage(
              pico: pico,
              croqui: croqui,
              cragId: 'bau',
              modalidadeInicial: 'Multienfiadas',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SetoresPage), findsOneWidget);
      expect(find.text('Fissura do Meio'), findsOneWidget);
    },
  );
}
