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

      // Ao mudar para Alfabético ou Mais escaladas, todos os cards continuam exibindo textoDistancia
      viewModel.alterarOrdem(OrdemOrdenacaoPico.alfabetico);
      expect(viewModel.picosCards.every((c) => c.textoDistancia != null), isTrue);

      viewModel.alterarOrdem(OrdemOrdenacaoPico.escaladas);
      expect(viewModel.picosCards.every((c) => c.textoDistancia != null), isTrue);

      homeVm.dispose();
    });

    test('focarSetimoPicoProximo limpa busca, restaura ordem proximidade e incrementa solicitacaoScrollSetimoPico', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': '1', 'nome': 'Pedra do Baú', 'latitude': -22.68, 'longitude': -45.66},
        ],
        downloadedPicos: [],
      );

      viewModel.alterarTermoBusca('Baú');
      viewModel.alterarOrdem(OrdemOrdenacaoPico.escaladas);
      expect(viewModel.solicitacaoScrollSetimoPico.value, equals(0));

      viewModel.focarSetimoPicoProximo();

      expect(viewModel.termoBusca, isEmpty);
      expect(viewModel.ordem, equals(OrdemOrdenacaoPico.proximidade));
      expect(viewModel.solicitacaoScrollSetimoPico.value, equals(1));
    });

    test('alterarTermoBusca filtra picos via busca fuzzy', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': '1', 'nome': 'Pedra do Baú'},
          {'id': '2', 'nome': 'Falésia Paraíso'},
        ],
        downloadedPicos: [],
      );

      viewModel.alterarTermoBusca('Baú');
      expect(viewModel.termoBusca, equals('Baú'));
      expect(viewModel.picosFiltrados.length, equals(1));
      expect(viewModel.picosFiltrados.first.nome, equals('Pedra do Baú'));
    });

    test('alterarOrdem ordena alfabeticamente e por número de vias', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {
            'id': 'b',
            'nome': 'B Pico',
            'estatisticas': {'totalVias': 10},
          },
          {
            'id': 'a',
            'nome': 'A Pico',
            'estatisticas': {'totalVias': 30},
          },
        ],
        downloadedPicos: [],
      );

      // Alfabético
      viewModel.alterarOrdem(OrdemOrdenacaoPico.alfabetico);
      expect(viewModel.ordem, equals(OrdemOrdenacaoPico.alfabetico));
      expect(viewModel.picosFiltrados.first.nome, equals('A Pico'));
      expect(mockTelemetria.recordedEvents, contains('alterar_ordenacao'));

      // Por escaladas (descendente)
      viewModel.alterarOrdem(OrdemOrdenacaoPico.escaladas);
      expect(viewModel.ordem, equals(OrdemOrdenacaoPico.escaladas));
      expect(viewModel.picosFiltrados.first.nome, equals('A Pico')); // 30 vias > 10 vias
    });

    test('modoEditorAtivo reflete estado de experimentalMode e editorUrl', () {
      expect(viewModel.modoEditorAtivo, isFalse);

      editor.isExperimentalMode.value = true;
      expect(viewModel.modoEditorAtivo, isTrue);

      editor.isExperimentalMode.value = false;
      editor.editorUrl.value = 'http://localhost:8000';
      expect(viewModel.modoEditorAtivo, isTrue);
    });

    test('estaBaixado verifica presença no dataset local', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [],
        croquisBaixados: [
          Croqui(id: 'pico_salvo', nome: 'Salvo'),
        ],
      );

      expect(viewModel.estaBaixado('pico_salvo'), isTrue);
      expect(viewModel.estaBaixado('pico_ausente'), isFalse);
    });

    test(
      'picosFiltrados e picosCards ordenam em 2 faixas (1º com estimativa de tempo por minutos, 2º demais por km) e propagam badge e tooltip',
      () {
        repositorio.activeDataset.value = TopoDataset(
          availablePicos: [
            {
              'id': 'pico_serra_lento',
              'nome': 'Pico Atrás da Serra',
              'latitude': -20.10,
              'longitude': -44.00,
            },
            {
              'id': 'pico_rodovia_rapido',
              'nome': 'Pico Acesso BR',
              'latitude': -20.20,
              'longitude': -44.00,
            },
            {
              'id': 'pico_sem_malha_local',
              'nome': 'Pico Sem Malha Local',
              'latitude': -20.05,
              'longitude': -44.00,
            },
          ],
          downloadedPicos: [],
        );

        viewModel.atualizarLocalizacaoUsuario(-20.00, -44.00);

        repositorio.calculadoraDistanciaEstrada.value =
            CalculadoraDistanciaEstrada(
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

        // Faixa 1: pico_rodovia_rapido (~35 min, 48.1 km) antes de pico_serra_lento (~1h 10min, 35.1 km)
        // Faixa 2: pico_sem_malha_local (sem estimativa de tempo, ordenado por km ao final)
        expect(
          viewModel.picosFiltrados.map((p) => p.id).toList(),
          equals(<String>[
            'pico_rodovia_rapido',
            'pico_serra_lento',
            'pico_sem_malha_local',
          ]),
        );
        expect(viewModel.picosCards[0].id, equals('pico_rodovia_rapido'));
        expect(viewModel.picosCards[0].textoDistancia, equals('~35 min'));
        expect(
          viewModel.picosCards[0].tooltipDistancia,
          equals('Estimativa sem trânsito: ~35 min (48.1 km)'),
        );
        expect(viewModel.picosCards[1].id, equals('pico_serra_lento'));
        expect(viewModel.picosCards[1].textoDistancia, equals('~1h 10min'));
        expect(
          viewModel.picosCards[1].tooltipDistancia,
          equals('Estimativa sem trânsito: ~1h 10min (35.1 km)'),
        );
        expect(viewModel.picosCards[2].id, equals('pico_sem_malha_local'));
        expect(viewModel.picosCards[2].textoDistancia, contains('km'));
        expect(viewModel.picosCards[2].tooltipDistancia, isNull);
      },
    );

    testWidgets(
      'cobre desempate de distância, picos sem coordenadas, debounce de busca, downloads e ações de UI',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        RegistroPrimeiraVisita.resetForTesting();

        final clienteHttp = ClienteHttpAresta.paraTestes(
          MockClient((_) async => http.Response('Erro', 500)),
        );
        final syncLocal = SyncService(
          datasetRepository: repositorio,
          client: clienteHttp,
        );
        final vmLocal = BrowseViewModel(
          datasetRepo: repositorio,
          syncService: syncLocal,
          telemetria: mockTelemetria,
        );
        addTearDown(vmLocal.dispose);

        expect(vmLocal.downloadingCrags, same(syncLocal.downloadingCrags));

        // Dois picos com mesma coordenada + 1 pico sem coordenada e mesma qtd de vias
        repositorio.activeDataset.value = TopoDataset(
          availablePicos: [
            {
              'id': 'p_z',
              'nome': 'Zeta',
              'latitude': -20.10,
              'longitude': -44.00,
              'estatisticas': {'totalVias': 10},
            },
            {
              'id': 'p_a',
              'nome': 'Alfa',
              'latitude': -20.10,
              'longitude': -44.00,
              'estatisticas': {'totalVias': 10},
            },
            {
              'id': 'p_sem_coord',
              'nome': 'Sem Coord',
              'estatisticas': {'totalVias': 10},
            },
          ],
          downloadedPicos: [],
        );
        vmLocal.atualizarLocalizacaoUsuario(-20.00, -44.00);

        final filtradosProx = vmLocal.picosFiltrados;
        expect(filtradosProx.map((m) => m.id).toList(), <String>[
          'p_a',
          'p_z',
          'p_sem_coord',
        ]);

        // alterarOrdem para a mesma ordem atual não dispara evento duplicado
        vmLocal.alterarOrdem(OrdemOrdenacaoPico.proximidade);
        // alterarOrdem para escaladas exercita desempate por nome quando totalEscaladas é igual
        vmLocal.alterarOrdem(OrdemOrdenacaoPico.escaladas);
        expect(vmLocal.picosFiltrados.first.id, equals('p_a'));

        // Debounce de busca após 500ms registra logBuscaCroquis
        vmLocal.alterarTermoBusca('Alfa');
        await tester.pump(const Duration(milliseconds: 550));
        expect(mockTelemetria.recordedEvents, contains('busca_croquis'));

        // baixarPico e baixarPicoPorId com indiceData nulo e preenchido
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

          // abrirPico com dataset nulo, encontrado e fallback orElse
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
  });
}
