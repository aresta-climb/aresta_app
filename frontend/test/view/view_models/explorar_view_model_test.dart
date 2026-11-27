// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/openapi/generated/dart/catalogo.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/clima/armazenamento_clima_local.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/services/clima/servico_clima_altimetria.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/registro_primeira_visita.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/view/view_models/card_croqui_view_model.dart';
import 'package:frontend/view/view_models/explorar_view_model.dart';
import 'package:frontend/view/view_models/home_view_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../fakes/cliente_clima_altimetria_fake.dart';
import '../../mocks/mock_geolocator_platform.dart';
import '../../mocks/mock_telemetria.dart';

class _PlataformaCaminhosFake extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String caminhoTemp;
  _PlataformaCaminhosFake(this.caminhoTemp);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminhoTemp;
  @override
  Future<String?> getTemporaryPath() async => caminhoTemp;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  sqfliteFfiInit();

  late Directory tempDir;
  late RepositorioCatalogo repoCatalogo;
  late DatasetRepository repositorio;
  late SyncService servicoSync;
  late EditorDeCroqui editor;
  late MockTelemetryService mockTelemetria;
  late ServicoClimaAltimetria servicoClima;
  late ClienteClimaAltimetriaFake fakeClima;
  late BrowseViewModel viewModel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('browse_vm_test_');
    PathProviderPlatform.instance = _PlataformaCaminhosFake(tempDir.path);
    editor = EditorDeCroqui();
    repoCatalogo = RepositorioCatalogo(
      provedorCaminhoBanco: () async => '${tempDir.path}/catalogo.db',
      fabricaBanco: databaseFactoryFfi,
    );
    repositorio = DatasetRepository(
      editorDeCroqui: editor,
      repositorioCatalogo: repoCatalogo,
    );
    servicoSync = SyncService(datasetRepository: repositorio);
    mockTelemetria = MockTelemetryService();
    TelemetryService.instance = mockTelemetria;

    fakeClima = ClienteClimaAltimetriaFake(
      snapshotInicial: SnapshotClimaAltimetria(
        geradoEm: DateTime.utc(2026, 11, 25, 12),
        bolhasChuva: const [
          BolhaChuvaRegional(
            id: 'bolha_igarape',
            latitude: -20.04,
            longitude: -44.24,
            intensidadeMmHora: 5.5,
            ventoRumoGraus: 45.0,
            ventoVelocidadeKmh: 22.0,
            contornoExterno: [
              PontoContornoGeo(longitude: -44.8, latitude: -20.6),
              PontoContornoGeo(longitude: -43.7, latitude: -20.5),
              PontoContornoGeo(longitude: -44.1, latitude: -19.5),
            ],
          ),
        ],
        chuvaPorPico: {
          'p_igarape': [
            EventoChuvaPico(
              data: DateTime.utc(2026, 11, 25),
              milimetros: 22.0,
              bolhaId: 'bolha_igarape',
            ),
          ],
        },
        altimetriaPorPico: const {
          'p_igarape': CotaAltimetricaPico(
            altitudeBaseMetros: 980,
            altitudePicoMetros: 1430,
          ),
        },
      ),
    );
    servicoClima = ServicoClimaAltimetria(
      armazenamento: ArmazenamentoClimaLocal(
        provedorDiretorioBase: () async => tempDir.path,
      ),
      fonteRemota: fakeClima,
      relogioUtc: () => DateTime.utc(2026, 11, 25, 14),
    );

    viewModel = BrowseViewModel(
      datasetRepo: repositorio,
      syncService: servicoSync,
      telemetria: mockTelemetria,
      servicoClima: servicoClima,
    );
  });

  tearDown(() async {
    viewModel.dispose();
    servicoClima.dispose();
    await repoCatalogo.fechar();
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('BrowseViewModel', () {
    test('carregando é true quando dataset é null', () {
      repositorio.activeDataset.value = null;
      expect(viewModel.carregando, isTrue);
      expect(viewModel.picosFiltrados, isEmpty);
    });

    test('picosFiltrados usa fallback alfabético (A-Z) quando sem localização na ordem proximidade padrão', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': '2', 'nome': 'Serra do Cipó'},
          {'id': '1', 'nome': 'Pedra do Baú'},
        ],
        downloadedPicos: [],
      );

      expect(viewModel.carregando, isFalse);
      expect(viewModel.ordem, equals(OrdemOrdenacaoPico.proximidade));
      expect(viewModel.picosFiltrados.length, equals(2));
      expect(viewModel.picosFiltrados.first.nome, equals('Pedra do Baú'));
      expect(viewModel.picosFiltrados.last.nome, equals('Serra do Cipó'));
      expect(viewModel.picosCards.first.textoDistancia, isNull);
    });

    test('ordenação por proximidade produz exatamente a mesma ordem e distância da HomeViewModel e preserva badges em todas as ordenações', () {
      final picos = List.generate(
        8,
        (i) => {
          'id': 'pico_$i',
          'nome': 'Pico ${8 - i}',
          'latitude': -22.0 - (i * 0.2),
          'longitude': -45.0,
          'estatisticas': {'totalVias': (i + 1) * 10},
        },
      );

      repositorio.activeDataset.value = TopoDataset(
        availablePicos: picos.reversed.toList(),
        downloadedPicos: [],
      );

      final homeVm = HomeViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
      );

      homeVm.atualizarLocalizacaoUsuario(-22.0, -45.0);
      viewModel.atualizarLocalizacaoUsuario(-22.0, -45.0);

      expect(viewModel.latitudeUsuario, equals(-22.0));
      expect(viewModel.longitudeUsuario, equals(-45.0));

      final idsHome = homeVm.picosProximos.map((p) => p.id).toList();
      final idsExplorarTop6 = viewModel.picosFiltrados.take(6).map((p) => p.id).toList();
      expect(idsExplorarTop6, equals(idsHome));
      expect(viewModel.picosFiltrados.length, equals(8));
      expect(viewModel.picosFiltrados[6].id, equals('pico_6'));

      final distHome = homeVm.picosProximos.map((p) => p.paraCardCroquiViewModel().textoDistancia).toList();
      final distExplorarTop6 = viewModel.picosCards.take(6).map((c) => c.textoDistancia).toList();
      expect(distExplorarTop6, equals(distHome));
      expect(viewModel.picosCards.every((c) => c.textoDistancia != null), isTrue);

      viewModel.alterarOrdem(OrdemOrdenacaoPico.alfabetico);
      expect(viewModel.picosCards.every((c) => c.textoDistancia != null), isTrue);

      viewModel.alterarOrdem(OrdemOrdenacaoPico.escaladas);
      expect(viewModel.picosCards.every((c) => c.textoDistancia != null), isTrue);

      homeVm.dispose();
    });

    test('focarSetimoPicoProximo limpa busca e filtros, restaura ordem proximidade e incrementa solicitacaoScrollSetimoPico', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': '1', 'nome': 'Pedra do Baú', 'latitude': -22.68, 'longitude': -45.66},
        ],
        downloadedPicos: [],
      );

      viewModel.alterarTermoBusca('Baú');
      viewModel.alternarModalidade(ModalidadeExploracaoPico.paredao);
      viewModel.alterarOrdem(OrdemOrdenacaoPico.escaladas);
      expect(viewModel.solicitacaoScrollSetimoPico.value, equals(0));

      viewModel.focarSetimoPicoProximo();

      expect(viewModel.termoBusca, isEmpty);
      expect(viewModel.modalidadesAtivas, isEmpty);
      expect(viewModel.ordem, equals(OrdemOrdenacaoPico.proximidade));
      expect(viewModel.solicitacaoScrollSetimoPico.value, equals(1));
    });

    test('alterarTermoBusca filtra picos via busca fuzzy e alterarOrdem ordena A-Z e por escaladas', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': 'b', 'nome': 'Pedra do Baú', 'estatisticas': {'totalVias': 10}},
          {'id': 'a', 'nome': 'Falésia Paraíso', 'estatisticas': {'totalVias': 30}},
        ],
        downloadedPicos: [],
      );

      viewModel.alterarTermoBusca('Baú');
      expect(viewModel.picosFiltrados.single.nome, equals('Pedra do Baú'));

      viewModel.alterarTermoBusca('');
      viewModel.alterarOrdem(OrdemOrdenacaoPico.alfabetico);
      expect(viewModel.picosFiltrados.first.nome, equals('Falésia Paraíso'));
      expect(mockTelemetria.recordedEvents, contains('alterar_ordenacao'));

      viewModel.alterarOrdem(OrdemOrdenacaoPico.escaladas);
      expect(viewModel.picosFiltrados.first.nome, equals('Falésia Paraíso'));
    });

    test('modoEditorAtivo e estaBaixado refletem estado do dataset local', () {
      expect(viewModel.modoEditorAtivo, isFalse);
      editor.isExperimentalMode.value = true;
      expect(viewModel.modoEditorAtivo, isTrue);
      editor.isExperimentalMode.value = false;
      editor.editorUrl.value = 'http://localhost:8000';
      expect(viewModel.modoEditorAtivo, isTrue);

      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [],
        croquisBaixados: [Croqui(id: 'pico_salvo', nome: 'Salvo')],
      );
      expect(viewModel.estaBaixado('pico_salvo'), isTrue);
      expect(viewModel.estaBaixado('pico_ausente'), isFalse);
    });

    test(
      'picosFiltrados e picosCards ordenam em 2 faixas com malha rodoviaria e propagam badge e tooltip',
      () {
        repositorio.activeDataset.value = TopoDataset(
          availablePicos: [
            {'id': 'pico_serra_lento', 'nome': 'Pico Atrás da Serra', 'latitude': -20.10, 'longitude': -44.00},
            {'id': 'pico_rodovia_rapido', 'nome': 'Pico Acesso BR', 'latitude': -20.20, 'longitude': -44.00},
            {'id': 'pico_sem_malha_local', 'nome': 'Pico Sem Malha Local', 'latitude': -20.05, 'longitude': -44.00},
          ],
          downloadedPicos: [],
        );

        viewModel.atualizarLocalizacaoUsuario(-20.00, -44.00);
        repositorio.calculadoraDistanciaEstrada.value = CalculadoraDistanciaEstrada(
          nos: const <NoEstrada>[
            NoEstrada(
              noOsmId: 77,
              latitude: -20.001,
              longitude: -44.000,
              distanciasPorCroquiMetros: <String, int>{
                'pico_serra_lento': 35000,
                'pico_rodovia_rapido': 48000,
              },
              duracoesPorCroquiMinutos: <String, int>{
                'pico_serra_lento': 65,
                'pico_rodovia_rapido': 34,
              },
            ),
          ],
        );

        expect(
          viewModel.picosFiltrados.map((p) => p.id).toList(),
          equals(<String>['pico_rodovia_rapido', 'pico_serra_lento', 'pico_sem_malha_local']),
        );
        expect(viewModel.picosCards[0].textoDistancia, equals('~35 min'));
        expect(viewModel.picosCards[0].distanciaRotaKm, isNotNull);
        expect(viewModel.picosCards[1].textoDistancia, equals('~1h 10min'));
        expect(viewModel.picosCards[1].distanciaRotaKm, isNotNull);
        expect(viewModel.picosCards[2].distanciaRotaKm, isNull);
      },
    );

    test(
      'filtra picos por modalidades (incluindo Paredão e Highline), faixa de grau offline via catalogo.db, raio km, offline, clima e selecao mapa-lista',
      () async {
        await repoCatalogo.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoAtual: 'v_explorar_1',
            upserts: UpsertsSyncCatalogo(
              croquis: [
                CatalogoCroqui(croquiUid: 'u_ig', idSlug: 'p_igarape', nome: 'Pedra Grande'),
                CatalogoCroqui(croquiUid: 'u_urca', idSlug: 'p_urca', nome: 'Pão de Açúcar'),
                CatalogoCroqui(croquiUid: 'u_milho', idSlug: 'p_milho', nome: 'Milho Verde'),
              ],
              entidades: [
                CatalogoEntidade(uid: 'e1', tipo: 'escalada', croquiUid: 'u_ig', nome: 'Via 7b', escaladaGrau: '7b', escaladaTipo: 'esportiva'),
                CatalogoEntidade(uid: 'e2', tipo: 'escalada', croquiUid: 'u_urca', nome: 'Italianos', escaladaGrau: '5sup', escaladaTipo: 'multienfiada'),
                CatalogoEntidade(uid: 'e3', tipo: 'escalada', croquiUid: 'u_milho', nome: 'Mandala', escaladaGrau: 'V9', escaladaTipo: 'boulder'),
              ],
            ),
          ),
        );
        await viewModel.recarregarPerfisGrauCatalogo();
        await servicoClima.inicializar();
        await servicoClima.sincronizarSeNecessario();

        repositorio.activeDataset.value = ConjuntoDadosCroqui(
          metadadosDisponiveis: [
            ResumoCroqui(
              id: 'p_igarape',
              nome: 'Pedra Grande',
              localizacao: Coordenada(latitude: -200700000, longitude: -443200000),
              precomputados: PrecomputadosResumoCroqui(
                totalEscaladas: 85,
                totalEsportivas: 80,
                totalMoveis: 5,
              ),
            ),
            ResumoCroqui(
              id: 'p_urca',
              nome: 'Pão de Açúcar',
              localizacao: Coordenada(latitude: -229500000, longitude: -431600000),
              precomputados: PrecomputadosResumoCroqui(
                totalEscaladas: 270,
                totalMoveis: 190,
                totalMultiplasEnfiadas: 145,
                totalHighlines: 2,
              ),
            ),
            ResumoCroqui(
              id: 'p_milho',
              nome: 'Milho Verde',
              localizacao: Coordenada(latitude: -184700000, longitude: -434900000),
              precomputados: PrecomputadosResumoCroqui(
                totalEscaladas: 140,
                totalBoulders: 132,
              ),
            ),
          ],
          croquisBaixados: [Croqui(id: 'p_igarape', nome: 'Pedra Grande')],
        );
        // Aguarda a sincronizacao seletiva automatica disparada ao detectar picos novos no dataset
        await Future<void>.delayed(const Duration(milliseconds: 30));

        viewModel.atualizarLocalizacaoUsuario(-20.00, -44.00);

        // 1. Tag Paredão filtra apenas multi-enfiadas (Pão de Açúcar) e alternar novamente desmarca
        expect(ModalidadeExploracaoPico.paredao.rotulo, equals('Paredão'));
        viewModel.alternarModalidade(ModalidadeExploracaoPico.paredao);
        expect(viewModel.picosFiltrados.map((p) => p.id).toList(), equals(['p_urca']));
        expect(viewModel.totalFiltrosAtivos, equals(1));
        viewModel.alternarModalidade(ModalidadeExploracaoPico.paredao);
        expect(viewModel.modalidadesAtivas, isEmpty);

        // 2. Highline, Boulder, Esportiva e Movel
        viewModel.definirModalidades({ModalidadeExploracaoPico.highline});
        expect(viewModel.picosFiltrados.single.id, equals('p_urca'));
        viewModel.definirModalidades({ModalidadeExploracaoPico.boulder});
        expect(viewModel.picosFiltrados.single.id, equals('p_milho'));
        viewModel.definirModalidades({ModalidadeExploracaoPico.esportiva, ModalidadeExploracaoPico.movel});
        expect(viewModel.picosFiltrados.length, equals(2));

        // 3. Faixa de Grau de Vias (7a=810 .. 7c=830 -> apenas p_igarape possui 7b!) + lookup por croquiUid
        repositorio.activeDataset.value = ConjuntoDadosCroqui(
          metadadosDisponiveis: [
            ...repositorio.activeDataset.value!.metadadosDisponiveis,
            ResumoCroqui(
              id: 'slug_sem_indice_direto',
              croquiUid: 'u_ig',
              nome: 'Alias Pedra Grande',
              precomputados: PrecomputadosResumoCroqui(totalEscaladas: 5, totalEsportivas: 5),
            ),
          ],
          croquisBaixados: [Croqui(id: 'p_igarape', nome: 'Pedra Grande')],
        );
        viewModel.limparTodosFiltros();
        viewModel.definirFaixaGrauVia(810, 830);
        expect(viewModel.minGrauVia, equals(810));
        expect(viewModel.maxGrauVia, equals(830));
        expect(viewModel.temFiltroGrauVia, isTrue);
        expect(
          viewModel.picosFiltrados.map((p) => p.id).toSet(),
          equals({'p_igarape', 'slug_sem_indice_direto'}),
        );

        // 4. Faixa de Grau de Boulder (V8=900 .. V10=1100 -> apenas p_milho possui V9!)
        viewModel.definirFaixaGrauVia(null, null);
        viewModel.definirFaixaGrauBoulder(900, 1100);
        expect(viewModel.minGrauBoulder, equals(900));
        expect(viewModel.maxGrauBoulder, equals(1100));
        expect(viewModel.temFiltroGrauBoulder, isTrue);
        expect(viewModel.picosFiltrados.map((p) => p.id).toList(), equals(['p_milho']));

        // 5. Combinacao simultanea de grau Via + Boulder
        viewModel.definirFaixaGrauVia(810, 830);
        expect(
          viewModel.picosFiltrados.map((p) => p.id).toSet(),
          equals({'p_igarape', 'slug_sem_indice_direto', 'p_milho'}),
        );

        // 6. Raio maximo km e apenas salvos offline + construtor padrao de ServicoClimaAltimetria
        viewModel.limparTodosFiltros();
        viewModel.definirRaioMaximoKm(100.0);
        expect(viewModel.raioMaximoKm, equals(100.0));
        expect(viewModel.picosFiltrados.map((p) => p.id).toList(), contains('p_igarape'));

        viewModel.definirRaioMaximoKm(null);
        viewModel.definirApenasSalvosOffline(true);
        expect(viewModel.apenasSalvosOffline, isTrue);
        expect(viewModel.picosFiltrados.map((p) => p.id).toList(), equals(['p_igarape']));

        final vmPadraoClima = BrowseViewModel(
          datasetRepo: repositorio,
          syncService: servicoSync,
          telemetria: mockTelemetria,
        );
        vmPadraoClima.dispose();

        viewModel.limparTodosFiltros();
        expect(viewModel.totalFiltrosAtivos, equals(0));

        // 7. Clima contextual + Altimetria + Botão opcional do radar no Mapa (inicia desligado)
        expect(viewModel.obterAltitudePico('p_igarape'), equals(1430));
        expect(viewModel.obterCotaAltimetricaPico('p_igarape')!.altitudeBaseMetros, equals(980));
        expect(
          viewModel.obterUmidadePico('p_igarape').nivel,
          equals(NivelUmidadePico.possivelmenteUmido),
        );
        expect(viewModel.obterUmidadePico('p_urca').nivel, equals(NivelUmidadePico.seco));
        expect(viewModel.radarClimaMapaAtivo, isFalse);
        expect(viewModel.bolhasChuvaAtivas, isEmpty);
        expect(viewModel.bolhasIncendioAtivas, isEmpty);

        viewModel.definirRadarClimaMapaAtivo(false);
        expect(viewModel.radarClimaMapaAtivo, isFalse);

        viewModel.definirRadarClimaMapaAtivo(true);
        expect(viewModel.radarClimaMapaAtivo, isTrue);
        expect(viewModel.bolhasChuvaAtivas.single.bolha.id, equals('bolha_igarape'));

        viewModel.definirRadarClimaMapaAtivo(false);
        expect(viewModel.bolhasChuvaAtivas, isEmpty);

        // 8. Selecao sincronizada Mapa <-> Lista (auto-scroll dispara apenas quando origemMapa=true!)
        expect(viewModel.solicitacaoAutoScrollPicoSelecionado.value, equals(0));
        viewModel.selecionarPico('p_urca', origemMapa: false);
        expect(viewModel.picoSelecionadoId, equals('p_urca'));
        expect(viewModel.solicitacaoAutoScrollPicoSelecionado.value, equals(0));

        viewModel.selecionarPico('p_milho', origemMapa: true);
        expect(viewModel.picoSelecionadoId, equals('p_milho'));
        expect(viewModel.solicitacaoAutoScrollPicoSelecionado.value, equals(1));
      },
    );

    testWidgets(
      'cobre desempate de distância, picos sem coordenadas, debounce de busca, downloads com HttpServer local e ações de UI',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        RegistroPrimeiraVisita.resetForTesting();

        late HttpServer servidorErro;
        await tester.runAsync(() async {
          servidorErro = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          servidorErro.listen((req) async {
            await req.drain<void>();
            req.response.statusCode = 500;
            await req.response.close();
          });
        });
        addTearDown(() => tester.runAsync(() => servidorErro.close(force: true)));

        SyncService.baseUrlOverride = 'http://127.0.0.1:${servidorErro.port}';
        addTearDown(() => SyncService.baseUrlOverride = null);

        final syncLocal = SyncService(
          datasetRepository: repositorio,
          client: ClienteHttpAresta.instancia,
        );
        final vmLocal = BrowseViewModel(
          datasetRepo: repositorio,
          syncService: syncLocal,
          telemetria: mockTelemetria,
          servicoClima: servicoClima,
        );
        addTearDown(vmLocal.dispose);

        expect(vmLocal.downloadingCrags, same(syncLocal.downloadingCrags));

        repositorio.activeDataset.value = TopoDataset(
          availablePicos: [
            {'id': 'p_z', 'nome': 'Zeta', 'latitude': -20.10, 'longitude': -44.00, 'estatisticas': {'totalVias': 10}},
            {'id': 'p_a', 'nome': 'Alfa', 'latitude': -20.10, 'longitude': -44.00, 'estatisticas': {'totalVias': 10}},
            {'id': 'p_sem_coord', 'nome': 'Sem Coord', 'estatisticas': {'totalVias': 10}},
          ],
          downloadedPicos: [],
        );
        vmLocal.atualizarLocalizacaoUsuario(-20.00, -44.00);

        expect(vmLocal.picosFiltrados.map((m) => m.id).toList(), <String>[
          'p_a',
          'p_z',
          'p_sem_coord',
        ]);

        vmLocal.alterarOrdem(OrdemOrdenacaoPico.proximidade);
        vmLocal.alterarOrdem(OrdemOrdenacaoPico.escaladas);
        expect(vmLocal.picosFiltrados.first.id, equals('p_a'));

        vmLocal.alterarTermoBusca('Alfa');
        await tester.pump(const Duration(milliseconds: 550));
        expect(mockTelemetria.recordedEvents, contains('busca_croquis'));

        repositorio.indiceData.value = null;
        expect(await vmLocal.baixarPico(MetadadosIndice(id: 'p_a')), isFalse);
        expect(await vmLocal.baixarPicoPorId('p_a'), isFalse);

        repositorio.indiceData.value = Indice(
          croquis: [
            ResumoCroqui(
              id: 'p_a',
              nome: 'Alfa',
              caminhoRelativo: 'picos/p_a/compilado.binarypb',
            ),
          ],
        );

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        final context = tester.element(find.byType(Scaffold));

        await tester.runAsync(() async {
          await vmLocal.baixarPico(MetadadosIndice(id: 'p_a'));
          await vmLocal.baixarPico(
            MetadadosIndice(
              id: 'p_outro_com_caminho',
              caminhoRelativo: 'picos/outro/compilado.binarypb',
            ),
          );
          expect(
            await vmLocal.baixarPico(
              MetadadosIndice(id: 'p_sem_caminho', caminhoRelativo: ''),
            ),
            isFalse,
          );

          await vmLocal.baixarPicoPorId('p_a');
          expect(await vmLocal.baixarPicoPorId('inexistente'), isFalse);

          final ds = repositorio.activeDataset.value;
          repositorio.activeDataset.value = null;
          await vmLocal.abrirPico(context, 'p_a');
          repositorio.activeDataset.value = ds;
          await vmLocal.abrirPico(context, 'p_a');
          await vmLocal.abrirPico(context, 'inexistente');

          await vmLocal.sincronizarServing(context);
        });
        await tester.pump();

        vmLocal.trocarServing(context);
        await tester.pump();
        expect(find.text('Trocar serving'), findsOneWidget);
      },
    );

    test(
      'obterLocalizacaoTempoReal hidrata cache previo e trata GPS desligado, permissoes negadas, fallback lastKnown e sucesso',
      () async {
        final geo = MockGeolocatorPlatform();
        GeolocatorPlatform.instance = geo;

        SharedPreferences.setMockInitialValues({
          'last_known_latitude': -19.92,
          'last_known_longitude': -43.94,
        });

        final vmGps = BrowseViewModel(
          datasetRepo: repositorio,
          syncService: servicoSync,
          telemetria: mockTelemetria,
          servicoClima: servicoClima,
        );
        addTearDown(vmGps.dispose);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(vmGps.latitudeUsuario, closeTo(-19.92, 0.001));
        expect(vmGps.longitudeUsuario, closeTo(-43.94, 0.001));

        // 1. GPS desligado com cache conhecido -> retorna cache com aviso informativo
        geo.isLocationServiceEnabledResult = false;
        final resCache = await vmGps.obterLocalizacaoTempoReal();
        expect(resCache.coordenada?.latitude, closeTo(-19.92, 0.001));
        expect(resCache.aviso, isNotNull);

        // 2. GPS desligado sem cache -> retorna coordenada nula e aviso
        SharedPreferences.setMockInitialValues({});
        final vmSemCache = BrowseViewModel(
          datasetRepo: repositorio,
          syncService: servicoSync,
          telemetria: mockTelemetria,
          servicoClima: servicoClima,
        );
        addTearDown(vmSemCache.dispose);
        await Future<void>.delayed(const Duration(milliseconds: 25));
        final resDesligado = await vmSemCache.obterLocalizacaoTempoReal();
        expect(resDesligado.coordenada, isNull);
        expect(resDesligado.aviso, contains('GPS'));

        // 3. Permissao negada permanentemente -> abre configuracoes e retorna aviso
        geo.isLocationServiceEnabledResult = true;
        geo.checkPermissionResult = LocationPermission.denied;
        geo.requestPermissionResult = LocationPermission.deniedForever;
        final resNegada = await vmSemCache.obterLocalizacaoTempoReal();
        expect(resNegada.coordenada, isNull);
        expect(geo.openAppSettingsCalled, isTrue);

        // 4. Excecao em getCurrentPosition -> cai para getLastKnownPosition; se ambos nulos sem cache -> aviso
        geo.checkPermissionResult = LocationPermission.whileInUse;
        geo.currentPositionException = Exception('Timeout GPS');
        geo.lastKnownPositionResult = null;
        final resSemSinal = await vmSemCache.obterLocalizacaoTempoReal();
        expect(resSemSinal.coordenada, isNull);
        expect(resSemSinal.aviso, isNotNull);

        // 5. Fallback via getLastKnownPosition valido e depois getCurrentPosition direto
        geo.lastKnownPositionResult = Position(
          latitude: -19.55,
          longitude: -43.75,
          timestamp: DateTime.utc(2026, 11, 25),
          accuracy: 8.0,
          altitude: 800.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        final resLastKnown = await vmSemCache.obterLocalizacaoTempoReal();
        expect(resLastKnown.coordenada?.latitude, closeTo(-19.55, 0.001));
        expect(resLastKnown.aviso, isNull);

        geo.currentPositionException = null;
        geo.currentPositionResult = Position(
          latitude: -20.12,
          longitude: -44.22,
          timestamp: DateTime.utc(2026, 11, 25),
          accuracy: 4.0,
          altitude: 950.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        final resAtual = await vmSemCache.obterLocalizacaoTempoReal();
        expect(resAtual.coordenada?.latitude, closeTo(-20.12, 0.001));
        expect(vmSemCache.latitudeUsuario, closeTo(-20.12, 0.001));

        // Instancia padrao compartilhada de ServicoClimaAltimetria
        final vmInstanciaPadrao = BrowseViewModel(
          datasetRepo: repositorio,
          syncService: servicoSync,
        );
        expect(vmInstanciaPadrao.obterUmidadePico('inexistente').nivel, NivelUmidadePico.seco);
        vmInstanciaPadrao.dispose();
        ServicoClimaAltimetria.redefinirParaTestes();
      },
    );

    test(
      'marcadoresGlobo, calcularDestinoVooPico e resolverAlvoDownload projetam dados prontos para a Dumb UI',
      () async {
        repositorio.activeDataset.value = TopoDataset(
          availablePicos: [
            {
              'id': 'p_igarape',
              'nome': 'Pedra Grande',
              'latitude': -20.07,
              'longitude': -44.30,
              'estatisticas': {'totalVias': 30},
            },
            {
              'id': 'p_sem_nome',
              'nome': '',
              'latitude': -20.15,
              'longitude': -44.10,
              'estatisticas': {'totalVias': 5},
            },
            {
              'id': 'p_sem_coord',
              'nome': 'Sem Coordenada',
              'estatisticas': {'totalVias': 2},
            },
          ],
          downloadedPicos: [],
        );
        await servicoClima.inicializar();
        await servicoClima.sincronizarSeNecessario(
          forcar: true,
          idsPicosCatalogo: const ['p_igarape'],
        );

        final marcadoresDesligado = viewModel.marcadoresGlobo;
        expect(
          marcadoresDesligado.map((m) => m.id).toSet(),
          equals({'p_igarape', 'p_sem_nome'}),
        );
        final refsCatalogo = viewModel.referenciasRelevoCatalogo;
        expect(refsCatalogo.map((r) => r.id).toSet(), equals({'p_igarape', 'p_sem_nome'}));
        expect(identical(viewModel.referenciasRelevoCatalogo, refsCatalogo), isTrue);
        viewModel.alterarTermoBusca('igarameca_sem_resultado');
        expect(viewModel.marcadoresGlobo, isEmpty);
        expect(identical(viewModel.referenciasRelevoCatalogo, refsCatalogo), isTrue);
        viewModel.alterarTermoBusca('');
        expect(
          marcadoresDesligado.firstWhere((m) => m.id == 'p_igarape').umidade.nivel,
          equals(NivelUmidadePico.seco),
        );
        viewModel.definirRadarClimaMapaAtivo(true);
        final marcadores = viewModel.marcadoresGlobo;
        expect(
          marcadores.firstWhere((m) => m.id == 'p_igarape').umidade.nivel,
          equals(NivelUmidadePico.possivelmenteUmido),
        );
        final mSemNome = marcadores.firstWhere((m) => m.id == 'p_sem_nome');
        expect(mSemNome.nome, isNotEmpty);
        expect(mSemNome.altitudePicoMetros, equals(920));
        expect(mSemNome.altitudeBaseMetros, equals(640));

        final vooLonge = viewModel.calcularDestinoVooPico('p_igarape', lodAtual: 1.0);
        expect(vooLonge, isNotNull);
        expect(vooLonge!.destinoLod, closeTo(2.35, 1e-4));
        expect(vooLonge.altitudeBaseMetros, equals(980.0));

        final vooPerto = viewModel.calcularDestinoVooPico('p_igarape', lodAtual: 2.5);
        expect(vooPerto!.destinoLod, closeTo(3.65, 1e-4));
        expect(viewModel.calcularDestinoVooPico('p_sem_coord', lodAtual: 1.0), isNull);
        expect(viewModel.calcularDestinoVooPico('inexistente', lodAtual: 1.0), isNull);

        expect(
          viewModel.resolverAlvoDownload({'id': 'm1', 'nome': 'Mapa Pico'}),
          equals((id: 'm1', nome: 'Mapa Pico')),
        );
        expect(viewModel.resolverAlvoDownload({'id': 'm2'}).id, equals('m2'));
        expect(
          viewModel.resolverAlvoDownload(
            const CardCroquiViewModel.deValores(
              id: 'c1',
              titulo: '',
              textoEstatisticas: '',
              caminhoMiniatura: '',
              salvoOffline: false,
            ),
          ).id,
          equals('c1'),
        );
        expect(viewModel.resolverAlvoDownload('br_mg_teste').id, equals('br_mg_teste'));
        expect(viewModel.buscandoLocalizacao, isFalse);
        expect(
          ModalidadeExploracaoPico.values.map((m) => m.rotulo).toList(),
          everyElement(isNotEmpty),
        );
      },
    );
  });
}
