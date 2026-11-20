// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/main.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/via_view_model.dart';
import 'package:frontend/widgets/mapa_thumbnail.dart';
import 'package:frontend/widgets/via/bolha_alerta_seguranca_via.dart';
import 'package:frontend/widgets/via/secoes_detalhes_via.dart';
import '../../mocks/mock_telemetria.dart';

void main() {
  Widget envolver(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: SingleChildScrollView(child: filho)),
    );
  }

  testWidgets('CabecalhoIdentidadeVia renderiza título completo, modalidade, selo CLÁSSICA e localização', (tester) async {
    final escalada = Escalada(
      viaEsportiva: ViaEsportiva(nome: 'Aresta do Sol Nascente', destaque: true),
    );
    final setor = Setor(nome: 'Setor Principal');
    final grupo = Grupo(nome: 'Face Norte');

    await tester.pumpWidget(
      envolver(
        CabecalhoIdentidadeVia(
          nomeEscalada: 'Aresta do Sol Nascente',
          modalidade: 'Esportiva',
          ehDestaque: true,
          cragId: 'crag1',
          escalada: escalada,
          setor: setor,
          grupo: grupo,
        ),
      ),
    );

    expect(find.text('Aresta do Sol Nascente'), findsOneWidget);
    expect(find.text('ESPORTIVA'), findsOneWidget);
    expect(find.text('CLÁSSICA'), findsOneWidget);
    expect(find.textContaining('Face Norte > Setor Principal'), findsOneWidget);
  });

  testWidgets('AreaHeroiTopoGrauVia posiciona bolha vermelha flutuante no canto superior direito e renderiza consenso', (tester) async {
    AlertaSegurancaVia? alertaTocado;
    final alerta = AlertaSegurancaVia.criar(
      uid: 'alertaTopo0001',
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.abelhasInsetos,
    );

    await tester.pumpWidget(
      envolver(
        AreaHeroiTopoGrauVia(
          escalada: Escalada(
            uid: 'x8siJek3FiG3aB',
            viaEsportiva: ViaEsportiva(nome: 'Deslize'),
          ),
          cragId: 'crag1',
          exibirCartaoGrau: true,
          rotuloGrauOficial: 'GRAU OFICIAL',
          grauOficial: '7a',
          codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
          complementoGrauOficial: 'Guia Oficial / Conquistador',
          consensoGrau: const ConsensoGrauVia(
            grauSugerido: '7b',
            totalVotos: 10,
            distribuicaoDeltas: {1: 8, 0: 2},
          ),
          alertasAtivos: [alerta],
          aoTocarAlerta: (a) => alertaTocado = a,
        ),
      ),
    );

    expect(find.text('GRAU OFICIAL'), findsOneWidget);
    expect(find.text('7a'), findsOneWidget);
    expect(find.text('CONSENSO DA COMUNIDADE'), findsOneWidget);
    expect(find.text('7b'), findsOneWidget);
    expect(find.text('80% sugerem +1'), findsOneWidget);
    expect(find.byKey(const Key('anel_consenso_grau_via')), findsOneWidget);
    expect(find.byKey(const Key('grafico_distribuicao_grau_via')), findsOneWidget);
    expect(find.text('DISTRIBUIÇÃO DE VOTOS (10)'), findsOneWidget);
    expect(find.text('7b (+1)'), findsOneWidget);
    expect(find.byType(BolhaEmojiAlertaVia), findsOneWidget);

    await tester.tap(find.byKey(const Key('bolha_alerta_ABELHAS_INSETOS')));
    expect(alertaTocado?.uid, 'alertaTopo0001');
  });

  testWidgets('CartaoGrauVia exibe estado vazio de consenso quando ainda não há votos', (tester) async {
    await tester.pumpWidget(
      envolver(
        const CartaoGrauVia(
          rotuloGrauOficial: 'GRAU OFICIAL',
          grauOficial: null,
          complementoGrauOficial: 'Guia Oficial / Conquistador',
          consensoGrau: ConsensoGrauVia.vazio(),
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('Sem votos'), findsOneWidget);
  });

  testWidgets('GradeAtributosTecnicosVia, SecaoEnfiadasVia, SecaoBetasMidiaVia, SecaoNotasComunidadeVia e SecaoHistoricoEPixVia renderizam e acionam callbacks sem overflow em 320x568 @ 1.5x', (tester) async {
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
                SecaoNotasComunidadeVia(
                  comentarios: [
                    ComentarioComunidadeVia(
                      uid: 'c1Kq2L1x9Y7zWq',
                      autorIdPublico: 'a1Lk9P1x4Vw8Mn',
                      autorNomePublico: 'Carlos Lagartixa',
                      criadoEm: DateTime.utc(2026, 9, 14),
                      estiloAscensao: TipoAscensao.flash,
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
    expect(find.text('Enfiada 1 • Diedro'), findsOneWidget);
    expect(find.text('FLASH ★'), findsOneWidget);

    await tester.ensureVisible(find.text('Beta Completo da Via'));
    await tester.tap(find.text('Beta Completo da Via'));
    expect(urlMidiaClicada, 'https://youtube.com/watch?v=abc');

    await tester.ensureVisible(find.byKey(const Key('btn_copiar_pix_manutencao')));
    await tester.tap(find.byKey(const Key('btn_copiar_pix_manutencao')));
    expect(copiouPix, isTrue);
  });

  testWidgets('CartaoGrauVia, AreaHeroiTopoGrauVia sem cartão de grau e GradeAtributosTecnicosVia adaptam layout em larguras estreitas (<250px)', (tester) async {
    final alerta = AlertaSegurancaVia.criar(
      uid: 'alertaHigh0001',
      escaladaUid: 'highlineUid001',
      categoria: CategoriaAlertaSeguranca.riscoExposicao,
    );

    await tester.pumpWidget(
      envolver(
        SizedBox(
          width: 220,
          child: Column(
            children: [
              const CartaoGrauVia(
                rotuloGrauOficial: 'GRAU OFICIAL',
                grauOficial: '7c',
                complementoGrauOficial: 'Guia Oficial / Conquistador',
                consensoGrau: ConsensoGrauVia(
                  grauSugerido: '7c',
                  totalVotos: 5,
                ),
              ),
              AreaHeroiTopoGrauVia(
                escalada: Escalada(
                  uid: 'highlineUid001',
                  highline: Highline(nome: 'Fita Alta'),
                ),
                cragId: 'crag1',
                exibirCartaoGrau: false,
                rotuloGrauOficial: 'GRAU OFICIAL',
                grauOficial: null,
                complementoGrauOficial: '',
                consensoGrau: null,
                alertasAtivos: [alerta],
                aoTocarAlerta: (_) {},
              ),
              const GradeAtributosTecnicosVia(
                atributos: [
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
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('5 avaliações'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.text('⚠️'), findsOneWidget);
    expect(find.text('90m'), findsOneWidget);
  });

  testWidgets('SecaoMapaCroquiVia renderiza MapaThumbnail sem pico e navega ao tocar em VER NO CROQUI INTERATIVO (ida e retorno)', (tester) async {
    final telemetria = MockTelemetryService();
    TelemetryService.instance = telemetria;

    // 1. Mapa próprio sem pico (usa mapasValidos diretamente)
    final escaladaComMapa = Escalada(
      uid: 'viaMapaProprio',
      viaEsportiva: ViaEsportiva(nome: 'Via Foto Própria'),
      mapas: [
        Mapa(
          caminhoImagemMapa: 'mapas/proprio.webp',
          larguraMapa: 1000,
          alturaMapa: 800,
        ),
      ],
    );
    await tester.pumpWidget(
      envolver(
        SecaoMapaCroquiVia(
          escalada: escaladaComMapa,
          cragId: 'crag1',
          setor: Setor(nome: 'Setor Sol'),
          grupo: Grupo(nome: 'Grupo Leste'),
        ),
      ),
    );
    expect(find.byType(MapaThumbnail), findsOneWidget);

    // 2. Referências em mapa do setor (fromMapaPage: false -> AppNav.toMapas)
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
            body: SecaoMapaCroquiVia(
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

    await tester.tap(find.text('VER NO CROQUI INTERATIVO'));
    await tester.pumpAndSettle();

    expect(navIda.currentNode, isA<MapasCarrosselNode>());
    final noMapas = navIda.currentNode as MapasCarrosselNode;
    expect(noMapas.mapas, hasLength(2));
    expect(noMapas.mapas[0].initialSelectedId, 'pt1');
    expect(noMapas.mapas[1].initialSelectedId, isNull);

    // 3. Aberta a partir do MapaPage (fromMapaPage: true -> AppNav.back)
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
          child: Builder(
            builder: (ctx) => Navigator(
              pages: [
                MaterialPage<void>(
                  child: Scaffold(
                    body: SecaoMapaCroquiVia(
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
      ),
    );

    await tester.tap(find.text('VER NO CROQUI INTERATIVO'));
    await tester.pumpAndSettle();
    expect(navVolta.currentNode, isA<PicoNode>());
  });
}
