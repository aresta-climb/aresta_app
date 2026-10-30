// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/openapi/generated/dart/catalogo.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/widgets/bottom_sheets/modal_croqui_sem_conexao.dart';
import 'package:frontend/widgets/busca_global.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';
import '../mocks/mock_telemetria.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
  @override
  Future<String?> getTemporaryPath() async => '$tempPath/temp';
}

void main() {
  sqfliteFfiInit();

  group('Teste do Widget GlobalSearch', () {
    late DatasetRepository repo;
    late RepositorioCatalogo repoCatalogo;
    late EditorDeCroqui editor;
    late Directory tempDir;
    late MockTelemetryService mockTelemetry;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;
      tempDir = Directory.systemTemp.createTempSync('global_search_test_');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);

      editor = EditorDeCroqui();
      repoCatalogo = RepositorioCatalogo(
        provedorCaminhoBanco: () async => '${tempDir.path}/catalogo.db',
        fabricaBanco: databaseFactoryFfi,
      );
      repo = DatasetRepository(
        editorDeCroqui: editor,
        repositorioCatalogo: repoCatalogo,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    testWidgets('Renderiza barra de pesquisa, expande/colapsa com autoFocus false, limpa busca e dispara telemetria no debounce', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlobalSearch(
              datasetRepo: repo,
              downloadedPicos: const [],
              autoFocus: false,
            ),
          ),
        ),
      );
      await tester.pump();

      // Inicialmente colapsado quando autoFocus == false
      expect(find.text('Filtro: Todos'), findsNothing);

      // Toca no TextField para expandir (carrega dados do SQLite via runAsync)
      await tester.runAsync(() async {
        await tester.tap(find.byType(TextField));
        await Future.delayed(const Duration(milliseconds: 80));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Filtro: Todos'), findsOneWidget);
      expect(find.textContaining('Dica: pesquise por picos'), findsOneWidget);

      // Digita algo sem correspondência e aguarda debounce de 1s
      await tester.enterText(find.byType(TextField), '7a_inexistente');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));

      expect(find.text('Nenhum resultado encontrado.'), findsOneWidget);
      expect(mockTelemetry.recordedEvents, contains('busca_escaladas'));

      // Limpa a busca clicando no ícone clear
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(find.text('Nenhum resultado encontrado.'), findsNothing);

      // Colapsa clicando no botão de voltar
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      expect(find.text('Filtro: Todos'), findsNothing);
      await tester.runAsync(() => repoCatalogo.fechar());
    });

    testWidgets('Carrega picos, grupos, setores e escaladas do catalogo.db, filtra por modalidade, exibe badge Offline e prioriza itens offline', (
      WidgetTester tester,
    ) async {
      final picoBaixadoResumo = ResumoPico(
        id: 'br_mg_igarape',
        nome: 'Pedra Grande',
        local: 'Igarapé, MG',
        descricao: '',
        url: '',
        checksum: '',
        thumbnailUrl: '',
        isDownloaded: true,
      );

      await tester.runAsync(() async {
        await repoCatalogo.aplicarDelta(
          RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoAtual: 'v1',
            versaoDestino: 'v1',
            upserts: UpsertsSyncCatalogo(
              croquis: [
                CatalogoCroqui(
                  croquiUid: 'cUidOnline1234',
                  idSlug: 'br_mg_cipo',
                  nome: 'Serra do Cipó',
                  cidade: 'Santana do Riacho',
                  estado: 'MG',
                ),
                CatalogoCroqui(
                  croquiUid: 'cUidOffline123',
                  idSlug: 'br_mg_igarape',
                  nome: 'Pedra Grande',
                  cidade: 'Igarapé',
                  estado: 'MG',
                ),
              ],
              entidades: [
                CatalogoEntidade(
                  uid: 'gUidOnline1234',
                  tipo: 'grupo',
                  croquiUid: 'cUidOnline1234',
                  nome: 'Grupo Grande',
                ),
                CatalogoEntidade(
                  uid: 'sUidOnline1234',
                  tipo: 'setor',
                  croquiUid: 'cUidOnline1234',
                  nome: 'Setor Fenda',
                  grupoUid: 'gUidOnline1234',
                ),
                CatalogoEntidade(
                  uid: 'sUidOffline123',
                  tipo: 'setor',
                  croquiUid: 'cUidOffline123',
                  nome: 'Setor Savassinha',
                ),
                CatalogoEntidade(
                  uid: 'vUidOnline1234',
                  tipo: 'escalada',
                  croquiUid: 'cUidOnline1234',
                  nome: 'Via Fenda Real',
                  escaladaGrau: '7a',
                  escaladaTipo: 'esportiva',
                  setorUid: 'sUidOnline1234',
                  grupoUid: 'gUidOnline1234',
                ),
                CatalogoEntidade(
                  uid: 'vUidOffline123',
                  tipo: 'escalada',
                  croquiUid: 'cUidOffline123',
                  nome: 'Via Fenda Real',
                  escaladaGrau: '7a',
                  escaladaTipo: 'esportiva',
                  setorUid: 'sUidOffline123',
                ),
                CatalogoEntidade(
                  uid: 'vUidMovel12345',
                  tipo: 'escalada',
                  croquiUid: 'cUidOnline1234',
                  nome: 'Diedro Clássico',
                  escaladaGrau: '6sup',
                  escaladaTipo: 'tradicional',
                  setorUid: 'sUidOnline1234',
                ),
                CatalogoEntidade(
                  uid: 'vUidBoulder123',
                  tipo: 'escalada',
                  croquiUid: 'cUidOffline123',
                  nome: 'Teto do Crime',
                  escaladaGrau: 'V4',
                  escaladaTipo: 'boulder',
                  setorUid: 'sUidOffline123',
                ),
                CatalogoEntidade(
                  uid: 'vUidHighline12',
                  tipo: 'escalada',
                  croquiUid: 'cUidOnline1234',
                  nome: 'Travessia do Vento',
                  escaladaGrau: '45m',
                  escaladaTipo: 'highline',
                  setorUid: 'sUidOnline1234',
                ),
                CatalogoEntidade(
                  uid: 'vUidMulti12345',
                  tipo: 'escalada',
                  croquiUid: 'cUidOnline1234',
                  nome: 'Parede Infinita',
                  escaladaGrau: '5',
                  escaladaTipo: 'multienfiada',
                  setorUid: 'sUidOnline1234',
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlobalSearch(
                datasetRepo: repo,
                downloadedPicos: [picoBaixadoResumo],
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 80));
      });
      await tester.pump();

      // 1. Verifica priorização offline e badge "Offline" ao buscar "Via Fenda Real"
      await tester.enterText(find.byType(TextField), 'Via Fenda Real');
      await tester.pump();

      expect(find.widgetWithText(ListTile, 'Via Fenda Real'), findsNWidgets(2));
      expect(find.text('Offline'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);

      // O primeiro ListTile deve ser o do croqui baixado ("Pedra Grande")
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      final subtituloPrimeiro = (listTiles.first.subtitle as Text).data!;
      expect(subtituloPrimeiro, contains('Pedra Grande'));

      // 2. Testa filtro "Picos"
      await tester.tap(find.text('Filtro: Todos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Picos').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Cipo');
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Serra do Cipó'), findsOneWidget);

      // 3. Testa filtro "Setores" (inclui setores e grupos)
      await tester.tap(find.text('Filtro: Picos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setores').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Grupo Grande');
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Grupo Grande'), findsOneWidget);

      // 4. Testa filtro "Móveis"
      await tester.tap(find.text('Filtro: Setores'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Móveis').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Diedro');
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Diedro Clássico'), findsOneWidget);
      expect(find.textContaining('Móvel | 6ºsup'), findsOneWidget);

      // 5. Testa filtro "Boulders"
      await tester.tap(find.text('Filtro: Móveis'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Boulders').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Crime');
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Teto do Crime'), findsOneWidget);
      expect(find.textContaining('Boulder | V4'), findsOneWidget);

      // 6. Testa filtro "Highlines"
      await tester.tap(find.text('Filtro: Boulders'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Highlines').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Travessia');
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Travessia do Vento'), findsOneWidget);
      expect(find.textContaining('Highline | 45m'), findsOneWidget);
      await tester.runAsync(() => repoCatalogo.fechar());
    });

    testWidgets('Navega via LocalizadorDestinoUid ao tocar em resultado do catalogo.db carregando croqui sob demanda', (
      WidgetTester tester,
    ) async {
      const String uidViaRemota = 'vCatRemoto1234';
      const String uidCroquiRemoto = 'cCatRemoto1234';
      const String idSlugRemoto = 'br_rj_urca';

      final croquiRemoto = Croqui()
        ..id = idSlugRemoto
        ..uid = uidCroquiRemoto
        ..picos.add(
          Pico()
            ..nome = 'Morro da Urca'
            ..setoresOuGrupos.add(
              SetorOuGrupo()
                ..setor = (ArquivoSetor()
                  ..conteudo = (Setor()
                    ..uid = 'sCatRemoto1234'
                    ..nome = 'Face Norte'
                    ..escaladas.add(
                      Escalada()
                        ..uid = uidViaRemota
                        ..viaEsportiva = (ViaEsportiva()..nome = 'Italianos'),
                    ))),
            ),
        );

      repo.gerenciadorSessaoOnline.registrarCroquiOnline(
        idSlugRemoto,
        croquiRemoto,
      );

      final treeController = TreeNavigationController();

      await tester.runAsync(() async {
        await repoCatalogo.aplicarDelta(
          RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoAtual: 'v1',
            versaoDestino: 'v1',
            upserts: UpsertsSyncCatalogo(
              croquis: [
                CatalogoCroqui(
                  croquiUid: uidCroquiRemoto,
                  idSlug: idSlugRemoto,
                  nome: 'Morro da Urca',
                  cidade: 'Rio de Janeiro',
                  estado: 'RJ',
                ),
              ],
              entidades: [
                CatalogoEntidade(
                  uid: uidViaRemota,
                  tipo: 'escalada',
                  croquiUid: uidCroquiRemoto,
                  nome: 'Italianos',
                  escaladaGrau: '5sup',
                  escaladaTipo: 'esportiva',
                  setorUid: 'sCatRemoto1234',
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: GlobalSearch(
                            datasetRepo: repo,
                            downloadedPicos: const [],
                            treeController: treeController,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir Modal Busca'),
                ),
              ),
            ),
          ),
        );
      });
      await tester.pump();

      // Abre a rota modal e fecha pelo botão arrow_back (_toggleExpand com canPop == true)
      await tester.runAsync(() async {
        await tester.tap(find.text('Abrir Modal Busca'));
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 80));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Reabre a rota modal e navega tocando em Italianos (_fecharModalSePossivel com canPop == true)
      await tester.runAsync(() async {
        await tester.tap(find.text('Abrir Modal Busca'));
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 80));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.enterText(find.byType(TextField), 'Italianos');
      await tester.pump();

      expect(find.widgetWithText(ListTile, 'Italianos'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(ListTile, 'Italianos'));
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(treeController.currentNode, isA<ViaNode>());
      final viaNode = treeController.currentNode as ViaNode;
      expect(viaNode.escaladaNome, equals('Italianos'));
      expect(viaNode.setorNome, equals('Face Norte'));
      expect(viaNode.cragId, equals(idSlugRemoto));
      await tester.runAsync(() => repoCatalogo.fechar());
    });

    testWidgets('Mescla croquis da sessão online e baixados quando não constam no catalogo.db (incluindo Via Mista)', (
      WidgetTester tester,
    ) async {
      final croqui = Croqui()
        ..id = 'crag_teste'
        ..uid = 'cUidSessao1234';
      final pico = Pico()
        ..nome = 'Pico Teste'
        ..estado = 'SP';
      final setorDireto = Setor()
        ..uid = 'sUidSol1234567'
        ..nome = 'Setor Sol';
      setorDireto.escaladas.addAll([
        Escalada(
          uid: 'vUidEsp1234567',
          viaEsportiva: ViaEsportiva(
            nome: 'Esportiva da Tarde',
            dificuldade: GrauVia_GrauVia.BR_5,
          ),
        ),
        Escalada(
          uid: 'vUidMista12345',
          viaMovel: ViaMovel(
            nome: 'Fenda da Manhã',
            dificuldade: GrauVia_GrauVia.BR_6SUP,
            quantidadeProtecoesIntermediarias: 3,
          ),
        ),
        Escalada(
          uid: 'vUidBoulderMem',
          boulder: Boulder(
            nome: 'Bloco da Noite',
            dificuldade: GrauBoulder_GrauBoulder.V3,
          ),
        ),
        Escalada(
          uid: 'vUidHighMem123',
          highline: Highline(
            nome: 'Fita nas Nuvens',
            distancia: 60,
          ),
        ),
        Escalada(uid: 'vUidSemTipo123'),
      ]);
      final grupoMem = Grupo()
        ..uid = 'gUidMem1234567'
        ..nome = 'Grupo Lua'
        ..setores.add(
          ArquivoSetor()
            ..conteudo = (Setor()
              ..uid = 'sUidLua1234567'
              ..nome = 'Setor Lua'),
        );
      pico.setoresOuGrupos.addAll([
        SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorDireto),
        SetorOuGrupo()..grupo = (ArquivoGrupo()..conteudo = grupoMem),
      ]);
      croqui.picos.add(pico);

      repo.gerenciadorSessaoOnline.registrarCroquiOnline('crag_teste', croqui);
      repo.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': 'pico_disp_extra', 'nome': 'Pico Extra Disponível', 'local': 'Ouro Preto, MG'},
        ],
        downloadedPicos: [
          {'id': 'pico_baixado_sem_proto', 'nome': 'Pico Sem Proto', 'local': 'Mariana, MG'},
        ],
      );

      final treeController = TreeNavigationController();

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlobalSearch(
                datasetRepo: repo,
                downloadedPicos: repo.activeDataset.value!.downloadedPicos,
                treeController: treeController,
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 80));
      });
      await tester.pump();

      // Busca via esportiva
      await tester.enterText(find.byType(TextField), 'Esportiva');
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Esportiva da Tarde'), findsOneWidget);
      expect(find.textContaining('Esportiva | 5º • Setor Sol • Pico Teste'), findsOneWidget);

      // Busca via mista (via móvel com fixas)
      await tester.enterText(find.byType(TextField), 'Fenda');
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Fenda da Manhã'), findsOneWidget);
      expect(find.textContaining('Mista | 6ºsup • Setor Sol • Pico Teste'), findsOneWidget);

      // Toca no Setor Lua dentro do Grupo Lua
      await tester.enterText(find.byType(TextField), 'Setor Lua');
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Setor Lua'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Setor Lua'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(treeController.currentNode, isA<SetorNode>());

      // Atualiza downloadedPicos no didUpdateWidget
      final novaListaBaixados = [
        ResumoPico(
          id: 'pico_baixado_sem_proto',
          nome: 'Pico Sem Proto',
          local: 'Mariana, MG',
          descricao: '',
          url: '',
          checksum: '',
          thumbnailUrl: '',
          isDownloaded: true,
        ),
      ];
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlobalSearch(
                datasetRepo: repo,
                downloadedPicos: novaListaBaixados,
                treeController: treeController,
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 80));
      });
      await tester.pump();

      // Toca no Pico Sem Proto (ResumoPico legado)
      await tester.enterText(find.byType(TextField), 'Pico Sem Proto');
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Pico Sem Proto'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Pico Sem Proto'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      // Quando indiceData está carregado, filtra croquis/entidades do catalogo.db que não constam no índice publicado
      repo.indiceData.value = Indice(
        croquis: [
          ResumoCroqui(id: 'pico_publicado', nome: 'Pico Publicado Oficial'),
        ],
      );
      await tester.runAsync(() async {
        await repoCatalogo.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoDestino: 'v_filtro_indice',
            upserts: UpsertsSyncCatalogo(
              croquis: [
                CatalogoCroqui(
                  croquiUid: 'cUidPublico',
                  idSlug: 'pico_publicado',
                  nome: 'Pico Publicado Oficial',
                ),
                CatalogoCroqui(
                  croquiUid: 'cUidRascunho',
                  idSlug: 'pico_rascunho_oculto',
                  nome: 'Pico Rascunho Oculto',
                ),
              ],
              entidades: [
                CatalogoEntidade(
                  uid: 'vUidRascunho',
                  tipo: 'escalada',
                  croquiUid: 'cUidRascunho',
                  nome: 'Via Rascunho Oculta',
                ),
              ],
            ),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlobalSearch(
                datasetRepo: repo,
                downloadedPicos: const [],
                treeController: treeController,
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Pico Publicado');
      await tester.pump();
      expect(
        find.widgetWithText(ListTile, 'Pico Publicado Oficial'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'Rascunho Ocult');
      await tester.pump();
      expect(
        find.widgetWithText(ListTile, 'Pico Rascunho Oculto'),
        findsNothing,
      );
      expect(
        find.widgetWithText(ListTile, 'Via Rascunho Oculta'),
        findsNothing,
      );

      await tester.runAsync(() => repoCatalogo.fechar());
    });

    testWidgets(
      'Recarrega resultados automaticamente quando repositorioCatalogo.versaoNotificador ou activeDataset mudam (ou ao trocar datasetRepo)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: GlobalSearch(
                  datasetRepo: repo,
                  downloadedPicos: const [],
                ),
              ),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 80));
        });
        await tester.pump();

        // Digita uma consulta que ainda não existe no catálogo
        await tester.enterText(find.byType(TextField), 'Via Live Reload');
        await tester.pump();
        expect(find.widgetWithText(ListTile, 'Via Live Reload'), findsNothing);

        // 1. Atualiza o catálogo enquanto GlobalSearch já está aberto/expandido
        await tester.runAsync(() async {
          await repoCatalogo.aplicarDelta(
            const RespostaSyncCatalogo(
              acao: 'apply_delta',
              versaoDestino: 'v_live_1',
              upserts: UpsertsSyncCatalogo(
                croquis: [
                  CatalogoCroqui(
                    croquiUid: 'cUidLive1',
                    idSlug: 'pico_live_1',
                    nome: 'Pico Live 1',
                  ),
                ],
                entidades: [
                  CatalogoEntidade(
                    uid: 'vUidLive1',
                    tipo: 'escalada',
                    croquiUid: 'cUidLive1',
                    nome: 'Via Live Reload',
                    escaladaGrau: '7b',
                    escaladaTipo: 'esportiva',
                  ),
                ],
              ),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 80));
        });
        await tester.pump();

        // Deve exibir imediatamente a nova via sem precisar fechar e reabrir a busca
        expect(find.widgetWithText(ListTile, 'Via Live Reload'), findsOneWidget);

        // 2. Atualiza datasetRepo.activeDataset enquanto GlobalSearch está aberto (sem piscar CircularProgressIndicator quando já há dados carregados)
        await tester.runAsync(() async {
          repo.activeDataset.value = TopoDataset(
            availablePicos: [
              {
                'id': 'pico_novo_dataset',
                'nome': 'Pico Novo Dataset',
                'local': 'Itabirito, MG',
              },
            ],
            downloadedPicos: const [],
          );
          await tester.pump();
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(
            find.widgetWithText(ListTile, 'Via Live Reload'),
            findsOneWidget,
          );
          await Future.delayed(const Duration(milliseconds: 80));
        });
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Pico Novo Dataset');
        await tester.pump();
        expect(find.widgetWithText(ListTile, 'Pico Novo Dataset'), findsOneWidget);

        // 3. Troca a instância de datasetRepo via didUpdateWidget
        final outroRepoCatalogo = RepositorioCatalogo(
          provedorCaminhoBanco: () async => '${tempDir.path}/outro_catalogo.db',
          fabricaBanco: databaseFactoryFfi,
        );
        final outroRepo = DatasetRepository(
          editorDeCroqui: editor,
          repositorioCatalogo: outroRepoCatalogo,
        );
        await tester.runAsync(() async {
          await outroRepoCatalogo.aplicarDelta(
            const RespostaSyncCatalogo(
              acao: 'apply_delta',
              versaoDestino: 'v_outro_1',
              upserts: UpsertsSyncCatalogo(
                croquis: [
                  CatalogoCroqui(
                    croquiUid: 'cUidOutro1',
                    idSlug: 'pico_outro_1',
                    nome: 'Pico Outro Repo',
                  ),
                ],
                entidades: [],
              ),
            ),
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: GlobalSearch(
                  datasetRepo: outroRepo,
                  downloadedPicos: const [],
                ),
              ),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 80));
        });
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Pico Outro Repo');
        await tester.pump();
        expect(find.widgetWithText(ListTile, 'Pico Outro Repo'), findsOneWidget);

        await tester.runAsync(() async {
          await repoCatalogo.fechar();
          await outroRepoCatalogo.fechar();
        });
      },
    );

    testWidgets(
      'Exibe ModalCroquiSemConexao ao tocar em via de croqui não baixado sem conexão na Busca Global e navega ao reconectar e tocar em Tentar novamente',
      (WidgetTester tester) async {
        final treeController = TreeNavigationController();

        await tester.runAsync(() async {
          await repoCatalogo.aplicarDelta(
            const RespostaSyncCatalogo(
              acao: 'apply_delta',
              versaoDestino: 'v_busca_offline',
              upserts: UpsertsSyncCatalogo(
                croquis: [
                  CatalogoCroqui(
                    croquiUid: 'cUidOffline001',
                    idSlug: 'br_rj_itacoa',
                    nome: 'Costão de Itacoatiara',
                    cidade: 'Niterói',
                    estado: 'RJ',
                  ),
                ],
                entidades: [
                  CatalogoEntidade(
                    uid: 'sUidOffline001',
                    tipo: 'setor',
                    croquiUid: 'cUidOffline001',
                    nome: 'Face Sul',
                  ),
                  CatalogoEntidade(
                    uid: 'vUidOffline001',
                    tipo: 'escalada',
                    croquiUid: 'cUidOffline001',
                    setorUid: 'sUidOffline001',
                    nome: 'Chaminé Stop',
                    escaladaGrau: '4º',
                    escaladaTipo: 'tradicional',
                  ),
                ],
              ),
            ),
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: GlobalSearch(
                  datasetRepo: repo,
                  downloadedPicos: const [],
                  treeController: treeController,
                ),
              ),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 80));
        });
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Chaminé Stop');
        await tester.pump();
        expect(find.widgetWithText(ListTile, 'Chaminé Stop'), findsOneWidget);

        // Toca na via sem conexão (e sem croqui em cache)
        await tester.runAsync(() async {
          await tester.tap(find.widgetWithText(ListTile, 'Chaminé Stop'));
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        expect(find.byType(ModalCroquiSemConexao), findsOneWidget);
        expect(
          find.text('Face Sul • Croqui Costão de Itacoatiara • Niterói, RJ'),
          findsOneWidget,
        );

        // Disponibiliza o croqui em memória (simulando que a conexão voltou) e toca em Tentar novamente
        final croquiItacoa = Croqui()
          ..id = 'br_rj_itacoa'
          ..uid = 'cUidOffline001'
          ..picos.add(
            Pico()
              ..nome = 'Costão de Itacoatiara'
              ..setoresOuGrupos.add(
                SetorOuGrupo()
                  ..setor = (ArquivoSetor()
                    ..conteudo = (Setor()
                      ..uid = 'sUidOffline001'
                      ..nome = 'Face Sul'
                      ..escaladas.add(
                        Escalada()
                          ..uid = 'vUidOffline001'
                          ..viaEsportiva =
                              (ViaEsportiva()..nome = 'Chaminé Stop'),
                      ))),
              ),
          );
        await tester.runAsync(() async {
          repo.activeDataset.value = TopoDataset(
            picosBaixados: [
              {
                'id': 'br_rj_itacoa',
                'data': {'pico': croquiItacoa.picos.first, 'croqui': croquiItacoa},
              },
            ],
            picosDisponiveis: [],
          );
          await Future.delayed(const Duration(milliseconds: 80));
        });
        await tester.pump();

        await tester.tap(find.text('Tentar novamente'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          await repoCatalogo.fechar();
        });
        await tester.pump();

        expect(find.byType(ModalCroquiSemConexao), findsNothing);
        expect(treeController.currentNode, isA<ViaNode>());
        expect(
          (treeController.currentNode as ViaNode).escaladaNome,
          equals('Chaminé Stop'),
        );
      },
    );

    testWidgets(
      'exibe modal bloqueante de carregamento ("Abrindo <título>...") ao tocar em resultado e ignora toques repetidos evitando empilhar múltiplos ModalCroquiSemConexao',
      (WidgetTester tester) async {
        final dbPath = '${tempDir.path}/catalogo_loading_bloqueante.db';
        Completer<void>? travaConsulta;
        int consultasItemPorUid = 0;

        late RepositorioCatalogo repoCatalogo;
        late DatasetRepository repo;
        final treeController = TreeNavigationController();

        await tester.runAsync(() async {
          repoCatalogo = RepositorioCatalogo(
            provedorCaminhoBanco: () async {
              if (travaConsulta != null) {
                consultasItemPorUid++;
                await travaConsulta.future;
              }
              return dbPath;
            },
            fabricaBanco: databaseFactoryFfiNoIsolate,
          );
          repo = DatasetRepository(
            editorDeCroqui: EditorDeCroqui(),
            repositorioCatalogo: repoCatalogo,
          );
          repo.loadEmpty();

          await repoCatalogo.aplicarDelta(
            const RespostaSyncCatalogo(
              acao: 'apply_delta',
              versaoDestino: 'v_loading_lock',
              upserts: UpsertsSyncCatalogo(
                croquis: [
                  CatalogoCroqui(
                    croquiUid: 'cUidLock000001',
                    idSlug: 'br_rj_itacoa_lock',
                    nome: 'Costão de Itacoatiara',
                    cidade: 'Niterói',
                    estado: 'RJ',
                  ),
                ],
                entidades: [
                  CatalogoEntidade(
                    uid: 'sUidLock000001',
                    tipo: 'setor',
                    croquiUid: 'cUidLock000001',
                    nome: 'Face Sul',
                  ),
                  CatalogoEntidade(
                    uid: 'vUidLock000001',
                    tipo: 'escalada',
                    croquiUid: 'cUidLock000001',
                    setorUid: 'sUidLock000001',
                    nome: 'Via Bloqueante',
                    escaladaGrau: '6a',
                    escaladaTipo: 'esportiva',
                  ),
                ],
              ),
            ),
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: GlobalSearch(
                  datasetRepo: repo,
                  downloadedPicos: const [],
                  treeController: treeController,
                ),
              ),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 80));
        });
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Via Bloqueante');
        await tester.pump();
        expect(find.widgetWithText(ListTile, 'Via Bloqueante'), findsOneWidget);

        // Ativa trava para segurar a resolução em andamento
        travaConsulta = Completer<void>();

        final tile = tester.widget<ListTile>(
          find.widgetWithText(ListTile, 'Via Bloqueante'),
        );
        await tester.runAsync(() async {
          await tester.tap(find.widgetWithText(ListTile, 'Via Bloqueante'));
        });
        await tester.pump();

        // Antes do limiar visual de 150ms, o diálogo não deve piscar na tela
        expect(find.text('Abrindo Via Bloqueante...'), findsNothing);

        // Simula 3 toques adicionais nos primeiros milissegundos (< 150ms) enquanto a primeira resolução está em andamento
        tile.onTap?.call();
        tile.onTap?.call();
        tile.onTap?.call();

        // Após ultrapassar 150ms com a resolução ainda pendente, o diálogo bloqueante deve aparecer
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 160)),
        );
        await tester.pump(const Duration(milliseconds: 160));
        expect(find.text('Abrindo Via Bloqueante...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        expect(
          consultasItemPorUid,
          equals(1),
          reason: 'Toques concorrentes devem ser ignorados pela trava _abrindoDestino desde 0ms',
        );

        // Libera a consulta e verifica que o diálogo de loading fecha e apenas 1 ModalCroquiSemConexao abre
        await tester.runAsync(() async {
          travaConsulta!.complete();
          await Future.delayed(const Duration(milliseconds: 80));
        });
        await tester.pumpAndSettle();

        expect(find.text('Abrindo Via Bloqueante...'), findsNothing);
        expect(find.byType(ModalCroquiSemConexao), findsOneWidget);

        // Um único clique em Fechar deve fechar o modal completamente (sem modais empilhados atrás)
        await tester.tap(find.text('Fechar'));
        await tester.pumpAndSettle();
        expect(find.byType(ModalCroquiSemConexao), findsNothing);

        await tester.runAsync(() async {
          await repoCatalogo.fechar();
        });
      },
    );
  });
}

