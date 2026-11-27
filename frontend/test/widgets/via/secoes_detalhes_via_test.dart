// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/main.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/function_library/via_functions.dart';
import 'package:frontend/view/view_models/via_view_model.dart';
import 'package:frontend/widgets/via/secoes_detalhes_via.dart';
import '../../mocks/mock_telemetria.dart';

void main() {
  Widget envolver(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: SingleChildScrollView(child: filho)),
    );
  }

  testWidgets('GradeAtributosTecnicosVia, SecaoEnfiadasVia, SecaoBetasMidiaVia, SecaoNotasComunidadeVia e SecaoHistoricoEPixVia renderizam sem overflow em 320x568 @ 1.5x', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    String? urlMidiaClicada;
    var copiouPix = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const GradeAtributosTecnicosVia(
                  atributos: [
                    AtributoTecnicoVia(
                      icone: TipoIconeAtributoVia.extensao,
                      rotulo: 'EXTENSÃO',
                      valor: '28m',
                    ),
                    AtributoTecnicoVia(
                      icone: TipoIconeAtributoVia.protecoes,
                      rotulo: 'PROTEÇÕES',
                      valor: '11+2',
                    ),
                    AtributoTecnicoVia(
                      icone: TipoIconeAtributoVia.parede,
                      rotulo: 'PAREDE',
                      valor: 'Negativo',
                    ),
                    AtributoTecnicoVia(
                      icone: TipoIconeAtributoVia.exposicao,
                      rotulo: 'EXPOSIÇÃO',
                      valor: 'E2',
                    ),
                    AtributoTecnicoVia(
                      icone: TipoIconeAtributoVia.enfiadas,
                      rotulo: 'ENFIADAS',
                      valor: '4',
                    ),
                    AtributoTecnicoVia(
                      icone: TipoIconeAtributoVia.duracao,
                      rotulo: 'DURAÇÃO',
                      valor: 'D3',
                    ),
                    AtributoTecnicoVia(
                      icone: TipoIconeAtributoVia.modalidade,
                      rotulo: 'TIPO',
                      valor: 'Mista',
                    ),
                    AtributoTecnicoVia(
                      icone: TipoIconeAtributoVia.distancia,
                      rotulo: 'DISTÂNCIA',
                      valor: '90m',
                    ),
                  ],
                  tipoAncoragem: 'Dupla com argola inox',
                ),
                const SecaoTextosETecnicasVia(
                  cragId: 'crag1',
                  secoes: [
                    SecaoTextoVia(
                      titulo: 'Descrição',
                      conteudo: 'Crux técnico na saída.',
                      ehMarkdown: true,
                    ),
                    SecaoTextoVia(
                      titulo: 'Peças Móveis',
                      conteudo: 'Camalots #1 e #2',
                      ehMarkdown: false,
                    ),
                    SecaoTextoVia(
                      titulo: 'Descrição do Acesso',
                      conteudo: 'Trilha de 10 min.',
                      ehMarkdown: false,
                    ),
                    SecaoTextoVia(
                      titulo: 'Descrição da Ancoragem',
                      conteudo: ' Dupla química.',
                      ehMarkdown: false,
                    ),
                  ],
                ),
                const SecaoEnfiadasVia(
                  enfiadas: [
                    ResumoEnfiadaVia(
                      numero: 1,
                      titulo: 'Enfiada 1 • Diedro',
                      grau: '6ºsup',
                      extensao: '30m',
                      protecoes: '8+2',
                      equipamentoMovel: 'Friends médios',
                      descricao: 'Diedro técnico.',
                    ),
                  ],
                ),
                SecaoBetasMidiaVia(
                  midias: const [
                    ItemMidiaBetaVia(
                      titulo: 'Beta Completo da Via',
                      url: 'https://youtube.com/watch?v=abc',
                      origemRotulo: 'YouTube',
                    ),
                  ],
                  aoAbrirMidia: (url) => urlMidiaClicada = url,
                ),
                const SecaoNotasComunidadeVia(
                  notas: [
                    NotaComunidadeApresentacao(
                      cabecalhoAutorData: 'Carlos Lagartixa • 14/09/2026',
                      rotuloEstilo: 'FLASH ★',
                      texto: 'Costura 4 tranquila pela esquerda.',
                    ),
                  ],
                ),
                SecaoHistoricoEPixVia(
                  conquistadoresTexto: 'Emerson Alves',
                  dataAbertura: '1993',
                  dataManutencao: '2024',
                  chavePixManutencao: 'pix@aresta.cc',
                  aoCopiarPix: () => copiouPix = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('11+2'), findsOneWidget);
    expect(find.textContaining('Dupla com argola inox'), findsOneWidget);
    expect(find.text('DESCRIÇÃO'), findsOneWidget);
    expect(find.text('PEÇAS MÓVEIS'), findsOneWidget);
    expect(find.text('ENFIADAS (1)'), findsOneWidget);
    expect(find.text('Enfiada 1 • Diedro'), findsOneWidget);
    expect(find.text('HISTÓRICO & CONQUISTA'), findsOneWidget);
    expect(find.text('VÍDEOS & BETAS (1)'), findsOneWidget);
    expect(find.text('BETAS DA COMUNIDADE (1)'), findsOneWidget);

    // Seções de beta iniciam fechadas por padrão e expandem sob demanda
    expect(find.text('Beta Completo da Via'), findsNothing);
    expect(find.text('FLASH ★'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('cabecalho_betas_midia_via')));
    await tester.tap(find.byKey(const Key('cabecalho_betas_midia_via')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Beta Completo da Via'));
    await tester.tap(find.text('Beta Completo da Via'));
    expect(urlMidiaClicada, 'https://youtube.com/watch?v=abc');

    await tester.ensureVisible(find.byKey(const Key('cabecalho_betas_comunidade_via')));
    await tester.tap(find.byKey(const Key('cabecalho_betas_comunidade_via')));
    await tester.pumpAndSettle();
    expect(find.text('FLASH ★'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('btn_copiar_pix_manutencao')));
    await tester.tap(find.byKey(const Key('btn_copiar_pix_manutencao')));
    expect(copiouPix, isTrue);

    // Adaptação em coluna única (< 250px) e seções vazias
    await tester.pumpWidget(
      envolver(
        SizedBox(
          width: 220,
          child: Column(
            children: [
              const GradeAtributosTecnicosVia(
                atributos: [
                  AtributoTecnicoVia(
                    icone: TipoIconeAtributoVia.extensao,
                    rotulo: 'EXTENSÃO',
                    valor: '20m',
                  ),
                ],
              ),
              const GradeAtributosTecnicosVia(atributos: []),
              SecaoHistoricoEPixVia(aoCopiarPix: () {}),
            ],
          ),
        ),
      ),
    );
    expect(find.text('20m'), findsOneWidget);
  });

  testWidgets('CorpoDetalhesVia coordena navegação de croqui interativo (ida e retorno) via ViaViewModel', (tester) async {
    final telemetria = MockTelemetryService();
    TelemetryService.instance = telemetria;

    final escaladaRef = Escalada(
      uid: 'viaRefCroqui01',
      viaEsportiva: ViaEsportiva(nome: 'Via Croqui'),
    );
    final setor = Setor(
      uid: 'setorUid000001',
      nome: 'Setor Croqui',
      escaladas: [escaladaRef],
      mapas: [
        Mapa(
          caminhoImagemMapa: 'mapas/setor_a.webp',
          larguraMapa: 1200,
          alturaMapa: 900,
          referencias: [
            Mapa_Referencia(alvoUid: 'viaRefCroqui01', pontosUids: ['pt1']),
          ],
        ),
        Mapa(
          caminhoImagemMapa: 'mapas/setor_b.webp',
          larguraMapa: 1200,
          alturaMapa: 900,
          referencias: [
            Mapa_Referencia(alvoUid: 'viaRefCroqui01'),
          ],
        ),
      ],
    );
    final pico = Pico(
      nome: 'Pico Croqui',
      setoresOuGrupos: [
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
      ],
    );

    final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
    final syncService = SyncService(datasetRepository: datasetRepo);
    final navIda = TreeNavigationController(
      estadoInicial: const ArvoreNavegacao(
        noAtual: PicoNode(cragId: 'crag1', parent: HomeNode()),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: construirTemaEscuro(),
        home: TreeNavigationWrapper(
          datasetRepo: datasetRepo,
          syncService: syncService,
          treeController: navIda,
          child: Scaffold(
            body: CorpoDetalhesVia(
              escalada: escaladaRef,
              cragId: 'crag1',
              pico: pico,
              setor: setor,
              fromMapaPage: false,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mapas Interativos (2)'));
    await tester.pumpAndSettle();

    expect(navIda.currentNode, isA<MapasCarrosselNode>());
    final noMapas = navIda.currentNode as MapasCarrosselNode;
    expect(noMapas.mapas, hasLength(2));
    expect(noMapas.mapas[0].initialSelectedId, 'pt1');
    expect(noMapas.mapas[1].initialSelectedId, isNull);

    const noPai = PicoNode(cragId: 'crag1', parent: HomeNode());
    final navVolta = TreeNavigationController(
      estadoInicial: const ArvoreNavegacao(
        noAtual: ViaNode(
          cragId: 'crag1',
          escaladaNome: 'Via Croqui',
          parent: noPai,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: construirTemaEscuro(),
        home: TreeNavigationWrapper(
          key: const Key('wrapper_nav_volta'),
          datasetRepo: datasetRepo,
          syncService: syncService,
          treeController: navVolta,
          child: Navigator(
            pages: [
              MaterialPage<void>(
                child: Scaffold(
                  body: CorpoDetalhesVia(
                    escalada: escaladaRef,
                    cragId: 'crag1',
                    pico: pico,
                    setor: setor,
                    fromMapaPage: true,
                  ),
                ),
              ),
            ],
            onDidRemovePage: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mapas Interativos (2)'));
    await tester.pumpAndSettle();
    expect(navVolta.currentNode, isA<PicoNode>());
  });
}
