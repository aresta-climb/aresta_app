// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/pages/explorar.dart';
import 'package:frontend/services/clima/armazenamento_clima_local.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/services/clima/servico_clima_altimetria.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/view/view_models/card_croqui_view_model.dart';
import 'package:frontend/view/view_models/explorar_view_model.dart';
import 'package:frontend/widgets/explorar/barra_busca_filtros_explorar.dart';
import 'package:frontend/widgets/explorar/gaveta_deslizante_explorar.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/superficie_globo_explorar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../fakes/cliente_clima_altimetria_fake.dart';
import '../mocks/mock_geolocator_platform.dart';
import '../mocks/mock_telemetria.dart';

class FakeDatasetRepository extends DatasetRepository {
  FakeDatasetRepository({
    required super.editorDeCroqui,
    required super.repositorioCatalogo,
  });

  @override
  Future<void> init({bool force = false}) async {}

  @override
  Future<Croqui?> getCroqui(
    String id, {
    bool indiceJaSincronizado = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return null;
  }
}

class FakeSyncService extends SyncService {
  FakeSyncService(DatasetRepository repo) : super(datasetRepository: repo);
  bool mockResult = true;
  bool downloadCragCalled = false;
  bool syncIndexCalled = false;
  bool forceBypassCacheUsed = false;

  @override
  Future<bool> downloadCrag(ResumoCroqui resumo) async {
    downloadCragCalled = true;
    return mockResult;
  }

  @override
  Future<List<String>> syncIndex({
    bool auto = true,
    bool forceBypassCache = false,
  }) async {
    syncIndexCalled = true;
    forceBypassCacheUsed = forceBypassCache;
    syncStatus.value = SyncStatus.justUpdated;
    return [];
  }
}

void main() {
  sqfliteFfiInit();
  late Directory dirTemp;
  late RepositorioCatalogo catalogo;
  late FakeDatasetRepository mockRepo;
  late FakeSyncService mockSync;
  late EditorDeCroqui mockEditor;
  late MockTelemetryService mockTelemetry;
  late ServicoClimaAltimetria servicoClima;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dirTemp = await Directory.systemTemp.createTemp('explorar_page_test_');
    catalogo = RepositorioCatalogo(
      fabricaBanco: databaseFactoryFfi,
      provedorCaminhoBanco: () async => '${dirTemp.path}/catalogo.db',
    );
    mockEditor = EditorDeCroqui();
    mockRepo = FakeDatasetRepository(
      editorDeCroqui: mockEditor,
      repositorioCatalogo: catalogo,
    );
    mockSync = FakeSyncService(mockRepo);
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    servicoClima = ServicoClimaAltimetria(
      armazenamento: ArmazenamentoClimaLocal(
        provedorDiretorioBase: () async => dirTemp.path,
      ),
      fonteRemota: ClienteClimaAltimetriaFake(
        snapshotInicial: SnapshotClimaAltimetria(
          geradoEm: DateTime.utc(2026, 11, 25, 12),
          bolhasChuva: const [
            BolhaChuvaRegional(
              id: 'frente_mg',
              latitude: -20.07,
              longitude: -44.32,
              intensidadeMmHora: 4.5,
              ventoRumoGraus: 45.0,
              ventoVelocidadeKmh: 20.0,
              contornoExterno: [
                PontoContornoGeo(longitude: -44.6, latitude: -20.3),
                PontoContornoGeo(longitude: -44.0, latitude: -20.3),
                PontoContornoGeo(longitude: -44.3, latitude: -19.8),
              ],
            ),
          ],
          chuvaPorPico: {
            'br_mg_igarape': [
              EventoChuvaPico(
                data: DateTime.utc(2026, 11, 24),
                milimetros: 20.0,
              ),
            ],
          },
          altimetriaPorPico: const {
            'br_mg_igarape': CotaAltimetricaPico(
              altitudeBaseMetros: 960,
              altitudePicoMetros: 1430,
            ),
          },
        ),
      ),
      relogioUtc: () => DateTime.utc(2026, 11, 25, 14),
    );
    await servicoClima.inicializar();
    await servicoClima.sincronizarSeNecessario();
  });

  tearDown(() async {
    servicoClima.dispose();
    await catalogo.fechar();
    if (await dirTemp.exists()) {
      try {
        await dirTemp.delete(recursive: true);
      } catch (_) {}
    }
  });

  BrowseViewModel criarVm() => BrowseViewModel(
        datasetRepo: mockRepo,
        syncService: mockSync,
        telemetria: mockTelemetry,
        servicoClima: servicoClima,
      );

  Future<BrowseViewModel> criarVmAssincrono(WidgetTester tester) async {
    late BrowseViewModel vm;
    await tester.runAsync(() async {
      vm = criarVm();
      await Future<void>.delayed(const Duration(milliseconds: 25));
    });
    addTearDown(vm.dispose);
    return vm;
  }

  testWidgets('BrowsePage exibe estado carregando quando dataset e nulo e SnackBars de download (Map, Card e String)', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => MalhaGeograficaGlobo.carregarDoAssetBundle());
    mockRepo.activeDataset.value = null;
    final vm = await criarVmAssincrono(tester);

    await tester.pumpWidget(MaterialApp(home: BrowsePage(viewModel: vm)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: [
        {'id': 'pico_1', 'nome': 'Pico Teste', 'url': 'fake.url'},
      ],
      downloadedPicos: [],
    );
    mockRepo.indiceData.value = Indice()
      ..croquis.add(
        ResumoCroqui()
          ..id = 'pico_1'
          ..nome = 'Pico Teste',
      );
    await tester.pumpAndSettle();

    expect(find.byType(SuperficieGloboExplorar), findsOneWidget);
    expect(find.byType(GavetaDeslizanteExplorar), findsOneWidget);
    expect(find.byType(BarraBuscaFiltrosExplorar), findsOneWidget);

    final browse = tester.widget<BrowsePage>(find.byType(BrowsePage));
    final element = tester.element(find.byType(BrowsePage));

    // Sucesso via Map
    mockSync.mockResult = true;
    await browse.handleDownload(element, {'id': 'pico_1', 'nome': 'Pico Teste'});
    await tester.pumpAndSettle();
    expect(find.text('Pico Teste baixado'), findsOneWidget);

    // Falha via CardCroquiViewModel e via String
    mockSync.mockResult = false;
    await browse.handleDownload(
      element,
      const CardCroquiViewModel.deValores(
        id: 'pico_1',
        titulo: '',
        textoEstatisticas: '',
        caminhoMiniatura: '',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Falha ao baixar Pico'), findsOneWidget);

    await browse.handleDownload(element, 'pico_1');
    await tester.pumpAndSettle();
    expect(find.text('Falha ao baixar Pico'), findsOneWidget);
  });

  testWidgets('BrowsePage filtra por busca, abre croqui baixado e voa no globo ao focar pico na lista ou tocar no mapa', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() => MalhaGeograficaGlobo.carregarDoAssetBundle());

    mockRepo.activeDataset.value = ConjuntoDadosCroqui(
      metadadosDisponiveis: [
        ResumoCroqui(
          id: 'br_mg_igarape',
          nome: 'Pedra Grande',
          localizacao: Coordenada(latitude: -200700000, longitude: -443200000),
        ),
        ResumoCroqui(
          id: 'br_rj_urca',
          nome: 'Pão de Açúcar',
          localizacao: Coordenada(latitude: -229500000, longitude: -431600000),
        ),
      ],
      croquisBaixados: [Croqui(id: 'br_mg_igarape', nome: 'Pedra Grande')],
    );

    final vm = await criarVmAssincrono(tester);

    await tester.pumpWidget(MaterialApp(home: BrowsePage(viewModel: vm)));
    await tester.pumpAndSettle();

    expect(find.text('PEDRA GRANDE'), findsOneWidget);
    expect(find.text('PÃO DE AÇÚCAR'), findsOneWidget);

    // Alerta conservador de chuva próxima aparece apenas para Pedra Grande
    expect(find.byKey(const Key('alerta_umidade_br_mg_igarape')), findsOneWidget);
    expect(find.byKey(const Key('alerta_umidade_br_rj_urca')), findsNothing);

    // Botão opcional de Clima e Fogo no Mapa inicia desligado e exige confirmação de ~85% de precisão
    expect(vm.radarClimaMapaAtivo, isFalse);
    expect(find.byKey(const Key('camada_atmosfera_clima_globo')), findsNothing);
    await tester.tap(find.byKey(const Key('botao_camada_clima_mapa')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dialogo_aviso_precisao_clima')), findsOneWidget);
    await tester.tap(find.byKey(const Key('botao_confirmar_aviso_clima')));
    await tester.pump();
    expect(vm.radarClimaMapaAtivo, isTrue);
    expect(find.byKey(const Key('camada_atmosfera_clima_globo')), findsOneWidget);
    await tester.tap(find.byKey(const Key('botao_camada_clima_mapa')));
    await tester.pumpAndSettle();
    expect(vm.radarClimaMapaAtivo, isFalse);
    expect(find.byKey(const Key('camada_atmosfera_clima_globo')), findsNothing);

    // Toque no botao de foco no globo no card dispara voo parabolico
    await tester.tap(find.byKey(const Key('botao_ver_no_globo_br_mg_igarape')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 45));
    }
    expect(vm.picoSelecionadoId, equals('br_mg_igarape'));

    // Toque em card nao baixado tenta abrir diretamente no modo exploracao online (sem auto-download)
    mockSync.downloadCragCalled = false;
    await tester.ensureVisible(find.text('PÃO DE AÇÚCAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PÃO DE AÇÚCAR'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(mockSync.downloadCragCalled, isFalse);
    expect(
      find.textContaining('ainda não está salvo offline'),
      findsOneWidget,
    );
    ScaffoldMessenger.of(tester.element(find.byType(BrowsePage)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    // Pesquisa filtra lista e marcadores do globo
    await tester.enterText(find.byType(TextField), 'Pedra');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('PEDRA GRANDE'), findsOneWidget);
    expect(find.text('PÃO DE AÇÚCAR'), findsNothing);

    // Toque no card baixado abre o croqui
    await tester.tap(find.text('PEDRA GRANDE'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'BrowsePage ordena por Mais proximos, Alfabetico (A-Z) e Mais escaladas pelo modal unificado e exibe badges de distancia',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 860));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(() => MalhaGeograficaGlobo.carregarDoAssetBundle());

      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [
          {
            'id': 'pico_c',
            'nome': 'C Pico',
            'latitude': -20.01,
            'longitude': -44.01,
            'estatisticas': {'totalVias': 10},
          },
          {
            'id': 'pico_a',
            'nome': 'A Pico',
            'latitude': -21.0,
            'longitude': -45.0,
            'estatisticas': {'totalVias': 5},
          },
          {
            'id': 'pico_b',
            'nome': 'B Pico',
            'latitude': -20.5,
            'longitude': -44.5,
            'estatisticas': {'totalVias': 50},
          },
        ],
        downloadedPicos: [],
      );
      mockRepo.indiceData.value = Indice();

      final vm = (await criarVmAssincrono(tester))
        ..atualizarLocalizacaoUsuario(-20.0, -44.0);

      await tester.pumpWidget(MaterialApp(home: BrowsePage(viewModel: vm)));
      await tester.pumpAndSettle();

      // Expande a gaveta para Lista para inspecionar os 3 cards simultaneamente
      await tester.tap(find.byKey(const Key('encaixe_gaveta_lista')));
      await tester.pumpAndSettle();

      double getPos(String text) => tester.getTopLeft(find.text(text)).dy;

      expect(getPos('C PICO') < getPos('B PICO'), isTrue);
      expect(getPos('B PICO') < getPos('A PICO'), isTrue);
      expect(find.byIcon(Icons.place), findsNWidgets(3));

      // Abre modal de Filtros e Ordenacao e seleciona Alfabetico (A-Z)
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      mockTelemetry.clear();
      await tester.tap(find.text('Alfabético (A-Z)'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('botao_aplicar_filtros_explorar')));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('alterar_ordenacao'));
      expect(getPos('A PICO') < getPos('B PICO'), isTrue);
      expect(getPos('B PICO') < getPos('C PICO'), isTrue);

      // Seleciona Mais escaladas
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mais escaladas'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('botao_aplicar_filtros_explorar')));
      await tester.pumpAndSettle();

      expect(getPos('B PICO') < getPos('C PICO'), isTrue);
      expect(getPos('C PICO') < getPos('A PICO'), isTrue);
    },
  );

  testWidgets(
    'BrowsePage rola ate o 7o pico, sincroniza serving e expoe botao de trocar serving em modo experimental',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(() => MalhaGeograficaGlobo.carregarDoAssetBundle());

      final picos = List.generate(10, (i) {
        return ResumoCroqui(
          id: 'br_mg_pico_$i',
          nome: 'Pico Ordem $i',
          localizacao: Coordenada(
            latitude: ((-19.2 - i * 0.08) * 1e7).round(),
            longitude: (-44.0 * 1e7).round(),
          ),
          precomputados: PrecomputadosResumoCroqui(totalEscaladas: 10),
        );
      });

      mockEditor.isExperimentalMode.value = true;
      final vm = (await criarVmAssincrono(tester))
        ..atualizarLocalizacaoUsuario(-20.0, -44.0);

      mockRepo.activeDataset.value = ConjuntoDadosCroqui(
        metadadosDisponiveis: picos,
        croquisBaixados: const [],
      );
      mockRepo.indiceData.value = Indice();

      await tester.pumpWidget(MaterialApp(home: BrowsePage(viewModel: vm)));
      await tester.pumpAndSettle();

      // Toque no cluster MG no globo aciona selecionarPico(origemMapa: true)
      await tester.tap(find.byKey(const Key('cluster_uf_MG')));
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 45));
      }

      // Focar 7o pico rola a gaveta ate PICO ORDEM 6
      vm.focarSetimoPicoProximo();
      await tester.pumpAndSettle();
      expect(find.text('PICO ORDEM 6'), findsOneWidget);

      // Botao de sincronizar serving
      await tester.tap(find.byTooltip('Sincronizar com serving'));
      await tester.pumpAndSettle();
      expect(mockSync.syncIndexCalled, isTrue);
      expect(mockSync.forceBypassCacheUsed, isTrue);
      expect(find.text('Catálogo atualizado com o serving!'), findsOneWidget);

      // Botao Minha Localizacao voa e faz zoom ate o GPS real (e exibe SnackBar se GPS desligado)
      final geo = MockGeolocatorPlatform()
        ..isLocationServiceEnabledResult = true
        ..checkPermissionResult = LocationPermission.always;
      GeolocatorPlatform.instance = geo;
      await tester.tap(find.byKey(const Key('botao_minha_localizacao')));
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 45));
      }
      expect(
        find.byKey(const Key('marcador_localizacao_usuario')),
        findsOneWidget,
      );

      geo.isLocationServiceEnabledResult = false;
      await tester.tap(find.byKey(const Key('botao_minha_localizacao')));
      await tester.pumpAndSettle();
      expect(find.textContaining('GPS'), findsOneWidget);

      // Botao de trocar serving visivel em modo experimental
      await tester.tap(find.byTooltip('Trocar serving'));
      await tester.pumpAndSettle();
      expect(find.text('Trocar serving'), findsWidgets);
    },
  );
}
