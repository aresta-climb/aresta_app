// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/firebase/registro_primeira_visita.dart';
import 'package:frontend/view/view_models/explorar_view_model.dart';
import 'package:frontend/view/view_models/home_view_model.dart';
import '../../mocks/mock_telemetria.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _PlataformaCaminhosMock extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String caminhoTemp;
  _PlataformaCaminhosMock(this.caminhoTemp);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminhoTemp;
  @override
  Future<String?> getTemporaryPath() async => caminhoTemp;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DatasetRepository repositorio;
  late SyncService servicoSync;
  late EditorDeCroqui editor;
  late MockTelemetryService mockTelemetria;
  late BrowseViewModel viewModel;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('browse_vm_test_');
    PathProviderPlatform.instance = _PlataformaCaminhosMock(tempDir.path);
    editor = EditorDeCroqui();
    repositorio = DatasetRepository(editorDeCroqui: editor);
    servicoSync = SyncService(datasetRepository: repositorio);
    mockTelemetria = MockTelemetryService();
    TelemetryService.instance = mockTelemetria;

    viewModel = BrowseViewModel(
      datasetRepo: repositorio,
      syncService: servicoSync,
      telemetria: mockTelemetria,
    );
  });

  tearDown(() {
    viewModel.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
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

      // Os 6 primeiros picos de BrowseViewModel devem ser idênticos aos 6 de HomeViewModel
      final idsHome = homeVm.picosProximos.map((p) => p.id).toList();
      final idsExplorarTop6 = viewModel.picosFiltrados.take(6).map((p) => p.id).toList();
      expect(idsExplorarTop6, equals(idsHome));
      expect(viewModel.picosFiltrados.length, equals(8));
      expect(viewModel.picosFiltrados[6].id, equals('pico_6'));

      // As badges de distância nos 6 primeiros cards devem ser idênticas às da Home
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
      'picosFiltrados e picosCards utilizam distância rodoviária da malha do catálogo e atualizam badges reativamente',
      () {
        repositorio.activeDataset.value = TopoDataset(
          availablePicos: [
            {
              'id': 'pico_serra',
              'nome': 'Pico Atrás da Serra',
              'latitude': -20.10,
              'longitude': -44.00,
            },
            {
              'id': 'pico_rodovia',
              'nome': 'Pico Acesso BR',
              'latitude': -20.20,
              'longitude': -44.00,
            },
          ],
          downloadedPicos: [],
        );

        viewModel.atualizarLocalizacaoUsuario(-20.00, -44.00);

        expect(viewModel.picosFiltrados.first.id, equals('pico_serra'));

        repositorio.calculadoraDistanciaEstrada.value =
            CalculadoraDistanciaEstrada(
          nos: const <NoEstrada>[
            NoEstrada(
              noOsmId: 77,
              latitude: -20.001,
              longitude: -44.000,
              distanciasPorCroquiMetros: <String, int>{
                'pico_serra': 65000,
                'pico_rodovia': 25000,
              },
            ),
          ],
        );

        expect(viewModel.picosFiltrados.first.id, equals('pico_rodovia'));
        expect(viewModel.picosCards.first.id, equals('pico_rodovia'));
        expect(viewModel.picosCards.first.textoDistancia, equals('25.1 km'));
        expect(viewModel.picosCards.last.id, equals('pico_serra'));
        expect(viewModel.picosCards.last.textoDistancia, equals('65.1 km'));
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
